-- ========================================================================================
-- ARCHIVO: 05_reporte_definitivo_s07.sql
-- AUTORES: Daniel (Reporte) / Mauricio (QA - Integracion)
-- OBJETIVO: Actividad 4B y 4C - Reporte de ventas y Matriz Automatizada de Pruebas.
-- ========================================================================================
USE NovaMarket;
GO

-- STREAMING_CHUNK: Creando el reporte de ventas por cliente...
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
      AND p.FechaPedido < '20270101'
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

PRINT '=======================================================';
PRINT ' REPORTE DEFINITIVO DE VENTAS 2026                     ';
PRINT '=======================================================';
SELECT v.ClienteID, v.Nombre, v.TotalPedidos2026, v.MontoVendido2026
FROM dbo.vw_S07_VentasPorCliente AS v
ORDER BY v.ClienteID;
GO

-- STREAMING_CHUNK: Iniciando Matriz de Pruebas QA...
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
    THROW 51015, 'Existen registros sin clave foranea valida.', 1;

-- STREAMING_CHUNK: Ejecutando Matriz de Casos Automatizada...
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
    (Caso, Tipo, ClienteID, PedidoBaseID, PedidosEsperados, MontoEsperado,
     ConclusionSiCumple)
VALUES
    (N'Pedido confirmado con tres lineas', N'Positivo', 1, 1, 1, 720.00,
     N'Tres lineas suman 720.00 y el pedido se cuenta una sola vez.'),
    (N'Sin compras confirmadas', N'Limite', 3, 40, 0, 0.00,
     N'El cliente activo permanece en el reporte con dos ceros.'),
    (N'Pedido pendiente', N'Negativo', 9, 10, 0, 0.00,
     N'El pedido pendiente no suma pedidos ni importe.'),
    (N'Pedido anulado', N'Negativo', 8, 29, 0, 0.00,
     N'El anulado no suma; el confirmado del cliente es de 2025.');

PRINT '=======================================================';
PRINT ' RESULTADO DE LA MATRIZ DE PRUEBAS (QA)                ';
PRINT '=======================================================';
SELECT
    e.Caso,
    e.Tipo,
    e.ClienteID,
    e.PedidosEsperados,
    v.TotalPedidos2026 AS PedidosObtenidos,
    e.MontoEsperado,
    v.MontoVendido2026 AS MontoObtenido,
    CASE WHEN v.TotalPedidos2026 = e.PedidosEsperados
          AND v.MontoVendido2026 = e.MontoEsperado
        THEN '✅ OK' ELSE '❌ FALLO' END AS Resultado,
    CASE WHEN v.TotalPedidos2026 = e.PedidosEsperados
          AND v.MontoVendido2026 = e.MontoEsperado
        THEN e.ConclusionSiCumple
        ELSE N'Revisar filtros, detalle y datos de origen.' END AS Conclusion
FROM #Casos AS e
LEFT JOIN dbo.vw_S07_VentasPorCliente AS v ON v.ClienteID = e.ClienteID
ORDER BY e.ClienteID;

IF EXISTS (
    SELECT 1
    FROM #Casos AS e
    LEFT JOIN dbo.vw_S07_VentasPorCliente AS v ON v.ClienteID = e.ClienteID
    WHERE v.ClienteID IS NULL
       OR v.TotalPedidos2026 <> e.PedidosEsperados
       OR v.MontoVendido2026 <> e.MontoEsperado
)
    THROW 51013, 'CRITICO: La matriz de casos no coincide con el reporte.', 1;

-- STREAMING_CHUNK: Contraste Independiente Final...
DROP TABLE IF EXISTS #Contraste;
CREATE TABLE #Contraste (
    PedidosOrigen INT NOT NULL,
    PedidosReporte INT NOT NULL,
    MontoOrigen DECIMAL(18,2) NOT NULL,
    MontoReporte DECIMAL(18,2) NOT NULL
);
;WITH Origen AS (
    SELECT p.PedidoID,
           COALESCE(SUM(d.Cantidad * d.PrecioUnitario), 0) AS Monto
    FROM dbo.Pedido AS p
    INNER JOIN dbo.Cliente AS c ON c.ClienteID = p.ClienteID
    LEFT JOIN dbo.DetallePedido AS d ON d.PedidoID = p.PedidoID
    WHERE c.Activo = 1
      AND p.Estado = 'CONFIRMADO'
      AND p.FechaPedido >= '20260101'
      AND p.FechaPedido < '20270101'
    GROUP BY p.PedidoID
), TotalesOrigen AS (
    SELECT COUNT(*) AS PedidosOrigen,
           COALESCE(SUM(o.Monto), 0) AS MontoOrigen
    FROM Origen AS o
), TotalesReporte AS (
    SELECT COALESCE(SUM(v.TotalPedidos2026), 0) AS PedidosReporte,
           COALESCE(SUM(v.MontoVendido2026), 0) AS MontoReporte
    FROM dbo.vw_S07_VentasPorCliente AS v
)
INSERT INTO #Contraste (PedidosOrigen, PedidosReporte, MontoOrigen, MontoReporte)
SELECT
    o.PedidosOrigen,
    r.PedidosReporte,
    o.MontoOrigen,
    r.MontoReporte
FROM TotalesOrigen AS o
CROSS JOIN TotalesReporte AS r;

PRINT '=======================================================';
PRINT ' VALIDACION DE CUADRE FINANCIERO (CONTRASte)           ';
PRINT '=======================================================';
SELECT c.PedidosOrigen, c.PedidosReporte, c.MontoOrigen, c.MontoReporte
FROM #Contraste AS c;

IF EXISTS (
    SELECT 1
    FROM #Contraste AS c
    WHERE c.PedidosOrigen <> c.PedidosReporte
       OR c.MontoOrigen <> c.MontoReporte
)
    THROW 51014, 'El reporte no coincide con los pedidos y detalles de origen.', 1;

DROP TABLE #Casos;
DROP TABLE #Contraste;
GO