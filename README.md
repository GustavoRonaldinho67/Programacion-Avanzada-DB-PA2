# Programacion-Avanzada-DB-PA2
PA2 - Programación Avanzada de Base de Datos - ISIL

## Sesión 7: buenas prácticas y reporte por cliente

La base `NovaMarket` y sus datos iniciales se encuentran en `sql/00_esquema_y_datos_base.sql` (40 pedidos y 80 detalles). Para la Sesión 7, ejecutar en este orden:

1. `sql/00_esquema_y_datos_base.sql` en una base de pruebas **vacía** llamada `NovaMarket`. Este archivo crea las tablas y los datos base; no es seguro ejecutarlo dos veces sin recrear la base.
2. `s07_generacion_datos.sql` reúne todo el Tema 3 de la Sesión 7 en un único archivo. Primero añade 162 pedidos y 324 detalles con IDs reservados, sin duplicarlos si se repite la ejecución. Después muestra conteos y distribución, crea o actualiza la vista de ventas por cliente y ejecuta la matriz de cuatro casos y las comprobaciones contra las tablas de origen. Un error de volumen o de casos produce `THROW`.

Se requiere Microsoft SQL Server 2017 o posterior. El script de carga admite los 40 pedidos iniciales y también el estado posterior a `s05_mantenimiento.sql`, que elimina dos borradores sin detalle. En ambos casos alcanza al menos 200 pedidos y 400 detalles. Los IDs 7001–7162 para pedidos y 7001–7324 para detalles quedan reservados para la Sesión 7.

El reporte incluye todos los clientes activos. Considera solo pedidos `CONFIRMADO` de 2026, calcula importes con el precio histórico de `DetallePedido`, cuenta cada pedido una sola vez y asigna cero a clientes sin ventas válidas. La matriz de pruebas y sus resultados esperados están dentro del mismo script.
