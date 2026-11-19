# Seguridad y autorización

↑ [[INDEX]] · Fuentes: `construx/docs/security.md`, `construx/auth.md`, `modules/identity/config/` (`SecurityConfig`, `JwtConfig`)

## Autenticación
- Cookie HttpOnly con **JWT de acceso** + **refresh token opaco rotativo**.
- Fila `auth_session` verificada en cada request (permite revocar).
- **CSRF** obligatorio en métodos no seguros: token en `GET /api/auth/csrf`.
- Login con Google vía `/oauth2`.

## Autorización por alcance
- `OrgScope` (`modules/organization/access`) y `SiteScope` (`modules/project/access`) se resuelven por request desde la ruta.
- No miembro u obra ajena → **404** antes del servicio. Luego `scope.require(PermissionAction.X)` → **403**.

## Roles sembrados
Cinco por organización: Owner, Administrator, Member, Worker, Finance. Matriz en `construx/src/main/resources/seeded-roles.properties` (ADR 0002).

## Pendientes conocidos
Rate limiting en endpoints de auth.
