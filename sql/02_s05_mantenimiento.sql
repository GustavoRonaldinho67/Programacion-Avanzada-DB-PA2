--ACTIVIDAD 1.A: Segmentación con EXISTS y NOT EXISTS (Corregido y Ajustado)
-- ============================================================================
SELECT 
    c.ClienteID,
    c.Nombre,
    c.Ciudad
FROM Cliente c
WHERE EXISTS (
    -- Que tenga al menos un pedido completado/confirmado de 'Redes'
    SELECT 1
    FROM Pedido p
    INNER JOIN DetallePedido dp ON p.PedidoID = dp.PedidoID
    INNER JOIN Producto pr ON dp.ProductoID = pr.ProductoID
    INNER JOIN Categoria cat ON pr.CategoriaID = cat.CategoriaID
    WHERE p.ClienteID = c.ClienteID
      AND cat.Nombre = 'Redes'
      AND p.Estado IN ('Completado', 'Confirmado')
)
AND NOT EXISTS (
    -- Que NO tenga pedidos de 'Seguridad'
    SELECT 1
    FROM Pedido p
    INNER JOIN DetallePedido dp ON p.PedidoID = dp.PedidoID
    INNER JOIN Producto pr ON dp.ProductoID = pr.ProductoID
    INNER JOIN Categoria cat ON pr.CategoriaID = cat.CategoriaID
    WHERE p.ClienteID = c.ClienteID
      AND cat.Nombre = 'Seguridad'
      AND p.Estado IN ('Completado', 'Confirmado')
);

-- ACTIVIDAD 1.B: Subconsulta correlacionada (Productos sobre el promedio de su categoría)
-- ============================================================================
SELECT 
    p.ProductoID,
    p.Nombre,
    cat.Nombre AS Categoria,
    p.PrecioLista,
    CAST((
        SELECT AVG(p_sub.PrecioLista)
        FROM Producto p_sub
        WHERE p_sub.CategoriaID = p.CategoriaID
    ) AS DECIMAL(10,2)) AS PromedioCategoria
FROM Producto p
INNER JOIN Categoria cat ON p.CategoriaID = cat.CategoriaID
WHERE p.PrecioLista > (
    SELECT AVG(p_sub.PrecioLista)
    FROM Producto p_sub
    WHERE p_sub.CategoriaID = p.CategoriaID
);


-- ACTIVIDAD 2.A: INSERT ... SELECT (Crear PedidoHistorico2025 y cargar datos)
-- ============================================================================

-- 1. Crear la tabla histórica con la misma estructura (si no existe)
IF OBJECT_ID('PedidoHistorico2025', 'U') IS NOT NULL
    DROP TABLE PedidoHistorico2025;
GO
SELECT PedidoID, ClienteID, FechaPedido, Estado, Canal
INTO PedidoHistorico2025
FROM Pedido
WHERE FechaPedido < '2026-01-01'
  AND Estado IN ('Completado', 'Confirmado');
GO
-- 2. Verificación y conteo origen/destino para asegurar la carga
SELECT 'Tabla Original Pedido' AS OrigenDestino, COUNT(*) AS TotalFilas FROM Pedido WHERE FechaPedido < '2026-01-01' AND Estado IN ('Completado', 'Confirmado')
UNION ALL
SELECT 'Tabla Historica Copiada' AS OrigenDestino, COUNT(*) AS TotalFilas FROM PedidoHistorico2025;
GO

-- ACTIVIDAD 2.B: UPDATE condicionado en Productos de Redes
-- ============================================================================

-- 1. COMPROBACIÓN ANTES (Visualizar productos de Redes con Stock >= 10)
SELECT 
    p.ProductoID,
    p.Nombre,
    cat.Nombre AS Categoria,
    p.PrecioLista,
    p.PrecioOferta AS PrecioOferta_Antes,
    p.Stock,
    p.Activo
FROM Producto p
INNER JOIN Categoria cat ON p.CategoriaID = cat.CategoriaID
WHERE cat.Nombre = 'Redes'
  AND p.Activo = 1
  AND p.Stock >= 10;
GO

-- 2. EJECUCIÓN DEL UPDATE CONTROLADO
UPDATE p
SET p.PrecioOferta = ROUND(p.PrecioLista * 0.90, 2)
FROM Producto p
INNER JOIN Categoria cat ON p.CategoriaID = cat.CategoriaID
WHERE cat.Nombre = 'Redes'
  AND p.Activo = 1
  AND p.Stock >= 10;
GO

-- 3. COMPROBACIÓN DESPUÉS (Demostrar los cambios aplicados)
SELECT 
    p.ProductoID,
    p.Nombre,
    cat.Nombre AS Categoria,
    p.PrecioLista,
    p.PrecioOferta AS PrecioOferta_Despues,
    p.Stock,
    p.Activo
FROM Producto p
INNER JOIN Categoria cat ON p.CategoriaID = cat.CategoriaID
WHERE cat.Nombre = 'Redes'
  AND p.Activo = 1
  AND p.Stock >= 10;
GO

-- ACTIVIDAD 2.C: DELETE protegido de pedidos BORRADOR sin detalle
-- ============================================================================

-- 1. COMPROBACIÓN ANTES (Listar todos los pedidos actuales y sus detalles asociados)
SELECT 
    p.PedidoID,
    p.Estado,
    p.FechaPedido,
    (SELECT COUNT(*) FROM DetallePedido dp WHERE dp.PedidoID = p.PedidoID) AS TotalDetalles
FROM Pedido p;
GO

-- 2. EJECUCIÓN DEL DELETE PROTEGIDO
-- Elimina solo pedidos 'Borrador' que NO tengan ningún detalle registrado
DELETE FROM Pedido
WHERE Estado = 'Borrador'
  AND NOT EXISTS (
      SELECT 1 
      FROM DetallePedido dp 
      WHERE dp.PedidoID = Pedido.PedidoID
  );
GO

-- 3. COMPROBACIÓN DESPUÉS (Verificar que los pedidos válidos o con detalle siguen intactos)
SELECT 
    p.PedidoID,
    p.Estado,
    p.FechaPedido,
    (SELECT COUNT(*) FROM DetallePedido dp WHERE dp.PedidoID = p.PedidoID) AS TotalDetalles
FROM Pedido p;
GO