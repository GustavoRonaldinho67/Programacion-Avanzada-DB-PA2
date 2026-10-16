# Programacion-Avanzada-DB-PA2

PA2 - Programación Avanzada de Base de Datos - ISIL. NovaMarket es una tienda de tecnología; el objetivo de la Sesión 7 es comprobar que sus consultas de ventas incluyan a todos los clientes activos y excluyan operaciones no confirmadas.

## Aporte de esta rama

Anthony Fernando Alcántara Valencia ([totomanxd321](https://github.com/totomanxd321)): generación reproducible de datos de prueba, reporte de ventas por cliente y validaciones del Tema 3 de la Sesión 7. Los archivos de las sesiones anteriores se conservan tal como estaban en `main`.

El examen solicita evidencias de datos y de reporte en archivos separados. Para esta rama se pidió **un solo archivo SQL**: `s07_generacion_datos.sql`. Sus secciones 1, 2 y 3 contienen respectivamente la carga y sus controles, el reporte, y la matriz de pruebas con resultados esperados, obtenidos y conclusiones.

## Requisitos y ejecución

Usar Microsoft SQL Server 2017 o posterior en una base de pruebas `NovaMarket`. El archivo `sql/00_esquema_y_datos_base.sql` crea las cinco tablas, 15 clientes, 12 productos, 40 pedidos y 80 detalles; debe ejecutarse una sola vez sobre una base vacía. `s07_generacion_datos.sql` puede repetirse sin duplicar sus filas.

Con `sqlcmd` y una instancia local predeterminada:

```powershell
sqlcmd -S . -E -b -d master -Q "IF DB_ID(N'NovaMarket') IS NULL CREATE DATABASE NovaMarket"
sqlcmd -S . -E -b -d NovaMarket -i sql/00_esquema_y_datos_base.sql
sqlcmd -S . -E -b -d NovaMarket -i s07_generacion_datos.sql
```

En SQL Server Management Studio se puede crear y seleccionar una base vacía `NovaMarket` y ejecutar los dos archivos en el mismo orden. Si se ejecuta `s05_mantenimiento.sql` entre ambos, la carga S07 también cumple el volumen mínimo. Los IDs 7001–7162 de pedidos y 7001–7324 de detalles quedan reservados para S07.

## Relación con los materiales académicos

| Requisito pertinente | Evidencia en `s07_generacion_datos.sql` |
| --- | --- |
| Examen S07-A: mínimo 200 pedidos y 400 detalles, claves válidas, conteos y distribución por estado y año | Sección 1: carga determinista, `COUNT(*)` de las cinco tablas, distribución y conteos de huérfanos. |
| Examen S07-B: todos los clientes activos, cuatro columnas obligatorias, solo confirmados de 2026, ceros y un conteo por pedido | Sección 2: `vw_S07_VentasPorCliente`, agregación por pedido y `LEFT JOIN` al cliente. |
| Examen S07-C: cuatro casos con IDs, valores esperados, obtenidos y conclusiones | Sección 3: matriz ejecutable, comparaciones con `THROW` y contraste de totales con origen. |
| Presentación S07: columnas explícitas, alias y `JOIN` claros, filtro de fecha sin función sobre la columna | Sección 2: consulta de reporte y vista. |
| Presentación S07: datos de prueba coherentes con restricciones, volumen y generación automatizada | Sección 1: fórmulas deterministas, claves foráneas y dos detalles por pedido generado. |

El reporte calcula el monto desde `DetallePedido.Cantidad * DetallePedido.PrecioUnitario`, que conserva el precio histórico. El filtro de estado y fecha está dentro de la agregación previa al `LEFT JOIN`; moverlo al `WHERE` exterior eliminaría clientes sin ventas. `COUNT(PedidoID)` devuelve cero sin coincidencias y `COALESCE` convierte la suma nula en `0.00`. El intervalo `[2026-01-01, 2027-01-01)` cubre todo 2026.

La presentación propone `TOP n` como orientación general; aquí no se aplica porque el examen exige **todos** los clientes activos. Sus funciones aleatorias son ejemplos posibles de generación; se eligieron fórmulas deterministas para poder repetir y contrastar la carga. La matriz cubre un caso positivo, dos negativos y el límite de un cliente sin compras confirmadas.

## Resultados y límites de verificación

La comprobación estática y la simulación local dieron 202 pedidos y 404 detalles desde la base inicial, o 200 y 404 después de eliminar los dos borradores sin detalle de S05. También pasaron los cuatro casos y una segunda ejecución de la carga sin duplicados. Estos resultados **no sustituyen** la ejecución del T-SQL en SQL Server: allí deben conservarse las tablas de salida y la matriz real que imprime el script.

No hay una instancia SQL Server disponible en este entorno. El enlace del video de sustentación, sus marcas de tiempo y los datos del resto de integrantes dependen del equipo y no se inventan en esta contribución.
