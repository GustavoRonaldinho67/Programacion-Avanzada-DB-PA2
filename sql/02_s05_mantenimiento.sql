-- ========================================================================================
-- ARCHIVO: 02_mantenimiento_s05.sql
-- AUTOR: Leandro
-- OBJETIVO: Actividad 2 - Mantenimiento controlado de datos DML con validaciones rigurosas.
-- ========================================================================================
USE NovaMarket;
GO

-- STREAMING_CHUNK: Ejecutando Actividad 2A (Insercion historica)...
PRINT '=======================================================';
PRINT ' S05.A: INSERT ... SELECT (Crear Historico 2025)       ';
PRINT '=======================================================';

SELECT 'ANTES: Total Confirmados < 2026 en Tabla Pedido' AS Metrica, COUNT(*) AS Cantidad 
FROM Pedido WHERE FechaPedido < '2026-01-01' AND Estado = 'CONFIRMADO';

IF OBJECT_ID('PedidoHistorico2025', 'U') IS NULL
BEGIN
    CREATE TABLE PedidoHistorico2025 (
        PedidoID INT PRIMARY KEY, ClienteID INT, FechaPedido DATE, Estado VARCHAR(15), Canal VARCHAR(20)
    );
END

INSERT INTO PedidoHistorico2025 (PedidoID, ClienteID, FechaPedido, Estado, Canal)
SELECT PedidoID, ClienteID, FechaPedido, Estado, Canal
FROM Pedido
WHERE FechaPedido < '2026-01-01' AND Estado = 'CONFIRMADO'
  AND PedidoID NOT IN (SELECT PedidoID FROM PedidoHistorico2025);

SELECT 'DESPUES: Total insertados en PedidoHistorico2025' AS Metrica, COUNT(*) AS Cantidad 
FROM PedidoHistorico2025;
GO

-- STREAMING_CHUNK: Ejecutando Actividad 2B (Update protegido)...
PRINT '=======================================================';
PRINT ' S05.B: UPDATE condicionado (Oferta Redes)             ';
PRINT '=======================================================';

SELECT p.ProductoID, p.Nombre, cat.Nombre AS Categoria, p.Stock, p.PrecioLista, p.PrecioOferta AS Oferta_ANTES
FROM Producto p INNER JOIN Categoria cat ON p.CategoriaID = cat.CategoriaID
WHERE cat.Nombre = 'Redes' AND p.Activo = 1 AND p.Stock >= 10;

UPDATE p
SET p.PrecioOferta = ROUND(p.PrecioLista * 0.90, 2)
FROM Producto p
INNER JOIN Categoria cat ON p.CategoriaID = cat.CategoriaID
WHERE cat.Nombre = 'Redes' AND p.Activo = 1 AND p.Stock >= 10
  AND (p.PrecioOferta IS NULL OR p.PrecioOferta <> ROUND(p.PrecioLista * 0.90, 2));

SELECT p.ProductoID, p.Nombre, cat.Nombre AS Categoria, p.Stock, p.PrecioLista, p.PrecioOferta AS Oferta_DESPUES
FROM Producto p INNER JOIN Categoria cat ON p.CategoriaID = cat.CategoriaID
WHERE cat.Nombre = 'Redes' AND p.Activo = 1 AND p.Stock >= 10;
GO

-- STREAMING_CHUNK: Ejecutando Actividad 2C (Limpieza controlada)...
PRINT '=======================================================';
PRINT ' S05.C: DELETE protegido (Borradores sin detalle)      ';
PRINT '=======================================================';

SELECT 'ANTES: Borradores sin detalle' AS Estatus, COUNT(*) AS Cantidad FROM Pedido 
WHERE Estado = 'BORRADOR' AND NOT EXISTS (SELECT 1 FROM DetallePedido dp WHERE dp.PedidoID = Pedido.PedidoID);

DELETE FROM Pedido
WHERE Estado = 'BORRADOR'
  AND NOT EXISTS (
      SELECT 1 FROM DetallePedido dp WHERE dp.PedidoID = Pedido.PedidoID
  );

SELECT 'DESPUES: Borradores sin detalle restantes' AS Estatus, COUNT(*) AS Cantidad FROM Pedido 
WHERE Estado = 'BORRADOR' AND NOT EXISTS (SELECT 1 FROM DetallePedido dp WHERE dp.PedidoID = Pedido.PedidoID);

SELECT 'Borradores intactos (POR TENER DETALLE)' AS Estatus, COUNT(*) AS Cantidad FROM Pedido WHERE Estado = 'BORRADOR';
GO