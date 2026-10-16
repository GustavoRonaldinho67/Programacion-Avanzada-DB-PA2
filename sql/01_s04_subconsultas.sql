-- ========================================================================================
-- ARCHIVO: 01_s04_subconsultas.sql
-- AUTOR: Gustavo
-- OBJETIVO: Actividad 1 - Segmentación usando EXISTS/NOT EXISTS y correlacionadas.
-- ========================================================================================
USE NovaMarket;
GO

-- STREAMING_CHUNK: Ejecutando Actividad 1A (Segmentacion excluyente)...
PRINT '--- S04.A: Clientes Redes (SI) y Seguridad (NO) en 2026 ---';
SELECT
    c.ClienteID,
    c.Nombre,
    c.Ciudad
FROM Cliente c
WHERE EXISTS (
    SELECT 1 FROM Pedido p
    INNER JOIN DetallePedido d ON p.PedidoID = d.PedidoID
    INNER JOIN Producto pr ON d.ProductoID = pr.ProductoID
    INNER JOIN Categoria ca ON pr.CategoriaID = ca.CategoriaID
    WHERE p.ClienteID = c.ClienteID
      AND p.Estado = 'CONFIRMADO' AND YEAR(p.FechaPedido) = 2026
      AND ca.Nombre = 'Redes'
)
AND NOT EXISTS (
    SELECT 1 FROM Pedido p
    INNER JOIN DetallePedido d ON p.PedidoID = d.PedidoID
    INNER JOIN Producto pr ON d.ProductoID = pr.ProductoID
    INNER JOIN Categoria ca ON pr.CategoriaID = ca.CategoriaID
    WHERE p.ClienteID = c.ClienteID
      AND p.Estado = 'CONFIRMADO' AND YEAR(p.FechaPedido) = 2026
      AND ca.Nombre = 'Seguridad'
)
ORDER BY c.ClienteID;
GO

-- STREAMING_CHUNK: Ejecutando Actividad 1B (Subconsulta correlacionada)...
PRINT '--- S04.B: Productos con precio > promedio de su categoria ---';
SELECT
    p.ProductoID,
    p.Nombre,
    c.Nombre AS Categoria,
    p.PrecioLista,
    CAST((SELECT AVG(p2.PrecioLista) FROM Producto p2 WHERE p2.CategoriaID = p.CategoriaID) AS DECIMAL(10,2)) AS PromedioCategoria
FROM Producto p
INNER JOIN Categoria c ON p.CategoriaID = c.CategoriaID
WHERE p.PrecioLista > (
    SELECT AVG(p2.PrecioLista) FROM Producto p2 WHERE p2.CategoriaID = p.CategoriaID
)
ORDER BY c.Nombre, p.PrecioLista DESC;
GO

-- STREAMING_CHUNK: Ejecutando Actividad 1C (Casos de prueba)...
PRINT '--- S04.C: Casos de Prueba (Validacion de Segmentacion A) ---';
SELECT c.ClienteID, c.Nombre, p.PedidoID, p.FechaPedido, ca.Nombre AS CategoriaComprada
FROM Cliente c
INNER JOIN Pedido p ON c.ClienteID = p.ClienteID
INNER JOIN DetallePedido d ON p.PedidoID = d.PedidoID
INNER JOIN Producto pr ON d.ProductoID = pr.ProductoID
INNER JOIN Categoria ca ON pr.CategoriaID = ca.CategoriaID
WHERE c.ClienteID IN (1,2) AND p.Estado = 'CONFIRMADO' AND YEAR(p.FechaPedido) = 2026;
GO