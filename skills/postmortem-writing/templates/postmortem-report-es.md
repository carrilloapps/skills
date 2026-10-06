# [SEV<n>] <Falla>: <sistema> — Postmortem del incidente — ES

> 🌐 También disponible en: `<YYYY-MM-DD>_SEV<n>_<SLUG>_EN.md`

Sin culpas: este documento describe sistemas, señales y decisiones. Ninguna persona es una causa.

Los nombres técnicos (clases, funciones, librerías, servicios, identificadores de alerta y de despliegue) se mantienen en su idioma original.

## Tabla de contenido

1. Resumen ejecutivo
2. Ficha del incidente
3. Línea de tiempo
4. Severidad
5. Factores contribuyentes
6. Cambio disparador
7. Brecha de detección
8. Lo que funcionó
9. Acciones
10. Métricas del incidente
11. Fuera de alcance y limitaciones
12. Lecciones
13. Estado del registro
14. Compuerta

## Resumen ejecutivo

<Cinco líneas como máximo. Primero el impacto, luego la causa, luego el estado. Sin jerga. Quien se detenga aquí debe saber qué pasó, a quién afectó, si ya terminó y qué sigue.>

## Ficha del incidente

| Campo | Valor |
|-------|-------|
| ID del incidente | `INC-<nnn>` |
| Detectado | `<YYYY-MM-DD HH:MM UTC>` / `<HH:MM LOCAL>` — fuente: `<alerta / rol / reporte>` |
| Estabilizado | `<HH:MM UTC>` — fuente: `<evidencia>` |
| Resuelto | `<YYYY-MM-DD HH:MM UTC>` o `pendiente` — fuente: `<evidencia>` |
| Severidad | `SEV<n>` (línea de rúbrica en § Severidad) |
| Sistemas afectados | `<servicio>`, `<servicio>` |
| **Sistemas NO afectados** | `<servicio>` — verificado: `<evidencia>` |
| Quienes respondieron (roles) | `<rol>`, `<rol>` |
| Autor del reporte | Agente, revisado por `<rol>` |

## Línea de tiempo

Todas las horas en UTC y `<ZONA LOCAL>`. Cada fila indica su fuente. `[desconocido]` significa que la evidencia no alcanza; una fila `— brecha —` significa que no existe evidencia para ese período.

| UTC | Local | Evento | Fuente | Confianza |
|-----|-------|--------|--------|-----------|
| `<HH:MM:SS>` | `<HH:MM>` | `<qué ocurrió>` | `<log / ID de alerta / commit / rol>` | Verificado |
| `<HH:MM>` | `<HH:MM>` | — brecha: sin evidencia entre `<HH:MM>` y `<HH:MM>` — | `<por qué: retención, sin registro>` | — |

Niveles de confianza: `Verificado` (la evidencia lo demuestra) · `Probable` (indicar la brecha) · `Posible` (hipótesis).

## Severidad

```text
SEV<n> ← D1 usuarios: <evidencia> (SEV<n>) · D2 datos: <evidencia> (SEV<n>)
       · D3 duración: <evidencia> (SEV<n>) · D4 alcance: <evidencia> (SEV<n>)
       · D5 regulatorio: <evidencia> (SEV<n>) → máx = SEV<n>
```

<Si es un casi-incidente, agregar el contrafactual: qué severidad habría tenido si el control no hubiera funcionado.>

## Factores contribuyentes

### CF-1 — <condición en una línea> (Verificado | Probable | Posible)

**Condición**: <qué era verdad>
**Evidencia**: <archivo:línea, log, configuración, métrica>
**Si se elimina**: <qué habría cambiado>

### CF-2 — <condición> (Verificado | Probable | Posible)

**Condición**: <…>
**Evidencia**: <…>
**Si se elimina**: <…>

## Cambio disparador

<El despliegue, cambio de configuración, variación de tráfico o falla de dependencia que hizo que las condiciones latentes importaran, con su identificador y hora. Separado de los factores: el disparador no es la causa.>

## Brecha de detección

<Inicio frente a detección, cuantificado desde la línea de tiempo cuando sea posible. Qué señal existía y no tenía alerta, y cuánto antes habría disparado. Si no se puede medir, indicar `no medido` y convertirlo en una acción.>

## Lo que funcionó

1. <Control, alerta o decisión que limitó el daño> — evidencia: `<…>`
2. <…>

## Acciones

| ID | Tipo | Acción | Deriva de | Responsable (rol) | Fecha límite | Verificación | Estado |
|----|------|--------|-----------|-------------------|--------------|--------------|--------|
| A-01 | prevenir | `<cambio en imperativo>` | CF-1 | `<rol>` | `<YYYY-MM-DD>` | `<verificación observable>` | Abierta |
| A-02 | detectar | `<cambio en imperativo>` | brecha de detección | `<rol>` | `<YYYY-MM-DD>` | `<verificación observable>` | Abierta |
| A-03 | mitigar | `<cambio en imperativo>` | CF-2 | `<rol>` | `<YYYY-MM-DD>` | `<verificación observable>` | Abierta |

El estado lo gestiona el equipo; el agente nunca cierra ni reasigna una acción.

## Métricas del incidente

| Métrica | Valor | Desde → hasta | Evidencia |
|---------|-------|---------------|-----------|
| Tiempo de detección | `<duración>` o `no medido` | `<HH:MM → HH:MM UTC>` | `<evidencia>` |
| Tiempo de mitigación | `<duración>` | `<HH:MM → HH:MM UTC>` | `<evidencia>` |
| Tiempo de resolución | `<duración>` o `pendiente` | `<… → …>` | `<evidencia>` |
| Duración del impacto | `<duración>` | `<inicio → mitigación>` | `<evidencia>` |
| Usuarios afectados | `<cantidad>` o `no medido` | — | `<qué mide realmente la cifra>` |

## Fuera de alcance y limitaciones

1. <Evidencia que no estuvo disponible y qué le costó al análisis.>
2. <Qué no se revisó deliberadamente y quién es responsable.>
3. <Cualquier regla de ignorado en `.memory/` que el agente no pudo escribir, por ejemplo en Subversion.>

## Lecciones

| # | Lección | Se activa en un plan que… | Evidencia |
|---|---------|---------------------------|-----------|
| L-1 | `<regla generalizada>` | `<condición que cumpliría un plan futuro>` | `INC-<nnn>` CF-1 |

## Estado del registro

| ID | Fecha | Sev | Título | Acciones abiertas | Estado |
|----|-------|-----|--------|-------------------|--------|
| `INC-<nnn>` | `<YYYY-MM-DD>` | `SEV<n>` | `<título>` | `<n>` | Abierto |

## Compuerta

1. ✅/❌ Ninguna persona aparece como causa — solo roles
2. ✅/❌ Cada fila de la línea de tiempo tiene fuente, `[desconocido]` o una fila de brecha explícita
3. ✅/❌ La severidad muestra su línea de rúbrica y la dimensión máxima
4. ✅/❌ Cada afirmación causal tiene nivel de confianza
5. ✅/❌ Cada acción tiene rol responsable, fecha límite y verificación
6. ✅/❌ Las métricas están medidas o marcadas como `no medido`
7. ✅/❌ Fuera de alcance y limitaciones enumera la evidencia no disponible
8. ✅/❌ "Lo que funcionó" no está vacío
