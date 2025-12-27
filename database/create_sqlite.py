#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Создание SQLite базы данных
"""
import sqlite3
from pathlib import Path

def create_database():
    """Создать SQLite базу данных"""
    
    # Путь к БД
    db_path = Path(__file__).parent / 'furniture_company.db'
    
    # Удалить старую БД если есть
    if db_path.exists():
        db_path.unlink()
    
    # Подключение
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    print("Создание таблиц...")
    
    # Material_types
    cursor.execute("""
        CREATE TABLE Material_types (
            material_type_id INTEGER PRIMARY KEY AUTOINCREMENT,
            material_type_name TEXT NOT NULL UNIQUE,
            waste_percentage REAL,
            description TEXT,
            is_ecological INTEGER DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    # Product_types
    cursor.execute("""
        CREATE TABLE Product_types (
            product_type_id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_type_name TEXT NOT NULL UNIQUE,
            type_coefficient REAL,
            style TEXT,
            description TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    # Workshops
    cursor.execute("""
        CREATE TABLE Workshops (
            workshop_id INTEGER PRIMARY KEY AUTOINCREMENT,
            workshop_name TEXT NOT NULL UNIQUE,
            workshop_type TEXT,
            staff_count INTEGER,
            location TEXT,
            equipment_description TEXT,
            is_active INTEGER DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    # Products
    cursor.execute("""
        CREATE TABLE Products (
            product_id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_name TEXT NOT NULL,
            article_number TEXT UNIQUE,
            product_type_id INTEGER NOT NULL,
            material_type_id INTEGER NOT NULL,
            min_partner_price REAL,
            dimensions TEXT,
            weight REAL,
            description TEXT,
            is_available INTEGER DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (product_type_id) REFERENCES Product_types(product_type_id),
            FOREIGN KEY (material_type_id) REFERENCES Material_types(material_type_id)
        )
    """)
    
    # Product_workshops
    cursor.execute("""
        CREATE TABLE Product_workshops (
            product_workshop_id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            workshop_id INTEGER NOT NULL,
            production_time_hours REAL,
            priority INTEGER DEFAULT 1,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (product_id) REFERENCES Products(product_id),
            FOREIGN KEY (workshop_id) REFERENCES Workshops(workshop_id),
            UNIQUE (product_id, workshop_id)
        )
    """)
    
    print("✓ Таблицы созданы")
    
    # Импорт данных
    print("\nИмпорт данных...")
    import_data(cursor)
    
    conn.commit()
    conn.close()
    
    print(f"\n✓ База данных создана: {db_path}")
    print(f"  Размер: {db_path.stat().st_size / 1024:.1f} KB")
    
    return db_path

def import_data(cursor):
    """Импорт данных из CSV"""
    import pandas as pd
    from pathlib import Path
    
    data_dir = Path(__file__).parent.parent / 'data'
    
    # Material_types
    df = pd.read_csv(data_dir / 'Material_type_import.csv', encoding='utf-8-sig')
    for _, row in df.iterrows():
        cursor.execute(
            "INSERT INTO Material_types (material_type_name, waste_percentage) VALUES (?, ?)",
            (row['Тип материала'], row['Процент потерь сырья'])
        )
    print(f"  ✓ Material_types: {len(df)} записей")
    
    # Product_types
    df = pd.read_csv(data_dir / 'Product_type_import.csv', encoding='utf-8-sig')
    for _, row in df.iterrows():
        cursor.execute(
            "INSERT INTO Product_types (product_type_name, type_coefficient) VALUES (?, ?)",
            (row['Тип продукции'], row['Коэффициент типа продукции'])
        )
    print(f"  ✓ Product_types: {len(df)} записей")
    
    # Workshops
    df = pd.read_csv(data_dir / 'Workshops_import.csv', encoding='utf-8-sig')
    for _, row in df.iterrows():
        cursor.execute(
            "INSERT INTO Workshops (workshop_name, workshop_type, staff_count) VALUES (?, ?, ?)",
            (row['Название цеха'], row['Тип цеха'], row['Количество человек для производства '])
        )
    print(f"  ✓ Workshops: {len(df)} записей")
    
    # Products
    df = pd.read_csv(data_dir / 'Products_import.csv', encoding='utf-8-sig')
    for _, row in df.iterrows():
        cursor.execute("""
            INSERT INTO Products (product_name, article_number, product_type_id, material_type_id, min_partner_price)
            VALUES (?, ?, 
                (SELECT product_type_id FROM Product_types WHERE product_type_name = ?),
                (SELECT material_type_id FROM Material_types WHERE material_type_name = ?),
                ?)
        """, (row['Наименование продукции'], str(row['Артикул']), 
              row['Тип продукции'], row['Основной материал'], 
              row['Минимальная стоимость для партнера']))
    print(f"  ✓ Products: {len(df)} записей")
    
    # Product_workshops
    df = pd.read_csv(data_dir / 'Product_workshops_import.csv', encoding='utf-8-sig')
    for _, row in df.iterrows():
        cursor.execute("""
            INSERT INTO Product_workshops (product_id, workshop_id, production_time_hours)
            VALUES (
                (SELECT product_id FROM Products WHERE product_name = ?),
                (SELECT workshop_id FROM Workshops WHERE workshop_name = ?),
                ?)
        """, (row['Наименование продукции'], row['Название цеха'], 
              row['Время изготовления, ч']))
    print(f"  ✓ Product_workshops: {len(df)} записей")

if __name__ == "__main__":
    create_database()
