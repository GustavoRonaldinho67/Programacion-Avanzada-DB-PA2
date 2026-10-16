# Programacion-Avanzada-DB-PA2
PA2 - Programación Avanzada de Base de Datos - ISIL

## Sesión 7: buenas prácticas y reporte por cliente

La base `NovaMarket` y sus datos iniciales se encuentran en `sql/00_esquema_y_datos_base.sql` (40 pedidos y 80 detalles). Para la Sesión 7, ejecutar en este orden:

1. `sql/00_esquema_y_datos_base.sql` en una base de pruebas **vacía** llamada `NovaMarket`. Este archivo crea las tablas y los datos base; no es seguro ejecutarlo dos veces sin recrear la base.
2. `s07_datos_prueba.sql` añade 162 pedidos y 324 detalles con IDs reservados, sin duplicarlos si se repite la ejecución. Muestra conteos por tabla, distribución por estado y año, y los IDs de los casos de prueba.
3. `s07_reporte_clientes.sql` crea o actualiza la vista de ventas por cliente y muestra sus cuatro columnas de salida.
4. `s07_validaciones.sql` compara el reporte con los valores esperados y con las tablas de origen. Un error de volumen o de casos produce `THROW`.

Se requiere Microsoft SQL Server 2017 o posterior. El script de carga admite los 40 pedidos iniciales y también el estado posterior a `s05_mantenimiento.sql`, que elimina dos borradores sin detalle. En ambos casos alcanza al menos 200 pedidos y 400 detalles. Los IDs 7001–7162 para pedidos y 7001–7324 para detalles quedan reservados para la Sesión 7.

El reporte incluye todos los clientes activos. Considera solo pedidos `CONFIRMADO` de 2026, calcula importes con el precio histórico de `DetallePedido`, cuenta cada pedido una sola vez y asigna cero a clientes sin ventas válidas. La [matriz de pruebas](evidencias/s07_matriz_pruebas.md) documenta los casos y sus resultados esperados.
