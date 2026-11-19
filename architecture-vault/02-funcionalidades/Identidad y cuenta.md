# Identidad y cuenta

↑ [[INDEX]] · Módulo `identity` · Dashboard: `features/auth`, `features/profile`, `features/onboarding`

## Registro y verificación
`POST /api/auth/register` → email de verificación → `POST /api/auth/verify` (`/resend` para reenviar).

## Sesión
`login`, `refresh`, `logout`, `GET /api/auth/me`, `GET /api/auth/csrf`. Google: `/oauth2` + `POST /api/auth/google/link`. Detalle en [[01-arquitectura/Seguridad y autorización]].

## Contraseña
`POST /api/auth/password` (cambio), `/password/forgot`, `/password/reset`.

## Perfil
`/api/profile` (GET/PUT), avatar con subida prefirmada (`/avatar/uploads` → `PUT /avatar`). Incluye oficio (`trade`). Contrato: `construx/docs/user-profile.md`.

## Onboarding
`GET/PUT /api/onboarding` guarda `intent` y `businessType` (no asigna rol, ADR 0002).

Endpoints completos: [[03-endpoints/API#Identidad]].
