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
  static const telegram = 'Avisos por Telegram';
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
  static const localAccounts = 'Cuentas de prueba en este dispositivo';
  static const localAccountsHint =
      'Cambia entre cuentas registradas con números diferentes.';
  static const addLocalAccount = 'Agregar otra cuenta';
  static const savedAccounts = 'Cuentas guardadas';
  static const removeLocalAccount = 'Quitar del dispositivo';
  static const removeLocalAccountTitle = 'QUITAR CUENTA';
  static const removeLocalAccountBody =
      'Se eliminará la sesión guardada de este dispositivo. La cuenta seguirá activa.';
  static const accountRemoved = 'Cuenta quitada de este dispositivo.';
  static const accountSwitched = 'Cuenta cambiada.';
  static const localMultiAccountOnly =
      'Disponible solo en modo debug con la opción local activada.';

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

abstract final class LotStatusStrings {
  // Estado visto por quien vende.
  static String owner(String status) => switch (status) {
        'published' => 'Publicado',
        'draft' => 'Borrador',
        'reserved' => 'Reservado',
        'sold_out' => 'Agotado',
        'cancelled' => 'Cancelado',
        'expired' => 'Vencido',
        _ => status
      };

  // Estado visto por quien busca.
  static String public(String status) =>
      switch (status) { 'published' => 'Disponible', _ => owner(status) };
}

abstract final class LotStrings {
  static const productFallback = 'Producto agropecuario';
  static const noLocation = 'Ubicación no informada';
  static const noQuality = 'No especificada';
  static const viewLot = 'Ver lote';
  static const tapToFlipBack = 'Toca para volver';
  static String location(String municipality, String department) =>
      '$municipality, $department';
  static String quantity(String amount, String unit) => '$amount $unit';
  static String pricePer(String price, String unit) => '$price por $unit';
  static String detailsTitle(String product) => '$product · Detalles';
  static String quality(String value) => 'Calidad: $value';
  static String dateRange(String from, String until) => '$from – $until';
}

abstract final class CatalogStrings {
  static const title = 'Buscar lotes';
  static const searchLabel = 'Buscar productos o ubicación';
  static const searchHint = 'Producto o ubicación';
  static const clearSearch = 'Limpiar búsqueda';
  static const openFilters = 'Abrir filtros';
  static const sortBy = 'Ordenar:';
  static const sortRecent = 'Recientes';
  static const sortPrice = 'Menor precio';
  static const sortAvailability = 'Disponibilidad';
  static const clearFilters = 'Limpiar filtros';
  static const unknownRole =
      'No pudimos confirmar tu rol; mostramos la búsqueda general.';
  static const carrierHint =
      'Prioriza cantidad y ubicación para planear la recogida.';
  static String resultsLabel(int count) => '$count resultados cargados';
  static String results(int count, bool hasMore) =>
      '$count ${count == 1 ? 'lote cargado' : 'lotes cargados'}'
      '${hasMore ? ' · hay más resultados' : ''}';
  static const loadMore = 'Cargar más';
  static String until(String date) => 'hasta $date';
  static String availableUntil(String date) => 'Disponible hasta $date';

  static const filters = 'Filtros';
  static const category = 'Categoría';
  static const allCategories = 'Todas las categorías';
  static const product = 'Producto';
  static const allProducts = 'Todos los productos';
  static const minPrice = 'Precio mínimo (COP)';
  static const maxPrice = 'Precio máximo (COP)';
  static const priceRangeError = 'El mínimo no puede ser mayor que el máximo.';
  static const availableSoon = 'Disponible en los próximos 30 días';
  static const showResults = 'Ver resultados';
  static String priceChip(String min, String max) => 'Precio $min – $max';
  static const priceFrom = 'desde';
  static const priceUpTo = 'hasta';
  static String priceChipFrom(String min) => 'Precio $priceFrom $min';
  static String priceChipUpTo(String max) => 'Precio $priceUpTo $max';
  static const availableChip = 'Disponible próximamente';
  static String removeFilter(String label) => 'Quitar filtro $label';

  static const offlinePrefix = 'Sin conexión.';
  static const staleCachePrefix = 'No pudimos actualizar.';
  static const noCachedResults =
      'No hay resultados guardados para esta búsqueda.';
  static String lastUpdate(String date) => 'Última actualización: $date';
  static const loadError =
      'No pudimos cargar los lotes. Revisa tu conexión e inténtalo de nuevo.';
  static const noMatches = 'No encontramos lotes con esos criterios.';
  static const noLots = 'Todavía no hay lotes disponibles.';
  static const clearAndSearch = 'Quitar filtros y buscar de nuevo';
  static String page(int number) => 'Página $number';
}

abstract final class MyLotsStrings {
  static const title = 'Mis lotes';
  static const sellerSubtitle = 'Crea, publica y mantén al día tu oferta.';
  static const buyerSubtitle = 'Aquí puedes consultar los lotes de tu cuenta.';
  static const newLot = 'Nuevo lote';
  static const sortByChange = 'Ordenar por modificación';
  static const newest = 'Recientes';
  static const oldest = 'Antiguos';
  static const all = 'Todos';
  static const drafts = 'Borradores';
  static const published = 'Publicados';
  static const cancelled = 'Cancelados';
  static String heading(String filter, int count) =>
      '$filter · $count ${count == 1 ? 'lote' : 'lotes'}';
  static const working = 'Guardando cambios del lote';

  static const publishTitle = 'Publicar lote';
  static const publishBody =
      'El lote quedará visible para los compradores con la información actual.';
  static const publish = 'Publicar';
  static const published1 = 'Lote publicado.';
  static const cancelTitle = 'Cancelar lote';
  static const cancelBody =
      'El lote dejará de estar disponible y esta acción no se puede deshacer.';
  static const cancel = 'Cancelar';
  static const cancelled1 = 'Lote cancelado.';
  static const deleteTitle = 'Eliminar borrador';
  static const deleteBody = 'El borrador se eliminará de forma permanente.';
  static const delete = 'Eliminar';
  static const deleted = 'Borrador eliminado.';
  static const needsConnection = 'Necesitas conexión para hacer este cambio.';

  static const view = 'Ver lote';
  static const viewShort = 'Ver';
  static const edit = 'Editar lote';
  static String available(String range) => 'Disponible $range';
  static String availability(String range) => 'Disponibilidad: $range';

  static const offline =
      'Sin conexión. Puedes revisar tus lotes guardados; para publicar, cancelar o eliminar necesitas señal.';
  static const onlySellers =
      'Solo productores y proveedores pueden publicar lotes.';
  static const exploreOffer = 'Explora la oferta disponible desde la búsqueda.';
  static const searchLots = 'Buscar lotes';
  static const emptyFiltered = 'No hay lotes en este estado.';
  static const empty = 'Aún no tienes lotes.';
  static const emptyFilteredBody = 'Prueba con otro filtro para ver tus lotes.';
  static const emptyBody =
      'Publica tu cosecha y aparece en la búsqueda de compradores.';
  static const createLot = 'Crear lote';
  static const seeAll = 'Ver todos';
  static const firstLot = 'Publicar mi primer lote';
  static const loadError = 'No pudimos cargar tus lotes.';
  static const loadErrorBody = 'Revisa tu conexión e intenta de nuevo.';
}

abstract final class LotFormStrings {
  static const leaveTitle = '¿Salir sin guardar?';
  static const leaveBody =
      'Los cambios de este lote se perderán. Puedes guardarlo como borrador para seguir después.';
  static const keepEditing = 'Seguir editando';
  static const leave = 'Salir';
  static const useProfilePoint = 'Usar el punto de recogida de mi perfil';
  static const profilePointUsed =
      'Tomamos el punto de recogida de tu perfil. Puedes cambiarlo si este lote sale de otro lugar.';
  static const completeProfile = 'Completar perfil';
}

abstract final class LotDetailStrings {
  static const title = 'Detalle del lote';
  static const back = 'Volver';
  static const unknownRole =
      'No pudimos confirmar tu rol; ocultamos acciones específicas.';
  static const quantityPickup = 'Cantidad para recoger';
  static const quantityAvailable = 'Cantidad disponible';
  static String pricePerUnit(String unit) => 'Precio por $unit';
  static const availability = 'Disponibilidad';
  static const pickupLocation = 'Ubicación de recogida';
  static const location = 'Ubicación';
  static const quality = 'Calidad informada';
  static const status = 'Estado';
  static const originContact = 'Contacto de origen';
  static const producer = 'Productor';
  static const provider = 'Proveedor';
  static const disclaimer =
      'La disponibilidad puede cambiar. La información se confirma con el proveedor.';
  static String photoPosition(int current, int total) => '$current / $total';
  static String photoLabel(int current, int total) => 'Foto $current de $total';
  static const offline = 'Sin conexión';
  static const stale = 'No se pudo actualizar';
  static const showingSaved = 'mostrando detalle guardado';
  static String savedAt(String date) => 'guardado $date';
  static const loading = 'Cargando detalle del lote';
  static const notFound = 'Este lote ya no está disponible.';
  static const loadError = 'No pudimos cargar el detalle del lote.';
  static const backToSearch = 'Volver a buscar';
  static const backToMyLots = 'Volver a mis lotes';
}

abstract final class ProviderProfileStrings {
  static const title = 'Perfil de proveedor';
  static const onlyProducers = 'Esta sección es solo para productores.';
  static const steps = [
    'Tu operación',
    'Ubicación',
    'Punto de recogida',
    'Sobre tu oferta'
  ];
  static String stepOf(int step, int total, String name) =>
      'Paso $step de $total · $name';
  static const saveProfile = 'Guardar perfil';
  static const draftRestored =
      'Recuperamos el borrador que dejaste. Puedes seguir donde ibas.';
  static const draftKept = 'Tu borrador queda guardado en este dispositivo.';

  static const nameRequired = 'Escribe el nombre de tu finca o negocio.';
  static const locationRequired =
      'Elige primero el departamento y luego el municipio.';
  static const pointRequired =
      'Elige el punto de recogida en el mapa o usa la opción manual.';
  static const pointOutside = 'Elige un punto dentro de Colombia.';
  static String descriptionTooLong(int max) =>
      'La descripción no puede superar $max caracteres.';
  static const offlineSave =
      'Guardamos tu borrador en este dispositivo. Conéctate para enviar el perfil.';
  static const gpsUnavailable =
      'El GPS del dispositivo no está habilitado en esta versión. Puedes marcar el mapa o ingresar el punto manualmente.';

  static const nameTitle = '¿Cómo se llama tu operación?';
  static const nameBody =
      'Este nombre lo verán las personas que buscan tus productos.';
  static const nameLabel = 'Nombre de la finca o negocio';
  static const producerTypeTitle = '¿Cómo produces?';
  static const producerTypes = ['Finca familiar', 'Asociación', 'Negocio'];

  static const locationTitle = '¿Dónde está tu operación?';
  static const locationBody = 'Elige departamento y municipio de la lista.';
  static const department = 'Departamento';
  static const departmentHint = 'Seleccionar departamento';
  static const municipality = 'Municipio';
  static const municipalityHint = 'Seleccionar municipio';
  static const municipalityLocked = 'Elige primero el departamento';

  static const pointTitle = 'Marca el punto de recogida';
  static const pointBody =
      'Toca el mapa en el lugar aproximado donde podemos recoger tus productos.';
  static const useReference = 'Usar ubicación de referencia';
  static const useGps = 'Usar mi ubicación GPS';
  static const privacy = 'La ubicación exacta no se muestra a compradores.';
  static const manualShow = 'Ingresar coordenadas manualmente';
  static const manualHide = 'Ocultar ingreso manual';
  static const latitude = 'Latitud';
  static const longitude = 'Longitud';
  static String point(String lat, String lng) => 'Punto: $lat, $lng';
  static const mapLabel = 'Mapa de Colombia. Toca para elegir un punto';
  static const mapTitle = 'COLOMBIA';
  static const mapNote = 'Mapa esquemático';

  static const offerTitle = 'Cuéntales sobre tu oferta';
  static const offerBody =
      'Agrega detalles que ayuden a conocer lo que produces. Es opcional.';
  static const descriptionLabel = 'Descripción (opcional)';
  static const descriptionHint = 'Productos, cosechas o forma de entrega';
  static const descriptionChips = [
    'Producción orgánica',
    'Entrega en finca',
    'Cosecha propia'
  ];
  static const chipSeparator = ' · ';

  static const reviewTitle = 'Revisa tu perfil';
  static const reviewOperation = 'Operación';
  static const reviewLocation = 'Ubicación';
  static const reviewPoint = 'Punto';
  static const reviewDescription = 'Descripción';
  static const noDescription = 'Sin descripción';
  static String editSection(String name) => 'Editar $name';

  static const savedTitle = '¡Perfil guardado!';
  static const savedBody = 'Ya puedes empezar a ofrecer tus productos.';
  static const firstLot = 'Publicar mi primer lote';
  static const backToAccount = 'Volver a mi cuenta';
  static const goHome = 'Ir al inicio';

  static const offline =
      'Sin conexión. El borrador queda guardado en este dispositivo.';

  static String error(String code) => switch (code) {
        'invalid_profile' =>
          'Revisa el nombre, municipio, departamento y descripción.',
        'invalid_coordinates' => 'Elige un punto dentro de Colombia.',
        'forbidden' => 'Solo productores pueden guardar este perfil.',
        'network_error' =>
          'Sin conexión. El borrador sigue guardado; intenta de nuevo cuando tengas señal.',
        _ =>
          'No pudimos guardar el perfil. Verifica los datos e intenta de nuevo.'
      };
}
