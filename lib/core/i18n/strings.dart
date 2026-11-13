// Textos de la interfaz agrupados por seccion.
abstract final class NavStrings {
  static const home = 'Inicio';
  static const search = 'Buscar';
  static const myLots = 'Mis lotes';
  static const profile = 'Perfil';
  static const brand = 'TRACOP Agro';
  static const brandLogoLabel = 'TRACOP Agro';
  static const brandIsotypeLabel = 'Isotipo TRACOP';
  static const myAccount = 'Mi cuenta';
  static String profileTooltip(String name) => 'Perfil: $name';
}

abstract final class SyncStrings {
  static const checking = 'Comprobando conexión';
  static const offline = 'Sin conexión';
  static const updating = 'Actualizando';
  static const failed = 'No se pudo actualizar';
  static const upToDate = 'Al día';
  static const online = 'En línea';
  static const lostConnection =
      'Sin conexión. Seguirás viendo lo guardado en este dispositivo.';
  static const backOnline = 'Conexión recuperada.';
}

abstract final class SessionStrings {
  static const expired = 'Tu sesión venció. Ingresa de nuevo para continuar.';
  static const testMode =
      'Modo de prueba: entraste sin sesión. Las funciones que requieren el servidor pueden fallar.';
}

abstract final class NotFoundStrings {
  static const title = 'No encontramos esta página';
  static const body =
      'Puede que el enlace esté incompleto o que la sección ya no exista.';
  static const goHome = 'Ir al inicio';
}

abstract final class CommonStrings {
  static const retry = 'Reintentar';
  static const cancel = 'Cancelar';
  static const save = 'Guardar';
  static const saved = 'Guardado';
  static const understood = 'Entendido';
  static const back = 'Volver';
  static const next = 'Siguiente';
  static const previous = 'Atrás';
  static const edit = 'Editar';
  static const empty = '—';
}
