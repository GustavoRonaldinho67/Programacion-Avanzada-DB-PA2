-- ========================================================================================
-- ARCHIVO: 00_esquema_y_datos_base.sql
-- OBJETIVO: Creación de base de datos, tablas maestras e inserción de datos iniciales.
-- ========================================================================================

-- STREAMING_CHUNK: Configurando contexto y creando Base de Datos...
USE master;
GO

IF DB_ID('NovaMarket') IS NULL
BEGIN
    CREATE DATABASE NovaMarket;
END
GO

USE NovaMarket;
GO

-- STREAMING_CHUNK: Limpiando tablas preventivamente...
IF OBJECT_ID('DetallePedido', 'U') IS NOT NULL DROP TABLE DetallePedido;
IF OBJECT_ID('Pedido', 'U') IS NOT NULL DROP TABLE Pedido;
IF OBJECT_ID('Producto', 'U') IS NOT NULL DROP TABLE Producto;
IF OBJECT_ID('Categoria', 'U') IS NOT NULL DROP TABLE Categoria;
IF OBJECT_ID('Cliente', 'U') IS NOT NULL DROP TABLE Cliente;
GO

-- STREAMING_CHUNK: Creando tablas maestras (Cliente y Categoria)...
CREATE TABLE Cliente (
    ClienteID INT IDENTITY(1,1) PRIMARY KEY,
    Documento VARCHAR(12) NOT NULL UNIQUE,
    Nombre VARCHAR(80) NOT NULL,
    Ciudad VARCHAR(50) NOT NULL,
    Activo BIT NOT NULL DEFAULT 1
);
GO

CREATE TABLE Categoria (
    CategoriaID INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL UNIQUE
);
GO

-- STREAMING_CHUNK: Creando tabla Producto con restricciones...
CREATE TABLE Producto (
    ProductoID INT IDENTITY(1,1) PRIMARY KEY,
    CategoriaID INT NOT NULL,
    Nombre VARCHAR(80) NOT NULL,
    PrecioLista DECIMAL(10,2) NOT NULL,
    PrecioOferta DECIMAL(10,2) NULL,
    Stock INT NOT NULL,
    Activo BIT NOT NULL DEFAULT 1,
    CONSTRAINT FK_Producto_Categoria FOREIGN KEY (CategoriaID) REFERENCES Categoria(CategoriaID),
    CONSTRAINT CK_Producto_Precio CHECK (PrecioLista > 0),
    CONSTRAINT CK_Producto_Stock CHECK (Stock >= 0)
);
GO

-- STREAMING_CHUNK: Creando tablas transaccionales (Pedido y Detalle)...
CREATE TABLE Pedido (
    PedidoID INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT NOT NULL,
    FechaPedido DATE NOT NULL,
    Estado VARCHAR(15) NOT NULL,
    Canal VARCHAR(20) NOT NULL,
    CONSTRAINT FK_Pedido_Cliente FOREIGN KEY (ClienteID) REFERENCES Cliente(ClienteID),
    CONSTRAINT CK_Pedido_Estado CHECK (Estado IN ('CONFIRMADO', 'PENDIENTE', 'ANULADO', 'BORRADOR'))
);
GO

CREATE TABLE DetallePedido (
    DetalleID INT IDENTITY(1,1) PRIMARY KEY,
    PedidoID INT NOT NULL,
    ProductoID INT NOT NULL,
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_Detalle_Pedido FOREIGN KEY (PedidoID) REFERENCES Pedido(PedidoID),
    CONSTRAINT FK_Detalle_Producto FOREIGN KEY (ProductoID) REFERENCES Producto(ProductoID),
    CONSTRAINT CK_Detalle_Cantidad CHECK (Cantidad > 0),
    CONSTRAINT CK_Detalle_Precio CHECK (PrecioUnitario > 0)
);
GO

-- STREAMING_CHUNK: Insertando Catalogos y Productos base...
INSERT INTO Categoria (Nombre) VALUES ('Redes'), ('Seguridad'), ('Accesorios');
GO

INSERT INTO Producto (CategoriaID, Nombre, PrecioLista, PrecioOferta, Stock, Activo)
VALUES
(1, 'Router WiFi 6', 300.00, NULL, 20, 1), (1, 'Switch 8 Puertos', 180.00, NULL, 15, 1),
(1, 'Access Point', 240.00, NULL, 12, 1), (1, 'Cable UTP 100m', 60.00, NULL, 50, 1),
(2, 'Camara IP Exterior', 280.00, NULL, 20, 1), (2, 'DVR 8 Canales', 450.00, NULL, 10, 1),
(2, 'Sensor Movimiento', 90.00, NULL, 30, 1), (2, 'Kit Alarma', 320.00, NULL, 15, 1),
(3, 'Mouse Gamer', 120.00, NULL, 25, 1), (3, 'Teclado Mecanico', 220.00, NULL, 20, 1),
(3, 'Webcam HD', 160.00, NULL, 18, 1), (3, 'Hub USB-C', 200.00, NULL, 22, 1);
GO

-- STREAMING_CHUNK: Insertando Clientes iniciales...
INSERT INTO Cliente (Documento, Nombre, Ciudad, Activo)
VALUES
('70000001', 'Tech Corp', 'Lima', 1), ('70000002', 'Global Net', 'Lima', 1),
('70000003', 'Secure IT', 'Arequipa', 1), ('70000004', 'Inversiones Sur', 'Cusco', 1),
('70000005', 'Data Center Peru', 'Lima', 1), ('70000006', 'Juan Perez', 'Trujillo', 1),
('70000007', 'Maria Gomez', 'Piura', 1), ('70000008', 'Carlos Ruiz', 'Lima', 1),
('70000009', 'Ana Torres', 'Tacna', 1), ('70000010', 'Luis Vega', 'Lima', 1),
('70000011', 'Jorge Castro', 'Chiclayo', 1), ('70000012', 'Elena Rojas', 'Arequipa', 1),
('70000013', 'Marta Silva', 'Lima', 1), ('70000014', 'Pedro Luna', 'Cusco', 1),
('70000015', 'Cliente Sin Compras', 'Lima', 1); -- Caso Limite S07
GO

-- STREAMING_CHUNK: Insertando 40 Pedidos Iniciales...
INSERT INTO Pedido (ClienteID, FechaPedido, Estado, Canal)
VALUES
(1, '2026-01-10', 'CONFIRMADO', 'WEB'), (2, '2026-01-12', 'CONFIRMADO', 'TIENDA'),
(2, '2026-02-05', 'CONFIRMADO', 'WEB'), (4, '2026-02-10', 'CONFIRMADO', 'APP'),
(5, '2026-03-01', 'CONFIRMADO', 'WEB'), (6, '2026-03-15', 'CONFIRMADO', 'TIENDA'),
(7, '2026-04-01', 'CONFIRMADO', 'WEB'), (7, '2026-04-20', 'CONFIRMADO', 'APP'),
(8, '2025-11-10', 'CONFIRMADO', 'WEB'), (9, '2026-05-01', 'PENDIENTE', 'WEB'),
(10, '2026-05-12', 'CONFIRMADO', 'TIENDA'), (11, '2026-06-01', 'CONFIRMADO', 'WEB'),
(12, '2026-06-15', 'CONFIRMADO', 'APP'), (12, '2026-06-20', 'BORRADOR', 'WEB'),
(13, '2026-07-01', 'CONFIRMADO', 'WEB'), (13, '2026-07-08', 'CONFIRMADO', 'TIENDA'),
(14, '2026-07-15', 'CONFIRMADO', 'WEB'), (1, '2026-08-01', 'CONFIRMADO', 'APP'),
(1, '2025-09-10', 'CONFIRMADO', 'TIENDA'), (5, '2025-10-05', 'CONFIRMADO', 'WEB'),
(6, '2026-08-12', 'PENDIENTE', 'WEB'), (4, '2025-12-15', 'CONFIRMADO', 'APP'),
(10, '2026-08-20', 'CONFIRMADO', 'WEB'), (11, '2025-06-11', 'CONFIRMADO', 'TIENDA'),
(12, '2026-09-01', 'CONFIRMADO', 'WEB'), (1, '2026-09-10', 'CONFIRMADO', 'TIENDA'),
(2, '2025-02-15', 'CONFIRMADO', 'WEB'), (7, '2025-03-11', 'CONFIRMADO', 'WEB'),
(8, '2026-09-20', 'ANULADO', 'APP'), (14, '2025-05-17', 'CONFIRMADO', 'TIENDA'),
(1, '2026-10-01', 'PENDIENTE', 'WEB'), (5, '2026-10-05', 'CONFIRMADO', 'APP'),
(6, '2025-08-09', 'CONFIRMADO', 'WEB'), (10, '2025-08-15', 'CONFIRMADO', 'TIENDA'),
(11, '2026-10-12', 'PENDIENTE', 'APP'), (13, '2026-10-20', 'CONFIRMADO', 'WEB'),
(14, '2026-11-01', 'CONFIRMADO', 'WEB'), (1, '2025-11-12', 'CONFIRMADO', 'TIENDA'),
(9, '2026-11-15', 'BORRADOR', 'WEB'), (3, '2026-12-01', 'BORRADOR', 'APP');
GO

-- STREAMING_CHUNK: Insertando Detalles de los Pedidos...
INSERT INTO DetallePedido (PedidoID, ProductoID, Cantidad, PrecioUnitario)
VALUES
(1,1,1,300.00), (1,9,2,120.00), (1,2,1,180.00),
(2,2,1,180.00), (2,10,1,220.00), (2,3,1,240.00),
(3,5,1,280.00), (3,10,2,220.00), (3,6,1,450.00),
(4,5,1,280.00), (4,6,1,450.00), (4,9,1,120.00),
(5,1,1,300.00), (5,10,1,220.00),
(6,2,2,180.00), (6,11,1,160.00),
(7,3,1,240.00), (7,9,1,120.00),
(8,5,1,280.00), (8,12,1,200.00),
(9,1,1,300.00), (9,9,1,120.00),
(10,4,3,60.00), (10,10,1,220.00),
(11,2,1,180.00), (11,12,1,200.00),
(12,6,1,450.00), (12,9,1,120.00),
(13,3,1,240.00), (13,11,1,160.00),
(14,5,1,280.00), (14,12,1,200.00),
(15,1,1,300.00), (15,9,1,120.00),
(16,8,1,320.00), (16,11,1,160.00),
(17,9,1,120.00), (17,10,1,220.00),
(18,4,4,60.00), (18,12,1,200.00),
(19,7,1,90.00), (19,9,1,120.00),
(20,5,1,280.00), (20,10,1,220.00),
(21,6,1,450.00), (21,9,1,120.00),
(22,2,1,180.00), (22,11,1,160.00),
(23,1,1,300.00), (23,9,2,120.00),
(24,3,1,240.00), (24,12,1,200.00),
(25,4,2,60.00), (25,10,1,220.00),
(26,2,1,180.00), (26,11,2,160.00),
(27,1,1,300.00), (27,9,1,120.00),
(28,3,1,240.00), (28,10,1,220.00),
(29,2,1,180.00), (29,12,1,200.00),
(30,4,2,60.00), (30,9,1,120.00),
(31,5,1,280.00), (31,11,1,160.00),
(32,3,1,240.00), (32,10,1,220.00),
(33,8,1,320.00), (33,9,1,120.00),
(34,1,1,300.00), (34,11,1,160.00),
(35,2,1,180.00), (35,12,1,200.00),
(36,6,1,450.00), (36,10,1,220.00),
(37,9,1,120.00), (37,11,1,160.00),
(38,5,1,280.00), (38,12,1,200.00);
GO