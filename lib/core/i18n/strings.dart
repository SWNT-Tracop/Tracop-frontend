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
  static const payments = 'Pagos';
  static const paymentsSummary = 'Resumen';
  static const paymentsReview = 'Revisión';
  static const settlements = 'Liquidaciones';
  static String profileTooltip(String name) => 'Perfil: $name';
}

abstract final class SyncStrings {
  static const checking = 'Comprobando conexión';
  static const offline = 'Sin conexión';
  static const connectedToInternet = 'Conectado a internet';
  static const synced = 'Sincronizado';
  static const connectedWithPending = 'Conectado, con operaciones pendientes';
  static const noInternetConnection = 'No tienes conexión en este momento';
  static const connectionDialogHint =
      'Puedes seguir consultando la información guardada en este dispositivo.';
  static const connectionDialogAction = 'Entendido';
  static const syncCenter = 'Estado de sincronización';
  static const syncNow = 'Sincronizar ahora';
  static const syncingNow = 'Sincronizando…';
  static const operationsTitle = 'Operaciones guardadas';
  static const operationsLoadError = 'No pudimos cargar las operaciones.';
  static const noActiveSession = 'No hay una sesión activa.';
  static const retryOperation = 'Reintentar';
  static const discardOperation = 'Descartar';
  static const acceptServerVersion = 'Usar versión del servidor';
  static const pendingStatus = 'Pendiente';
  static const conflictStatus = 'Conflicto';
  static const rejectedStatus = 'Rechazada';
  static const appliedStatus = 'Aplicada';
  static const noPendingOperations = 'No hay operaciones pendientes.';
  static String pendingSummary(int count) => 'Pendientes: $count';
  static String failedSummary(int count) => 'Requieren revisión: $count';
  static const updating = 'Actualizando';
  static const failed = 'No se pudo actualizar';
  static const upToDate = 'Al día';
  static const online = 'En línea';
  static const lostConnection =
      'Sin conexión. Seguirás viendo lo guardado en este dispositivo.';
  static const backOnline = 'Conexión recuperada.';
  static const neverSynced = 'Sin una sincronización exitosa registrada.';
  static const syncNoConnection =
      'No hay conexión. Tus cambios siguen guardados en este dispositivo.';
  static const syncServerUnavailable =
      'El servicio no está disponible. Tus cambios siguen guardados aquí.';
  static const syncRateLimited =
      'Has realizado muchas solicitudes. Intenta más tarde.';
  static const syncSessionExpired =
      'Tu sesión venció. Inicia sesión nuevamente para sincronizar.';
  static const syncConflict =
      'El servidor tiene una versión diferente. Revisa la operación.';
  static const syncForbidden =
      'No tienes permisos para sincronizar este cambio.';
  static const syncGenericFailure =
      'No pudimos sincronizar todavía. Tus cambios siguen guardados aquí.';
  static const lotsUpdateFailed = 'No pudimos actualizar tus lotes';
  static String serverVersion(int version) => 'versión del servidor $version';
  static String lastSynced(DateTime value) =>
      'Última sincronización exitosa: ${value.toLocal()}';
}

abstract final class TelegramStrings {
  static const codeByTelegram = 'Te enviaremos el código por Telegram.';
  static const title = 'Tu código llega por Telegram';
  static const stepOpen = '1. Abre el bot de TRACOP en Telegram.';
  static const stepShare = '2. Pulsa «Compartir mi contacto».';
  static const stepCode = '3. El bot te envía el código: escríbelo aquí.';
  static const alreadyLinked =
      'Si ya vinculaste Telegram, el código llega a ese chat.';
  static const openBot = 'Abrir Telegram';
  static const resend = 'Reenviar código';
  static const resent = 'Te enviamos un código nuevo por Telegram.';
  static const cannotOpen =
      'No pudimos abrir Telegram. Instálalo y vuelve a intentarlo.';
  static const privacyConsent = 'Acepto el aviso de privacidad';
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
        'operator' => 'Operaciones TRACOP',
        'finance' => 'Finanzas TRACOP',
        'admin' => 'Administración TRACOP',
        _ => role
      };
}

abstract final class LogisticsStrings {
  static const title = 'Logística';
  static const intro = 'Organiza tus viajes y confirma cada parada.';
  static const candidates = 'Pedidos disponibles';
  static const trips = 'Mis viajes';
  static const noCandidates = 'No hay pedidos listos para recoger.';
  static const refreshCandidates = 'Actualizar pedidos';
  static const noTrips = 'Todavía no tienes viajes asignados.';
  static const createTrip = 'Crear viaje';
  static const selectOrders = 'Selecciona al menos un pedido.';
  static const tripCreated = 'Viaje guardado para sincronizar.';
  static const localTripCreated =
      'Viaje guardado en este dispositivo, sin sincronizar.';
  static const localTripNotice =
      'Viaje local: se guarda únicamente en este dispositivo.';
  static const startTrip = 'Iniciar viaje';
  static const checkinPickup = 'Confirmar recogida';
  static const checkinDelivery = 'Confirmar entrega';
  static const checkinSaved = 'Check-in guardado para sincronizar.';
  static const reportIncident = 'Reportar novedad';
  static const incidentSaved = 'Novedad guardada para sincronizar.';
  static const pendingSync = 'acciones pendientes de sincronización';
  static String pendingSyncCount(int count) => count == 1
      ? '1 acción pendiente de sincronización'
      : '$count $pendingSync';
  static const route = 'Recorrido';
  static const delivery = 'Entrega';
  static const pickup = 'Recogida';
  static const order = 'Pedido';
  static const offlineNotice =
      'Sin conexión: verás los datos guardados y tus acciones se enviarán al volver a conectarte.';
  static const homeHeadline = 'Tus viajes, a tu ritmo.';
  static const homeDescription =
      'Consulta pedidos listos, organiza tu recorrido y confirma cada parada.';
  static const openLogistics = 'Abrir logística';
  static const saveTripError = 'No pudimos guardar el viaje. Intenta de nuevo.';
  static const candidatesLoadError = 'No pudimos cargar pedidos.';
  static const tripsLoadError = 'No pudimos cargar tus viajes.';
  static const vehicleSetup = 'Completa tu vehículo';
  static const vehicleSetupHint = 'Necesario para crear viajes.';
  static const complete = 'Completar';
  static const vehicleData = 'Datos del vehículo';
  static const vehicleType = 'Tipo de vehículo';

  /// PROVISIONAL: vocabulario de vehículos del piloto (§23).
  static const vehicleTypes = ['Moto', 'Carro', 'Camioneta', 'Camión', 'Otro'];
  static const vehicleCapacity = 'Capacidad (kg)';
  static const plate = 'Placa';
  static const profileSaved = 'Perfil guardado para sincronizar.';
  static const profileSaveError = 'No pudimos guardar los datos del vehículo.';
  static const vehicleValidation =
      'Revisa tipo, capacidad y placa del vehículo.';
  static const candidatesEmptyHint =
      'Aquí solo aparecen pedidos con el pago verificado. Cuando se confirme, estarán listos para recoger.';
  static const pickupAt = 'Recoge en';
  static const deliveryAt = 'Entrega en';
  static String orderShort(String id) => 'Pedido $id';
  static String deliveryWindow(String date) => 'Ventana: $date';
  static const tripsEmptyHint =
      'Selecciona pedidos disponibles para organizar tu primer viaje.';
  static String tripShort(String id) => 'Viaje $id';
  static const saveActionError = 'No pudimos guardar la acción.';
  static const tripUnavailable = 'Viaje no disponible';
  static const refreshTripsHint =
      'Actualiza la lista de viajes para continuar.';
  static const backToLogistics = 'Volver a logística';
  static const tripStartSaved = 'Inicio del viaje guardado para sincronizar.';
  static const localActionSaved =
      'Cambio guardado en este dispositivo, sin sincronizar.';
  static const stopsLoadError = 'No pudimos cargar las paradas.';
  static const incidentType = 'Tipo';
  static const delay = 'Retraso';
  static const cargoIssue = 'Problema con la carga';
  static const other = 'Otro';
  static const incidentDescription = '¿Qué ocurrió?';
  static const incidentSaveError = 'No pudimos guardar la novedad.';
  static const noStops = 'Sin paradas';
  static const noStopsHint = 'Este viaje todavía no tiene paradas registradas.';
  static const failedOperations = 'acciones necesitan revisión.';
  static const pendingSavedLocally =
      'Tus cambios siguen guardados en este dispositivo.';
  static const syncNotAccepted =
      'Algunas acciones necesitan revisión. Tus datos locales se conservaron.';
  static const syncCouldNotSend =
      'No se pudo enviar todavía. Tus cambios siguen guardados aquí.';
  static const retrySync = 'Reintentar sincronización';
  static const recordLocalPayment = 'Registrar pago local (demo)';
  static const paymentReported = 'Pago reportado. Pendiente de confirmación.';
  static const locallyPaidStatus = 'Pago reportado, pendiente de confirmación';
  static const pendingTrip = 'Pendiente de sincronización';
  static String tripStatus(String status) => switch (status) {
        'planned' => 'Planeado',
        'assigned' => 'Asignado',
        'in_progress' => 'En curso',
        'completed' => 'Completado',
        'cancelled' => 'Cancelado',
        'sync_pending' => pendingTrip,
        _ => status,
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
  static const productProposals = 'Propuestas de productos';
  static const noProductProposals = 'Aún no tienes propuestas de productos.';
  static const pendingReview = 'Pendiente';
  static const approved = 'Aprobada';
  static const rejected = 'Rechazada';
  static const rejectionReason = 'Motivo';
  static const resubmit = 'Proponer nuevamente';
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
  static const publishedPending =
      'Publicación guardada en este dispositivo. Pendiente de sincronización.';
  static const cancelledPending =
      'Cancelación guardada en este dispositivo. Pendiente de sincronización.';
  static const deletedPending =
      'Eliminación guardada en este dispositivo. Pendiente de sincronización.';

  static const view = 'Ver lote';
  static const viewShort = 'Ver';
  static const edit = 'Editar lote';
  static String available(String range) => 'Disponible $range';
  static String availability(String range) => 'Disponibilidad: $range';

  static const offline =
      'Sin conexión. Los cambios se guardan en este dispositivo y se sincronizan al recuperar señal.';
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
  static const pointRequired =
      'Toca el mapa en el punto de recogida, o usa el de tu perfil o tu ubicación.';
  static const pointOutside =
      'El punto de recogida debe estar en Colombia. Elígelo en el mapa.';
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
      'Toca el mapa en el punto de recogida, o usa el centro del municipio o tu ubicación.';
  static const pointOutside = 'Elige un punto dentro de Colombia.';
  static String descriptionTooLong(int max) =>
      'La descripción no puede superar $max caracteres.';
  static const offlineSave =
      'Guardamos tu borrador en este dispositivo. Conéctate para enviar el perfil.';
  static const gpsServiceDisabled =
      'La ubicación del celular está apagada. Actívala y vuelve a intentarlo.';
  static const gpsPermissionDenied =
      'Necesitamos permiso de ubicación para usar tu GPS. También puedes tocar el mapa.';
  static const gpsDeniedForever =
      'El permiso de ubicación está bloqueado. Actívalo en los ajustes de la app.';
  static const gpsUnavailable =
      'No pudimos leer tu ubicación. Intenta de nuevo al aire libre o toca el mapa.';
  static const gpsOutside =
      'Tu ubicación está fuera de Colombia. Toca el mapa.';
  static const gpsLocating = 'Buscando tu ubicación…';
  static const openSettings = 'Abrir ajustes';

  static const nameTitle = '¿Cómo se llama tu operación?';
  static const nameBody =
      'Este nombre lo verán las personas que buscan tus productos.';
  static const nameLabel = 'Nombre de la finca o negocio';
  static const producerTypeTitle = '¿Cómo produces?';
  static const producerTypes = ['Finca familiar', 'Asociación', 'Negocio'];

  static const locationTitle = '¿Dónde está tu operación?';
  static const locationBody =
      'Elige el departamento y luego busca tu municipio por su nombre.';
  static const department = 'Departamento';
  static const departmentHint = 'Seleccionar departamento';
  static const municipality = 'Municipio';
  static const municipalityHint = 'Seleccionar municipio';
  static const municipalityLocked = 'Elige primero el departamento';

  static const pointTitle = 'Marca el punto de recogida';
  static const pointBody =
      'Acerca el mapa y toca el lugar donde podemos recoger tus productos.';
  static String useMunicipalityCentre(String municipality) =>
      'Usar el centro de $municipality';
  static const useGps = 'Usar mi ubicación actual';
  static const privacy = 'La ubicación exacta no se muestra a compradores.';
  static const pointChosen = 'Punto de recogida marcado.';
  static const mapLabel = 'Mapa. Toca para elegir el punto de recogida';
  static const mapOffline =
      'Sin conexión el mapa no carga. Usa el centro de tu municipio y ajústalo después.';
  static const mapAttribution = '© OpenStreetMap';

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

abstract final class PaymentStrings {
  // Estados (textos del documento funcional de pagos).
  static String status(String wire) => switch (wire) {
        'pending' => 'Pendiente de pago',
        'proof_uploaded' => 'Comprobante pendiente de revisión',
        'verified' => 'Pago verificado',
        'held' => 'Pago retenido hasta la entrega',
        'rejected' => 'Pago rechazado',
        'disputed' => 'Pago en disputa',
        'settled' => 'Pago liquidado',
        'refunded' => 'Pago reembolsado',
        '' => 'Estado desconocido',
        _ => 'Estado desconocido ($wire)',
      };

  /// Rótulo para mostrar un pago: igual que `status`, salvo una disputa
  /// liberada (el API la devuelve como `held` con `disputeReason`).
  static String statusLabel(String wire, {bool disputeResolved = false}) =>
      disputeResolved ? disputeResolvedLabel : status(wire);
  static const disputeResolvedLabel = 'Disputa resuelta';

  static const methodTransfer = 'Transferencia';
  static const methodNequi = 'Nequi';
  static String method(String wire) => switch (wire) {
        'transfer' => methodTransfer,
        'nequi' => methodNequi,
        '' => 'Medio desconocido',
        _ => wire,
      };
  static const loading = 'Cargando';

  // Comprador.
  static const screenTitle = 'PAGO DEL PEDIDO';
  static String orderShort(String id) =>
      'Pedido #${id.substring(0, 8).toUpperCase()}';
  static const pay = 'Pagar';
  static const viewPayment = 'Ver pago';
  static const orderSummary = 'Resumen del pedido';
  static const products = 'Productos';
  static String lotShort(String id) =>
      'Lote ${id.substring(0, 8).toUpperCase()}';
  static const subtotal = 'Subtotal';
  static const freight = 'Flete';
  static const commission = 'Comisión TRACOP';
  static const total = 'Total a pagar';
  static const totalShort = 'Total';
  static const providerNet = 'Neto del proveedor';
  static const amountsFromPayment = 'Montos registrados en el pago.';
  static const amountsFromOrder = 'Montos de la cotización aceptada.';
  static const chooseMethod = 'Elige cómo vas a pagar';
  static const transferHint = 'Desde tu banco a la cuenta de TRACOP';
  static const nequiHint = 'Desde tu app Nequi';
  static const methodLocked =
      'El medio de pago queda fijado para este pago. Si lo rechazan, podrás elegir otro.';
  static String continueWith(String method) => 'Continuar con $method';
  static const starting = 'Registrando pago…';
  static const notPayableYet =
      'Este pedido todavía no está listo para pagar. Primero acepta la cotización.';
  static const orderClosedForPayment =
      'Este pedido no admite pagos en su estado actual.';
  static const orderNotPayableTitle =
      'Pedido cancelado o reserva vencida: no transfieras';
  static const orderNotPayableBody =
      'Este pedido ya no se puede pagar. No hagas ninguna transferencia; si ya la hiciste, comunícate con TRACOP con el número del pedido.';
  static const paymentsUnavailableTitle = 'Pagos no disponibles por el momento';
  static const paymentsUnavailableBody =
      'Estamos configurando los datos de pago de TRACOP. Intenta más tarde y no transfieras todavía.';
  static const instructionsTitle = 'Cómo pagar';
  static const transferSteps =
      'Haz una transferencia por el total exacto a esta cuenta y guarda el comprobante.';
  static const nequiSteps =
      'Envía el total exacto a este número Nequi y toma captura del comprobante.';
  static const bank = 'Banco';
  static const accountType = 'Tipo de cuenta';
  static const accountNumber = 'Número de cuenta';
  static const accountHolder = 'Titular';
  static const accountHolderId = 'NIT';
  static const nequiNumber = 'Número Nequi';
  static const placeholderWarning =
      'Datos de cuenta de ejemplo: confirma con TRACOP antes de pagar.';
  static const copy = 'Copiar';
  static String copied(String label) => '$label copiado.';
  static const referenceHint =
      'En la descripción del pago escribe el número del pedido.';
  static const currentStatus = 'Estado del pago';
  static const statusPendingBody =
      'Cuando hagas el pago, sube aquí el comprobante para que lo revisemos.';
  static const statusProofUploadedBody =
      'Recibimos tu comprobante. El equipo de TRACOP lo revisará pronto; mientras tanto tu reserva se mantiene.';
  static const statusVerifiedBody =
      'Confirmamos tu pago. El pedido sigue con la recogida y el envío.';
  static const statusHeldBody =
      'El pedido fue entregado. El dinero queda retenido un tiempo por si hay algún reclamo antes de pagar al proveedor.';
  static const statusRejectedBody =
      'No pudimos validar el comprobante. Puedes iniciar un nuevo pago.';
  static const statusDisputedBody =
      'Abriste una disputa. El equipo de TRACOP la revisará y te contactará.';
  static const statusDisputeResolvedBody =
      'TRACOP revisó la disputa y decidió continuar con el pedido. El pago sigue su curso hacia la liquidación al proveedor.';
  static const statusSettledBody =
      'El pago se completó y se liquidó al proveedor.';
  static const statusRefundedBody =
      'Registramos la devolución. La transferencia se hace por fuera de la app.';
  static const statusUnknownBody =
      'Esta versión de la app no reconoce el estado del pago. Actualiza la app o consulta con TRACOP.';
  static const rejectionReason = 'Motivo del rechazo';
  static const disputeReason = 'Motivo de la disputa';
  static const startNewPayment = 'Iniciar un nuevo pago';
  static const proofTitle = 'Comprobante de pago';
  static const uploadProof = 'Subir comprobante';
  static const uploadingProof = 'Subiendo comprobante…';
  static const cancelUpload = 'Cancelar';
  static const cancelUploadTooltip = 'Cancelar la carga del comprobante';
  static const uploadCancelled =
      'Carga cancelada. Tu pago no cambió; puedes subir el comprobante cuando quieras.';
  static const chooseFromGallery = 'Elegir de la galería';
  static const takePhoto = 'Tomar foto';
  static String proofRequirements(int megabytes) =>
      'Imagen JPEG, PNG o WebP de máximo $megabytes MB. Debe verse el valor, la fecha y la referencia.';
  static const proofUploaded = 'Comprobante enviado. Lo revisaremos pronto.';
  static const pickerFailed =
      'No pudimos abrir la cámara o la galería. Revisa los permisos e intenta de nuevo.';
  static const retryUpload = 'Reintentar carga';
  static const proofImageLabel = 'Imagen del comprobante';
  static const openProof = 'Ver comprobante en grande';
  static const proofUnavailable = 'Este pago todavía no tiene comprobante.';
  static const expiredLinkTitle = 'El enlace del comprobante venció';
  static const expiredLinkBody =
      'Por seguridad, el enlace dura pocos minutos. Vuelve a cargarlo para verlo.';
  static const reload = 'Volver a cargar';
  static const close = 'Cerrar';

  // Hitos (no hay historial completo en el API).
  static const milestonesTitle = 'Hitos del pago';
  static const milestonesHint =
      'Solo se muestran las fechas que registra el pago; no es un historial completo.';
  static const milestoneCreated = 'Pago iniciado';
  static const milestoneProofUploaded = 'Comprobante enviado';
  static const milestoneVerified = 'Pago verificado';
  static const milestoneRejected = 'Comprobante rechazado';
  static const milestoneHeld = 'Pedido entregado, pago retenido';
  static const milestoneDisputed = 'Disputa abierta';
  static const milestoneDisputeResolved = 'Disputa resuelta';
  static const milestoneNoDate = 'Fecha no registrada';
  static String milestoneCurrent(String status) =>
      'Última actualización: $status';
  static const bogotaTimeNote = 'Horas en hora de Colombia.';

  // Disputa del comprador.
  static const openDispute = 'Abrir disputa';
  static const disputeTitle = 'Abrir una disputa';
  static const disputeIntro =
      'Cuéntanos qué pasó con el pedido. El equipo de TRACOP revisará tu caso.';
  static const disputeWarning =
      'Mientras la disputa esté abierta, el pago al proveedor queda bloqueado. Úsala solo si hubo un problema real con el pedido.';
  static const disputeReasonLabel = 'Motivo *';
  static const disputeReasonHint = 'Ej.: llegó incompleto o en mal estado';
  static const reasonRequired = 'Escribe el motivo.';
  static const reasonTooLong = 'Máximo 500 caracteres.';
  static const confirmDisputeTitle = '¿Abrir la disputa?';
  static const confirmDisputeBody =
      'No podrás deshacerlo desde la app. El pago al proveedor quedará bloqueado hasta que TRACOP resuelva.';
  static const confirmDispute = 'Sí, abrir disputa';
  static const disputeOpened = 'Disputa abierta. Te contactaremos pronto.';

  // Personal TRACOP.
  static const reviewTitle = 'REVISIÓN DE PAGOS';
  static const reviewIntro =
      'Comprobantes por verificar y disputas abiertas, del más antiguo al más reciente.';
  static const refresh = 'Actualizar';
  static String lastRefresh(String time) => 'Actualizado a las $time';
  static const autoRefreshNote =
      'Se actualiza cada minuto mientras esté abierta.';
  static const searchLabel = 'Buscar por id de pago o de pedido';
  static const filterStatus = 'Estado';
  static const filterMethod = 'Medio';
  static const filterAll = 'Todos';
  static const filterProofs = 'Por verificar';
  static const filterDisputes = 'Disputas';
  static String resultsCount(int shown, int total) =>
      shown == total ? '$total pagos' : '$shown de $total pagos';
  static const reviewEmptyTitle = 'No hay pagos por revisar';
  static const reviewEmptyBody =
      'Cuando un comprador suba un comprobante o abra una disputa, aparecerá aquí.';
  static const reviewNoMatchesTitle = 'Ningún pago coincide';
  static const reviewNoMatchesBody = 'Cambia los filtros o la búsqueda.';
  static const clearFilters = 'Limpiar filtros';
  static const reviewLoadError = 'No pudimos cargar la cola de revisión.';
  static String reviewHidden(int count) => count == 1
      ? 'Hay 1 pendiente más que no se muestra.'
      : 'Hay $count pendientes más que no se muestran.';
  static const reviewHiddenUnknown =
      'Puede haber más pendientes que no se muestran.';
  static const reviewHiddenHelp =
      'El servidor entrega como máximo 100, empezando por los que llevan más tiempo sin cambios; los más recientes quedan fuera. Resuelve los más antiguos primero y actualiza para ver los siguientes.';
  static const columnPayment = 'Pago';
  static const columnOrder = 'Pedido';
  static const columnMethod = 'Medio';
  static const columnStatus = 'Estado';
  static const columnTotal = 'Total';
  static const columnWaiting = 'En espera';
  static String waiting(Duration age) {
    if (age.inMinutes < 1) return 'hace menos de 1 min';
    if (age.inHours < 1) return 'hace ${age.inMinutes} min';
    if (age.inDays < 1) return 'hace ${age.inHours} h';
    return 'hace ${age.inDays} d';
  }

  static String waitingSinceAt(String dateTime) => 'Desde $dateTime';
  static String overdue(int hours) => 'Más de $hours h';
  static const overdueTooltip = 'Lleva más tiempo del esperado sin revisión.';
  static String shortId(String id) => id.substring(0, 8).toUpperCase();

  static const detailTitle = 'DETALLE DEL PAGO';
  static const paymentId = 'Id del pago';
  static const orderId = 'Id del pedido';
  static const copyId = 'Copiar id';
  static const idCopied = 'Id copiado.';
  static const orderAccessNote =
      'El detalle del pedido no está disponible para el personal en el API actual; usa el id para buscarlo en el backoffice.';
  static const methodLabel = 'Medio de pago';
  static const version = 'Versión';
  static const createdAt = 'Creado';
  static const proofUploadedAt = 'Comprobante enviado';
  static const reviewedAt = 'Revisado';
  static const heldAt = 'Retenido desde';
  static const updatedAt = 'Última actualización';
  static const backToInbox = 'Volver a la revisión';
  static const noActions = 'No hay acciones disponibles en este estado.';
  static const detailLoadError = 'No pudimos cargar el pago.';

  static const verify = 'Verificar pago';
  static const verifyTitle = '¿Verificar este pago?';
  static const verifyBody =
      'Confirmas que recibiste este valor en la cuenta de TRACOP:';
  static const verifyConsequences =
      'El pedido pasará a pagado y la reserva de los lotes se consumirá. Esta acción no se puede deshacer.';
  static const confirmVerify = 'Sí, verificar';
  static const verified = 'Pago verificado.';

  static const reject = 'Rechazar';
  static const rejectTitle = 'Rechazar comprobante';
  static const rejectIntro = 'Elige o escribe el motivo. El comprador lo verá.';
  static const rejectReasons = [
    'El comprobante es ilegible.',
    'El valor no coincide con el total del pedido.',
    'No encontramos el dinero en la cuenta de TRACOP.',
    'El comprobante no corresponde a este pedido.',
  ];
  static const rejectReasonLabel = 'Motivo del rechazo *';
  static const rejectConsequences =
      'El comprador podrá iniciar un nuevo pago. La reserva del pedido vuelve a vencer tras un periodo de gracia.';
  static const confirmReject = 'Rechazar comprobante';
  static const rejected = 'Comprobante rechazado.';

  static const resolve = 'Resolver disputa';
  static const resolveTitle = 'Resolver disputa';
  static const releaseTitle = 'Liberar al proveedor';
  static const releaseBody =
      'El pago vuelve a "retenido" y seguirá a liquidación al proveedor.';
  static const releaseUnavailable =
      'No disponible: el pedido no se ha entregado.';
  static const refundTitle = 'Reembolsar al comprador';
  static const refundBody =
      'Se registra la devolución en TRACOP. La transferencia al comprador se hace por fuera de la app.';
  static const resolutionNoteLabel = 'Nota de resolución *';
  static const resolutionNoteHint = 'Qué se verificó y por qué se decide así';
  static const chooseOutcome = 'Elige una resolución.';
  static const orderWillClose = 'En ambos casos el pedido queda cerrado.';
  static const confirmRelease = 'Liberar pago';
  static const confirmRefund = 'Registrar reembolso';
  static const resolved = 'Disputa resuelta.';

  // Auditoría (solo administración).
  static const auditTitle = 'Auditoría';
  static const auditHint =
      'Acciones del personal sobre este pago, de la más reciente a la más antigua. Solo la ve administración.';
  static const auditEmpty = 'No hay acciones registradas para este pago.';
  static const auditLoadError = 'No pudimos cargar la auditoría.';
  static const auditLoadMore = 'Cargar más';
  static const auditSystem = 'Sistema';
  static String auditActor(String role, String? shortId) =>
      shortId == null ? 'Por $role' : 'Por $role · $shortId';
  static String auditAction(String action) => switch (action) {
        'payment.verify' => 'Pago verificado',
        'payment.reject' => 'Comprobante rechazado',
        'payment.dispute_release' => 'Disputa liberada al proveedor',
        'payment.dispute_refund' => 'Disputa resuelta con reembolso',
        'settlement.mark_paid' => 'Liquidación marcada como pagada',
        _ => action,
      };

  static const conflictTitle = 'El pago cambió';
  static const conflictBody =
      'Otra persona actualizó este pago mientras lo revisabas. Carga la última versión y revisa antes de continuar.';
  static const loadLatest = 'Cargar última versión';
}

abstract final class SettlementStrings {
  static const title = 'LIQUIDACIONES';
  static const intro =
      'Pagos a proveedores y transportistas. Marca cada una como pagada cuando hagas la transferencia.';
  static const loadError = 'No pudimos cargar las liquidaciones.';
  static const emptyTitle = 'No hay liquidaciones';
  static const emptyIssuedBody =
      'No hay liquidaciones por pagar. Se emiten cuando se confirma la entrega de un pedido.';
  static const emptyBody = 'Todavía no hay liquidaciones en este estado.';
  static const noMatchesTitle = 'Ninguna liquidación coincide';
  static const noMatchesBody = 'Cambia los filtros o la búsqueda.';
  static const limitNote =
      'El servidor entrega como máximo las 100 liquidaciones emitidas más recientemente; las más antiguas no aparecen aquí.';
  static String hiddenIssued(int count) => count == 1
      ? 'Hay 1 liquidación por pagar más antigua que no se muestra.'
      : 'Hay $count liquidaciones por pagar más antiguas que no se muestran.';
  static const hiddenIssuedHelp =
      'El servidor solo entrega las 100 más recientes. Al marcar como pagadas las visibles y actualizar, aparecerán las siguientes.';
  static String resultsCount(int shown, int total) => shown == total
      ? '$total ${total == 1 ? 'liquidación' : 'liquidaciones'}'
      : '$shown de $total liquidaciones';

  // Filtros.
  static const searchLabel = 'Buscar por id de pedido o de pago';
  static const filterStatus = 'Estado';
  static const filterIssued = 'Emitidas';
  static const filterPaid = 'Pagadas';
  static const filterAll = 'Todas';
  static const filterKind = 'Beneficiario';
  static const filterKindAll = 'Todos';
  static const filterPeriod = 'Emitidas en';
  static const periodAll = 'Cualquier fecha';
  static const period7 = 'Últimos 7 días';
  static const period30 = 'Últimos 30 días';
  static const periodRange = 'Elegir fechas…';
  static String periodRangeLabel(String from, String to) =>
      from == to ? from : '$from – $to';
  static const clearRange = 'Quitar rango de fechas';
  static const rangePickerHelp = 'Fecha de emisión (hora de Colombia)';

  // `producer` es el proveedor del pedido (productor o proveedor).
  static String kind(String wire) => switch (wire) {
        'producer' => 'Proveedor',
        'carrier' => 'Transportista',
        '' => 'Beneficiario desconocido',
        _ => wire,
      };
  static String status(String wire) => switch (wire) {
        'issued' => 'Por pagar',
        'paid' => 'Pagada',
        '' => 'Estado desconocido',
        _ => wire,
      };

  // Columnas.
  static const columnBeneficiary = 'Beneficiario';
  static const columnOrder = 'Pedido';
  static const columnPayment = 'Pago';
  static const columnAmount = 'Monto';
  static const columnStatus = 'Estado';
  static const columnIssued = 'Emitida';
  static const columnPaid = 'Pagada';
  static const columnReference = 'Referencia';
  static const noDate = '—';
  static const noReference = 'Sin referencia';
  static String openPayment(String shortId) => 'Abrir pago $shortId';

  // Marcar como pagada.
  static const markPaid = 'Marcar pagada';
  static const markPaidTitle = 'Marcar liquidación como pagada';
  static const markPaidIntro =
      'Registra el pago solo después de hacer la transferencia al beneficiario.';
  static const beneficiary = 'Beneficiario';
  static const amount = 'Monto a pagar';
  static const referenceLabel = 'Referencia de la transferencia *';
  static const referenceHint = 'Ej.: número de comprobante del banco';
  static const referenceHelp =
      'Queda guardada en la liquidación para conciliar con el extracto.';
  static const referenceRequired = 'Escribe la referencia de la transferencia.';
  static const referenceTooLong = 'Máximo 100 caracteres.';
  static const irreversibleWarning =
      'Esta acción no se puede deshacer. Si es la última liquidación del pago, el pago queda liquidado y el pedido se cierra.';
  static const continueLabel = 'Continuar';
  static const confirmTitle = '¿Confirmas que ya pagaste?';
  static const confirmBody =
      'Vas a registrar como pagada esta liquidación con la referencia:';
  static const confirmMarkPaid = 'Sí, marcar como pagada';
  static const markedPaid = 'Liquidación marcada como pagada.';
  static const conflictTitle = 'La liquidación cambió';
  static const conflictBody =
      'Otra persona actualizó esta liquidación. Cargamos la lista de nuevo; revísala antes de continuar.';

  // En el detalle del pago.
  static const paymentSectionTitle = 'Liquidaciones de este pago';
  static const paymentSectionEmpty =
      'No encontramos liquidaciones de este pago entre las 100 más recientes.';
  static const heldNotIssuedYet =
      'Todavía no hay liquidaciones: se emiten al terminar la ventana de reclamo tras la entrega (parámetro payment.claim_window_hours, 48 h por defecto).';
  static const settledOutOfRange =
      'Fuera de las 100 más recientes: las liquidaciones de este pago no están entre las que entrega el servidor. Búscalas en la lista de liquidaciones.';
  static const backToSettlements = 'Volver a liquidaciones';
  static const viewInSettlements = 'Ver en liquidaciones';
  static const paymentSectionError =
      'No pudimos cargar las liquidaciones de este pago.';
  static String paidOn(String date) => 'Pagada el $date';
  static String issuedOn(String date) => 'Emitida el $date';

  // Quién marcó la liquidación como pagada (auditoría, solo administración).
  static const showPaidBy = 'Ver quién la marcó pagada';
  static String paidBy(String role, String? shortId, String date) =>
      'Marcada pagada por $role${shortId == null ? '' : ' · $shortId'} el $date';
  static const paidByMissing =
      'No hay registro en la auditoría de quién la marcó pagada.';
  static const paidByError = 'No pudimos consultar la auditoría.';
  static const paidByUnavailable =
      'Quién la marcó pagada: no disponible (solo administración ve la auditoría).';
}

abstract final class LedgerStrings {
  static const title = 'Libro contable del pedido';
  static const readOnly =
      'Solo lectura. Cada transacción debe cuadrar: débitos = créditos.';
  static const empty = 'Este pedido todavía no tiene asientos contables.';
  static const loadError = 'No pudimos cargar el libro contable.';
  static const account = 'Cuenta';
  static const debit = 'Débito';
  static const credit = 'Crédito';
  static const total = 'Total del pedido';
  static const balanced = 'Cuadrado';
  static String unbalanced(String difference) => 'Descuadre de $difference';
  static const someUnbalanced = 'Hay transacciones descuadradas';
  static const unbalancedHelp =
      'Los débitos y créditos no coinciden. Reporta el pedido al equipo técnico.';
  static const zero = '—';

  static String kind(String wire) => switch (wire) {
        'payment_verified' => 'Pago verificado',
        'delivery_confirmed' => 'Entrega confirmada',
        'settlement_paid_producer' => 'Liquidación al proveedor',
        'settlement_paid_carrier' => 'Liquidación al transportista',
        'refund' => 'Reembolso',
        '' => 'Asiento desconocido',
        _ => wire,
      };

  static String accountName(String account) => switch (account) {
        'cash_held' => 'Dinero recibido en custodia',
        'payable_buyer_funds' => 'Fondos del comprador',
        'payable_producer' => 'Por pagar al proveedor',
        'payable_carrier' => 'Por pagar al transportista',
        'revenue_commission' => 'Ingreso por comisión',
        _ => account,
      };
}

abstract final class PaymentsDashboardStrings {
  static const title = 'RESUMEN DE PAGOS';
  static const intro = 'Lo que necesita atención hoy y el estado del dinero.';
  static String updated(String dateTime) => 'Actualizado: $dateTime';
  static const loadError = 'No pudimos cargar el resumen de pagos.';

  static const proofs = 'Comprobantes por revisar';
  static const disputes = 'Disputas abiertas';
  static const issued = 'Liquidaciones por pagar';
  static const paid = 'Liquidaciones pagadas';
  static const paidOrders = 'Pedidos pagados';
  static const paidOrdersHint = 'Total cobrado a compradores';
  static String paidOrdersCount(int value) =>
      count(value, 'pedido pagado', 'pedidos pagados');
  static String count(int value, String singular, String plural) =>
      '$value ${value == 1 ? singular : plural}';
  static String settlementsCount(int value) =>
      count(value, 'liquidación', 'liquidaciones');
  static String oldest(String age) => 'El más antiguo: $age';
  static const noneWaiting = 'Nada en espera';
  static const reviewProofs = 'Revisar comprobantes';
  static const reviewDisputes = 'Ver disputas';
  static const openIssued = 'Pagar liquidaciones';
  static const openPaid = 'Ver pagadas';

  static String overdueAlert(int count, int hours, String age) =>
      '$count ${count == 1 ? 'comprobante lleva' : 'comprobantes llevan'} '
      'más de $hours h sin revisar (el más antiguo, $age).';

  static const barTitle = 'Liquidaciones: pagado vs por pagar';
  static const barEmpty = 'Todavía no hay liquidaciones emitidas.';
  static const legendPaid = 'Pagado';
  static const legendIssued = 'Por pagar';
  static String percent(int value) => '$value %';
  static String barSemantics(String paid, String issued) =>
      'Pagado $paid, por pagar $issued';
  static String pendingCount(int count) =>
      count == 1 ? '1 por pagar' : '$count por pagar';
}
