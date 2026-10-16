# Matriz de pruebas: Sesión 7

Ejecutar los cuatro scripts indicados en `README.md`. `s07_validaciones.sql` muestra los valores obtenidos y marca `OK` o `FALLO`.

| Caso | IDs de origen | Pedidos esperados | Monto esperado | Justificación |
| --- | --- | ---: | ---: | --- |
| Varias líneas en un pedido | Cliente 1, Pedido 1, Detalles 1–3 | 1 | 720.00 | 1 × 300 + 2 × 120 + 1 × 180; las tres líneas corresponden a un solo pedido. |
| Sin compras confirmadas | Cliente 3, Pedido 40 si aún existe | 0 | 0.00 | Su único pedido base es un borrador sin detalle. |
| Pedido pendiente | Cliente 9, Pedido 10 | 0 | 0.00 | El estado `PENDIENTE` queda fuera. |
| Pedido anulado | Cliente 8, Pedido 29 | 0 | 0.00 | El pedido de 2026 está `ANULADO`; su confirmado es de 2025 (Pedido 9). |

Los `NULL` que resultan del `LEFT JOIN` para clientes sin ventas válidas se convierten en ceros numéricos. El filtro de fecha y estado está dentro de la agregación de pedidos, antes de unirla a clientes, para conservar a todos los activos.

**Resultados obtenidos:** pendientes de ejecutar en SQL Server. El script de validación los calcula y compara; no se presentan cifras simuladas como evidencia del motor.
