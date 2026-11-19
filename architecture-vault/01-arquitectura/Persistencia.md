# Persistencia

↑ [[INDEX]]

- PostgreSQL; JPA con `ddl-auto=validate`.
- **Solo Flyway**: añade `V<n>__descripcion.sql` en `construx/src/main/resources/db/migration` (siguiente número libre). Entidad sin migración = el arranque falla.
- Archivos (planos, fotos, avatares, documentos, reportes) en **S3 privado** con URLs prefirmadas (`shared/storage`). Setup: `construx/docs/plans-aws-setup.md`.
- `ConstruxApplicationTests` corre migraciones contra la BD configurada → usa una BD desechable.
