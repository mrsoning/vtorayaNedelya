# Спецификация модулей системы учета заявок

## Содержание
1. [Общие требования](#общие-требования)
2. [Модуль статистики (StatisticsModule)](#модуль-статистики-statisticsmodule)
3. [Модуль отчетности (ReportsModule)](#модуль-отчетности-reportsmodule)
4. [Модуль управления заявками (RequestModule)](#модуль-управления-заявками-requestmodule)
5. [Модуль аутентификации (AuthModule)](#модуль-аутентификации-authmodule)
6. [Интерфейсы взаимодействия](#интерфейсы-взаимодействия)

---

## Общие требования

### Архитектурные принципы
- **Модульность:** Каждый модуль имеет четко определенные границы и интерфейсы
- **Слабая связанность:** Модули взаимодействуют только через определенные интерфейсы
- **Высокая связность:** Функции внутри модуля тесно связаны по назначению
- **Обработка ошибок:** Все модули должны корректно обрабатывать исключительные ситуации

### Стандарты кодирования
- Использование camelCase для переменных и функций
- Использование PascalCase для классов и модулей
- Обязательная JSDoc документация для всех публичных методов
- Валидация всех входных параметров

---

## Модуль статистики (StatisticsModule)

### Назначение
Модуль отвечает за расчет различных статистических показателей системы управления заявками.

### Структура модуля

```javascript
class StatisticsModule {
    constructor(database) {
        this.db = database;
    }
    
    // Основные методы
    calculateGeneralStatistics(filters)
    calculateEquipmentStatistics(filters)
    calculateStatusStatistics(filters)
    calculateWorkshopStatistics(filters)
    calculateTimeStatistics(filters)
    
    // Вспомогательные методы
    validateFilters(filters)
    normalizePercentages(data)
    applyRoleFilters(query, userRole, userId)
}
```

### Метод: calculateGeneralStatistics

**Назначение:** Расчет общей статистики по заявкам

**Входные данные:**
```javascript
{
    userRole: String,           // Роль пользователя: 'Администратор', 'Менеджер', 'Мастер', 'Клиент'
    userId: Integer,            // ID пользователя для фильтрации
    dateFrom: Date | null,      // Начальная дата периода (опционально)
    dateTo: Date | null,        // Конечная дата периода (опционально)
    equipmentType: Integer | null, // Фильтр по типу оборудования (опционально)
    status: Integer | null      // Фильтр по статусу (опционально)
}
```

**Выходные данные:**
```javascript
{
    success: Boolean,           // Успешность выполнения
    data: {
        totalRequests: Integer,     // Общее количество заявок
        activeRequests: Integer,    // Активные заявки (статусы 1,2,3)
        completedRequests: Integer, // Завершенные заявки (статус 5)
        cancelledRequests: Integer, // Отмененные заявки (статус 6)
        avgCompletionTime: Float,   // Среднее время выполнения в днях
        completionRate: Float,      // Процент завершенных заявок
        timestamp: DateTime         // Время расчета статистики
    },
    error: String | null        // Сообщение об ошибке
}
```

**Алгоритм:**
1. Валидация входных параметров
2. Построение SQL-запроса с учетом фильтров роли
3. Выполнение запросов для каждого показателя
4. Расчет производных показателей (проценты, средние значения)
5. Формирование результата

**Исключительные ситуации:**
- `InvalidRoleError` - некорректная роль пользователя
- `DatabaseConnectionError` - ошибка подключения к БД
- `ValidationError` - ошибка валидации входных данных

### Метод: calculateEquipmentStatistics

**Назначение:** Расчет статистики по типам оборудования

**Входные данные:**
```javascript
{
    userRole: String,
    userId: Integer,
    dateFrom: Date | null,
    dateTo: Date | null,
    sortBy: String,             // 'count' | 'percentage' | 'name'
    sortOrder: String           // 'ASC' | 'DESC'
}
```

**Выходные данные:**
```javascript
{
    success: Boolean,
    data: [
        {
            type_id: Integer,
            type_name: String,
            count: Integer,         // Количество заявок
            percentage: Float,      // Процент от общего числа
            avgCompletionTime: Float, // Среднее время для этого типа
            completionRate: Float   // Процент завершенных для этого типа
        }
    ],
    totalCount: Integer,        // Общее количество заявок
    error: String | null
}
```

### Метод: calculateWorkshopStatistics

**Назначение:** Расчет статистики по мастерским (специалистам)

**Входные данные:**
```javascript
{
    userRole: String,
    userId: Integer,
    dateFrom: Date | null,
    dateTo: Date | null,
    workshopId: Integer | null  // Фильтр по конкретной мастерской
}
```

**Выходные данные:**
```javascript
{
    success: Boolean,
    data: [
        {
            master_id: Integer,
            master_name: String,
            assigned_count: Integer,    // Назначено заявок
            completed_count: Integer,   // Завершено заявок
            in_progress_count: Integer, // В работе
            completion_rate: Float,     // Процент выполнения
            avg_completion_time: Float, // Среднее время выполнения
            quality_rating: Float       // Средняя оценка качества
        }
    ],
    error: String | null
}
```

---

## Модуль отчетности (ReportsModule)

### Назначение
Модуль отвечает за генерацию различных типов отчетов и их экспорт в различные форматы.

### Структура модуля

```javascript
class ReportsModule {
    constructor(statisticsModule, pdfGenerator) {
        this.stats = statisticsModule;
        this.pdf = pdfGenerator;
    }
    
    // Основные методы
    generateGeneralReport(filters)
    generateWorkshopReport(filters)
    generateEquipmentReport(filters)
    generateProductReport(filters)
    exportToPDF(reportData, options)
    
    // Вспомогательные методы
    formatReportData(data, format)
    validateReportAccess(userRole, reportType)
    applyRoleBasedFiltering(data, userRole, userId)
}
```

### Метод: generateGeneralReport

**Назначение:** Генерация общего отчета по системе

**Входные данные:**
```javascript
{
    userRole: String,
    userId: Integer,
    reportPeriod: {
        from: Date,
        to: Date
    },
    includeCharts: Boolean,     // Включать ли графики
    format: String              // 'web' | 'pdf' | 'excel'
}
```

**Выходные данные:**
```javascript
{
    success: Boolean,
    report: {
        title: String,
        generatedAt: DateTime,
        period: {
            from: Date,
            to: Date
        },
        summary: {
            totalRequests: Integer,
            completedRequests: Integer,
            avgCompletionTime: Float,
            completionRate: Float
        },
        equipmentBreakdown: Array,  // Статистика по типам оборудования
        statusBreakdown: Array,     // Статистика по статусам
        workshopPerformance: Array, // Производительность мастерских
        charts: Array | null        // Данные для графиков (если включены)
    },
    error: String | null
}
```

### Метод: exportToPDF

**Назначение:** Экспорт отчета в PDF формат

**Входные данные:**
```javascript
{
    reportData: Object,         // Данные отчета
    options: {
        title: String,
        includeHeader: Boolean,
        includeFooter: Boolean,
        pageSize: String,       // 'A4' | 'A3' | 'Letter'
        orientation: String,    // 'portrait' | 'landscape'
        watermark: String | null
    }
}
```

**Выходные данные:**
```javascript
{
    success: Boolean,
    pdfBuffer: Buffer | null,   // PDF данные в виде буфера
    filename: String,           // Предлагаемое имя файла
    size: Integer,              // Размер файла в байтах
    error: String | null
}
```

---

## Модуль управления заявками (RequestModule)

### Назначение
Модуль отвечает за создание, обновление и управление жизненным циклом заявок на ремонт.

### Структура модуля

```javascript
class RequestModule {
    constructor(database, notificationService) {
        this.db = database;
        this.notifications = notificationService;
    }
    
    // Основные методы
    createRequest(requestData)
    updateRequestStatus(requestId, newStatus, userId)
    assignMaster(requestId, masterId, assignedBy)
    addComment(requestId, userId, message)
    getRequestDetails(requestId, userId, userRole)
    
    // Вспомогательные методы
    generateRequestNumber()
    validateRequestData(data)
    checkPermissions(userId, userRole, action, requestId)
    logStatusChange(requestId, oldStatus, newStatus, changedBy)
}
```

### Метод: createRequest

**Назначение:** Создание новой заявки на ремонт

**Входные данные:**
```javascript
{
    clientId: Integer,
    equipmentType: Integer,     // ID типа оборудования
    equipmentModel: Integer,    // ID модели оборудования
    problemDescription: String, // Описание проблемы (мин. 10 символов)
    priorityLevel: Integer,     // 1-5 (1 - низкий, 5 - критический)
    contactPhone: String | null, // Дополнительный телефон
    preferredDate: Date | null,  // Предпочтительная дата ремонта
    address: String | null       // Адрес для выездного ремонта
}
```

**Выходные данные:**
```javascript
{
    success: Boolean,
    request: {
        request_id: Integer,
        request_number: String,     // Формат: REQ-XXXXXX
        status: String,             // "Новая заявка"
        created_at: DateTime,
        estimated_date: Date | null
    },
    error: String | null
}
```

**Бизнес-правила:**
1. Номер заявки генерируется автоматически в формате REQ-XXXXXX
2. Начальный статус всегда "Новая заявка"
3. Описание проблемы не может быть пустым
4. Уровень приоритета должен быть от 1 до 5
5. Клиент может создавать заявки только от своего имени

### Метод: updateRequestStatus

**Назначение:** Обновление статуса заявки

**Входные данные:**
```javascript
{
    requestId: Integer,
    newStatusId: Integer,
    userId: Integer,            // Кто изменяет статус
    comment: String | null,     // Комментарий к изменению
    completionDate: Date | null // Дата завершения (для статуса "Завершена")
}
```

**Выходные данные:**
```javascript
{
    success: Boolean,
    statusChange: {
        old_status: String,
        new_status: String,
        changed_at: DateTime,
        changed_by: String
    },
    notifications: [            // Список уведомлений
        {
            recipient_id: Integer,
            message: String,
            type: String        // 'email' | 'sms' | 'push'
        }
    ],
    error: String | null
}
```

**Бизнес-правила:**
1. Клиент может изменять статус только своих заявок и только на "Отменена"
2. Мастер может изменять статус назначенных ему заявок
3. Менеджер и администратор могут изменять любые статусы
4. При изменении на "Завершена" обязательно указание даты завершения
5. Все изменения статуса логируются в историю

---

## Модуль аутентификации (AuthModule)

### Назначение
Модуль отвечает за аутентификацию пользователей и управление сессиями.

### Структура модуля

```javascript
class AuthModule {
    constructor(database, sessionManager) {
        this.db = database;
        this.sessions = sessionManager;
    }
    
    // Основные методы
    authenticate(login, password)
    createSession(user)
    validateSession(sessionId)
    logout(sessionId)
    checkPermissions(userId, userRole, resource, action)
    
    // Вспомогательные методы
    hashPassword(password)
    verifyPassword(password, hash)
    generateSessionId()
    logAuthAttempt(login, success, ip)
}
```

### Метод: authenticate

**Назначение:** Аутентификация пользователя по логину и паролю

**Входные данные:**
```javascript
{
    login: String,              // Логин пользователя
    password: String,           // Пароль в открытом виде
    rememberMe: Boolean,        // Запомнить пользователя
    clientIP: String,           // IP адрес клиента
    userAgent: String           // User-Agent браузера
}
```

**Выходные данные:**
```javascript
{
    success: Boolean,
    user: {
        user_id: Integer,
        full_name: String,
        user_type: String,      // Роль пользователя
        phone: String,
        last_login: DateTime,
        permissions: Array      // Список разрешений
    } | null,
    session: {
        session_id: String,
        expires_at: DateTime
    } | null,
    error: {
        code: String,           // 'INVALID_CREDENTIALS' | 'ACCOUNT_DISABLED' | 'TOO_MANY_ATTEMPTS'
        message: String,
        retry_after: Integer | null // Секунды до следующей попытки
    } | null
}
```

**Бизнес-правила:**
1. Максимум 5 неудачных попыток входа за 15 минут
2. После превышения лимита - блокировка на 30 минут
3. Пароли хранятся в виде bcrypt хешей
4. Сессии имеют время жизни 24 часа (или 30 дней при "Запомнить меня")
5. Все попытки входа логируются

### Метод: checkPermissions

**Назначение:** Проверка прав доступа пользователя к ресурсу

**Входные данные:**
```javascript
{
    userId: Integer,
    userRole: String,
    resource: String,           // 'requests' | 'reports' | 'users' | 'settings'
    action: String,             // 'create' | 'read' | 'update' | 'delete'
    resourceId: Integer | null  // ID конкретного ресурса (опционально)
}
```

**Выходные данные:**
```javascript
{
    allowed: Boolean,
    reason: String | null,      // Причина отказа (если allowed = false)
    conditions: Array | null    // Дополнительные условия доступа
}
```

---

## Интерфейсы взаимодействия

### API Endpoints

#### GET /api/statistics/general
**Описание:** Получение общей статистики  
**Параметры:** filters (query parameters)  
**Ответ:** Результат StatisticsModule.calculateGeneralStatistics()

#### GET /api/statistics/equipment
**Описание:** Получение статистики по оборудованию  
**Параметры:** filters (query parameters)  
**Ответ:** Результат StatisticsModule.calculateEquipmentStatistics()

#### POST /api/reports/generate
**Описание:** Генерация отчета  
**Тело запроса:** Параметры отчета  
**Ответ:** Результат ReportsModule.generateGeneralReport()

#### POST /api/reports/export/pdf
**Описание:** Экспорт отчета в PDF  
**Тело запроса:** Данные отчета и опции  
**Ответ:** PDF файл или ошибка

#### POST /api/requests
**Описание:** Создание новой заявки  
**Тело запроса:** Данные заявки  
**Ответ:** Результат RequestModule.createRequest()

#### PUT /api/requests/:id/status
**Описание:** Обновление статуса заявки  
**Параметры:** id заявки в URL  
**Тело запроса:** Новый статус и комментарий  
**Ответ:** Результат RequestModule.updateRequestStatus()

### Коды ошибок

| Код | Описание | HTTP Status |
|-----|----------|-------------|
| AUTH_001 | Неверные учетные данные | 401 |
| AUTH_002 | Аккаунт заблокирован | 403 |
| AUTH_003 | Сессия истекла | 401 |
| PERM_001 | Недостаточно прав | 403 |
| PERM_002 | Доступ к ресурсу запрещен | 403 |
| VAL_001 | Ошибка валидации данных | 400 |
| VAL_002 | Обязательное поле не заполнено | 400 |
| DB_001 | Ошибка подключения к БД | 500 |
| DB_002 | Ошибка выполнения запроса | 500 |
| REP_001 | Ошибка генерации отчета | 500 |
| REP_002 | Ошибка экспорта в PDF | 500 |

---

*Спецификация составлена в соответствии с требованиями технического задания и стандартами разработки ПО*