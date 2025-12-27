# Design Document - Reporting System

## Overview

Система отчетности предоставляет комплексную аналитику и документацию для приложения управления заявками на ремонт климатического оборудования. Система включает веб-интерфейс для просмотра отчетов, экспорт в PDF, роль-ориентированный доступ и генерацию технической документации.

## Architecture

Система построена на основе MVC архитектуры с использованием Node.js, Express.js и SQLite:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Presentation  │    │    Business     │    │      Data       │
│     Layer       │    │     Logic       │    │     Layer       │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ EJS Templates   │◄──►│ Report Services │◄──►│ SQLite Database │
│ PDF Generator   │    │ Role Manager    │    │ Data Models     │
│ Web Interface   │    │ Statistics Calc │    │ Repositories    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Components and Interfaces

### Report Service
- `generateStatistics()`: Вычисляет общую статистику по заявкам
- `getEquipmentStats()`: Получает статистику по типам оборудования  
- `getStatusStats()`: Получает статистику по статусам заявок
- `getWorkshopStats()`: Получает статистику по мастерским
- `getProductStats()`: Получает статистику по продукции и материалам

### PDF Generator Service
- `generateReportPDF(reportData)`: Генерирует PDF отчет
- `formatReportData(data)`: Форматирует данные для PDF
- `addHeader(doc, title)`: Добавляет заголовок в PDF
- `addTable(doc, tableData)`: Добавляет таблицу в PDF

### Role Access Manager
- `checkReportAccess(userRole, reportType)`: Проверяет доступ к отчету
- `filterDataByRole(data, userRole)`: Фильтрует данные по роли
- `getUserSpecificData(userId, userRole)`: Получает данные для конкретного пользователя

### Documentation Generator
- `generateERDiagram()`: Создает ER-диаграмму базы данных
- `generateAlgorithmDoc()`: Создает документ с алгоритмами
- `generateUserGuide()`: Создает руководство пользователя
- `exportDocumentation()`: Экспортирует всю документацию

## Data Models

### Report Data Model
```javascript
{
  totalRequests: Number,
  activeRequests: Number, 
  completedRequests: Number,
  avgCompletionTime: Number,
  equipmentStats: [
    {
      type_name: String,
      count: Number,
      percentage: Number
    }
  ],
  statusStats: [
    {
      status_name: String,
      status_color: String,
      count: Number,
      percentage: Number
    }
  ],
  workshopStats: [
    {
      workshop_name: String,
      assigned_count: Number,
      completed_count: Number,
      completion_rate: Number,
      avg_time: Number
    }
  ]
}
```

### User Access Model
```javascript
{
  userId: Number,
  role: String, // 'admin', 'manager', 'master', 'client', 'quality_assessor'
  permissions: [String],
  accessibleReports: [String],
  dataFilters: Object
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

After reviewing all testable properties from the prework analysis, several redundancies were identified:
- Properties 1.1, 1.2, 1.3 can be combined into a comprehensive statistics calculation property
- Properties 2.2 and 3.3 are essentially the same percentage calculation logic
- Properties 5.2, 5.3, 5.4, 5.5 can be combined into a workshop statistics property
- Properties 6.1, 6.2, 6.3, 6.4 can be combined into a role-based access control property

### Core Properties

**Property 1: Statistics calculation accuracy**
*For any* set of requests in the database, the calculated statistics (total, active, completed counts and average completion time) should accurately reflect the actual data
**Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5**

**Property 2: Percentage calculations sum to 100**
*For any* non-empty dataset being analyzed, the sum of all percentage values in equipment stats and status stats should equal 100%
**Validates: Requirements 2.2, 3.3**

**Property 3: Data sorting consistency**
*For any* list of equipment types or statuses, sorting by count in descending order should result in the first item having the highest count and the last item having the lowest count
**Validates: Requirements 2.4**

**Property 4: Role-based data filtering**
*For any* user with a specific role, the data returned should only include information that the user's role is authorized to access
**Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5**

**Property 5: Workshop statistics completeness**
*For any* workshop in the system, the workshop statistics should include assigned count, completed count, completion rate, and average time calculations
**Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5**

**Property 6: PDF content preservation**
*For any* report data, the generated PDF should contain all the same information as the web version of the report
**Validates: Requirements 4.1, 4.2, 4.3**

**Property 7: Database schema completeness**
*For any* ER diagram generation, all tables, fields, primary keys, and foreign key relationships from the actual database schema should be represented
**Validates: Requirements 7.1, 7.2, 7.3, 7.4**

**Property 8: Documentation completeness**
*For any* generated user guide, all main system functions should be documented with role-specific instructions
**Validates: Requirements 9.1, 9.2, 9.3**

**Property 9: Product-workshop relationship accuracy**
*For any* product in the system, the displayed workshop associations and material information should match the actual database relationships
**Validates: Requirements 10.1, 10.2, 10.3, 10.4, 10.5**

## Error Handling

### Database Connection Errors
- Graceful degradation when database is unavailable
- Cached statistics display with timestamp
- User notification of data freshness

### PDF Generation Errors
- Fallback to HTML export if PDF generation fails
- Error logging for debugging
- User-friendly error messages

### Role Authorization Errors
- Clear access denied messages
- Redirect to appropriate pages
- Audit logging of access attempts

### Data Validation Errors
- Input sanitization for all user inputs
- SQL injection prevention
- XSS protection in report displays

## Testing Strategy

### Dual Testing Approach

The system will use both unit testing and property-based testing to ensure comprehensive coverage:

**Unit Testing:**
- Specific examples of report calculations
- Edge cases like empty datasets
- Integration points between components
- Error condition handling

**Property-Based Testing:**
- Universal properties using fast-check library for JavaScript
- Minimum 100 iterations per property test
- Each property test tagged with format: **Feature: reporting-system, Property {number}: {property_text}**
- Random data generation for comprehensive testing

**Property-Based Testing Library:** fast-check for JavaScript/Node.js

**Test Configuration:**
- Each property-based test runs minimum 100 iterations
- Custom generators for realistic test data
- Shrinking enabled for minimal failing examples

**Test Tagging Requirements:**
- Each property-based test must include comment: **Feature: reporting-system, Property {number}: {property_text}**
- Each correctness property implemented by single property-based test
- Property tests placed close to implementation for early error detection