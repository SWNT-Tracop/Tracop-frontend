/// Qué puede abrir cada rol. Refleja `docs/AUTHZ-MATRIX.md` del backend (generado por sus
/// pruebas): el servidor sigue siendo la autoridad; esta tabla solo evita ofrecer pantallas que
/// responderían 403.
library;

const staffRoles = {'operator', 'finance', 'admin'};
const sellerRoles = {'producer', 'supplier'};

/// Herramientas del personal fuera de la barra inferior (menú «Más herramientas»).
enum StaffTool {
  operations,
  trust,
  catalog,
  proposals,
  logistics,
  parameters,
  pricing,
  audit,
}

abstract final class RoleAccess {
  static const _staffTools = <StaffTool, Set<String>>{
    StaffTool.operations: staffRoles, // GET /backoffice/metrics
    StaffTool.trust: {'operator', 'admin'}, // /trust/staff/*
    StaffTool.catalog: {
      'operator',
      'admin'
    }, // POST /catalog/categories, /catalog/products
    StaffTool.proposals: {'operator', 'admin'}, // /catalog/product-proposals/*
    StaffTool.logistics: {
      'operator'
    }, // /logistics/trips, carriers, incidents (admin: 403)
    StaffTool.parameters:
        staffRoles, // GET /backoffice/parameters (editar: solo admin)
    StaffTool.pricing: {'operator', 'admin'}, // /pricing/mappings
    StaffTool.audit: {'admin'}, // GET /backoffice/audit
  };

  static bool isStaff(String? role) => staffRoles.contains(role);
  static bool isSeller(String? role) => sellerRoles.contains(role);

  static bool canUse(String? role, StaffTool tool) =>
      _staffTools[tool]?.contains(role) ?? false;

  /// Roles que pueden abrir una herramienta, para proteger su ruta.
  static Set<String> rolesFor(StaffTool tool) => _staffTools[tool] ?? const {};

  static List<StaffTool> toolsFor(String? role) => [
        for (final tool in StaffTool.values)
          if (canUse(role, tool)) tool
      ];

  /// PUT /backoffice/parameters/{key}: solo administración.
  static bool canEditParameters(String? role) => role == 'admin';

  /// GET /lots/mine: solo quienes venden.
  static bool hasOwnLots(String? role) => isSeller(role);
}
