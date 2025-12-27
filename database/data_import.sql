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