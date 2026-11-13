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

abstract final class RoleStrings {
  static String label(String role) => switch (role) {
        'producer' => 'Productor',
        'supplier' => 'Proveedor',
        'buyer' => 'Comprador',
        'carrier' => 'Transportista',
        _ => role
      };
}

abstract final class ProfileStrings {
  static const title = 'Mi cuenta';
  static const notFound = 'No encontramos los datos de tu cuenta.';
  static const editName = 'Editar nombre';
  static const name = 'Nombre';
  static const phone = 'Celular';
  static const offlineEditHint = 'Conéctate a internet para editar tus datos.';
  static const nameSaved = 'Nombre actualizado.';
  static const nameLengthError =
      'Escribe un nombre de entre 2 y 160 caracteres.';
  static String editTitle(String field) => 'Editar ${field.toLowerCase()}';
  static String avatarLabel(String name) => 'Avatar de $name';

  static const completenessLabel = 'Perfil';
  static String completeness(String label, int percent) =>
      '$label $percent% completo';
  static const completeTitle = 'Tu perfil está completo.';
  static const pendingProvider =
      'Completa tu perfil de proveedor para poder publicar lotes.';
  static const pendingGeneral =
      'Completa tus datos para aprovechar mejor TRACOP.';
  static const completeNow = 'Completar ahora';

  static const providerCard = 'Perfil de proveedor';
  static String providerReady(String name, String place) =>
      'Listo · $name, $place';
  static const providerPending = 'Pendiente · necesario para publicar lotes';

  static const sectionAccount = 'Cuenta';
  static const sectionPreferences = 'Preferencias';
  static const sectionHelp = 'Ayuda y soporte';
  static const sectionAbout = 'Acerca de';
  static const whatsapp = 'Avisos por WhatsApp';
  static const sms = 'Avisos por SMS';
  static const preferencesNote =
      'Estas preferencias solo se mantienen durante esta sesión; aún no se sincronizan.';
  static const helpCenter = 'Centro de ayuda';
  static const helpCenterBody =
      'Pronto encontrarás aquí formas de contactar al equipo TRACOP.';
  static const support = 'Contactar soporte';
  static const supportTitle = 'Soporte';
  static const supportBody = 'Estamos preparando este canal de atención.';
  static const appName = 'TRACOP';
  static const tagline = 'Conectamos el campo con quienes lo necesitan';

  static const online = 'Conectado';
  static const onlineBody = 'Tus cambios se guardan al confirmar.';
  static const offline = 'Sin conexión';
  static const offlineBody =
      'Mostrando los datos guardados en este dispositivo.';

  static const logout = 'Cerrar sesión';
  static const loggingOut = 'Cerrando sesión…';
  static const logoutTitle = '¿Cerrar sesión?';
  static const logoutBody =
      'Para volver a entrar te enviaremos un código a tu celular.';
  static const logoutOfflineBody =
      'No tienes conexión. Para volver a entrar necesitarás señal para recibir el código.';
  static const logoutPreferencesNote =
      ' Las preferencias de avisos de esta sesión se perderán.';
  static const stay = 'Seguir aquí';

  static String error(String code) => switch (code) {
        'invalid_session' => 'Tu sesión venció. Inicia sesión nuevamente.',
        'network_error' => 'No hay conexión. Mostramos los datos guardados.',
        'invalid_full_name' => 'El nombre debe tener entre 2 y 160 caracteres.',
        'user_not_found' =>
          'No encontramos tu cuenta. Inicia sesión nuevamente.',
        _ => 'No pudimos actualizar la información. Intenta de nuevo.'
      };
}
