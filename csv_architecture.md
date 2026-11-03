# Guía de datos ConstruBASE → CSV

Esta guía explica cada hoja y cada columna de los dos archivos exportados de ConstruBASE (1-abr-2026), cómo se relacionan entre sí y cómo convertirlos a CSV para usarlos en una app.

- **Archivo A – FASAR** (`..._FasarEstandar_UMAXn_PESOS.xls`): cálculo del **Factor de Salario Real (FSR/FASAR)** de la mano de obra, conforme al art. 191 del RLOPSRM (Reglamento de la Ley de Obras Públicas), con cuotas IMSS/INFONAVIT expresadas sobre la UMA. Moneda: pesos.
- **Archivo B – Presupuesto** (`..._Presupuesto.xlsx`): **base de datos de precios unitarios**: catálogo de insumos y conceptos, presupuesto por partidas, matrices (análisis de precio unitario), detalle de mano de obra y de maquinaria (costos horarios).

---

## 1. Recomendaciones generales para exportar a CSV

1. **Una hoja = un CSV.** Nombra el archivo con el nombre de la hoja sin espacios ni paréntesis (ej. `catalogo_general.csv`, `fasar_salarios.csv`).
2. **Codificación UTF-8** (hay acentos y "Ø"). Separador coma, texto entre comillas dobles (las descripciones largas contienen comas).
3. **Exporta valores, no formatos.** En Excel se ven cosas como `$290.00`, `1,006.42`, `16.00%` o `######`. En el CSV deben quedar como número puro: `290`, `1006.42`, `0.16`. El `######` sólo significa que la columna es angosta; el valor real existe.
4. **Porcentajes como fracción decimal** (`7.58875%` → `0.0758875`). Documenta en tu app que todos los % se guardan así.
5. **Fechas en ISO** `AAAA-MM-DD`. Ojo: los archivos mezclan `2019/12/05` y `05/12/2019` (día/mes/año). La fecha `01/01/1900` significa **"sin fecha"** → guárdala como vacía/NULL.
6. **Códigos siempre como texto.** Hay códigos que parecen número (`10301`, `103030`) o que empiezan con `%` o contienen `:` (`1:4`). Si se tratan como número se pierden ceros o se rompen las relaciones.
7. **Hojas de reporte vs. hojas de datos.** El archivo B ya trae tablas limpias (encabezado en la fila 1). En el archivo A casi todas las hojas son *reportes impresos* con encabezado de empresa en las filas 1-14; ahí hay que exportar **sólo el bloque tabular** indicado en cada sección.
8. **Columnas con sufijo 0 / 1 / 2** (`Costo0`, `Costo1`, `Costo2`, `SalarioBaseM0`…) = **moneda 0, 1 y 2**: 0 = M.N. (pesos), 1 = DLS (dólares), 2 = EURO. En estos archivos sólo la moneda 0 tiene valores; las demás están en 0.

---

## 2. Archivo A – FASAR (Factor de Salario Real)

### Flujo de cálculo

```
N_Campos Generales ─┐
uma ────────────────┤
a)TablaFactores ────┼──► e) / g) Fsr  ◄── f) / h) Ps (IMSS+INFONAVIT por categoría)
b) CapturaDatos ────┤          │
c) Horas Extras ────┘          ▼
                         d) Salarios  (resultado: salario real por categoría)
                         o) / p) Fasar en una sola tabla  (resumen)
                         q) / r) Fasar individual (una ficha por categoría)
```

Cada cálculo existe en dos variantes: **Jornada normal de 8 h** (hojas e, f, o, q y columnas izquierdas de d) y **Jornada con horas extras** (hojas g, h, p, r y columnas derechas de d). En este archivo sólo la jornada de 8 h tiene categorías capturadas.

### 2.1 `N_Campos Generales` — datos generales del documento
Tabla clave-valor (exportar filas 5-61, columnas A-C). Las filas en mayúsculas sin valor (`DATOS DE LA EMPRESA`, `DATOS DEL CLIENTE`…) son títulos de grupo: puedes usarlas como columna `grupo`.

| Columna | Significado |
|---|---|
| NOMBRE DE CELDA | Clave interna del dato (también es el *nombre definido* que usan las fórmulas). |
| DESCRIPCION | Explicación del dato. |
| VALOR | Valor capturado. |

Claves principales:
- **Empresa:** `razonsocial`, `domicilio`, `colonia`, `ciudad`, `estado`, `rfc`, `telefono`, `email`, `cmic`, `infonavit`, `imss` (registros patronales), `responsable` y `cargo` (quien firma).
- **Cliente:** `nombrecliente`, `area`, `departamento`, `direccioncliente`, `coloniacliente`, `codigopostalcliente`, `ciudadcliente`, `telefonocliente`, `emailcliente`, `contactocliente`.
- **Concurso / licitación:** `fechadeconcurso`, `numerodeconcurso`, `direcciondeconcurso`, `numconvocatoria`, `fechaconvocatoria`, `tipodelicitacion`.
- **Obra:** `nombredelaobra`, `direcciondelaobra`, `coloniadelaobra`, `ciudaddelaobra`, `estadodelaobra`, `codigopostaldelaobra`, `telefonodelaobra`, `emaildelaobra`, `responsabledelaobra`, `cargoresponsabledelaobra`, `fechainicio`, `fechaterminacion`.
- **Totales y formato:** `totalpresupuestoprimeramoneda` / `segundamoneda` (importe total), `porcentajeivapresupuesto` (IVA, 16 %), `plazocalculado` (días naturales), `plazoreal` (días hábiles), `decimalesredondeo` (decimales de importes), `primeramoneda` / `segundamoneda` (nombre de la moneda, ej. PESOS), `remateprimeramoneda` / `rematesegundamoneda` (texto que sigue al importe en letra, ej. "M.N.").

### 2.2 `uma` — Unidad de Medida y Actualización
| Celda | Significado |
|---|---|
| `uma_cap` | Valor de la UMA diaria capturado en pesos (86.88). |
| `uma` | UMA usada en los cálculos: si el FASAR se trabaja "en veces UMA" (TipodeFasar = 1) vale 1; si se trabaja en importes (TipodeFasar = 2) vale lo mismo que `uma_cap`. |

### 2.3 `a)TablaFactores` — cuotas obrero-patronales (parámetros del año)
Es una tabla de parámetros. Recomendado: CSV "largo" con columnas `concepto, patron, trabajador, total`.

| Concepto (columna) | Significado | Base de cálculo |
|---|---|---|
| I. Riesgo de trabajo | Prima de riesgo de trabajo IMSS (sólo patrón). | SBC |
| II. Cuota fija | Enfermedad y maternidad, cuota fija (20.4 %). | UMA |
| II. Excedente de tres UMA | Enf. y maternidad sobre lo que el SBC exceda 3 UMA. | SBC − 3 UMA |
| II. Prestaciones en dinero | Enf. y maternidad, prestaciones en dinero. | SBC |
| II. Gastos médicos pensionados | Prestaciones en especie de pensionados. | SBC |
| III. Invalidez y vida | Seguro de invalidez y vida. | SBC (tope límite 2) |
| IV. Retiro (SAR) | Ahorro para el retiro. | SBC |
| IV. Cesantía en edad avanzada y vejez | | SBC (tope límite 2) |
| V. Guarderías y prestaciones sociales | | SBC |
| INFONAVIT | Aportación de vivienda (5 %). | SBC |
| Impuesto Sobre Nómina | ISN estatal (aquí 0 %). | SBC |
| Otros cargos | Cargo adicional libre que se suma al FSR (aquí 0 %). | — |

Filas: **PATRON** (% que paga el patrón), **TRABAJADOR** (% que paga el trabajador), **TOTAL CUOTA** (suma; es lo que se usa en el cálculo).

Otros parámetros de la hoja:
- `AÑO PARA CAPTURA DE FACTORES`: año de vigencia de las cuotas (2019).
- `SALARIO MINIMO`: salario mínimo diario (123.22).
- `Limite superior grupo 1` y `grupo 2`: topes del SBC en veces UMA (25 = 25 UMA).
- `Unidad de Medida y Actualización UMA`: 86.88.
- `TIPO DE FASAR`: 1 = cálculo con factores (veces UMA), 2 = cálculo con importes en pesos.
- `REDONDEO PARA FACTORES`: decimales para los factores (6).

### 2.4 `b) CapturaDatos` — días del año (base del FSR)
Exportar filas 16-38. Dos columnas de valores: **Jornadas 8 Horas** y **Jornadas Horas Extras**.

| Renglón | Dato | Significado |
|---|---|---|
| — | Días calendario anualizado | Días del periodo (365). Es **DICAL**. |
| 1.1 | Domingos | Días de descanso semanal. |
| 1.2 | Vacaciones | Días de vacaciones (art. 76 LFT). |
| 1.3 | Días lunes | Ausentismo por "san lunes". |
| 1.4 | Días festivos por ley | Art. 74 LFT. |
| 1.5 | Condiciones climatológicas | Días perdidos por lluvia, etc. |
| 1.6 | Días por costumbre | Por contrato colectivo / costumbre (ej. 3 de mayo, 12 dic). |
| 1.7 | Permisos y enfermedad no profesional | |
| 1.8 | Días sindicato | Por contrato colectivo. |
| 2.1 | Aguinaldo | Días pagados de aguinaldo (art. 87 LFT, 15). |
| 2.2 | Prima vacacional | % (25 %) y días equivalentes (= vacaciones × %). |
| 2.3 | Prima dominical | % y días equivalentes (= domingos × %). |
| — | Días equivalentes por horas extras gravables / no gravables | Sólo jornada con horas extras; vienen de la hoja c). |
| 2.4 | Total días equivalentes por horas extras | Suma de los dos anteriores. |
| 2.5-2.8 | ISN, SAR, INFONAVIT, Otros cargos | % tomados de `a)TablaFactores` (sólo informativos aquí). |

Las filas 40 en adelante son notas legales (no exportar).

### 2.5 `c)Horas Extras` — cálculo de días equivalentes por tiempo extra
Tabla de parámetros `concepto, valor`:
- **Días calendario / semanas laboradas / horas por turno / días laborados por semana** → horas laboradas en el periodo.
- **Horas permitidas por la LFT** (8 h/día, 6 días/semana; arts. 61 y 69).
- **Horas extras por turno** y **días con horas extras por semana** → horas extra del periodo.
- **Horas extras permitidas (art. 66, máx. 9 h/semana)** se pagan **dobles** → `Numero de días equivalentes a días dobles` = horas × 2 / 8.
- **Horas extras excedentes** se pagan **triples** → `Número de días equivalentes a días triples` = horas × 3 / 8.
- **Total de días equivalentes a horas extras** = dobles + triples (se suma a los días pagados).

### 2.6 `d)Salarios` — **tabla principal de categorías de mano de obra**
Exportar desde la fila 7 (encabezado en fila 6) y descartar filas sin código. Lado izquierdo = jornada 8 h (columnas B-I); lado derecho = jornada con horas extras (columnas K-Q, mismas columnas sin "No").

| Columna | Significado |
|---|---|
| No | Número consecutivo (1-500). |
| CODIGO | Clave de la categoría (ej. `MO011`). **Llave** que enlaza con el archivo B (`DetalleManoObra.Codigo`). |
| DESCRIPCION DE CATEGORIA | Puesto (PEON, OFICIAL ALBAÑIL…). |
| SALARIO NOMINAL Sn | Salario diario nominal en pesos (lo que se le paga al trabajador por día). |
| FACTOR SALARIO BASE COTIZACION | FSBC = días pagados / días calendario (1.045205). Multiplicado por Sn da el SBC para IMSS. |
| FACTOR SALARIO REAL | **FSR** de la categoría (≈1.70). |
| SALARIO REAL | Sn × FSR, en pesos: costo diario real para la empresa. Es el valor que se usa en los precios unitarios. |
| Sn EQUIVALENTE AL SALARIO EN UMA | Sn ÷ UMA (salario expresado en veces UMA). |

### 2.7 `f)Ps_factorJornada8hrs` y `h)Ps_factorJornadaExtra` — obligaciones obrero-patronales (Ps)
Exportar desde la fila 20 (encabezados en filas 13-19). Una fila por categoría.

| Col | Nombre | Cálculo | Significado |
|---|---|---|---|
| A | Clave de categoría | — | Código `MO…` |
| B | Salario nominal Sn | — | Pesos o veces UMA según TipodeFasar. |
| C | FSBC | — | Factor de salario base de cotización. |
| D | SBC | B × C | Salario base de cotización. |
| E | Riesgo de trabajo | % × SBC | Cuota diaria en pesos. |
| F | Cuota fija | % × UMA | |
| G | Excedente de tres UMA | SBC − 3 UMA | Monto excedente (no es cuota). |
| H | Aplicación IMSS al excedente | % × G | Cuota sobre el excedente. |
| I | Prestaciones en dinero | % × SBC | |
| J | Gastos médicos pensionados | % × SBC | |
| K | Invalidez y vida | % × SBC | |
| L | Retiro (SAR) | % × SBC | |
| M | Cesantía y vejez | % × SBC | |
| N | Guarderías | % × SBC | |
| O | INFONAVIT | % × SBC | |
| P | Impuesto sobre nómina | % × SBC | |
| Q | Suma prestaciones (SP) | E+F+H+…+P | Total de cuotas diarias. |
| R | Ps | Q ÷ D | Obligación obrero-patronal como fracción decimal (≈0.30). |

Las filas 17-19 de la hoja son los % PATRON / TRABAJADOR / CUOTA TOTAL (ya están en `a)TablaFactores`). Arriba (fila 11) están los topes: salario mínimo, UMA, 3 UMA y 25 UMA.

### 2.8 `e) Fsr_FactorJornada8hrs` y `g) Fsr_FactorJornadaExtra` — Factor de Salario Real
**Bloque de parámetros** (filas 15-34), exportar como clave-valor:

| Clave | Significado |
|---|---|
| DICAL | Días calendario. |
| DIAGI | Días de aguinaldo. |
| PIVAC | Días por prima vacacional. |
| Prima dominical | Días por prima dominical. |
| **Tp** | Total de días realmente pagados al año (suma de los anteriores, + horas extra en la jornada extra). |
| DIDOM, DIVAC, DILUN, DIFEO, DIPEC, DIPCO, DIPEN, DISIN | Domingos, vacaciones, lunes, festivos, clima, costumbre, permisos/enfermedad, sindicato (días no laborados). |
| DINLA | Días no laborados al año (suma). |
| **Tl** | Días realmente laborados = DICAL − DINLA. |
| Tp/Tl | Días pagados entre días laborados. |
| FSBC | (Tp − Te) / DICAL. Te = tiempo extra no gravable. |

**Tabla de salarios reales** (desde la fila 40; letras A-H en la fila 39):

| Col | Nombre | Significado |
|---|---|---|
| A | CLAVE | Código de categoría. |
| B | CATEGORÍAS | Descripción. |
| C | Salario nominal | Sn. |
| D | Tp/Tl | |
| E | Ps | Viene de la hoja f)/h). |
| F | Ps × (Tp/Tl) | |
| G | Otros cargos | % adicional. |
| H | **Fsr** | = Ps·(Tp/Tl) + (Tp/Tl) + Otros cargos. |

### 2.9 `o)Fasar Una TablaJnormal` y `p)Fasar Una TablaJextra` — resumen en una sola tabla
Combina los dos cálculos anteriores. Bloque de parámetros en filas 16-37 (igual que 2.8, añade `(Tp−Te)/Tl` y `OC` = otros cargos) y tabla desde la fila 48 con columnas A-U:
A Clave · B Descripción · C Tp/Tl · D Sn · E FSBC · F SBC · G-R cuotas (igual que f), corridas una letra) · S Suma de prestaciones · T Ps · U **FSR**.
**Para tu app basta con esta hoja o con `d)Salarios`**; e/f/g/h contienen la misma información desglosada.

### 2.10 `q)Fasar Individual_Jnormal` y `r)Fasar Individual_Jextra`
Fichas imprimibles, una por categoría (bloques repetidos de ~37 filas). **No conviene pasarlas a CSV**: todo su contenido ya está en las tablas anteriores.

### Fórmulas clave (para recalcular en tu app)
```
Tp   = DICAL(días calendario) + aguinaldo + prima vacacional + prima dominical [+ días equiv. horas extra]
Tl   = DICAL − días no laborados
FSBC = (Tp − Te) / DICAL
SBC  = Sn × FSBC
Ps   = Σ cuotas IMSS/INFONAVIT/ISN diarias ÷ SBC
FSR  = Ps × (Tp − Te)/Tl + Tp/Tl + OtrosCargos
Salario real = Sn × FSR
```
Topes: cuota fija se calcula sobre la UMA; excedente sobre (SBC − 3 UMA); el SBC se topa en 25 UMA.

---

## 3. Archivo B – Presupuesto (base de precios unitarios)

### Modelo de relaciones
```
Partidas (árbol WBS) ──< Presupuesto >── CatalogoGeneral (Tipo 4 = concepto)
                                              │
                                              └──< Matrices >── CatalogoGeneral (insumos: Tipo 1/2/3, o conceptos auxiliares)

CatalogoGeneral Tipo 2 (mano de obra) ── DetalleManoObra
CatalogoGeneral Tipo 3 (equipo)       ── DetalleMaquinaria ──< OperacionCH / ConsumosCH
CatalogoGeneral.Familia   → Familias.Familia
CatalogoGeneral.Proveedor → Proveedores.Proveedor
CatalogoGeneral.Unidad    → Unidades.Unidad
```

### 3.1 `N_Campos Generales`
Mismo formato clave-valor que en el archivo A (ver 2.1), con claves adicionales:
- `cargocontacto`, `telefonocontacto`, `mailcontacto`: datos del contacto del cliente.
- `codigodelaobra`, `observacionesobra`.
- `codigovendedor`, `nombrevendedor`, `cargovendedor`, `telefonovendedor`, `mailvendedor`.
- `decimalesredondeoconceptos` (4): decimales de cantidades en conceptos. `decimalesredondeoexplosion` (8): decimales de la explosión de insumos.
- **Programa de obra:** `Periodicidad` (1 mensual, 2 quincenal, 3 semanal, 4 diaria), `Numero de programa`, `Programa Vigente`, `Tipo de captura` (1 porcentajes, 0 cantidades), `Numero de periodos`, `Descripcion Programa`, `FechaInicioPrograma`, `FechaFinalPrograma`.
- **FASAR:** `Salario Mínimo`, `Impuesto sobre nomina`, `Otros cargos`, `Sar`, `Invonavit`, `Riesgo de trabajo`, `Patron + Trabajado` (1 = se suman cuotas patrón + trabajador). ⚠️ Aquí los % están mal formateados en Excel (`200%` significa **2 %**, `759%` significa **7.59 %**): divide entre 100 al importar.
- **Monedas** (filas 92-97): pares clave/descripción: `M.N.`=PESOS (moneda 0), `DLS`=DOLARES (1), `EURO`=EUROS (2).

### 3.2 `PorcentajesCh` — porcentajes del costo horario en espera / reserva
Cuando una máquina está **en espera** (detenida en obra) o **en reserva** (disponible sin trabajar) sólo se cobra parte de su costo horario.

| Columna | Significado |
|---|---|
| Cargo | Componente del costo horario: depreciación, inversión, seguros, mantenimiento, combustible, lubricante, llantas, piezas especiales, operación, otras fuentes de energía. |
| Espera | % de ese cargo que se aplica con el equipo en espera. |
| Reserva | % que se aplica con el equipo en reserva. |

### 3.3 `CatalogoGeneral` — **catálogo maestro** (34,869 registros)
Contiene todo: insumos y conceptos (precios unitarios).

| Columna | Significado |
|---|---|
| Codigo | **Llave primaria** (texto). |
| Descripcion completa | Descripción larga (especificación del concepto). |
| Descripcion | Descripción corta (máx. 40 caracteres). |
| Unidad | Unidad de medida → `Unidades.Unidad`. |
| Tipo | **Tipo de registro:** 1 = Material (24,375), 2 = Mano de obra / cuadrilla (85), 3 = Equipo / maquinaria / herramienta (145), 4 = Concepto de obra / precio unitario (10,264). |
| Familia | Clasificación → `Familias.Familia`. |
| Agrupador | Agrupador adicional (0 = ninguno). |
| % | 1 = el insumo es un porcentaje (ej. `%MO1` herramienta menor); 0 = insumo normal. |
| Tipo % | Base sobre la que se aplica el porcentaje (2 = sobre el importe de mano de obra). |
| Proveedor | Proveedor → `Proveedores.Proveedor`. |
| FichaTecnica | Ruta o referencia a la ficha técnica. |
| Referencia | Texto libre de referencia (ej. "VARIOS"). |
| CodigoSap | Código en un ERP externo. |
| InsumoDescontinuado | 1 = ya no se usa. |
| Procedimiento | Procedimiento constructivo (texto). |
| InsumoIntegrado | 1 = es un insumo compuesto por otros (tiene matriz). |
| EsCostoHorario | 1 = su costo proviene de un cálculo de costo horario. |
| Costo0 / Costo1 / Costo2 | Costo unitario en moneda 0 (pesos), 1 (dólares), 2 (euros). Para conceptos (Tipo 4) es el **costo directo** del precio unitario. |
| Fecha0 / Fecha1 / Fecha2 | Fecha de actualización de cada costo (01/01/1900 = sin fecha). |

Prefijos de código observados: `MO…` categorías de mano de obra; `1A`, `1A1P`… cuadrillas; `EQ…` equipos; `CF…`/`VA…`/`LL…` cargo fijo, valor de adquisición y llantas de un equipo; `%MO…` porcentajes; `301-ARE-0101` materiales (familia-clave-consecutivo); `10301-001` conceptos (partida-consecutivo).

### 3.4 `Unidades`
| Columna | Significado |
|---|---|
| Unidad | Clave de unidad (M2, M3, KG, JOR = jornada, HOR = hora, PZA = pieza, % …). |
| Descripcion | Nombre ("Sin descripción" = no capturada). |
Las columnas C-E vienen vacías: no exportarlas. Hay claves duplicadas con distinta escritura (`HR`, `HRS`, `HOR`; `M2`, `Mt2`); conviene normalizarlas.

### 3.5 `Presupuesto` — conceptos dentro de cada partida (10,264 renglones)

| Columna | Significado |
|---|---|
| PartidaWBS | Partida a la que pertenece el concepto (código jerárquico `1.01.001`) → `Partidas.PartidaWbs`. |
| Partida | Clave corta de la partida (`10301`). |
| Codigo | Concepto → `CatalogoGeneral.Codigo` (Tipo 4). |
| Control | Identificador interno único del renglón. |
| Renglon | Orden del concepto dentro de la partida (10, 20, 30…). |
| Cantidad | Cantidad de obra del concepto. |
| CantidadTotal | Cantidad total; se infiere que es cantidad × multiplicadores de las partidas padre (aquí siempre igual a Cantidad). |
| IndirectoEspecial | 1 = el concepto usa un % de indirectos propio. |
| PorcentajeIndirectoEspecial | Ese % especial. |
| CodigoAuxiliar / DescripcionAuxiliar | Clave y descripción alternas (ej. clave del cliente). |
| Costo0 / precio0 | Costo directo unitario y precio unitario (con indirectos, financiamiento, utilidad y cargos) en moneda 0. Aquí son iguales: el presupuesto no tiene sobrecosto aplicado. |
| Costo1 / precio1, Costo2 / precio2 | Igual en monedas 1 y 2. |
Importe del renglón = `Cantidad × precio0`.

### 3.6 `Partidas` — árbol del presupuesto (WBS)

| Columna | Significado |
|---|---|
| PadreWbs | Partida padre (vacío = raíz). Permite armar el árbol. |
| PartidaWbs | Código jerárquico de la partida (`1`, `1.01`, `1.01.001`…). Llave. |
| Partida | Clave corta de la partida. |
| Renglon | Orden dentro de su padre. |
| DescripcionPartida | Descripción corta / clave. |
| DescripcionPartidaLarga | Nombre de la partida (PRELIMINARES, Limpia y Tala…). |
| MetrosCuadrados | m² de referencia (para costo por m²). |
| Cantidad | Multiplicador de la partida (cuántas veces se repite). |
| Costo0 / Precio0 … Costo2 / Precio2 | Importe total de la partida por moneda (suma de sus conceptos e hijos). |

### 3.7 `Matrices` — análisis de precios unitarios (82,051 renglones)
Cada renglón dice "el código M lleva X cantidad del insumo I".

| Columna | Significado |
|---|---|
| CodigoM | Código "padre": concepto, cuadrilla o insumo compuesto (ej. mortero `1:4`). |
| CodigoI | Insumo que lo compone → `CatalogoGeneral.Codigo`. Puede ser a su vez otro compuesto (recursivo). |
| Renglon | Orden del insumo en la matriz. |
| / | Operador: `*` = la cantidad es un **consumo** (importe = cantidad × costo); `/` = la cantidad es un **rendimiento** (importe = costo ÷ cantidad; ej. cuadrilla `/ 200` = rinde 200 m² por jornada). |
| Cantidad | Consumo o rendimiento. Para insumos `%` es una fracción (0.03 = 3 % de la mano de obra). |
| Expresion | Fórmula de origen de la cantidad (ej. `350/8`, `1/(1.83*2.44)`); casi siempre vacía. |
Las columnas G-H vienen vacías.

Costo directo de un concepto = Σ (costo del insumo × cantidad) para `*` + Σ (costo ÷ cantidad) para `/` + Σ (% × importe de mano de obra) para insumos `%`.

### 3.8 `DetalleManoObra` — salarios de las categorías
Una fila por categoría `MO…`. Columnas repetidas para M0, M1 y M2 (monedas):

| Columna | Significado |
|---|---|
| Codigo | Categoría → `CatalogoGeneral.Codigo` y `d)Salarios.CODIGO` del archivo A. |
| SalarioBaseM0 | Salario nominal diario (Sn). |
| FasarM0 | Factor de salario real (FSR), viene del archivo A. |
| SalarioRealM0 | Sn × FSR (costo usado en los análisis). |
| FactorSalarioIntegradoM0 | FSBC. |
| SalarioIntegradoM0 | SBC = Sn × FSBC. |
| ViaticosM0, AlimentacionYHospedajeM0, GastosDeSepelioM0, OtrasPrestacionesM0 | Prestaciones adicionales diarias. |
| TipoFasarM0 | Tipo de FASAR usado (1 = jornada normal). |

### 3.9 `DetalleMaquinaria` — datos para el costo horario de equipos (60 equipos)

| Columna | Significado |
|---|---|
| Codigo | Equipo → `CatalogoGeneral.Codigo` (Tipo 3). |
| UnidadPotencia | Unidad de potencia (HP, KW). |
| CargoFijo | Código del insumo que guarda el cargo fijo calculado (`CF…`). |
| ValorAdquisicion | Código del insumo con el valor de adquisición (`VA…`). |
| EqEspera / EqReserva | Códigos de los costos horarios en espera / reserva. |
| Llantas | Código del insumo de llantas. |
| PzaEsp | Código del insumo de piezas especiales. |
| Combustible / Lubricante / OtrasFuentes | Códigos de los insumos de combustible, aceite y otras energías. |
| VidaEconomicaLlantas / VidaEconomicaPiezas | Vida en horas de llantas y piezas especiales. |
| TipoCalculo | Método de cálculo del costo horario. |
| potencia | Potencia nominal. |
| foper | Factor de operación (%). |
| TipoCombustible | Código del tipo de combustible (1, 2, 3). El archivo no trae la tabla de equivalencias; probablemente gasolina / diésel / otro: confírmalo en ConstruBASE. |
| FactorCombustible / FactorOtrasFuentes / FactorLubricante | Coeficientes de consumo por unidad de potencia y hora. |
| CapacidadCarter | Capacidad del cárter (litros). |
| HorasCambio | Horas entre cambios de aceite. |
| VidaEconomicaHrs | Vida económica del equipo en horas. |
| HorasAño | Horas efectivas de uso por año. |
| ValorRescate | % del valor de adquisición recuperable al final de su vida. |
| PrimaSeguros | % anual de seguros. |
| FactorMantenimiento | Coeficiente de mantenimiento (Ko). |
| Marca, Modelo, NumeroSerie, Capacidad, Ubicacion, VidaUtil, Propietario | Datos descriptivos. |
| Disponibilidad | Estado de disponibilidad (texto). |
| ValorComercial | Valor comercial actual. |
| CantidadCombustible / CantidadLubricante | Consumos calculados por hora. |
| ProponerCodigos | Bandera interna del sistema. |
| TasaInteresM0 / M1 / M2 | Tasa de interés anual (%) para el cargo por inversión, por moneda. |

### 3.10 `OperacionCH` — operadores del equipo
| Columna | Significado |
|---|---|
| CodigoM | Equipo. |
| CodigoI | Categoría o cuadrilla que lo opera. |
| / | Operador (siempre `/`). |
| cantidad | Horas por turno (8 = el salario de la jornada se divide entre 8 h). |

### 3.11 `ConsumosCH` — consumos del equipo por hora
| Columna | Significado |
|---|---|
| CodigoM | Equipo. |
| CodigoI | Insumo consumido (combustible, gas, discos…). |
| / | Operador (`*` = consumo por hora). |
| cantidad | Cantidad consumida por hora. |

### 3.12 `Familias`
| Columna | Significado |
|---|---|
| Familia | Clave de la familia de insumos. |
| Descripcion | Nombre de la familia. |

### 3.13 `Proveedores`
`Proveedor` (clave), `RazonSocial`, `Rfc`, `Ciudad`, `Direccion`, `Colonia`, `Estado`, `CodigoPostal`, `Telefono`, `Fax`, `Mail`, `Contacto`, `Observaciones`, `Celular`, `PaginaWeb`, `ProveedorDefault` (1 = proveedor por defecto). Las columnas Q-R vienen vacías.

---

## 4. CSV generados (carpeta `csv/`)

Formato de todos: UTF-8 sin BOM, separador coma, punto decimal, números sin formato, porcentajes como fracción (0.16 = 16 %), fechas `AAAA-MM-DD` (vacío = sin fecha), encabezados en `snake_case` sin acentos. Las columnas de las hojas del archivo B conservan el nombre original convertido (`PartidaWBS` → `partida_wbs`, `SalarioBaseM0` → `salario_base_m0`, `Descripcion completa` → `descripcion_completa`), salvo `%` → `es_porcentaje`, `Tipo %` → `base_porcentaje` y `/` → `operador`.

| CSV | Origen | Filas | Llave | Columnas |
|---|---|---|---|---|
| `parametros_generales.csv` | A y B › N_Campos Generales | 135 | archivo + clave | archivo (`fasar`/`presupuesto`), grupo, clave, descripcion, valor, valor_extra |
| `parametros_fasar.csv` | A › nombres definidos | 8 | clave | clave, descripcion, valor (año, tipo_fasar, uma_cap, uma, salario_minimo, limite_superior1/2, redondeo_factores) |
| `cuotas_imss.csv` | A › a)TablaFactores | 12 | clave | clave, concepto, base_calculo, patron, trabajador, total |
| `dias_fsr.csv` | A › b) CapturaDatos | 19 | renglon/concepto | renglon, concepto, porcentaje, jornada_8h, jornada_extra |
| `horas_extras.csv` | A › c)Horas Extras | 21 | concepto | concepto, valor |
| `fsr_parametros.csv` | A › o) y p) (bloque de días) | 21 | clave | clave (DICAL, Tp, Tl, FSBC…), descripcion, jornada_8h, jornada_extra |
| `categorias_mo.csv` | A › d)Salarios | 41 | tipo_jornada + codigo | tipo_jornada (`8h`/`extra`), no, codigo, descripcion, salario_nominal, factor_sbc, fsr, salario_real, salario_nominal_uma |
| `fasar_desglose.csv` | A › o) y p) (tabla) | 41 | tipo_jornada + clave | tipo_jornada, clave, descripcion, tp_tl, salario_nominal, factor_sbc, sbc, riesgo_trabajo … impuesto_nomina, suma_prestaciones, ps, fsr |
| `catalogo.csv` | B › CatalogoGeneral | 34,869 | codigo | ver 3.3 |
| `unidades.csv` | B › Unidades | 51 | unidad | unidad, descripcion |
| `familias.csv` | B › Familias | 17 | familia | familia, descripcion |
| `proveedores.csv` | B › Proveedores | 9 | proveedor | ver 3.13 |
| `partidas.csv` | B › Partidas | 301 | partida_wbs | ver 3.6 |
| `presupuesto.csv` | B › Presupuesto | 10,264 | control | ver 3.5 |
| `matrices.csv` | B › Matrices | 82,051 | codigo_m + renglon | codigo_m, codigo_i, renglon, operador, cantidad, expresion |
| `mano_obra.csv` | B › DetalleManoObra | 40 | codigo | ver 3.8 |
| `maquinaria.csv` | B › DetalleMaquinaria | 60 | codigo | ver 3.9 |
| `operacion_ch.csv` | B › OperacionCH | 52 | codigo_m + codigo_i | codigo_m, codigo_i, operador, cantidad |
| `consumos_ch.csv` | B › ConsumosCH | 18 | codigo_m + codigo_i | codigo_m, codigo_i, operador, cantidad |
| `porcentajes_ch.csv` | B › PorcentajesCh | 10 | cargo | cargo, espera, reserva |

En la jornada con horas extras sólo hay parámetros (`fsr_parametros`, `dias_fsr`); `categorias_mo` y `fasar_desglose` traen únicamente filas `8h` porque el archivo no tiene categorías capturadas para horas extras.

**Validaciones hechas:** todos los `codigo` de `presupuesto`, `codigo_m`/`codigo_i` de `matrices` y `codigo` de `mano_obra` existen en `catalogo`; todas las `partida_wbs` de `presupuesto` existen en `partidas`; el importe de cada partida coincide con Σ(cantidad × precio0) de sus conceptos. `partidas` tiene **dos raíces** (`1` = 112,406,223.14 y `2` = 1,715,230.11); juntas suman 114,121,453.25, igual que todo `presupuesto`.

**Ya corregido en los CSV:** los % mal formateados de "DATOS DE FASAR" (`Sar` = 0.02, `Invonavit` = 0.05, `Riesgo de trabajo` = 0.0758875).

**Notas sobre los datos:** los archivos tienen fechas de distintos años (FASAR 2019, catálogo 2020-2026); la UMA de 86.88 y el salario mínimo de 123.22 son de 2019, así que conviene actualizarlos antes de usarlos en cálculos reales. En `N_Campos Generales` del presupuesto la `fechaterminacion` (2019-02-24) es anterior a la `fechainicio` (2020-04-06) y `totalpresupuestoprimeramoneda` viene en 0: son datos del archivo de origen, no del proceso de conversión.
