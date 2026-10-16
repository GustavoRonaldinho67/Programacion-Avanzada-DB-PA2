-- ========================================================================================
-- ARCHIVO: 04_datos_de_prueba_y_volumetria_s07.sql
-- AUTOR: Daniel
-- OBJETIVO: Actividad 4A - Generacion y control estricto de datos de prueba (Volumetria).
-- ========================================================================================
USE NovaMarket;
GO
SET NOCOUNT ON;

-- STREAMING_CHUNK: Validando esquema base...
IF OBJECT_ID(N'dbo.Pedido', N'U') IS NULL
    THROW 51000, 'Ejecute primero sql/00_esquema_y_datos_base.sql.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.Pedido WHERE PedidoID = 1)
   OR NOT EXISTS (SELECT 1 FROM dbo.Pedido WHERE PedidoID = 10)
   OR NOT EXISTS (SELECT 1 FROM dbo.Pedido WHERE PedidoID = 29)
    THROW 51001, 'Faltan los pedidos base de los casos de prueba.', 1;

-- STREAMING_CHUNK: Generando Pedidos con CTE Recursiva...
SET IDENTITY_INSERT dbo.Pedido ON;
;WITH Numeros AS (
    SELECT 1 AS Numero
    UNION ALL
    SELECT Numero + 1
    FROM Numeros
    WHERE Numero < 162
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
        WHEN n.Numero % 5 = 0 THEN 'PENDIENTE'
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
    SELECT 1
    FROM dbo.Pedido AS existente
    WHERE existente.PedidoID = 7000 + n.Numero
)
OPTION (MAXRECURSION 0);
SET IDENTITY_INSERT dbo.Pedido OFF;

-- STREAMING_CHUNK: Generando Detalles de Pedidos...
SET IDENTITY_INSERT dbo.DetallePedido ON;
INSERT INTO dbo.DetallePedido
    (DetalleID, PedidoID, ProductoID, Cantidad, PrecioUnitario)
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
      SELECT 1
      FROM dbo.DetallePedido AS existente
      WHERE existente.DetalleID = 7000 + 2 * (p.PedidoID - 7001) + linea.Numero
  );
SET IDENTITY_INSERT dbo.DetallePedido OFF;

-- STREAMING_CHUNK: Verificando metricas de volumetria...
PRINT '=======================================================';
PRINT ' METRICAS DE VOLUMETRIA                                ';
PRINT '=======================================================';
SELECT 'Cliente' AS Tabla, COUNT(*) AS Total FROM dbo.Cliente
UNION ALL SELECT 'Categoria', COUNT(*) FROM dbo.Categoria
UNION ALL SELECT 'Producto', COUNT(*) FROM dbo.Producto
UNION ALL SELECT 'Pedido', COUNT(*) FROM dbo.Pedido
UNION ALL SELECT 'DetallePedido', COUNT(*) FROM dbo.DetallePedido;

SELECT YEAR(p.FechaPedido) AS Anio, p.Estado, COUNT(*) AS TotalPedidos
FROM dbo.Pedido AS p
GROUP BY YEAR(p.FechaPedido), p.Estado
ORDER BY Anio, p.Estado;

-- STREAMING_CHUNK: Auditoria de Integridad Referencial...
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

-- STREAMING_CHUNK: Validacion de preservacion de Casos Limite...
PRINT '=======================================================';
PRINT ' AUDITORIA DE CASOS LIMITE INTACTOS                    ';
PRINT '=======================================================';
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