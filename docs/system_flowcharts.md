# Блок-схемы системы учета заявок (ГОСТ 19.701-90)

## Содержание
1. [Основная блок-схема системы](#основная-блок-схема-системы)
2. [Блок-схема расчета статистики](#блок-схема-расчета-статистики)
3. [Блок-схема обработки заявок](#блок-схема-обработки-заявок)
4. [Блок-схема аутентификации](#блок-схема-аутентификации)
5. [Блок-схема генерации отчетов](#блок-схема-генерации-отчетов)

---

## Основная блок-схема системы

### Общий алгоритм работы системы управления заявками

```mermaid
flowchart TD
    Start([Начало работы системы]) --> Init[Инициализация системы]
    Init --> DBConnect{Подключение к БД успешно?}
    
    DBConnect -->|Нет| DBError[Ошибка подключения к БД]
    DBError --> LogError[Записать в лог ошибки]
    LogError --> Retry{Повторить попытку?}
    Retry -->|Да| DBConnect
    Retry -->|Нет| SystemStop([Остановка системы])
    
    DBConnect -->|Да| ServerStart[Запуск веб-сервера]
    ServerStart --> WaitRequest[Ожидание запроса]
    
    WaitRequest --> RequestReceived[Получен запрос]
    RequestReceived --> ParseRequest[Парсинг запроса]
    ParseRequest --> AuthCheck{Требуется аутентификация?}
    
    AuthCheck -->|Нет| ProcessPublic[Обработка публичного запроса]
    AuthCheck -->|Да| ValidateSession{Сессия валидна?}
    
    ValidateSession -->|Нет| ShowLogin[Показать форму входа]
    ShowLogin --> WaitRequest
    
    ValidateSession -->|Да| CheckPermissions{Права доступа есть?}
    CheckPermissions -->|Нет| AccessDenied[Доступ запрещен]
    AccessDenied --> SendResponse[Отправить ответ]
    
    CheckPermissions -->|Да| RouteRequest{Тип запроса?}
    
    RouteRequest -->|Создание заявки| CreateRequest[Создать заявку]
    RouteRequest -->|Просмотр заявок| ViewRequests[Показать заявки]
    RouteRequest -->|Обновление статуса| UpdateStatus[Обновить статус]
    RouteRequest -->|Генерация отчета| GenerateReport[Сгенерировать отчет]
    RouteRequest -->|Экспорт PDF| ExportPDF[Экспортировать в PDF]
    
    CreateRequest --> ValidateData{Данные корректны?}
    ValidateData -->|Нет| ValidationError[Ошибка валидации]
    ValidateData -->|Да| SaveRequest[Сохранить заявку]
    SaveRequest --> NotifyUsers[Уведомить пользователей]
    
    ViewRequests --> ApplyFilters[Применить фильтры по роли]
    ApplyFilters --> FetchData[Получить данные из БД]
    FetchData --> FormatData[Форматировать данные]
    
    UpdateStatus --> CheckStatusPermissions{Права на изменение?}
    CheckStatusPermissions -->|Нет| PermissionError[Ошибка прав]
    CheckStatusPermissions -->|Да| UpdateDB[Обновить БД]
    UpdateDB --> LogChange[Записать в историю]
    LogChange --> CheckCompleted{Статус "Завершена"?}
    CheckCompleted -->|Да| GenerateQR[Сгенерировать QR-код]
    CheckCompleted -->|Нет| NotifyChange[Уведомить об изменении]
    
    GenerateReport --> CalculateStats[Рассчитать статистику]
    CalculateStats --> FormatReport[Форматировать отчет]
    
    ExportPDF --> PrepareData[Подготовить данные]
    PrepareData --> CreatePDF[Создать PDF документ]
    CreatePDF --> SendFile[Отправить файл]
    
    ProcessPublic --> SendResponse
    ValidationError --> SendResponse
    NotifyUsers --> SendResponse
    FormatData --> SendResponse
    PermissionError --> SendResponse
    GenerateQR --> SendResponse
    NotifyChange --> SendResponse
    FormatReport --> SendResponse
    SendFile --> SendResponse
    
    SendResponse --> WaitRequest
```

---

## Блок-схема расчета статистики

### Алгоритм расчета статистических показателей

```mermaid
flowchart TD
    StartStats([Начало расчета статистики]) --> GetParams[Получить параметры запроса]
    GetParams --> ValidateParams{Параметры корректны?}
    
    ValidateParams -->|Нет| ParamError[Ошибка параметров]
    ValidateParams -->|Да| GetUserRole[Определить роль пользователя]
    
    GetUserRole --> BuildFilters[Построить фильтры по роли]
    BuildFilters --> ConnectDB[Подключиться к БД]
    
    ConnectDB --> CalcTotal[Рассчитать общее количество заявок]
    CalcTotal --> CalcActive[Рассчитать активные заявки]
    CalcActive --> CalcCompleted[Рассчитать завершенные заявки]
    CalcCompleted --> CalcAvgTime[Рассчитать среднее время]
    
    CalcAvgTime --> GetEquipmentStats[Получить статистику по оборудованию]
    GetEquipmentStats --> CalcEquipmentPercent[Рассчитать проценты для оборудования]
    
    CalcEquipmentPercent --> CheckEquipmentSum{Сумма процентов = 100%?}
    CheckEquipmentSum -->|Нет| NormalizeEquipment[Нормализовать проценты оборудования]
    CheckEquipmentSum -->|Да| GetStatusStats[Получить статистику по статусам]
    NormalizeEquipment --> GetStatusStats
    
    GetStatusStats --> CalcStatusPercent[Рассчитать проценты для статусов]
    CalcStatusPercent --> CheckStatusSum{Сумма процентов = 100%?}
    CheckStatusSum -->|Нет| NormalizeStatus[Нормализовать проценты статусов]
    CheckStatusSum -->|Да| GetWorkshopStats[Получить статистику по мастерским]
    NormalizeStatus --> GetWorkshopStats
    
    GetWorkshopStats --> CalcWorkshopMetrics[Рассчитать метрики мастерских]
    CalcWorkshopMetrics --> FormatResult[Форматировать результат]
    
    FormatResult --> ValidateResult{Результат корректен?}
    ValidateResult -->|Нет| ResultError[Ошибка в результате]
    ValidateResult -->|Да| ReturnResult[Вернуть результат]
    
    ParamError --> EndError([Конец с ошибкой])
    ResultError --> EndError
    ReturnResult --> EndSuccess([Конец успешно])
```

---

## Блок-схема обработки заявок

### Алгоритм создания и обработки заявок на ремонт

```mermaid
flowchart TD
    StartRequest([Начало обработки заявки]) --> GetRequestType{Тип операции?}
    
    GetRequestType -->|Создание| ValidateCreateData[Валидация данных создания]
    GetRequestType -->|Обновление| ValidateUpdateData[Валидация данных обновления]
    GetRequestType -->|Просмотр| ValidateViewData[Валидация прав просмотра]
    GetRequestType -->|Удаление| ValidateDeleteData[Валидация прав удаления]
    
    ValidateCreateData --> CheckCreatePermissions{Права на создание?}
    CheckCreatePermissions -->|Нет| CreatePermError[Ошибка прав создания]
    CheckCreatePermissions -->|Да| GenerateNumber[Сгенерировать номер заявки]
    
    GenerateNumber --> CheckDuplicate{Номер уникален?}
    CheckDuplicate -->|Нет| GenerateNumber
    CheckDuplicate -->|Да| SetInitialStatus[Установить статус "Новая"]
    
    SetInitialStatus --> SaveToDB[Сохранить в БД]
    SaveToDB --> CreateSuccess{Сохранение успешно?}
    CreateSuccess -->|Нет| SaveError[Ошибка сохранения]
    CreateSuccess -->|Да| NotifyOperators[Уведомить операторов]
    NotifyOperators --> LogCreation[Записать в лог создания]
    
    ValidateUpdateData --> CheckUpdatePermissions{Права на обновление?}
    CheckUpdatePermissions -->|Нет| UpdatePermError[Ошибка прав обновления]
    CheckUpdatePermissions -->|Да| CheckRequestExists{Заявка существует?}
    
    CheckRequestExists -->|Нет| NotFoundError[Заявка не найдена]
    CheckRequestExists -->|Да| CheckOwnership{Владелец заявки?}
    
    CheckOwnership -->|Нет| OwnershipError[Ошибка владения]
    CheckOwnership -->|Да| ValidateStatusTransition{Переход статуса валиден?}
    
    ValidateStatusTransition -->|Нет| TransitionError[Недопустимый переход]
    ValidateStatusTransition -->|Да| UpdateRequest[Обновить заявку]
    
    UpdateRequest --> LogStatusChange[Записать изменение статуса]
    LogStatusChange --> CheckIfCompleted{Статус "Завершена"?}
    CheckIfCompleted -->|Да| GenerateQRCode[Сгенерировать QR-код]
    CheckIfCompleted -->|Нет| NotifyParticipants[Уведомить участников]
    
    GenerateQRCode --> QRSuccess{QR-код создан?}
    QRSuccess -->|Нет| QRError[Ошибка создания QR]
    QRSuccess -->|Да| NotifyCompletion[Уведомить о завершении]
    
    ValidateViewData --> CheckViewPermissions{Права на просмотр?}
    CheckViewPermissions -->|Нет| ViewPermError[Ошибка прав просмотра]
    CheckViewPermissions -->|Да| ApplyViewFilters[Применить фильтры просмотра]
    
    ApplyViewFilters --> FetchRequestData[Получить данные заявки]
    FetchRequestData --> FormatRequestData[Форматировать данные]
    
    ValidateDeleteData --> CheckDeletePermissions{Права на удаление?}
    CheckDeletePermissions -->|Нет| DeletePermError[Ошибка прав удаления]
    CheckDeletePermissions -->|Да| CheckDeleteConditions{Условия удаления выполнены?}
    
    CheckDeleteConditions -->|Нет| DeleteConditionError[Условия не выполнены]
    CheckDeleteConditions -->|Да| SoftDelete[Мягкое удаление заявки]
    SoftDelete --> LogDeletion[Записать удаление в лог]
    
    CreatePermError --> EndError([Конец с ошибкой])
    SaveError --> EndError
    UpdatePermError --> EndError
    NotFoundError --> EndError
    OwnershipError --> EndError
    TransitionError --> EndError
    QRError --> EndError
    ViewPermError --> EndError
    DeletePermError --> EndError
    DeleteConditionError --> EndError
    
    LogCreation --> EndSuccess([Конец успешно])
    NotifyParticipants --> EndSuccess
    NotifyCompletion --> EndSuccess
    FormatRequestData --> EndSuccess
    LogDeletion --> EndSuccess
```

---

## Блок-схема аутентификации

### Алгоритм аутентификации и авторизации пользователей

```mermaid
flowchart TD
    StartAuth([Начало аутентификации]) --> GetCredentials[Получить логин и пароль]
    GetCredentials --> ValidateInput{Входные данные корректны?}
    
    ValidateInput -->|Нет| InputError[Ошибка входных данных]
    ValidateInput -->|Да| CheckAttempts[Проверить количество попыток]
    
    CheckAttempts --> AttemptsOK{Попытки не превышены?}
    AttemptsOK -->|Нет| TooManyAttempts[Слишком много попыток]
    AttemptsOK -->|Да| FindUser[Найти пользователя в БД]
    
    FindUser --> UserExists{Пользователь найден?}
    UserExists -->|Нет| UserNotFound[Пользователь не найден]
    UserExists -->|Да| CheckActive{Пользователь активен?}
    
    CheckActive -->|Нет| UserInactive[Пользователь неактивен]
    CheckActive -->|Да| VerifyPassword[Проверить пароль]
    
    VerifyPassword --> PasswordCorrect{Пароль верен?}
    PasswordCorrect -->|Нет| WrongPassword[Неверный пароль]
    PasswordCorrect -->|Да| CreateSession[Создать сессию]
    
    CreateSession --> SessionCreated{Сессия создана?}
    SessionCreated -->|Нет| SessionError[Ошибка создания сессии]
    SessionCreated -->|Да| UpdateLastLogin[Обновить время последнего входа]
    
    UpdateLastLogin --> LogSuccessfulLogin[Записать успешный вход]
    LogSuccessfulLogin --> LoadPermissions[Загрузить права пользователя]
    LoadPermissions --> SetSessionData[Установить данные сессии]
    
    UserNotFound --> IncrementAttempts[Увеличить счетчик попыток]
    WrongPassword --> IncrementAttempts
    IncrementAttempts --> LogFailedAttempt[Записать неудачную попытку]
    
    InputError --> EndAuthError([Конец с ошибкой])
    TooManyAttempts --> EndAuthError
    UserInactive --> EndAuthError
    SessionError --> EndAuthError
    LogFailedAttempt --> EndAuthError
    
    SetSessionData --> EndAuthSuccess([Конец успешно])
```

---

## Блок-схема генерации отчетов

### Алгоритм создания и экспорта отчетов

```mermaid
flowchart TD
    StartReport([Начало генерации отчета]) --> GetReportParams[Получить параметры отчета]
    GetReportParams --> ValidateReportParams{Параметры корректны?}
    
    ValidateReportParams -->|Нет| ReportParamError[Ошибка параметров отчета]
    ValidateReportParams -->|Да| CheckReportAccess{Доступ к отчету разрешен?}
    
    CheckReportAccess -->|Нет| ReportAccessError[Нет доступа к отчету]
    CheckReportAccess -->|Да| DetermineReportType{Тип отчета?}
    
    DetermineReportType -->|Общий| GenerateGeneralReport[Сгенерировать общий отчет]
    DetermineReportType -->|По мастерским| GenerateWorkshopReport[Сгенерировать отчет по мастерским]
    DetermineReportType -->|По оборудованию| GenerateEquipmentReport[Сгенерировать отчет по оборудованию]
    DetermineReportType -->|По продукции| GenerateProductReport[Сгенерировать отчет по продукции]
    
    GenerateGeneralReport --> CollectGeneralData[Собрать общие данные]
    CollectGeneralData --> CalculateGeneralStats[Рассчитать общую статистику]
    
    GenerateWorkshopReport --> CollectWorkshopData[Собрать данные по мастерским]
    CollectWorkshopData --> CalculateWorkshopStats[Рассчитать статистику мастерских]
    
    GenerateEquipmentReport --> CollectEquipmentData[Собрать данные по оборудованию]
    CollectEquipmentData --> CalculateEquipmentStats[Рассчитать статистику оборудования]
    
    GenerateProductReport --> CollectProductData[Собрать данные по продукции]
    CollectProductData --> CalculateProductStats[Рассчитать статистику продукции]
    
    CalculateGeneralStats --> FormatGeneralReport[Форматировать общий отчет]
    CalculateWorkshopStats --> FormatWorkshopReport[Форматировать отчет мастерских]
    CalculateEquipmentStats --> FormatEquipmentReport[Форматировать отчет оборудования]
    CalculateProductStats --> FormatProductReport[Форматировать отчет продукции]
    
    FormatGeneralReport --> CheckExportFormat{Формат экспорта?}
    FormatWorkshopReport --> CheckExportFormat
    FormatEquipmentReport --> CheckExportFormat
    FormatProductReport --> CheckExportFormat
    
    CheckExportFormat -->|Web| PrepareWebView[Подготовить веб-представление]
    CheckExportFormat -->|PDF| PreparePDFExport[Подготовить экспорт в PDF]
    CheckExportFormat -->|Excel| PrepareExcelExport[Подготовить экспорт в Excel]
    
    PrepareWebView --> AddWebFormatting[Добавить веб-форматирование]
    AddWebFormatting --> ReturnWebReport[Вернуть веб-отчет]
    
    PreparePDFExport --> CreatePDFDocument[Создать PDF документ]
    CreatePDFDocument --> AddPDFHeader[Добавить заголовок PDF]
    AddPDFHeader --> AddPDFContent[Добавить содержимое PDF]
    AddPDFContent --> AddPDFFooter[Добавить подвал PDF]
    AddPDFFooter --> FinalizePDF[Финализировать PDF]
    FinalizePDF --> ReturnPDFFile[Вернуть PDF файл]
    
    PrepareExcelExport --> CreateExcelWorkbook[Создать Excel книгу]
    CreateExcelWorkbook --> AddExcelSheets[Добавить листы Excel]
    AddExcelSheets --> FormatExcelData[Форматировать данные Excel]
    FormatExcelData --> ReturnExcelFile[Вернуть Excel файл]
    
    ReportParamError --> EndReportError([Конец с ошибкой])
    ReportAccessError --> EndReportError
    
    ReturnWebReport --> EndReportSuccess([Конец успешно])
    ReturnPDFFile --> EndReportSuccess
    ReturnExcelFile --> EndReportSuccess
```

---

## Условные обозначения (ГОСТ 19.701-90)

| Символ | Описание |
|--------|----------|
| ![Начало/Конец](https://via.placeholder.com/60x30/4CAF50/FFFFFF?text=Oval) | Начало или конец алгоритма |
| ![Процесс](https://via.placeholder.com/80x40/2196F3/FFFFFF?text=Rect) | Процесс (выполнение операции) |
| ![Решение](https://via.placeholder.com/60x60/FF9800/FFFFFF?text=Diamond) | Решение (условие, проверка) |
| ![Данные](https://via.placeholder.com/80x40/9C27B0/FFFFFF?text=Para) | Ввод/вывод данных |
| ![Документ](https://via.placeholder.com/80x40/795548/FFFFFF?text=Doc) | Документ или отчет |
| ![База данных](https://via.placeholder.com/60x40/607D8B/FFFFFF?text=DB) | База данных |
| ![Соединитель](https://via.placeholder.com/30x30/FFC107/000000?text=O) | Соединитель |

---

*Блок-схемы составлены в соответствии с ГОСТ 19.701-90 "Схемы алгоритмов, программ, данных и систем"*