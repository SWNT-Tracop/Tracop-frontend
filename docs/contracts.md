# Contratos de integración — TRACOP Mobile

Este documento describe la superficie HTTP que consume la aplicación Flutter. La app es un cliente del backend de TRACOP: las reglas de negocio, la autorización, los estados y la persistencia viven en el servidor. El cliente solo cachea datos y encola operaciones para funcionar sin conexión.

- API base: configurable con `--dart-define=API_BASE_URL=...`
- Formato: JSON (`application/json`)
- Autenticación: `Authorization: Bearer <accessToken>`
- Fechas: ISO 8601 en UTC
- Moneda: entero en pesos colombianos (COP)
- Cantidades: milésimas de unidad (`quantityMilli`)

---

## 1. Roles

| Rol | Descripción | Uso en la app |
| --- | --- | --- |
| `producer` | Productor | Publica y gestiona lotes |
| `supplier` | Proveedor / acopiador | Publica y gestiona lotes |
| `buyer` | Comprador | Explora y busca lotes |
| `carrier` | Transportista | Perfil y cuenta |
| `operator` | Staff TRACOP | No usa la app móvil |
| `finance` | Staff TRACOP | No usa la app móvil |
| `admin` | Staff TRACOP | No usa la app móvil |

Roles auto-registrables desde la app: `producer`, `supplier`, `buyer`, `carrier`.
Los roles `operator`, `finance` y `admin` se crean únicamente por CLI en el backend.

---

## 2. Modelos base

### 2.1 `User`

```json
{
  "id": "018f47a2-8b45-7cc2-9a1e-123456789abd",
  "role": "producer",
  "fullName": "María Ejemplo",
  "phone": "+573001234567",
  "status": "active",
  "locale": "es-CO"
}
```

| Campo | Tipo | Notas |
| --- | --- | --- |
| `id` | string UUID | Generado por el servidor |
| `role` | enum | Ver sección de roles |
| `fullName` | string | 2–160 caracteres |
| `phone` | string | E.164, por ejemplo `+573001234567` |
| `status` | string | `pending_verification`, `active`, `suspended` |
| `locale` | string | Por defecto `es-CO` |

### 2.2 `AuthSession`

```json
{
  "accessToken": "<jwt>",
  "refreshToken": "<token-opaco>",
  "accessTokenExpiresIn": 900,
  "refreshTokenExpiresAt": "2026-12-04T12:00:00.000Z",
  "user": {
    "id": "018f47a2-8b45-7cc2-9a1e-123456789abd",
    "role": "producer",
    "fullName": "María Ejemplo",
    "phone": "+573001234567",
    "status": "active",
    "locale": "es-CO"
  }
}
```

| Campo | Tipo | Notas |
| --- | --- | --- |
| `accessToken` | string | JWT de corta duración (900 s por defecto) |
| `refreshToken` | string | Token opaco; se guarda en almacenamiento seguro |
| `accessTokenExpiresIn` | int | Segundos de vigencia |
| `refreshTokenExpiresAt` | string ISO | Vencimiento del refresh |
| `user` | `User` | Perfil autenticado |

### 2.3 `ProviderSummary`

```json
{
  "displayName": "Finca La Esperanza",
  "municipality": "Tunja",
  "department": "Boyacá"
}
```

### 2.4 `Category`

```json
{
  "id": "018f47a2-8b45-7cc2-9a1e-123456789abc",
  "name": "Hortalizas",
  "parentId": null,
  "depth": 1
}
```

- `name`: 1–100 caracteres.
- `depth`: 1–3.
- `parentId`: UUID o `null`.

### 2.5 `Product`

```json
{
  "id": "018f47a2-8b45-7cc2-9a1e-123456789abd",
  "categoryId": "018f47a2-8b45-7cc2-9a1e-123456789abc",
  "name": "Tomate chonto",
  "unit": "kg",
  "attributes": {
    "color": "rojo",
    "organico": true
  }
}
```

- `name`: 1–120 caracteres.
- `unit`: una de las unidades aceptadas.
- `attributes`: objeto con máximo 20 claves y 2 KB serializados. Claves con el patrón `^[a-z][a-zA-Z0-9_]{0,39}$`; valores `string` (≤120), `number` o `boolean`.

### 2.6 Unidades aceptadas

```text
kg · g · lb · und · docena · arroba · quintal · caja · mano · bulto
```

La unidad del lote debe coincidir con la unidad del producto.

### 2.7 `Lot`

Respuesta para el proveedor dueño del lote:

```json
{
  "id": "018f47a2-8b45-7cc2-9a1e-123456789abe",
  "providerId": "018f47a2-8b45-7cc2-9a1e-123456789abd",
  "productId": "018f47a2-8b45-7cc2-9a1e-123456789abd",
  "quantityMilli": "25000",
  "unit": "kg",
  "unitPrice": "3200",
  "qualityGrade": "Primera",
  "availableFrom": "2026-11-05T12:00:00.000Z",
  "availableUntil": "2026-11-10T12:00:00.000Z",
  "status": "draft",
  "version": 1,
  "provider": {
    "displayName": "Finca La Esperanza",
    "municipality": "Tunja",
    "department": "Boyacá"
  },
  "locationLat": 5.5353,
  "locationLng": -73.3678
}
```

Respuesta para un comprador u otro usuario:

```json
{
  "id": "018f47a2-8b45-7cc2-9a1e-123456789abe",
  "productId": "018f47a2-8b45-7cc2-9a1e-123456789abd",
  "quantityMilli": "25000",
  "unit": "kg",
  "unitPrice": "3200",
  "qualityGrade": "Primera",
  "availableFrom": "2026-11-05T12:00:00.000Z",
  "availableUntil": "2026-11-10T12:00:00.000Z",
  "status": "published",
  "version": 2,
  "provider": {
    "displayName": "Finca La Esperanza",
    "municipality": "Tunja",
    "department": "Boyacá"
  },
  "distanceKm": 42
}
```

| Campo | Tipo | Notas |
| --- | --- | --- |
| `id` | string UUID v7 | Generado por el cliente al crear |
| `providerId` | string UUID | Solo se incluye al proveedor dueño |
| `productId` | string UUID | Producto del catálogo |
| `quantityMilli` | string | Milésimas enteras positivas |
| `unit` | enum | Debe coincidir con la unidad del producto |
| `unitPrice` | string | Pesos COP enteros, serializado como string |
| `qualityGrade` | string \| null | Máximo 100 caracteres |
| `availableFrom` | string ISO | Inicio de disponibilidad |
| `availableUntil` | string ISO | Fin de disponibilidad |
| `status` | enum | Ver estados del lote |
| `version` | int | Control de concurrencia |
| `provider` | `ProviderSummary` | Resumen público del proveedor |
| `locationLat` / `locationLng` | number | Solo se incluyen al proveedor dueño |
| `distanceKm` | int | Solo para terceros cuando la búsqueda incluyó ubicación |

### 2.8 Estados del lote

```text
draft → published → reserved → sold_out
published → expired
draft | published | reserved → cancelled
```

- Solo se edita un lote en `draft`.
- `sold_out`, `expired` y `cancelled` son estados finales.
- Las transiciones inválidas devuelven `400 invalid_transition`.

### 2.9 Página de búsqueda

```json
{
  "items": [],
  "nextCursor": "cursor-opaco-cifrado"
}
```

`nextCursor` solo aparece cuando existe otra página. Es opaco: no se decodifica ni se modifica y está ligado al `sort` usado.

---

## 3. Convenciones de datos

| Dato | Representación |
| --- | --- |
| Dinero | Entero en COP. Nunca decimales ni `float`. |
| Cantidad del lote | `quantityMilli` como string de milésimas enteras. `25000` = 25 unidades. |
| `unitPrice` en request | Entero JSON. |
| `unitPrice` en response | String con el entero. |
| Fechas | ISO 8601 UTC, por ejemplo `2026-11-05T12:00:00.000Z`. |
| Visualización de fechas | Zona `America/Bogota`. |
| UUID de lote | v7 generado en el cliente. |
| Coordenadas | Dentro de Colombia: lat `-4.3..13.7`, lng `-81.8..-66.9`. |
| Teléfono | E.164 o formato local colombiano de 10 dígitos que empieza por `3`. |

Límites del lote:

- `quantityMilli`: `1..999999999999`.
- `unitPrice`: entero positivo y seguro.
- `availableFrom <= availableUntil`.
- `availableUntil` no puede superar el horizonte configurado por el servidor (90 días por defecto).
- `qualityGrade`: `null` o texto de hasta 100 caracteres.
- El lote debe tener un perfil de proveedor para poder publicarse.

---

## 4. Autenticación

### 4.1 Registro

`POST /auth/register` — público

```json
{
  "phone": "3001234567",
  "role": "producer",
  "fullName": "María Ejemplo",
  "locale": "es-CO",
  "deviceId": "018f47a2-8b45-7cc2-9a1e-123456789abc",
  "platform": "android",
  "consent": {
    "accepted": true,
    "version": "v0-draft"
  }
}
```

Respuesta `201`:

```json
{
  "message": "Si el registro puede continuar, recibirás un código."
}
```

Reglas:

- `consent.accepted` debe ser `true`.
- `consent.version` debe coincidir con la versión vigente del servidor (`PRIVACY_POLICY_VERSION`).
- `deviceId` es un UUID persistente por instalación.
- `platform`: `ios`, `android`, `web` u `other`. La app usa `ios` o `android`.
- La respuesta no revela si el teléfono ya existía.
- Errores posibles: `invalid_phone`, `invalid_role`, `consent_required`, `consent_version_mismatch`, `invalid_full_name`, `invalid_locale`, `rate_limited`.

### 4.2 Solicitar OTP

`POST /auth/otp/request` — público

```json
{
  "phone": "3001234567"
}
```

Respuesta `201`:

```json
{
  "message": "Si el número puede autenticarse, recibirás un código.",
  "botLink": "https://t.me/tracop_demo_bot?start=link"
}
```

`botLink` permite vincular el teléfono con el bot de Telegram cuando el canal está configurado.

Límites por teléfono: 3 solicitudes por ventana de 600 s y 1 solicitud por minuto de espera. Límite por IP: 30 solicitudes por 600 s. Exceder devuelve `429 rate_limited` con `Retry-After`.

### 4.3 Verificar OTP

`POST /auth/otp/verify` — público

```json
{
  "phone": "3001234567",
  "code": "123456",
  "deviceId": "018f47a2-8b45-7cc2-9a1e-123456789abc",
  "platform": "android"
}
```

Respuesta `201`: `AuthSession` (ver 2.2).

- `code`: 4–10 dígitos.
- El OTP es de un solo uso y tiene vigencia limitada por el servidor.
- Errores: `invalid_otp`, `otp_expired`, `otp_attempts_exceeded`, `invalid_phone`, `rate_limited`.

### 4.4 Refresh

`POST /auth/refresh` — público

```json
{
  "refreshToken": "<refresh-token>",
  "deviceId": "018f47a2-8b45-7cc2-9a1e-123456789abc"
}
```

Respuesta `201`: `AuthSession` con tokens rotados.

- El refresh token anterior deja de ser válido después de la rotación.
- Reutilizar un token ya rotado revoca la familia de sesión.
- `deviceId` debe coincidir con el de la sesión.
- Errores: `401` credenciales inválidas, `invalid_session`.

### 4.5 Logout

`POST /auth/logout` — autenticado

Respuesta `201`:

```json
{
  "message": "Sesión cerrada."
}
```

Revoca la sesión actual.

### 4.6 Perfil

`GET /me` — autenticado

Respuesta `200`: `User`.

`PATCH /me` — autenticado

```json
{
  "fullName": "María Ejemplo",
  "locale": "es-CO"
}
```

- Al menos uno de los dos campos debe enviarse.
- No se permite modificar `role`, `phone` ni otros campos protegidos.
- `fullName`: 2–160 caracteres, sin caracteres de control.
- Respuesta `200`: `User` actualizado.

---

## 5. Perfil de proveedor

`PUT /me/provider-profile` — solo `producer` y `supplier`

```json
{
  "displayName": "Finca La Esperanza",
  "municipality": "Tunja",
  "department": "Boyacá",
  "lat": 5.5353,
  "lng": -73.3678,
  "description": "Productor de hortalizas."
}
```

Respuesta `200`:

```json
{
  "status": "saved"
}
```

Reglas:

- `displayName`: 2–100 caracteres.
- `municipality` y `department`: 1–100 caracteres.
- `description`: máximo 1000 caracteres.
- `lat`/`lng` dentro de Colombia.
- Es una operación de creación o actualización (upsert).
- Publicar un lote exige tener este perfil; si falta, el servidor devuelve `400 profile_required`.
- La app conserva una copia local del perfil para mostrarlo sin conexión.

---

## 6. Catálogo

### 6.1 Categorías

`GET /catalog/categories` — autenticado

Respuesta `200`: arreglo de `Category`.

```json
[
  {
    "id": "018f47a2-8b45-7cc2-9a1e-123456789abc",
    "name": "Hortalizas",
    "parentId": null,
    "depth": 1
  }
]
```

Las escrituras de categorías (`POST`, `PATCH`) están reservadas a `operator` y `admin`; la app no las usa.

### 6.2 Productos

`GET /catalog/products` — autenticado

Parámetros opcionales:

| Parámetro | Tipo | Notas |
| --- | --- | --- |
| `categoryId` | UUID | Filtra por categoría |
| `q` | string | Texto, máximo 120 caracteres |

Respuesta `200`: arreglo de `Product`.

Las escrituras de productos (`POST`, `PATCH`) están reservadas a `operator` y `admin`; la app no las usa.

---

## 7. Lotes

### 7.1 Crear lote

`POST /lots` — `producer` o `supplier`

```json
{
  "id": "018f47a2-8b45-7cc2-9a1e-123456789abe",
  "productId": "018f47a2-8b45-7cc2-9a1e-123456789abd",
  "quantityMilli": "25000",
  "unit": "kg",
  "unitPrice": 3200,
  "qualityGrade": "Primera",
  "availableFrom": "2026-11-05T12:00:00.000Z",
  "availableUntil": "2026-11-10T12:00:00.000Z",
  "locationLat": 5.5353,
  "locationLng": -73.3678
}
```

Respuesta `201`: `Lot` del dueño.

- `id` debe ser UUID v7 generado por el cliente.
- El lote se crea en estado `draft` con `version: 1`.
- `providerId`, `status` y `version` no se envían.
- `qualityGrade` es obligatorio en el cuerpo, aunque puede ser `null`.
- Reenviar el mismo `id` del mismo proveedor devuelve el lote existente, lo que hace segura la reintención.
- Errores: `invalid_quantity`, `invalid_price`, `unit_mismatch`, `invalid_availability`, `availability_horizon`, `invalid_coordinates`, `invalid_quality`, `not_found` (producto), `version_conflict`.

### 7.2 Mis lotes

`GET /lots/mine` — `producer` o `supplier`

Respuesta `200`: arreglo de `Lot` del dueño, en todos los estados.

### 7.3 Consultar lote

`GET /lots/{id}` — autenticado

Respuesta `200`: `Lot`.

- El dueño recibe `providerId`, `locationLat` y `locationLng`.
- Terceros no reciben coordenadas exactas ni `providerId`.
- Un lote no visible se devuelve como `404 not_found`.

### 7.4 Actualizar lote

`PATCH /lots/{id}` — `producer` o `supplier` dueño

```json
{
  "version": 1,
  "quantityMilli": "30000",
  "unitPrice": 3500,
  "qualityGrade": "Primera",
  "availableFrom": "2026-11-06T12:00:00.000Z",
  "availableUntil": "2026-11-12T12:00:00.000Z"
}
```

Respuesta `200`: `Lot` actualizado.

- `version` es obligatorio y debe ser la versión conocida por el cliente.
- Solo se edita un lote en `draft`.
- La versión aumenta en cada actualización.
- Si la versión no coincide, devuelve `409 version_conflict`.

### 7.5 Publicar lote

`POST /lots/{id}/publish` — `producer` o `supplier` dueño

```json
{
  "version": 1
}
```

Respuesta `200`: `Lot` con `status: "published"`.

- Requiere perfil de proveedor; si falta, devuelve `400 profile_required`.
- Si la versión no coincide, devuelve `409 version_conflict`.

### 7.6 Cancelar lote

`POST /lots/{id}/cancel` — `producer` o `supplier` dueño

```json
{
  "version": 2
}
```

Respuesta `200`: `Lot` con `status: "cancelled"`.

- Válido desde `draft`, `published` o `reserved`.
- Si la versión no coincide, devuelve `409 version_conflict`.

---

## 8. Búsqueda de lotes

`GET /lots` — autenticado

Parámetros:

| Parámetro | Tipo | Notas |
| --- | --- | --- |
| `q` | string | Texto, máximo 120 caracteres |
| `categoryId` | UUID | Incluye productos de la categoría y sus descendientes |
| `productId` | UUID | Filtra por producto |
| `minPrice` | int | Precio unitario mínimo |
| `maxPrice` | int | Precio unitario máximo |
| `availableFrom` | ISO | Disponibilidad desde |
| `availableUntil` | ISO | Disponibilidad hasta |
| `lat` | number | Latitud, junto con `lng` y `radiusKm` |
| `lng` | number | Longitud, junto con `lat` y `radiusKm` |
| `radiusKm` | number | Radio positivo; máximo configurado por el servidor (500 por defecto) |
| `sort` | enum | `price`, `distance`, `availability`, `recent` |
| `limit` | int | 1–50, por defecto 20 |
| `cursor` | string | Cursor opaco de la página anterior |

Reglas:

- `lat`, `lng` y `radiusKm` se envían juntos o no se envía ninguno.
- `sort=distance` exige `lat`, `lng` y `radiusKm`.
- Las coordenadas de búsqueda deben estar dentro de Colombia.
- El cursor está ligado al `sort`; reutilizarlo con otro orden devuelve `400 invalid_cursor`.
- `minPrice` no puede ser mayor que `maxPrice`.
- `availableFrom` no puede ser posterior a `availableUntil`.
- Rate limit: 60 búsquedas por usuario cada 60 s. Exceder devuelve `429 rate_limited` con `Retry-After`.
- Solo se devuelven lotes publicados y vigentes.

Respuesta `200`:

```json
{
  "items": [
    {
      "id": "018f47a2-8b45-7cc2-9a1e-123456789abe",
      "productId": "018f47a2-8b45-7cc2-9a1e-123456789abd",
      "quantityMilli": "25000",
      "unit": "kg",
      "unitPrice": "3200",
      "qualityGrade": "Primera",
      "availableFrom": "2026-11-05T12:00:00.000Z",
      "availableUntil": "2026-11-10T12:00:00.000Z",
      "status": "published",
      "version": 2,
      "provider": {
        "displayName": "Finca La Esperanza",
        "municipality": "Tunja",
        "department": "Boyacá"
      },
      "distanceKm": 42
    }
  ],
  "nextCursor": "cursor-opaco-cifrado"
}
```

---

## 9. Errores

Formato general:

```json
{
  "statusCode": 400,
  "code": "version_conflict",
  "message": "Conflicto de versión."
}
```

`code` puede estar ausente en errores que no son de dominio.

| HTTP | Significado | Manejo en la app |
| --- | --- | --- |
| `400` | Contrato inválido o regla de entrada | Mostrar mensaje y corregir formulario |
| `401` | Falta autenticación o sesión inválida | Intentar refresh; si falla, cerrar sesión |
| `403` | Rol sin permiso | Ocultar acción o mostrar aviso |
| `404` | Recurso inexistente o no visible | Remover de caché local |
| `409` | Conflicto de estado o versión | Resolver conflicto y reconciliar |
| `413` | Cuerpo demasiado grande | Reducir datos enviados |
| `429` | Límite de solicitudes | Respetar `Retry-After` |
| `500` | Error interno | Reintentar y mostrar estado de error |

### Códigos de dominio frecuentes

```text
invalid_phone
invalid_role
consent_required
consent_version_mismatch
invalid_full_name
invalid_locale
invalid_otp
otp_expired
otp_attempts_exceeded
invalid_session
rate_limited
invalid_quantity
invalid_price
unit_mismatch
invalid_availability
availability_horizon
invalid_coordinates
invalid_quality
invalid_transition
invalid_version
version_conflict
profile_required
invalid_search_radius
invalid_cursor
not_found
forbidden
```

---

## 10. Idempotencia y concurrencia

- No existe una cabecera general de idempotencia HTTP.
- La creación de lotes es idempotente por el `id` UUID v7 generado en el cliente: el mismo proveedor puede reintentar sin duplicar.
- Las actualizaciones, publicaciones y cancelaciones usan `version` como control optimista.
- Un reintento después de una operación exitosa puede devolver `409 version_conflict`; la app debe consultar el lote y reconciliar el estado local.
- El refresh token rota en cada uso y está vinculado al `deviceId`.
- Las operaciones offline se guardan en una cola local y se envían en orden por entidad.

---

## 11. Privacidad y permisos

- `providerId` y coordenadas exactas solo se devuelven al proveedor dueño del lote.
- A terceros se les devuelve `distanceKm` redondeado cuando la búsqueda incluyó ubicación.
- Las coordenadas enviadas al buscar o crear un lote deben estar dentro de Colombia.
- La app no registra tokens, teléfonos ni coordenadas en logs.
- El refresh token se guarda en almacenamiento seguro; el access token vive en memoria.

### Matriz de permisos

| Operación | producer | supplier | buyer | carrier | operator | finance | admin |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Registro / OTP | Sí | Sí | Sí | Sí | No | No | No |
| `/me` | Sí | Sí | Sí | Sí | Sí | Sí | Sí |
| Perfil de proveedor | Sí | Sí | No | No | No | No | No |
| Leer catálogo | Sí | Sí | Sí | Sí | Sí | Sí | Sí |
| Buscar lotes | Sí | Sí | Sí | Sí | Sí | Sí | Sí |
| Crear / editar lote | Sí | Sí | No | No | No | No | No |
| Publicar / cancelar lote | Sí | Sí | No | No | No | No | No |
| Escribir categorías / productos | No | No | No | No | Sí | No | Sí |

---

## 12. Integración offline

La app usa SQLite local como fuente de lectura y una cola de operaciones para las mutaciones.

| Operación local | Endpoint | Clave de reconciliación |
| --- | --- | --- |
| Crear lote | `POST /lots` | `id` UUID v7 |
| Editar lote | `PATCH /lots/{id}` | `version` |
| Publicar lote | `POST /lots/{id}/publish` | `version` |
| Cancelar lote | `POST /lots/{id}/cancel` | `version` |
| Guardar perfil de proveedor | `PUT /me/provider-profile` | upsert del usuario |
| Actualizar perfil | `PATCH /me` | última escritura |

Reglas de la cola:

- Cada operación tiene un `opId` local, `entity`, `entityId`, `type`, `payload` y `baseVersion`.
- Los reintentos usan espera exponencial y se detienen ante `401`.
- Un `409` marca la operación como conflicto y conserva la versión del servidor.
- Una operación rechazada no bloquea operaciones independientes de otras entidades.
- Al recuperar conexión, la cola se vacía antes de refrescar datos del servidor.

Datos que se cachean:

- Usuario autenticado y perfil de proveedor.
- Categorías y productos.
- Lotes propios.
- Resultados de búsqueda consultados.
- Última fecha de sincronización por recurso.

---

## 13. Ejemplos de errores

```json
{
  "statusCode": 400,
  "code": "profile_required",
  "message": "Completa el perfil de proveedor antes de publicar."
}
```

```json
{
  "statusCode": 409,
  "code": "version_conflict",
  "message": "Conflicto de versión."
}
```

```json
{
  "statusCode": 429,
  "code": "rate_limited",
  "message": "Demasiadas solicitudes. Intenta nuevamente más tarde."
}
```
