-- ============================================================================
-- SESIÓN 7 / ACTIVIDAD 4: DATOS DE PRUEBA Y VALIDACIÓN DE CONSULTAS
-- Generación de datos de prueba y reporte de ventas por cliente.
-- Requiere el esquema y datos base de sql/00_esquema_y_datos_base.sql
-- ============================================================================

USE NovaMarket;
GO
SET NOCOUNT ON;

-- ----------------------------------------------------------------------------
-- 1. GENERACIÓN Y CONTROL DE DATOS DE PRUEBA
-- ----------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.Pedido', N'U') IS NULL
    THROW 51000, 'Ejecute primero sql/00_esquema_y_datos_base.sql.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.Pedido WHERE PedidoID = 1)
   OR NOT EXISTS (SELECT 1 FROM dbo.Pedido WHERE PedidoID = 10)
   OR NOT EXISTS (SELECT 1 FROM dbo.Pedido WHERE PedidoID = 29)
    THROW 51001, 'Faltan los pedidos base de los casos de prueba.', 1;

-- IDs explícitos y fórmulas fijas permiten repetir la carga sin duplicados.
SET IDENTITY_INSERT dbo.Pedido ON;
;WITH Numeros AS (
    SELECT 1 AS Numero
    UNION ALL
    SELECT Numero + 1 FROM Numeros WHERE Numero < 162
)
INSERT INTO dbo.Pedido (PedidoID, ClienteID, FechaPedido, Estado, Canal)
SELECT
    7000 + n.Numero,
    c.ClienteID,
    CASE WHEN n.Numero % 6 = 0
        THEN DATEADD(DAY, (n.Numero * 11) % 365, CONVERT(DATE, '20250101', 112))
        ELSE DATEADD(DAY, (n.Numero * 11) % 365, CONVERT(DATE, '20260101', 112))
    END,
    CASE
        WHEN n.Numero % 11 = 0 THEN 'ANULADO'
        WHEN n.Numero % 5 = 0  THEN 'PENDIENTE'
        WHEN n.Numero % 13 = 0 THEN 'BORRADOR'
        ELSE 'CONFIRMADO'
    END,
    CASE n.Numero % 3
        WHEN 0 THEN 'WEB'
        WHEN 1 THEN 'TIENDA'
        ELSE 'APP'
    END
FROM Numeros AS n
INNER JOIN (VALUES
    (1, 2), (2, 4), (3, 5), (4, 6), (5, 7), (6, 10),
    (7, 11), (8, 12), (9, 13), (10, 14), (11, 15)
) AS c(Posicion, ClienteID)
    ON c.Posicion = 1 + ((n.Numero - 1) % 11)
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Pedido AS existente
    WHERE existente.PedidoID = 7000 + n.Numero
)
OPTION (MAXRECURSION 0);
SET IDENTITY_INSERT dbo.Pedido OFF;

SET IDENTITY_INSERT dbo.DetallePedido ON;
INSERT INTO dbo.DetallePedido (DetalleID, PedidoID, ProductoID, Cantidad, PrecioUnitario)
SELECT
    7000 + 2 * (p.PedidoID - 7001) + linea.Numero,
    p.PedidoID,
    pr.ProductoID,
    CASE WHEN (p.PedidoID - 7000) % 3 = 0 AND linea.Numero = 1 THEN 2 ELSE 1 END,
    pr.PrecioLista
FROM dbo.Pedido AS p
CROSS JOIN (VALUES (1), (2)) AS linea(Numero)
INNER JOIN dbo.Producto AS pr
    ON pr.ProductoID = 1 + ((p.PedidoID - 7001 + linea.Numero - 1) % 12)
WHERE p.PedidoID BETWEEN 7001 AND 7162
  AND NOT EXISTS (
      SELECT 1 FROM dbo.DetallePedido AS existente
      WHERE existente.DetalleID = 7000 + 2 * (p.PedidoID - 7001) + linea.Numero
  );
SET IDENTITY_INSERT dbo.DetallePedido OFF;

-- Conteo por tabla
SELECT 'Cliente' AS Tabla, COUNT(*) AS Total FROM dbo.Cliente
UNION ALL SELECT 'Categoria', COUNT(*) FROM dbo.Categoria
UNION ALL SELECT 'Producto', COUNT(*) FROM dbo.Producto
UNION ALL SELECT 'Pedido', COUNT(*) FROM dbo.Pedido
UNION ALL SELECT 'DetallePedido', COUNT(*) FROM dbo.DetallePedido;

-- Distribución por año y estado
SELECT YEAR(p.FechaPedido) AS Anio, p.Estado, COUNT(*) AS TotalPedidos
FROM dbo.Pedido AS p
GROUP BY YEAR(p.FechaPedido), p.Estado
ORDER BY Anio, p.Estado;

-- Validación de integridad referencial
SELECT 'PedidosSinCliente' AS Validacion, COUNT(*) AS Total
FROM dbo.Pedido AS p
LEFT JOIN dbo.Cliente AS c ON c.ClienteID = p.ClienteID
WHERE c.ClienteID IS NULL
UNION ALL
SELECT 'DetallesSinPedido', COUNT(*)
FROM dbo.DetallePedido AS d
LEFT JOIN dbo.Pedido AS p ON p.PedidoID = d.PedidoID
WHERE p.PedidoID IS NULL
UNION ALL
SELECT 'DetallesSinProducto', COUNT(*)
FROM dbo.DetallePedido AS d
LEFT JOIN dbo.Producto AS pr ON pr.ProductoID = d.ProductoID
WHERE pr.ProductoID IS NULL;

-- IDs de los casos de prueba: 1 (3 líneas), 10 (pendiente), 29 (anulado)
SELECT c.ClienteID, c.Nombre, p.PedidoID, p.Estado,
       COUNT(d.DetalleID) AS TotalLineas
FROM dbo.Cliente AS c
LEFT JOIN dbo.Pedido AS p
    ON p.ClienteID = c.ClienteID
   AND p.PedidoID IN (1, 10, 29, 40)
LEFT JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
WHERE c.ClienteID IN (1, 3, 8, 9)
GROUP BY c.ClienteID, c.Nombre, p.PedidoID, p.Estado
ORDER BY c.ClienteID;
GO

-- ----------------------------------------------------------------------------
-- 2. REPORTE DE VENTAS POR CLIENTE
-- ----------------------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_S07_VentasPorCliente
AS
WITH VentasPorPedido AS (
    SELECT
        p.PedidoID,
        p.ClienteID,
        COALESCE(SUM(d.Cantidad * d.PrecioUnitario), 0) AS MontoPedido
    FROM dbo.Pedido AS p
    LEFT JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
    WHERE p.Estado = 'CONFIRMADO'
      AND p.FechaPedido >= '20260101'
      AND p.FechaPedido <  '20270101'
    GROUP BY p.PedidoID, p.ClienteID
)
SELECT
    c.ClienteID,
    c.Nombre,
    COUNT(v.PedidoID) AS TotalPedidos2026,
    CAST(COALESCE(SUM(v.MontoPedido), 0) AS DECIMAL(18,2)) AS MontoVendido2026
FROM dbo.Cliente AS c
LEFT JOIN VentasPorPedido AS v ON v.ClienteID = c.ClienteID
WHERE c.Activo = 1
GROUP BY c.ClienteID, c.Nombre;
GO

SELECT v.ClienteID, v.Nombre, v.TotalPedidos2026, v.MontoVendido2026
FROM dbo.vw_S07_VentasPorCliente AS v
ORDER BY v.ClienteID;
GO

-- ----------------------------------------------------------------------------
-- 3. VALIDACIONES Y MATRIZ DE CASOS
-- ----------------------------------------------------------------------------
SET NOCOUNT ON;

IF (SELECT COUNT(*) FROM dbo.Pedido) < 200
    THROW 51010, 'Se requieren al menos 200 pedidos.', 1;
IF (SELECT COUNT(*) FROM dbo.DetallePedido) < 400
    THROW 51011, 'Se requieren al menos 400 detalles.', 1;
IF (SELECT COUNT(*) FROM dbo.vw_S07_VentasPorCliente)
   <> (SELECT COUNT(*) FROM dbo.Cliente WHERE Activo = 1)
    THROW 51012, 'El reporte debe incluir a todos los clientes activos.', 1;
IF EXISTS (
    SELECT 1 FROM dbo.Pedido AS p
    LEFT JOIN dbo.Cliente AS c ON c.ClienteID = p.ClienteID
    WHERE c.ClienteID IS NULL
)
OR EXISTS (
    SELECT 1 FROM dbo.DetallePedido AS d
    LEFT JOIN dbo.Pedido AS p ON p.PedidoID = d.PedidoID
    WHERE p.PedidoID IS NULL
)
OR EXISTS (
    SELECT 1 FROM dbo.DetallePedido AS d
    LEFT JOIN dbo.Producto AS pr ON pr.ProductoID = d.ProductoID
    WHERE pr.ProductoID IS NULL
)
    THROW 51015, 'Existen registros sin clave foránea válida.', 1;

DROP TABLE IF EXISTS #Casos;
CREATE TABLE #Casos (
    Caso NVARCHAR(80) NOT NULL,
    Tipo NVARCHAR(20) NOT NULL,
    ClienteID INT NOT NULL,
    PedidoBaseID INT NULL,
    PedidosEsperados INT NOT NULL,
    MontoEsperado DECIMAL(18,2) NOT NULL,
    ConclusionSiCumple NVARCHAR(180) NOT NULL
);
INSERT INTO #Casos
    (Caso, Tipo, ClienteID, PedidoBaseID, PedidosEsperados, MontoEsperado, ConclusionSiCumple)
VALUES
    (N'Pedido confirmado con tres líneas', N'Positivo', 1, 1, 1, 720.00,
     N'Tres líneas suman 720.00 y el pedido se cuenta una sola vez.'),
    (N'Sin compras confirmadas', N'Límite', 3, 40, 0, 0.00,
     N'El cliente activo permanece en el reporte con dos ceros.'),
    (N'Pedido pendiente', N'Negativo', 9, 10, 0, 0.00,
     N'El pedido pendiente no suma pedidos ni importe.'),
    (N'Pedido anulado', N'Negativo', 8, 29, 0, 0.00,
     N'El anulado no suma; el confirmado del cliente es de 2025.');

SELECT
    e.Caso, e.Tipo, e.ClienteID, e.PedidoBaseID,
    e.PedidosEsperados, v.TotalPedidos2026 AS PedidosObtenidos,
    e.MontoEsperado, v.MontoVendido2026 AS MontoObtenido,
    CASE WHEN v.TotalPedidos2026 = e.PedidosEsperados
          AND v.MontoVendido2026 = e.MontoEsperado
        THEN 'OK' ELSE 'FALLO' END AS Resultado,
    CASE WHEN v.TotalPedidos2026 = e.PedidosEsperados
          AND v.MontoVendido2026 = e.MontoEsperado
        THEN e.ConclusionSiCumple
        ELSE N'Revisar filtros, detalle y datos de origen.' END AS Conclusion
FROM #Casos AS e
LEFT JOIN dbo.vw_S07_VentasPorCliente AS v ON v.ClienteID = e.ClienteID
ORDER BY e.ClienteID;

IF EXISTS (
    SELECT 1 FROM #Casos AS e
    LEFT JOIN dbo.vw_S07_VentasPorCliente AS v ON v.ClienteID = e.ClienteID
    WHERE v.ClienteID IS NULL
       OR v.TotalPedidos2026 <> e.PedidosEsperados
       OR v.MontoVendido2026 <> e.MontoEsperado
)
    THROW 51013, 'La matriz de casos no coincide con el reporte.', 1;

DROP TABLE IF EXISTS #Contraste;
CREATE TABLE #Contraste (
    PedidosOrigen INT NOT NULL,
    PedidosReporte INT NOT NULL,
    MontoOrigen DECIMAL(18,2) NOT NULL,
    MontoReporte DECIMAL(18,2) NOT NULL
);
;WITH Origen AS (
    SELECT p.PedidoID, COALESCE(SUM(d.Cantidad * d.PrecioUnitario), 0) AS Monto
    FROM dbo.Pedido AS p
    INNER JOIN dbo.Cliente AS c ON c.ClienteID = p.ClienteID
    LEFT JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
    WHERE c.Activo = 1
      AND p.Estado = 'CONFIRMADO'
      AND p.FechaPedido >= '20260101'
      AND p.FechaPedido <  '20270101'
    GROUP BY p.PedidoID
), TotalesOrigen AS (
    SELECT COUNT(*) AS PedidosOrigen, COALESCE(SUM(o.Monto), 0) AS MontoOrigen
    FROM Origen AS o
), TotalesReporte AS (
    SELECT COALESCE(SUM(v.TotalPedidos2026), 0) AS PedidosReporte,
           COALESCE(SUM(v.MontoVendido2026), 0) AS MontoReporte
    FROM dbo.vw_S07_VentasPorCliente AS v
)
INSERT INTO #Contraste (PedidosOrigen, PedidosReporte, MontoOrigen, MontoReporte)
SELECT o.PedidosOrigen, r.PedidosReporte, o.MontoOrigen, r.MontoReporte
FROM TotalesOrigen AS o CROSS JOIN TotalesReporte AS r;

SELECT c.PedidosOrigen, c.PedidosReporte, c.MontoOrigen, c.MontoReporte
FROM #Contraste AS c;

IF EXISTS (
    SELECT 1 FROM #Contraste AS c
    WHERE c.PedidosOrigen <> c.PedidosReporte
       OR c.MontoOrigen <> c.MontoReporte
)
    THROW 51014, 'El reporte no coincide con los pedidos y detalles de origen.', 1;

DROP TABLE #Casos;
DROP TABLE #Contraste;
GO
