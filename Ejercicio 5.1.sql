-- =====================================================================
-- setup_base_datos.sql
-- Crea y carga las tablas: regiones, productos y ventas
-- Base para el Ejercicio 1 del Módulo 5 (CTEs)
-- Motor: PostgreSQL
-- =====================================================================
 
-- (Opcional) Crear la base y conectarse desde psql:
-- CREATE DATABASE analisis_ventas;
-- \c analisis_ventas
 
-- Limpiar si ya existen (el orden respeta las claves foráneas)
DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS regiones;
 
-- ---------------------------------------------------------------------
-- Tabla: regiones
-- ---------------------------------------------------------------------
CREATE TABLE regiones (
    id_region   SERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL UNIQUE
);
 
-- ---------------------------------------------------------------------
-- Tabla: productos
-- ---------------------------------------------------------------------
CREATE TABLE productos (
    id_producto     SERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    categoria       VARCHAR(50)  NOT NULL,
    precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario > 0)
);
 
-- ---------------------------------------------------------------------
-- Tabla: ventas
-- ---------------------------------------------------------------------
CREATE TABLE ventas (
    id_venta     SERIAL PRIMARY KEY,
    fecha        DATE    NOT NULL,
    id_region    INT     NOT NULL REFERENCES regiones(id_region),
    id_producto  INT     NOT NULL REFERENCES productos(id_producto),
    cantidad     INT     NOT NULL CHECK (cantidad > 0),
    monto        NUMERIC(12,2) NOT NULL CHECK (monto >= 0)
);
 
-- ---------------------------------------------------------------------
-- Datos: regiones
-- ---------------------------------------------------------------------
INSERT INTO regiones (nombre) VALUES
    ('Norte'),
    ('Sur'),
    ('Centro'),
    ('Cuyo'),
    ('Patagonia');
 
-- ---------------------------------------------------------------------
-- Datos: productos
-- ---------------------------------------------------------------------
INSERT INTO productos (nombre, categoria, precio_unitario) VALUES
    ('Notebook 14"',        'Tecnología',  850000.00),
    ('Monitor 24"',         'Tecnología',  210000.00),
    ('Mouse inalámbrico',   'Accesorios',   18000.00),
    ('Teclado mecánico',    'Accesorios',   65000.00),
    ('Silla ergonómica',    'Mobiliario',  320000.00),
    ('Escritorio',          'Mobiliario',  280000.00),
    ('Auriculares',         'Accesorios',   45000.00),
    ('Impresora láser',     'Tecnología',  390000.00);
 
-- ---------------------------------------------------------------------
-- Datos: ventas
-- monto = cantidad * precio_unitario
-- Distribución desigual a propósito: Centro y Norte venden mucho,
-- Patagonia y Cuyo poco, así el filtro por promedio muestra diferencias.
-- ---------------------------------------------------------------------
INSERT INTO ventas (fecha, id_region, id_producto, cantidad, monto) VALUES
    -- Norte (1)
    ('2026-01-05', 1, 1,  3, 2550000.00),
    ('2026-01-18', 1, 2,  5, 1050000.00),
    ('2026-02-10', 1, 3, 20,  360000.00),
    ('2026-03-02', 1, 5,  4, 1280000.00),
    ('2026-03-25', 1, 8,  2,  780000.00),
    ('2026-04-14', 1, 7, 10,  450000.00),
    -- Sur (2)
    ('2026-01-09', 2, 3, 15,  270000.00),
    ('2026-02-03', 2, 4,  6,  390000.00),
    ('2026-02-27', 2, 2,  2,  420000.00),
    ('2026-04-01', 2, 6,  1,  280000.00),
    ('2026-04-20', 2, 7,  8,  360000.00),
    -- Centro (3)
    ('2026-01-12', 3, 1,  6, 5100000.00),
    ('2026-01-30', 3, 2,  8, 1680000.00),
    ('2026-02-15', 3, 5,  5, 1600000.00),
    ('2026-03-08', 3, 6,  4, 1120000.00),
    ('2026-03-22', 3, 8,  3, 1170000.00),
    ('2026-04-05', 3, 4, 12,  780000.00),
    ('2026-04-28', 3, 3, 30,  540000.00),
    -- Cuyo (4)
    ('2026-01-20', 4, 3, 10,  180000.00),
    ('2026-02-22', 4, 7,  4,  180000.00),
    ('2026-03-15', 4, 2,  1,  210000.00),
    ('2026-04-10', 4, 4,  3,  195000.00),
    -- Patagonia (5)
    ('2026-02-01', 5, 1,  1,  850000.00),
    ('2026-03-11', 5, 3,  5,   90000.00),
    ('2026-04-25', 5, 6,  1,  280000.00);
 
-- ---------------------------------------------------------------------
-- Verificación rápida
-- ---------------------------------------------------------------------
SELECT 'regiones'  AS tabla, COUNT(*) AS filas FROM regiones
UNION ALL
SELECT 'productos', COUNT(*) FROM productos
UNION ALL
SELECT 'ventas',    COUNT(*) FROM ventas;



-- =====================================================================
-- modulo_5/analisis_ctes.sql
-- Informe de rendimiento regional usando CTEs (Common Table Expressions)
-- Motor: PostgreSQL
-- Tablas utilizadas: ventas, regiones
-- =====================================================================
 
-- ---------------------------------------------------------------------
-- Paso 2: Definición de la CTE
-- ventas_por_region agrupa las ventas por región y calcula el total.
-- Toda la agregación (SUM) ocurre aquí dentro.
-- ---------------------------------------------------------------------
WITH ventas_por_region AS (
    SELECT
        r.nombre       AS region,          -- alias para usarlo afuera
        SUM(v.monto)   AS total_ventas     -- alias obligatorio para la columna calculada
    FROM ventas AS v
    INNER JOIN regiones AS r
        ON v.id_region = r.id_region
    GROUP BY r.nombre
)  -- fin de la CTE: el paréntesis se cierra antes del SELECT final
 
-- ---------------------------------------------------------------------
-- Paso 3: Consulta principal
-- Filtra las regiones cuyo total supera el promedio general.
-- El promedio se calcula con una subconsulta simple dentro del WHERE.
-- ---------------------------------------------------------------------
SELECT
    region,
    total_ventas
FROM ventas_por_region
WHERE total_ventas > (
    -- Promedio de los totales por región
    SELECT AVG(total_ventas)
    FROM ventas_por_region
)
 
-- ---------------------------------------------------------------------
-- Paso 4: Ordenamiento
-- De mayor a menor venta.
-- ---------------------------------------------------------------------
ORDER BY total_ventas DESC;
 
 
-- =====================================================================
-- Nota: interpretación alternativa del "promedio general"
-- Si se quiere comparar contra el promedio de cada venta individual,
-- reemplazar la subconsulta del WHERE por:
--
--     SELECT AVG(monto) FROM ventas
--
-- Con esta variante, todas las regiones superan el promedio, porque el
-- total de una región siempre es mayor que el monto de una venta suelta.
-- =====================================================================