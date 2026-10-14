USE NovaMarket;
GO

-- ACTIVIDAD 1A
-- CLIENTES QUE COMPRARON REDES PERO NO SEGURIDAD DURANTE 2026

SELECT
    c.ClienteID,
    c.Nombre,
    c.Ciudad
FROM Cliente c
WHERE EXISTS
(
    SELECT 1
    FROM Pedido p
    INNER JOIN DetallePedido d
        ON p.PedidoID = d.PedidoID
    INNER JOIN Producto pr
        ON d.ProductoID = pr.ProductoID
    INNER JOIN Categoria ca
        ON pr.CategoriaID = ca.CategoriaID
    WHERE p.ClienteID = c.ClienteID
      AND p.Estado = 'CONFIRMADO'
      AND p.FechaPedido >= '2026-01-01'
      AND p.FechaPedido < '2027-01-01'
      AND ca.Nombre = 'Redes'
)
AND NOT EXISTS
(
    SELECT 1
    FROM Pedido p
    INNER JOIN DetallePedido d
        ON p.PedidoID = d.PedidoID
    INNER JOIN Producto pr
        ON d.ProductoID = pr.ProductoID
    INNER JOIN Categoria ca
        ON pr.CategoriaID = ca.CategoriaID
    WHERE p.ClienteID = c.ClienteID
      AND p.Estado = 'CONFIRMADO'
      AND p.FechaPedido >= '2026-01-01'
      AND p.FechaPedido < '2027-01-01'
      AND ca.Nombre = 'Seguridad'
)
ORDER BY c.ClienteID;
GO


-- ACTIVIDAD 1B
-- PRODUCTOS CON PRECIO MAYOR AL PROMEDIO DE SU CATEGORIa

SELECT
    p.ProductoID,
    p.Nombre,
    c.Nombre AS Categoria,
    p.PrecioLista,

    CAST(
        (
            SELECT AVG(p2.PrecioLista)
            FROM Producto p2
            WHERE p2.CategoriaID = p.CategoriaID
        )
        AS DECIMAL(10,2)
    ) AS PromedioCategoria

FROM Producto p

INNER JOIN Categoria c
    ON p.CategoriaID = c.CategoriaID

WHERE p.PrecioLista >
(
    SELECT AVG(p2.PrecioLista)
    FROM Producto p2
    WHERE p2.CategoriaID = p.CategoriaID
)

ORDER BY
    c.Nombre,
    p.PrecioLista DESC;
GO



-- ACTIVIDAD 1C
-- ANALISIS


-- Se utiliza EXISTS para comprobar si existe  al menos una compra que cumpla las condiciones

-- NOT EXISTS permite comprobar que el clirnte no tenga compras confirmadas de seeguridad durante el ano 2026

-- EXISTS y NOT EXISTS son adecuados porque solo necesitamos saber si los registros existen o no

-- Se debe tener cuidado con NOT IN porque si la subconsulta devuelve valores NULL puede generar resultados inesperados
-- ============================================
-- CASOS DE PRUEBA
-- ============================================

SELECT
    c.ClienteID,
    c.Nombre,
    p.PedidoID,
    p.FechaPedido,
    p.Estado,
    ca.Nombre AS Categoria
FROM Cliente c

INNER JOIN Pedido p
    ON c.ClienteID = p.ClienteID

INNER JOIN DetallePedido d
    ON p.PedidoID = d.PedidoID

INNER JOIN Producto pr
    ON d.ProductoID = pr.ProductoID

INNER JOIN Categoria ca
    ON pr.CategoriaID = ca.CategoriaID

WHERE c.ClienteID IN (1,2)
  AND p.FechaPedido >= '2026-01-01'
  AND p.FechaPedido < '2027-01-01'
  

ORDER BY
    c.ClienteID,
    p.PedidoID;
GO

-- Cliente 1 debe incluirse pq tiene compra confirmada de redes en 2026  y no tiene compra confirmaada de eguridad

-- Cliente 2 debe excluirse  tiene compras confirmadas de redes y seguridad en 2026