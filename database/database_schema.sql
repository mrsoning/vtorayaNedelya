-- =============================================
-- База данных для системы управления продукцией мебельной компании
-- =============================================

-- Удаление существующих таблиц (если есть)
DROP TABLE IF EXISTS Product_workshops;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Product_types;
DROP TABLE IF EXISTS Material_types;
DROP TABLE IF EXISTS Workshops;

-- =============================================
-- Таблица: Material_types (Типы материалов)
-- =============================================
CREATE TABLE Material_types (
    material_type_id INT PRIMARY KEY AUTO_INCREMENT,
    material_type_name VARCHAR(100) NOT NULL UNIQUE,
    waste_percentage DECIMAL(5, 4), -- процент потерь сырья
    description TEXT,
    is_ecological BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Таблица: Product_types (Типы продукции)
-- =============================================
CREATE TABLE Product_types (
    product_type_id INT PRIMARY KEY AUTO_INCREMENT,
    product_type_name VARCHAR(100) NOT NULL UNIQUE,
    type_coefficient DECIMAL(5, 2), -- коэффициент типа продукции
    style VARCHAR(50), -- 'Современный', 'Классический' и т.д.
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Таблица: Workshops (Цеха)
-- =============================================
CREATE TABLE Workshops (
    workshop_id INT PRIMARY KEY AUTO_INCREMENT,
    workshop_name VARCHAR(100) NOT NULL UNIQUE,
    workshop_type VARCHAR(100), -- тип цеха
    staff_count INT, -- количество человек для производства
    location VARCHAR(200),
    equipment_description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Таблица: Products (Продукция)
-- =============================================
CREATE TABLE Products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(200) NOT NULL,
    article_number VARCHAR(50) UNIQUE,
    product_type_id INT NOT NULL,
    material_type_id INT NOT NULL,
    min_partner_price DECIMAL(10, 2), -- минимальная стоимость для партнера
    dimensions VARCHAR(100), -- например "200x100x80"
    weight DECIMAL(8, 2),
    description TEXT,
    is_available BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_product_type 
        FOREIGN KEY (product_type_id) 
        REFERENCES Product_types(product_type_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_material_type 
        FOREIGN KEY (material_type_id) 
        REFERENCES Material_types(material_type_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

-- =============================================
-- Таблица: Product_workshops (Связь продукции с цехами)
-- =============================================
CREATE TABLE Product_workshops (
    product_workshop_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    workshop_id INT NOT NULL,
    production_time_hours DECIMAL(6, 2), -- время производства в часах
    priority INT DEFAULT 1, -- приоритет производства
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_pw_product 
        FOREIGN KEY (product_id) 
        REFERENCES Products(product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT fk_pw_workshop 
        FOREIGN KEY (workshop_id) 
        REFERENCES Workshops(workshop_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    
    CONSTRAINT unique_product_workshop 
        UNIQUE (product_id, workshop_id)
);

-- =============================================
-- Индексы для оптимизации запросов
-- =============================================
CREATE INDEX idx_products_type ON Products(product_type_id);
CREATE INDEX idx_products_material ON Products(material_type_id);
CREATE INDEX idx_products_available ON Products(is_available);
CREATE INDEX idx_pw_product ON Product_workshops(product_id);
CREATE INDEX idx_pw_workshop ON Product_workshops(workshop_id);
CREATE INDEX idx_workshops_active ON Workshops(is_active);

-- =============================================
-- Представления для удобства работы
-- =============================================

-- Представление: Полная информация о продукции
CREATE VIEW v_products_full AS
SELECT 
    p.product_id,
    p.product_name,
    p.article_number,
    pt.product_type_name,
    pt.type_coefficient,
    pt.style,
    mt.material_type_name,
    mt.waste_percentage,
    mt.is_ecological,
    p.min_partner_price,
    p.dimensions,
    p.weight,
    p.description,
    p.is_available,
    p.created_at,
    p.updated_at
FROM Products p
INNER JOIN Product_types pt ON p.product_type_id = pt.product_type_id
INNER JOIN Material_types mt ON p.material_type_id = mt.material_type_id;

-- Представление: Продукция с цехами
CREATE VIEW v_products_workshops AS
SELECT 
    p.product_id,
    p.product_name,
    p.article_number,
    w.workshop_id,
    w.workshop_name,
    w.location,
    pw.production_time_hours,
    pw.priority,
    w.is_active
FROM Products p
INNER JOIN Product_workshops pw ON p.product_id = pw.product_id
INNER JOIN Workshops w ON pw.workshop_id = w.workshop_id;

-- =============================================
-- Комментарии к таблицам
-- =============================================
