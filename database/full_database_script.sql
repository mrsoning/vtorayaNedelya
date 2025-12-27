-- =============================================
-- ПОЛНЫЙ СКРИПТ БАЗЫ ДАННЫХ
-- Система управления продукцией мебельной компании
-- =============================================

-- Создание базы данных
CREATE DATABASE IF NOT EXISTS furniture_company 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE furniture_company;

-- =============================================
-- УДАЛЕНИЕ СУЩЕСТВУЮЩИХ ТАБЛИЦ
-- =============================================
DROP TABLE IF EXISTS Product_workshops;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Product_types;
DROP TABLE IF EXISTS Material_types;
DROP TABLE IF EXISTS Workshops;

-- =============================================
-- СОЗДАНИЕ ТАБЛИЦ
-- =============================================

-- Таблица: Material_types (Типы материалов)
CREATE TABLE Material_types (
    material_type_id INT PRIMARY KEY AUTO_INCREMENT,
    material_type_name VARCHAR(100) NOT NULL UNIQUE,
    waste_percentage DECIMAL(5, 4), -- процент потерь сырья
    description TEXT,
    is_ecological BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица: Product_types (Типы продукции)
CREATE TABLE Product_types (
    product_type_id INT PRIMARY KEY AUTO_INCREMENT,
    product_type_name VARCHAR(100) NOT NULL UNIQUE,
    type_coefficient DECIMAL(5, 2), -- коэффициент типа продукции
    style VARCHAR(50), -- 'Современный', 'Классический' и т.д.
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица: Workshops (Цеха)
CREATE TABLE Workshops (
    workshop_id INT PRIMARY KEY AUTO_INCREMENT,
    workshop_name VARCHAR(100) NOT NULL UNIQUE,
    workshop_type VARCHAR(100), -- тип цеха
    staff_count INT, -- количество человек для производства
    location VARCHAR(200),
    equipment_description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица: Products (Продукция)
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица: Product_workshops (Связь продукции с цехами)
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================
-- ИНДЕКСЫ
-- =============================================
CREATE INDEX idx_products_type ON Products(product_type_id);
CREATE INDEX idx_products_material ON Products(material_type_id);
CREATE INDEX idx_products_available ON Products(is_available);
CREATE INDEX idx_pw_product ON Product_workshops(product_id);
CREATE INDEX idx_pw_workshop ON Product_workshops(workshop_id);
CREATE INDEX idx_workshops_active ON Workshops(is_active);

-- =============================================
-- ПРЕДСТАВЛЕНИЯ
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
    w.workshop_type,
    w.location,
    pw.production_time_hours,
    pw.priority,
    w.is_active
FROM Products p
INNER JOIN Product_workshops pw ON p.product_id = pw.product_id
INNER JOIN Workshops w ON pw.workshop_id = w.workshop_id;


-- =============================================
-- ИМПОРТ ДАННЫХ
-- =============================================
-- =============================================
-- Импорт данных в базу данных
-- =============================================

-- =============================================
-- Импорт типов материалов
-- =============================================
INSERT INTO Material_types (material_type_name, waste_percentage) VALUES ('Мебельный щит из массива дерева', 0.008);
INSERT INTO Material_types (material_type_name, waste_percentage) VALUES ('Ламинированное ДСП', 0.007);
INSERT INTO Material_types (material_type_name, waste_percentage) VALUES ('Фанера', 0.0055);
INSERT INTO Material_types (material_type_name, waste_percentage) VALUES ('МДФ', 0.003);

-- =============================================
-- Импорт типов продукции
-- =============================================
INSERT INTO Product_types (product_type_name, type_coefficient) VALUES ('Гостиные', 3.5);
INSERT INTO Product_types (product_type_name, type_coefficient) VALUES ('Прихожие', 5.6);
INSERT INTO Product_types (product_type_name, type_coefficient) VALUES ('Мягкая мебель', 3.0);
INSERT INTO Product_types (product_type_name, type_coefficient) VALUES ('Кровати', 4.7);
INSERT INTO Product_types (product_type_name, type_coefficient) VALUES ('Шкафы', 1.5);
INSERT INTO Product_types (product_type_name, type_coefficient) VALUES ('Комоды', 2.3);

-- =============================================
-- Импорт цехов
-- =============================================
INSERT INTO Workshops (workshop_name, workshop_type, staff_count) VALUES ('Проектный', 'Проектирование', 4);
INSERT INTO Workshops (workshop_name, workshop_type, staff_count) VALUES ('Расчетный', 'Проектирование', 5);
INSERT INTO Workshops (workshop_name, workshop_type, staff_count) VALUES ('Раскроя', 'Обработка', 5);
INSERT INTO Workshops (workshop_name, workshop_type, staff_count) VALUES ('Обработки', 'Обработка', 6);
INSERT INTO Workshops (workshop_name, workshop_type, staff_count) VALUES ('Сушильный', 'Сушка', 3);
INSERT INTO Workshops (workshop_name, workshop_type, staff_count) VALUES ('Покраски', 'Обработка', 5);
INSERT INTO Workshops (workshop_name, workshop_type, staff_count) VALUES ('Столярный', 'Обработка', 7);
INSERT INTO Workshops (workshop_name, workshop_type, staff_count) VALUES ('Изготовления изделий из искусственного камня и композитных материалов', 'Обработка', 3);
INSERT INTO Workshops (workshop_name, workshop_type, staff_count) VALUES ('Изготовления мягкой мебели', 'Обработка', 5);
INSERT INTO Workshops (workshop_name, workshop_type, staff_count) VALUES ('Монтажа стеклянных, зеркальных вставок и других изделий', 'Сборка', 2);
INSERT INTO Workshops (workshop_name, workshop_type, staff_count) VALUES ('Сборки', 'Сборка', 6);
INSERT INTO Workshops (workshop_name, workshop_type, staff_count) VALUES ('Упаковки', 'Сборка', 4);

-- =============================================
-- Импорт продукции
-- =============================================
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Комплект мебели для гостиной Ольха горная', '1549922', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Гостиные'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Мебельный щит из массива дерева'),
    160507);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Стенка для гостиной Вишня темная', '1018556', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Гостиные'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Мебельный щит из массива дерева'),
    216907);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Прихожая Венге Винтаж', '3028272', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Прихожие'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Ламинированное ДСП'),
    24970);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Тумба с вешалкой Дуб натуральный', '3029272', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Прихожие'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Ламинированное ДСП'),
    18206);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Прихожая-комплект Дуб темный', '3028248', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Прихожие'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Мебельный щит из массива дерева'),
    177509);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Диван-кровать угловой Книжка', '7118827', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Мягкая мебель'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Мебельный щит из массива дерева'),
    85900);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Диван модульный Телескоп', '7137981', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Мягкая мебель'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Мебельный щит из массива дерева'),
    75900);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Диван-кровать Соло', '7029787', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Мягкая мебель'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Мебельный щит из массива дерева'),
    120345);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Детский диван Выкатной', '7758953', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Мягкая мебель'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Фанера'),
    25990);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Кровать с подъемным механизмом с матрасом 1600х2000 Венге', '6026662', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Кровати'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Мебельный щит из массива дерева'),
    69500);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Кровать с матрасом 90х2000 Венге', '6159043', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Кровати'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Ламинированное ДСП'),
    55600);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Кровать универсальная Дуб натуральный', '6588376', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Кровати'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Ламинированное ДСП'),
    37900);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Кровать с ящиками Ясень белый', '6758375', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Кровати'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Фанера'),
    46750);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Шкаф-купе 3-х дверный Сосна белая', '2759324', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Шкафы'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Ламинированное ДСП'),
    131560);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Стеллаж Бук натуральный', '2118827', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Шкафы'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Мебельный щит из массива дерева'),
    38700);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Шкаф 4 дверный с ящиками Ясень серый', '2559898', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Шкафы'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Фанера'),
    160151);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Шкаф-пенал Береза белый', '2259474', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Шкафы'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Фанера'),
    40500);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Комод 6 ящиков Вишня светлая', '4115947', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Комоды'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Мебельный щит из массива дерева'),
    61235);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Комод 4 ящика Вишня светлая', '4033136', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Комоды'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'Мебельный щит из массива дерева'),
    41200);
INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
VALUES ('Тумба под ТВ ', '4028048', 
    (SELECT product_type_id FROM Product_types WHERE product_type_name = 'Комоды'),
    (SELECT material_type_id FROM Material_types WHERE material_type_name = 'МДФ'),
    12350);

-- =============================================
-- Импорт связей продукции с цехами
-- =============================================
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с подъемным механизмом с матрасом 1600х2000 Венге'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Изготовления изделий из искусственного камня и композитных материалов'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Тумба под ТВ '),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Изготовления изделий из искусственного камня и композитных материалов'),
    2.7);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать угловой Книжка'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Изготовления мягкой мебели'),
    4.2);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван модульный Телескоп'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Изготовления мягкой мебели'),
    4.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать Соло'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Изготовления мягкой мебели'),
    4.7);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Детский диван Выкатной'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Изготовления мягкой мебели'),
    4.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с матрасом 90х2000 Венге'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Изготовления мягкой мебели'),
    5.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стенка для гостиной Вишня темная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Монтажа стеклянных, зеркальных вставок и других изделий'),
    0.3);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Прихожая Венге Винтаж'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Монтажа стеклянных, зеркальных вставок и других изделий'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Прихожая-комплект Дуб темный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Монтажа стеклянных, зеркальных вставок и других изделий'),
    0.3);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с подъемным механизмом с матрасом 1600х2000 Венге'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Монтажа стеклянных, зеркальных вставок и других изделий'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф-купе 3-х дверный Сосна белая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Монтажа стеклянных, зеркальных вставок и других изделий'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Тумба под ТВ '),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Монтажа стеклянных, зеркальных вставок и других изделий'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комплект мебели для гостиной Ольха горная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стенка для гостиной Вишня темная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.3);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Прихожая Венге Винтаж'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Тумба с вешалкой Дуб натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Прихожая-комплект Дуб темный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать угловой Книжка'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван модульный Телескоп'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать Соло'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Детский диван Выкатной'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.3);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с подъемным механизмом с матрасом 1600х2000 Венге'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.6);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с матрасом 90х2000 Венге'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать универсальная Дуб натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.8);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с ящиками Ясень белый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф-купе 3-х дверный Сосна белая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стеллаж Бук натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.3);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф 4 дверный с ящиками Ясень серый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    1.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф-пенал Береза белый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комод 6 ящиков Вишня светлая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комод 4 ящика Вишня светлая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.4);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Тумба под ТВ '),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Обработки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комплект мебели для гостиной Ольха горная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Покраски'),
    0.3);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стенка для гостиной Вишня темная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Покраски'),
    0.4);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Прихожая-комплект Дуб темный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Покраски'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать угловой Книжка'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Покраски'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван модульный Телескоп'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Покраски'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать Соло'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Покраски'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Детский диван Выкатной'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Покраски'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с подъемным механизмом с матрасом 1600х2000 Венге'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Покраски'),
    0.4);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с ящиками Ясень белый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Покраски'),
    1.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стеллаж Бук натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Покраски'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф-пенал Береза белый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Покраски'),
    2.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комод 6 ящиков Вишня светлая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Покраски'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комод 4 ящика Вишня светлая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Покраски'),
    0.4);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Тумба под ТВ '),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Покраски'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комплект мебели для гостиной Ольха горная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Проектный'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стенка для гостиной Вишня темная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Проектный'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Прихожая-комплект Дуб темный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Проектный'),
    1.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать Соло'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Проектный'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф-купе 3-х дверный Сосна белая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Проектный'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стеллаж Бук натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Проектный'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Тумба под ТВ '),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Проектный'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комплект мебели для гостиной Ольха горная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стенка для гостиной Вишня темная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Прихожая Венге Винтаж'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Тумба с вешалкой Дуб натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Прихожая-комплект Дуб темный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать угловой Книжка'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван модульный Телескоп'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать Соло'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Детский диван Выкатной'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    0.7);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с подъемным механизмом с матрасом 1600х2000 Венге'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с матрасом 90х2000 Венге'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать универсальная Дуб натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.1);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с ящиками Ясень белый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф-купе 3-х дверный Сосна белая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стеллаж Бук натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф 4 дверный с ящиками Ясень серый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф-пенал Береза белый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комод 6 ящиков Вишня светлая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комод 4 ящика Вишня светлая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Тумба под ТВ '),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Раскроя'),
    0.6);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комплект мебели для гостиной Ольха горная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Расчетный'),
    0.4);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стенка для гостиной Вишня темная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Расчетный'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Прихожая-комплект Дуб темный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Расчетный'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать Соло'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Расчетный'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф-купе 3-х дверный Сосна белая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Расчетный'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стеллаж Бук натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Расчетный'),
    0.7);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Тумба под ТВ '),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Расчетный'),
    0.4);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стенка для гостиной Вишня темная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сборки'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Прихожая Венге Винтаж'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сборки'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Прихожая-комплект Дуб темный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сборки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать угловой Книжка'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сборки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван модульный Телескоп'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сборки'),
    0.3);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать универсальная Дуб натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сборки'),
    0.8);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с ящиками Ясень белый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сборки'),
    0.3);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф-купе 3-х дверный Сосна белая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сборки'),
    1.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стеллаж Бук натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сборки'),
    0.3);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф 4 дверный с ящиками Ясень серый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сборки'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комод 6 ящиков Вишня светлая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сборки'),
    0.3);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Тумба под ТВ '),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сборки'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комплект мебели для гостиной Ольха горная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Столярный'),
    1.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стенка для гостиной Вишня темная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Столярный'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Прихожая-комплект Дуб темный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Столярный'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван модульный Телескоп'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Столярный'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать Соло'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Столярный'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Детский диван Выкатной'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Столярный'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стеллаж Бук натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Столярный'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф 4 дверный с ящиками Ясень серый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Столярный'),
    1.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф-пенал Береза белый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Столярный'),
    3.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комод 6 ящиков Вишня светлая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Столярный'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комод 4 ящика Вишня светлая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Столярный'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комплект мебели для гостиной Ольха горная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сушильный'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стенка для гостиной Вишня темная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сушильный'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Прихожая-комплект Дуб темный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сушильный'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать угловой Книжка'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сушильный'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван модульный Телескоп'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сушильный'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стеллаж Бук натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сушильный'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комод 6 ящиков Вишня светлая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сушильный'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комод 4 ящика Вишня светлая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Сушильный'),
    2.0);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комплект мебели для гостиной Ольха горная'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.3);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Тумба с вешалкой Дуб натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Прихожая-комплект Дуб темный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.2);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать угловой Книжка'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.3);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван модульный Телескоп'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.2);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Диван-кровать Соло'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.3);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Детский диван Выкатной'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с подъемным механизмом с матрасом 1600х2000 Венге'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с матрасом 90х2000 Венге'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать универсальная Дуб натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.3);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Кровать с ящиками Ясень белый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.2);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф-купе 3-х дверный Сосна белая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Стеллаж Бук натуральный'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.2);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф 4 дверный с ящиками Ясень серый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Шкаф-пенал Береза белый'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.5);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комод 6 ящиков Вишня светлая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.2);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Комод 4 ящика Вишня светлая'),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.2);
INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
VALUES (
    (SELECT product_id FROM Products WHERE product_name = 'Тумба под ТВ '),
    (SELECT workshop_id FROM Workshops WHERE workshop_name = 'Упаковки'),
    0.3);
