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

## Roles
Owner + 7 Built-in por organización (Administrator, Member, Worker, Finance, Resident, Site Manager, Superintendent), más roles Custom de cada empresa. Defaults en `construx/src/main/resources/built-in-roles.yml`, aplicados a todas las empresas al arrancar (`BuiltInRoleSync`, ADR 0010). Catálogo de acciones y alcances: `PermissionAction` + `permission-catalog.yml`.
- El permiso se lee de la BD en cada request: un cambio de rol aplica en la siguiente request.
- Escrituras de roles, asignaciones e invitaciones pasan por `RoleAuthority` ("nunca por encima de tu propio rol").
- 403 con código de regla: `ForbiddenRuleException` (`shared/exception`), p. ej. `ROLE_ABOVE_CALLER`, `ROLE_OWN`; un `require()` fallido sigue siendo `FORBIDDEN`.

Detalle: [[02-funcionalidades/Roles y permisos]].

## Pendientes conocidos
Rate limiting en endpoints de auth.
