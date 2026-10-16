USE NovaMarket;
GO

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

SELECT v.ClienteID, v.Nombre, v.TotalPedidos2026, v.MontoVendido2026
FROM dbo.vw_S07_VentasPorCliente AS v
ORDER BY v.ClienteID;
