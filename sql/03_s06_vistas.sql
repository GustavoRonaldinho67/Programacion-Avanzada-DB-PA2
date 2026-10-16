-- ========================================================================================
-- ARCHIVO: 03_vistas_s06.sql
-- AUTOR: Fernando
-- OBJETIVO: Actividad 3 - Creacion de Vistas y verificacion de resultados consolidados.
-- ========================================================================================
USE NovaMarket;
GO

-- STREAMING_CHUNK: Creando vista de consolidacion (3A)...
CREATE OR ALTER VIEW vw_VentasCategoriaMes AS
SELECT 
    YEAR(p.FechaPedido) AS Anio,
    MONTH(p.FechaPedido) AS Mes,
    cat.CategoriaID,
    cat.Nombre AS NombreCategoria,
    SUM(dp.Cantidad) AS TotalUnidades,
    SUM(CAST(dp.Cantidad * dp.PrecioUnitario AS DECIMAL(10,2))) AS MontoTotal
FROM Pedido p
INNER JOIN DetallePedido dp ON p.PedidoID = dp.PedidoID
INNER JOIN Producto pr ON dp.ProductoID = pr.ProductoID
INNER JOIN Categoria cat ON pr.CategoriaID = cat.CategoriaID
WHERE p.Estado = 'CONFIRMADO'
GROUP BY YEAR(p.FechaPedido), MONTH(p.FechaPedido), cat.CategoriaID, cat.Nombre;
GO

PRINT '--- S06.A: Consultando Vista VentasCategoriaMes (Solo 2026) ---';
SELECT * FROM vw_VentasCategoriaMes WHERE Anio = 2026 ORDER BY Mes ASC, MontoTotal DESC;
GO

-- STREAMING_CHUNK: Creando vista de inactividad (3B)...
CREATE OR ALTER VIEW vw_ClientesSinCompra2026 AS
SELECT DISTINCT
    c.ClienteID,
    c.Nombre,
    c.Ciudad
FROM Cliente c
WHERE NOT EXISTS (
    SELECT 1 
    FROM Pedido p
    WHERE p.ClienteID = c.ClienteID
      AND p.Estado = 'CONFIRMADO'
      AND YEAR(p.FechaPedido) = 2026
);
GO

PRINT '--- S06.B: Consultando Vista ClientesSinCompra2026 ---';
SELECT * FROM vw_ClientesSinCompra2026;
GO

-- STREAMING_CHUNK: Contraste de vista vs tablas base (3C)...
PRINT '=======================================================';
PRINT ' S06.C: Contraste de Vista vs Tablas Base (Mes 1)      ';
PRINT '=======================================================';

-- 1. Monto total desde la Vista para Enero 2026
SELECT 'Origen: VISTA' AS Fuente, MontoTotal, NombreCategoria
FROM vw_VentasCategoriaMes 
WHERE Anio = 2026 AND Mes = 1;

-- 2. Monto total agrupando directamente las Tablas Base para Enero 2026
SELECT 'Origen: TABLAS BASE' AS Fuente, SUM(CAST(dp.Cantidad * dp.PrecioUnitario AS DECIMAL(10,2))) AS MontoTotal, cat.Nombre AS NombreCategoria
FROM Pedido p
INNER JOIN DetallePedido dp ON p.PedidoID = dp.PedidoID
INNER JOIN Producto pr ON dp.ProductoID = pr.ProductoID
INNER JOIN Categoria cat ON pr.CategoriaID = cat.CategoriaID
WHERE p.Estado = 'CONFIRMADO' AND YEAR(p.FechaPedido) = 2026 AND MONTH(p.FechaPedido) = 1
GROUP BY cat.Nombre;
GO