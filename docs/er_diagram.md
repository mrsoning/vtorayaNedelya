# ER-диаграмма базы данных системы управления заявками на ремонт климатического оборудования

## Описание

Данная ER-диаграмма представляет структуру базы данных в третьей нормальной форме (3НФ) с обеспечением ссылочной целостности. База данных предназначена для управления заявками на ремонт климатического оборудования.

## ER-диаграмма

```mermaid
erDiagram
    users {
        INTEGER user_id PK "Уникальный идентификатор пользователя"
        VARCHAR full_name "Полное имя пользователя"
        VARCHAR phone "Номер телефона"
        VARCHAR login UK "Логин для входа в систему"
        VARCHAR password_hash "Хеш пароля"
        VARCHAR user_type "Тип пользователя (Менеджер, Специалист, Заказчик, Оператор, Менеджер по качеству)"
        BOOLEAN is_active "Активность пользователя"
        DATETIME created_at "Дата создания записи"
    }

    equipment_types {
        INTEGER type_id PK "Уникальный идентификатор типа оборудования"
        VARCHAR type_name UK "Название типа оборудования"
        TEXT description "Описание типа оборудования"
        DATETIME created_at "Дата создания записи"
    }

    equipment_models {
        INTEGER model_id PK "Уникальный идентификатор модели"
        VARCHAR model_name "Название модели оборудования"
        INTEGER type_id FK "Ссылка на тип оборудования"
        VARCHAR manufacturer "Производитель"
        TEXT description "Описание модели"
        DATETIME created_at "Дата создания записи"
    }

    request_statuses {
        INTEGER status_id PK "Уникальный идентификатор статуса"
        VARCHAR status_name UK "Название статуса"
        TEXT status_description "Описание статуса"
        VARCHAR status_color "Цвет для отображения статуса"
    }

    repair_requests {
        INTEGER request_id PK "Уникальный идентификатор заявки"
        VARCHAR request_number UK "Номер заявки"
        DATE start_date "Дата начала заявки"
        DATE completion_date "Дата завершения заявки"
        TEXT problem_description "Описание проблемы"
        TEXT repair_parts "Необходимые запчасти"
        INTEGER priority_level "Уровень приоритета (1-5)"
        DATE estimated_completion_date "Планируемая дата завершения"
        DATE actual_completion_date "Фактическая дата завершения"
        INTEGER client_id FK "Ссылка на клиента"
        INTEGER master_id FK "Ссылка на мастера"
        INTEGER status_id FK "Ссылка на статус заявки"
        INTEGER type_id FK "Ссылка на тип оборудования"
        INTEGER model_id FK "Ссылка на модель оборудования"
        DATETIME created_at "Дата создания заявки"
        DATETIME updated_at "Дата последнего обновления"
    }

    request_comments {
        INTEGER comment_id PK "Уникальный идентификатор комментария"
        TEXT message "Текст комментария"
        DATETIME created_at "Дата создания комментария"
        INTEGER request_id FK "Ссылка на заявку"
        INTEGER user_id FK "Ссылка на пользователя"
    }

    quality_ratings {
        INTEGER rating_id PK "Уникальный идентификатор оценки"
        INTEGER request_id FK "Ссылка на заявку"
        VARCHAR rating "Оценка качества (Хорошо, Нормально, Плохо)"
        TEXT comment "Комментарий к оценке"
        DATETIME created_at "Дата создания оценки"
    }

    request_history {
        INTEGER history_id PK "Уникальный идентификатор записи истории"
        INTEGER request_id FK "Ссылка на заявку"
        VARCHAR field_name "Название изменённого поля"
        TEXT old_value "Старое значение"
        TEXT new_value "Новое значение"
        INTEGER changed_by FK "Пользователь, внёсший изменение"
        DATETIME changed_at "Дата и время изменения"
    }

    %% Связи между таблицами
    users ||--o{ repair_requests : "client_id (один клиент - много заявок)"
    users ||--o{ repair_requests : "master_id (один мастер - много заявок)"
    users ||--o{ request_comments : "user_id (один пользователь - много комментариев)"
    users ||--o{ request_history : "changed_by (один пользователь - много изменений)"

    equipment_types ||--o{ equipment_models : "type_id (один тип - много моделей)"
    equipment_types ||--o{ repair_requests : "type_id (один тип - много заявок)"

    equipment_models ||--o{ repair_requests : "model_id (одна модель - много заявок)"

    request_statuses ||--o{ repair_requests : "status_id (один статус - много заявок)"

    repair_requests ||--o{ request_comments : "request_id (одна заявка - много комментариев)"
    repair_requests ||--o{ quality_ratings : "request_id (одна заявка - одна оценка)"
    repair_requests ||--o{ request_history : "request_id (одна заявка - много записей истории)"
```

## Описание сущностей

### 1. users (Пользователи)
**Назначение:** Хранение информации о всех пользователях системы
**Ключевые атрибуты:**
- `user_id` - первичный ключ
- `login` - уникальный логин
- `user_type` - роль пользователя в системе

### 2. equipment_types (Типы оборудования)
**Назначение:** Классификация климатического оборудования по типам
**Ключевые атрибуты:**
- `type_id` - первичный ключ
- `type_name` - уникальное название типа

### 3. equipment_models (Модели оборудования)
**Назначение:** Конкретные модели оборудования каждого типа
**Ключевые атрибуты:**
- `model_id` - первичный ключ
- `type_id` - внешний ключ на equipment_types

### 4. request_statuses (Статусы заявок)
**Назначение:** Определение возможных статусов заявок
**Ключевые атрибуты:**
- `status_id` - первичный ключ
- `status_name` - уникальное название статуса

### 5. repair_requests (Заявки на ремонт)
**Назначение:** Основная сущность - заявки на ремонт оборудования
**Ключевые атрибуты:**
- `request_id` - первичный ключ
- `request_number` - уникальный номер заявки
- Множественные внешние ключи для связи с другими сущностями

### 6. request_comments (Комментарии к заявкам)
**Назначение:** Комментарии пользователей к заявкам
**Ключевые атрибуты:**
- `comment_id` - первичный ключ
- `request_id` - внешний ключ на repair_requests
- `user_id` - внешний ключ на users

### 7. quality_ratings (Оценки качества)
**Назначение:** Оценки качества выполненных работ
**Ключевые атрибуты:**
- `rating_id` - первичный ключ
- `request_id` - внешний ключ на repair_requests

### 8. request_history (История изменений)
**Назначение:** Аудит изменений в заявках
**Ключевые атрибуты:**
- `history_id` - первичный ключ
- `request_id` - внешний ключ на repair_requests
- `changed_by` - внешний ключ на users

## Кардинальности связей

1. **users → repair_requests (client_id)**: 1:M (один клиент может иметь много заявок)
2. **users → repair_requests (master_id)**: 1:M (один мастер может обслуживать много заявок)
3. **equipment_types → equipment_models**: 1:M (один тип может иметь много моделей)
4. **equipment_types → repair_requests**: 1:M (один тип может быть в многих заявках)
5. **equipment_models → repair_requests**: 1:M (одна модель может быть в многих заявках)
6. **request_statuses → repair_requests**: 1:M (один статус может быть у многих заявок)
7. **repair_requests → request_comments**: 1:M (одна заявка может иметь много комментариев)
8. **repair_requests → quality_ratings**: 1:1 (одна заявка имеет одну оценку)
9. **repair_requests → request_history**: 1:M (одна заявка может иметь много записей истории)
10. **users → request_comments**: 1:M (один пользователь может оставить много комментариев)
11. **users → request_history**: 1:M (один пользователь может внести много изменений)

## Ссылочная целостность

Все внешние ключи настроены с соответствующими ограничениями:
- **CASCADE** - для зависимых записей (комментарии, история, оценки удаляются при удалении заявки)
- **SET NULL** - для необязательных связей (мастер может быть не назначен)
- **RESTRICT** - для критически важных связей (нельзя удалить тип оборудования, если есть связанные заявки)

## Соответствие 3НФ

База данных соответствует третьей нормальной форме:
1. **1НФ**: Все атрибуты атомарны, нет повторяющихся групп
2. **2НФ**: Все неключевые атрибуты полностью функционально зависят от первичного ключа
3. **3НФ**: Отсутствуют транзитивные зависимости между неключевыми атрибутами

## Индексы

Созданы индексы для оптимизации часто используемых запросов:
- По внешним ключам для ускорения JOIN операций
- По полям поиска (login, дата создания заявки)
- По полям фильтрации (статус, тип пользователя)