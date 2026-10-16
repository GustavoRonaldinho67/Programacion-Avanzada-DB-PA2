USE NovaMarket;
GO
SET NOCOUNT ON;

IF (SELECT COUNT(*) FROM dbo.Pedido) < 200
    THROW 51010, 'Se requieren al menos 200 pedidos.', 1;
IF (SELECT COUNT(*) FROM dbo.DetallePedido) < 400
    THROW 51011, 'Se requieren al menos 400 detalles.', 1;
IF (SELECT COUNT(*) FROM dbo.vw_S07_VentasPorCliente)
   <> (SELECT COUNT(*) FROM dbo.Cliente WHERE Activo = 1)
    THROW 51012, 'El reporte debe incluir a todos los clientes activos.', 1;

CREATE TABLE #Casos (
    Caso NVARCHAR(80) NOT NULL,
    ClienteID INT NOT NULL,
    PedidosEsperados INT NOT NULL,
    MontoEsperado DECIMAL(18,2) NOT NULL
);
INSERT INTO #Casos (Caso, ClienteID, PedidosEsperados, MontoEsperado)
VALUES
    (N'Pedido confirmado con tres líneas', 1, 1, 720.00),
    (N'Sin compras confirmadas', 3, 0, 0.00),
    (N'Pedido pendiente', 9, 0, 0.00),
    (N'Pedido anulado', 8, 0, 0.00);

SELECT
    e.Caso,
    e.ClienteID,
    e.PedidosEsperados,
    v.TotalPedidos2026 AS PedidosObtenidos,
    e.MontoEsperado,
    v.MontoVendido2026 AS MontoObtenido,
    CASE WHEN v.TotalPedidos2026 = e.PedidosEsperados
          AND v.MontoVendido2026 = e.MontoEsperado
        THEN 'OK' ELSE 'FALLO' END AS Resultado
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
    THROW 51013, 'La matriz de casos no coincide con el reporte.', 1;

-- Contraste independiente de pedidos y montos del reporte con las tablas base.
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
)
INSERT INTO #Contraste (PedidosOrigen, PedidosReporte, MontoOrigen, MontoReporte)
SELECT
    (SELECT COUNT(*) FROM Origen) AS PedidosOrigen,
    (SELECT SUM(v.TotalPedidos2026) FROM dbo.vw_S07_VentasPorCliente AS v) AS PedidosReporte,
    (SELECT SUM(o.Monto) FROM Origen AS o) AS MontoOrigen,
    (SELECT SUM(v.MontoVendido2026) FROM dbo.vw_S07_VentasPorCliente AS v) AS MontoReporte;

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
