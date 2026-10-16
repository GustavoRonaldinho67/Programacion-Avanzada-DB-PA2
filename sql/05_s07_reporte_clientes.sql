-- ============================================================================
-- SESIÓN 7 / ACTIVIDAD 4: REPORTE DE VENTAS POR CLIENTE
-- Esquema: ClienteID | Nombre | TotalPedidos2026 | MontoVendido2026
-- ============================================================================

USE NovaMarket;
GO

SELECT
    ClienteID,
    Nombre,
    TotalPedidos2026,
    MontoVendido2026
FROM dbo.vw_S07_VentasPorCliente
ORDER BY ClienteID;
GO
