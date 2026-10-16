# Matriz de pruebas — Actividad 4 (S07)

| # | Caso | Tipo | Esperado | Obtenido | Conclusión |
|---|------|------|----------|----------|------------|
| 1 | Pedido confirmado con tres líneas (Cliente 1, Pedido 1) | Positivo | 1 pedido / 720.00 | OK | Tres líneas suman 720.00 y el pedido se cuenta una sola vez |
| 2 | Cliente sin compras confirmadas (Cliente 3) | Límite | 0 / 0.00 | OK | Permanece en el reporte con ceros |
| 3 | Pedido PENDIENTE (Cliente 9, Pedido 10) | Negativo | 0 / 0.00 | OK | No suma |
| 4 | Pedido ANULADO (Cliente 8, Pedido 29) | Negativo | 0 / 0.00 | OK | No suma; su confirmado es de 2025 |

## Justificación de NULL
- `COUNT(v.PedidoID)` devuelve 0 cuando no hay coincidencias.
- `COALESCE(SUM(v.MontoPedido), 0)` transforma NULL en 0.00.

## Por qué el filtro va dentro de la CTE
Si el filtro `Estado='CONFIRMADO'` y `FechaPedido >= 2026` se moviera
al WHERE exterior, los clientes sin pedidos válidos desaparecerían
del LEFT JOIN y el reporte perdería clientes activos.

## Volumen alcanzado
- Pedidos: ≥200
- Detalles: ≥400
- Integridad referencial: 0 huérfanos en Pedido, DetallePedido

## Conclusión
Los 4 casos arrojan OK. La matriz y el contraste contra tablas base
confirman que el reporte incluye a todos los clientes activos, cuenta
un pedido una sola vez y no suma pedidos PENDIENTE ni ANULADO.
