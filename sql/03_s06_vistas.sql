-- ACTIVIDAD 3.A: Creación de la vista vw_VentasCategoriaMes
-- ============================================================================
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
GROUP BY 
    YEAR(p.FechaPedido),
    MONTH(p.FechaPedido),
    cat.CategoriaID,
    cat.Nombre;
GO

-- Consulta obligatoria sobre la vista para el año 2026
SELECT Anio, Mes, CategoriaID, NombreCategoria, TotalUnidades, MontoTotal
FROM vw_VentasCategoriaMes
WHERE Anio = 2026
ORDER BY Mes ASC, MontoTotal DESC;
GO
-- ACTIVIDAD 3.B: Creación de la vista vw_ClientesSinCompra2026
-- ============================================================================
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

-- Consulta sobre la vista creada
SELECT ClienteID, Nombre, Ciudad
FROM vw_ClientesSinCompra2026;
GO

-- ACTIVIDAD 3.C: Verificación y contraste con tablas base
-- ============================================================================
-- 1. Contraste de totales mensuales usando la Vista A
SELECT * FROM vw_VentasCategoriaMes WHERE Anio = 2026 AND Mes = 5;

-- 2. Contraste directo con las tablas base para verificar el mismo mes y categoría
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
  AND YEAR(p.FechaPedido) = 2026 
  AND MONTH(p.FechaPedido) = 1
GROUP BY YEAR(p.FechaPedido), MONTH(p.FechaPedido), cat.CategoriaID, cat.Nombre;
GO

