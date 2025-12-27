-- =============================================
-- База данных для системы учета заявок на ремонт климатического оборудования
-- =============================================

-- Удаление существующих таблиц (если есть)
DROP TABLE IF EXISTS request_comments;
DROP TABLE IF EXISTS request_history;
DROP TABLE IF EXISTS quality_ratings;
DROP TABLE IF EXISTS repair_requests;
DROP TABLE IF EXISTS equipment_models;
DROP TABLE IF EXISTS equipment_types;
DROP TABLE IF EXISTS request_statuses;
DROP TABLE IF EXISTS users;

-- =============================================
-- Таблица: users (Пользователи системы)
-- =============================================
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    login VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    user_type VARCHAR(30) NOT NULL,
    is_active BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Таблица: equipment_types (Типы климатического оборудования)
-- =============================================
CREATE TABLE equipment_types (
    type_id INTEGER PRIMARY KEY AUTOINCREMENT,
    type_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================
-- Таблица: equipment_models (Модели оборудования)
-- =============================================
CREATE TABLE equipment_models (
    model_id INTEGER PRIMARY KEY AUTOINCREMENT,
    model_name VARCHAR(100) NOT NULL,
    type_id INTEGER NOT NULL,
    manufacturer VARCHAR(100),
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (type_id) REFERENCES equipment_types(type_id) ON DELETE CASCADE
);

-- =============================================
-- Таблица: request_statuses (Статусы заявок)
-- =============================================
CREATE TABLE request_statuses (
    status_id INTEGER PRIMARY KEY AUTOINCREMENT,
    status_name VARCHAR(50) NOT NULL UNIQUE,
    status_description TEXT,
    status_color VARCHAR(7) DEFAULT '#007bff'
);

-- =============================================
-- Таблица: repair_requests (Заявки на ремонт)
-- =============================================
CREATE TABLE repair_requests (
    request_id INTEGER PRIMARY KEY AUTOINCREMENT,
    request_number VARCHAR(20) UNIQUE NOT NULL,
    start_date DATE NOT NULL,
    completion_date DATE,
    problem_description TEXT NOT NULL,
    repair_parts TEXT,
    priority_level INTEGER DEFAULT 1 CHECK (priority_level BETWEEN 1 AND 5),
    estimated_completion_date DATE,
    actual_completion_date DATE,
    
    -- Внешние ключи
    client_id INTEGER NOT NULL,
    master_id INTEGER,
    status_id INTEGER NOT NULL DEFAULT 1,
    type_id INTEGER NOT NULL,
    model_id INTEGER NOT NULL,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (client_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (master_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (status_id) REFERENCES request_statuses(status_id),
    FOREIGN KEY (type_id) REFERENCES equipment_types(type_id),
    FOREIGN KEY (model_id) REFERENCES equipment_models(model_id)
);

-- =============================================
-- Таблица: request_comments (Комментарии к заявкам)
-- =============================================
CREATE TABLE request_comments (
    comment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    message TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    -- Внешние ключи
    request_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    
    FOREIGN KEY (request_id) REFERENCES repair_requests(request_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- =============================================
-- Таблица: quality_ratings (Оценки качества работ)
-- =============================================
CREATE TABLE quality_ratings (
    rating_id INTEGER PRIMARY KEY AUTOINCREMENT,
    request_id INTEGER NOT NULL,
    rating VARCHAR(20) NOT NULL CHECK (rating IN ('Хорошо', 'Нормально', 'Плохо')),
    comment TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (request_id) REFERENCES repair_requests(request_id) ON DELETE CASCADE
);

-- =============================================
-- Таблица: request_history (История изменений заявок)
-- =============================================
CREATE TABLE request_history (
    history_id INTEGER PRIMARY KEY AUTOINCREMENT,
    request_id INTEGER NOT NULL,
    field_name VARCHAR(50) NOT NULL,
    old_value TEXT,
    new_value TEXT,
    changed_by INTEGER NOT NULL,
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (request_id) REFERENCES repair_requests(request_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(user_id)
);

-- =============================================
-- Таблица: quality_ratings (Оценки качества работ)
-- =============================================
CREATE TABLE quality_ratings (
    rating_id INTEGER PRIMARY KEY AUTOINCREMENT,
    request_id INTEGER NOT NULL,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    feedback TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (request_id) REFERENCES repair_requests(request_id) ON DELETE CASCADE
);

-- =============================================
-- Индексы для оптимизации запросов
-- =============================================
CREATE INDEX idx_requests_client ON repair_requests(client_id);
CREATE INDEX idx_requests_master ON repair_requests(master_id);
CREATE INDEX idx_requests_status ON repair_requests(status_id);
CREATE INDEX idx_requests_date ON repair_requests(start_date);
CREATE INDEX idx_comments_request ON request_comments(request_id);
CREATE INDEX idx_history_request ON request_history(request_id);
CREATE INDEX idx_users_login ON users(login);
CREATE INDEX idx_users_type ON users(user_type);

-- =============================================
-- Представления для удобства работы
-- =============================================

-- Представление: Полная информация о заявках
CREATE VIEW v_requests_full AS
SELECT 
    r.request_id,
    r.request_number,
    r.start_date,
    r.completion_date,
    r.problem_description,
    r.repair_parts,
    r.priority_level,
    
    -- Информация о клиенте
    c.full_name as client_name,
    c.phone as client_phone,
    
    -- Информация о специалисте
    m.full_name as master_name,
    m.phone as master_phone,
    
    -- Информация об оборудовании
    et.type_name as equipment_type,
    em.model_name as equipment_model,
    
    -- Статус заявки
    rs.status_name,
    rs.status_description,
    rs.status_color,
    
    r.created_at,
    r.updated_at
FROM repair_requests r
INNER JOIN users c ON r.client_id = c.user_id
LEFT JOIN users m ON r.master_id = m.user_id
INNER JOIN equipment_types et ON r.type_id = et.type_id
INNER JOIN equipment_models em ON r.model_id = em.model_id
INNER JOIN request_statuses rs ON r.status_id = rs.status_id;

-- Представление: Статистика по специалистам
CREATE VIEW v_master_stats AS
SELECT 
    m.user_id,
    m.full_name as master_name,
    COUNT(r.request_id) as total_requests,
    COUNT(CASE WHEN r.status_id = 5 THEN 1 END) as completed_requests,
    COUNT(CASE WHEN r.status_id IN (2, 3) THEN 1 END) as active_requests,
    AVG(CASE 
        WHEN r.completion_date IS NOT NULL AND r.start_date IS NOT NULL 
        THEN julianday(r.completion_date) - julianday(r.start_date)
    END) as avg_completion_days
FROM users m
LEFT JOIN repair_requests r ON m.user_id = r.master_id
WHERE m.user_type = 'Специалист'
GROUP BY m.user_id, m.full_name;

-- =============================================
-- Вставка базовых данных
-- =============================================

-- Типы оборудования
INSERT INTO equipment_types (type_name, description) VALUES 
('Кондиционер', 'Системы кондиционирования воздуха'),
('Увлажнитель воздуха', 'Устройства для увлажнения воздуха'),
('Сушилка для рук', 'Электрические сушилки для рук'),
('Вентиляционная система', 'Системы вентиляции и воздухообмена'),
('Отопительная система', 'Системы отопления и обогрева');

-- Статусы заявок
INSERT INTO request_statuses (status_name, status_description, status_color) VALUES 
('Новая заявка', 'Заявка создана, ожидает обработки', '#17a2b8'),
('В процессе ремонта', 'Заявка принята в работу специалистом', '#ffc107'),
('Ожидание комплектующих', 'Ремонт приостановлен в ожидании запчастей', '#6c757d'),
('Готова к выдаче', 'Ремонт завершен, оборудование готово к выдаче', '#007bff'),
('Завершена', 'Заявка полностью выполнена', '#28a745'),
('Отменена', 'Заявка отменена по запросу клиента', '#dc3545');