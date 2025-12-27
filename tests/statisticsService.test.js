/**
 * **Feature: reporting-system, Property 1: Statistics calculation accuracy**
 * **Validates: Requirements 1.1, 1.2, 1.3, 1.4, 1.5**
 */

const fc = require('fast-check');
const Database = require('better-sqlite3');
const StatisticsService = require('../services/statisticsService');
const fs = require('fs');
const path = require('path');

describe('Statistics Service Property Tests', () => {
  let testDb;
  let statsService;
  let testDbPath;

  beforeEach(() => {
    // Create a temporary test database
    testDbPath = path.join(__dirname, 'test_climate_repair.db');
    testDb = new Database(testDbPath);
    
    // Create the necessary tables for testing
    testDb.exec(`
      CREATE TABLE IF NOT EXISTS repair_requests (
        request_id INTEGER PRIMARY KEY AUTOINCREMENT,
        request_number TEXT NOT NULL,
        start_date TEXT NOT NULL,
        completion_date TEXT,
        problem_description TEXT,
        priority_level INTEGER DEFAULT 1,
        client_id INTEGER NOT NULL,
        master_id INTEGER,
        status_id INTEGER NOT NULL,
        type_id INTEGER NOT NULL,
        model_id INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS equipment_types (
        type_id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_name TEXT NOT NULL UNIQUE
      );

      CREATE TABLE IF NOT EXISTS request_statuses (
        status_id INTEGER PRIMARY KEY AUTOINCREMENT,
        status_name TEXT NOT NULL UNIQUE,
        status_color TEXT NOT NULL
      );
    `);

    // Insert basic reference data
    testDb.prepare(`
      INSERT INTO equipment_types (type_id, type_name) VALUES 
      (1, 'Кондиционер'),
      (2, 'Вентилятор'),
      (3, 'Обогреватель')
    `).run();

    testDb.prepare(`
      INSERT INTO request_statuses (status_id, status_name, status_color) VALUES 
      (1, 'Новая', '#007bff'),
      (2, 'В работе', '#ffc107'),
      (3, 'Ожидание', '#6c757d'),
      (4, 'Отменена', '#dc3545'),
      (5, 'Завершена', '#28a745')
    `).run();

    statsService = new StatisticsService(testDbPath);
  });

  afterEach(() => {
    if (statsService) {
      statsService.close();
    }
    if (testDb) {
      testDb.close();
    }
    // Clean up test database file
    if (fs.existsSync(testDbPath)) {
      fs.unlinkSync(testDbPath);
    }
  });

  // Helper function to generate valid date strings
  const generateDateString = () => {
    return fc.integer({ min: 0, max: 1000 }).map(days => {
      const baseDate = new Date('2020-01-01');
      baseDate.setDate(baseDate.getDate() + days);
      return baseDate.toISOString().split('T')[0];
    });
  };

  // Helper function to generate completion date that's after start date
  const generateCompletionDate = (startDate) => {
    return fc.option(
      fc.integer({ min: 0, max: 365 }).map(additionalDays => {
        const completionDate = new Date(startDate);
        completionDate.setDate(completionDate.getDate() + additionalDays);
        return completionDate.toISOString().split('T')[0];
      }),
      { nil: null }
    );
  };

  // Helper function to generate a request with valid dates
  const generateRequest = () => {
    return generateDateString().chain(startDate =>
      generateCompletionDate(startDate).chain(completionDate =>
        fc.record({
          request_number: fc.string({ minLength: 1, maxLength: 20 }),
          start_date: fc.constant(startDate),
          completion_date: fc.constant(completionDate),
          problem_description: fc.string({ minLength: 1, maxLength: 100 }),
          priority_level: fc.integer({ min: 1, max: 5 }),
          client_id: fc.integer({ min: 1, max: 100 }),
          master_id: fc.option(fc.integer({ min: 1, max: 50 }), { nil: null }),
          status_id: fc.integer({ min: 1, max: 5 }),
          type_id: fc.integer({ min: 1, max: 3 }),
          model_id: fc.integer({ min: 1, max: 10 })
        })
      )
    );
  };

  /**
   * Property 1: Statistics calculation accuracy
   * For any set of requests in the database, the calculated statistics should accurately reflect the actual data
   */
  test('Property 1: Statistics calculation accuracy', () => {
    fc.assert(
      fc.property(
        // Generate an array of repair requests with various properties
        fc.array(generateRequest(), { minLength: 0, maxLength: 50 }),
        (requests) => {
          // Clear existing data
          testDb.prepare('DELETE FROM repair_requests').run();

          // Insert generated requests
          const insertStmt = testDb.prepare(`
            INSERT INTO repair_requests (
              request_number, start_date, completion_date, problem_description,
              priority_level, client_id, master_id, status_id, type_id, model_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          `);

          requests.forEach((request, index) => {
            insertStmt.run(
              `REQ-${String(index + 1).padStart(6, '0')}`,
              request.start_date,
              request.completion_date,
              request.problem_description,
              request.priority_level,
              request.client_id,
              request.master_id,
              request.status_id,
              request.type_id,
              request.model_id
            );
          });

          // Calculate statistics using the service
          const stats = statsService.calculateGeneralStatistics();

          // Verify total requests count
          expect(stats.totalRequests).toBe(requests.length);

          // Verify active requests count (status_id IN (1, 2, 3))
          const expectedActiveCount = requests.filter(r => [1, 2, 3].includes(r.status_id)).length;
          expect(stats.activeRequests).toBe(expectedActiveCount);

          // Verify completed requests count (status_id = 5)
          const expectedCompletedCount = requests.filter(r => r.status_id === 5).length;
          expect(stats.completedRequests).toBe(expectedCompletedCount);

          // Verify average completion time calculation
          const completedWithDates = requests.filter(r => 
            r.status_id === 5 && r.completion_date !== null
          );
          
          if (completedWithDates.length > 0) {
            const totalDays = completedWithDates.reduce((sum, request) => {
              const startDate = new Date(request.start_date);
              const completionDate = new Date(request.completion_date);
              const diffTime = completionDate.getTime() - startDate.getTime();
              const diffDays = diffTime / (1000 * 60 * 60 * 24);
              return sum + diffDays;
            }, 0);
            
            const expectedAvgTime = Math.round((totalDays / completedWithDates.length) * 10) / 10;
            expect(stats.avgCompletionTime).toBe(expectedAvgTime);
          } else {
            expect(stats.avgCompletionTime).toBe(0);
          }

          // Verify that all counts are non-negative
          expect(stats.totalRequests).toBeGreaterThanOrEqual(0);
          expect(stats.activeRequests).toBeGreaterThanOrEqual(0);
          expect(stats.completedRequests).toBeGreaterThanOrEqual(0);
          expect(stats.avgCompletionTime).toBeGreaterThanOrEqual(0);

          // Verify that active + completed <= total (other statuses exist)
          expect(stats.activeRequests + stats.completedRequests).toBeLessThanOrEqual(stats.totalRequests);
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Additional property test for equipment statistics accuracy
   */
  test('Equipment statistics should accurately reflect request counts by type', () => {
    fc.assert(
      fc.property(
        fc.array(generateRequest(), { minLength: 0, maxLength: 30 }),
        (requests) => {
          // Clear existing data
          testDb.prepare('DELETE FROM repair_requests').run();

          // Insert generated requests
          const insertStmt = testDb.prepare(`
            INSERT INTO repair_requests (
              request_number, start_date, completion_date, problem_description,
              priority_level, client_id, master_id, status_id, type_id, model_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          `);

          requests.forEach((request, index) => {
            insertStmt.run(
              `REQ-${String(index + 1).padStart(6, '0')}`,
              request.start_date,
              request.completion_date,
              request.problem_description,
              request.priority_level,
              request.client_id,
              request.master_id,
              request.status_id,
              request.type_id,
              request.model_id
            );
          });

          // Calculate equipment statistics
          const equipmentStats = statsService.calculateEquipmentStatistics();

          // Verify that all equipment types are present
          expect(equipmentStats).toHaveLength(3);

          // Verify counts for each equipment type
          const type1Count = requests.filter(r => r.type_id === 1).length;
          const type2Count = requests.filter(r => r.type_id === 2).length;
          const type3Count = requests.filter(r => r.type_id === 3).length;

          const type1Stat = equipmentStats.find(s => s.type_name === 'Кондиционер');
          const type2Stat = equipmentStats.find(s => s.type_name === 'Вентилятор');
          const type3Stat = equipmentStats.find(s => s.type_name === 'Обогреватель');

          expect(type1Stat.count).toBe(type1Count);
          expect(type2Stat.count).toBe(type2Count);
          expect(type3Stat.count).toBe(type3Count);

          // Verify that all counts are non-negative
          equipmentStats.forEach(stat => {
            expect(stat.count).toBeGreaterThanOrEqual(0);
          });
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Additional property test for status statistics accuracy
   */
  test('Status statistics should accurately reflect request counts by status', () => {
    fc.assert(
      fc.property(
        fc.array(generateRequest(), { minLength: 0, maxLength: 30 }),
        (requests) => {
          // Clear existing data
          testDb.prepare('DELETE FROM repair_requests').run();

          // Insert generated requests
          const insertStmt = testDb.prepare(`
            INSERT INTO repair_requests (
              request_number, start_date, completion_date, problem_description,
              priority_level, client_id, master_id, status_id, type_id, model_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          `);

          requests.forEach((request, index) => {
            insertStmt.run(
              `REQ-${String(index + 1).padStart(6, '0')}`,
              request.start_date,
              request.completion_date,
              request.problem_description,
              request.priority_level,
              request.client_id,
              request.master_id,
              request.status_id,
              request.type_id,
              request.model_id
            );
          });

          // Calculate status statistics
          const statusStats = statsService.calculateStatusStatistics();

          // Verify that all statuses are present
          expect(statusStats).toHaveLength(5);

          // Verify counts for each status
          for (let statusId = 1; statusId <= 5; statusId++) {
            const expectedCount = requests.filter(r => r.status_id === statusId).length;
            const statusStat = statusStats.find(s => s.status_name === 
              ['Новая', 'В работе', 'Ожидание', 'Отменена', 'Завершена'][statusId - 1]
            );
            expect(statusStat.count).toBe(expectedCount);
            expect(statusStat.count).toBeGreaterThanOrEqual(0);
          }

          // Verify that the sum of all status counts equals total requests
          const totalFromStatuses = statusStats.reduce((sum, stat) => sum + stat.count, 0);
          expect(totalFromStatuses).toBe(requests.length);
        }
      ),
      { numRuns: 100 }
    );
  });
});

/**
 * **Feature: reporting-system, Property 4: Role-based data filtering**
 * **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5**
 */
describe('Role-based Data Filtering Property Tests', () => {
  let testDb;
  let statsService;
  let testDbPath;
  let RoleAccessManager;

  beforeEach(() => {
    // Create a temporary test database
    testDbPath = path.join(__dirname, 'test_role_filtering.db');
    testDb = new Database(testDbPath);
    
    // Create the necessary tables for testing
    testDb.exec(`
      CREATE TABLE IF NOT EXISTS repair_requests (
        request_id INTEGER PRIMARY KEY AUTOINCREMENT,
        request_number TEXT NOT NULL,
        start_date TEXT NOT NULL,
        completion_date TEXT,
        problem_description TEXT,
        priority_level INTEGER DEFAULT 1,
        client_id INTEGER NOT NULL,
        master_id INTEGER,
        status_id INTEGER NOT NULL,
        type_id INTEGER NOT NULL,
        model_id INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS equipment_types (
        type_id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_name TEXT NOT NULL UNIQUE
      );

      CREATE TABLE IF NOT EXISTS request_statuses (
        status_id INTEGER PRIMARY KEY AUTOINCREMENT,
        status_name TEXT NOT NULL UNIQUE,
        status_color TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        user_type TEXT NOT NULL,
        is_active INTEGER DEFAULT 1
      );
    `);

    // Insert basic reference data
    testDb.prepare(`
      INSERT INTO equipment_types (type_id, type_name) VALUES 
      (1, 'Кондиционер'),
      (2, 'Вентилятор'),
      (3, 'Обогреватель')
    `).run();

    testDb.prepare(`
      INSERT INTO request_statuses (status_id, status_name, status_color) VALUES 
      (1, 'Новая', '#007bff'),
      (2, 'В работе', '#ffc107'),
      (3, 'Ожидание', '#6c757d'),
      (4, 'Отменена', '#dc3545'),
      (5, 'Завершена', '#28a745')
    `).run();

    // Insert test users with different roles
    testDb.prepare(`
      INSERT INTO users (user_id, full_name, user_type, is_active) VALUES 
      (1, 'Админ Админов', 'Администратор', 1),
      (2, 'Менеджер Менеджеров', 'Менеджер', 1),
      (3, 'Специалист Специалистов', 'Специалист', 1),
      (4, 'Заказчик Заказчиков', 'Заказчик', 1),
      (5, 'Оператор Операторов', 'Оператор', 1),
      (6, 'Качество Качественное', 'Менеджер по качеству', 1)
    `).run();

    statsService = new StatisticsService(testDbPath);
    RoleAccessManager = require('../middleware/roleAccess');
  });

  afterEach(() => {
    if (statsService) {
      statsService.close();
    }
    if (testDb) {
      testDb.close();
    }
    // Clean up test database file
    if (fs.existsSync(testDbPath)) {
      fs.unlinkSync(testDbPath);
    }
  });

  // Helper function to generate valid date strings
  const generateDateString = () => {
    return fc.integer({ min: 0, max: 1000 }).map(days => {
      const baseDate = new Date('2020-01-01');
      baseDate.setDate(baseDate.getDate() + days);
      return baseDate.toISOString().split('T')[0];
    });
  };

  // Helper function to generate completion date that's after start date
  const generateCompletionDate = (startDate) => {
    return fc.option(
      fc.integer({ min: 0, max: 365 }).map(additionalDays => {
        const completionDate = new Date(startDate);
        completionDate.setDate(completionDate.getDate() + additionalDays);
        return completionDate.toISOString().split('T')[0];
      }),
      { nil: null }
    );
  };

  // Helper function to generate a request with valid dates and user assignments
  const generateRequest = () => {
    return generateDateString().chain(startDate =>
      generateCompletionDate(startDate).chain(completionDate =>
        fc.record({
          request_number: fc.string({ minLength: 1, maxLength: 20 }),
          start_date: fc.constant(startDate),
          completion_date: fc.constant(completionDate),
          problem_description: fc.string({ minLength: 1, maxLength: 100 }),
          priority_level: fc.integer({ min: 1, max: 5 }),
          client_id: fc.integer({ min: 1, max: 6 }), // Match user IDs
          master_id: fc.option(fc.integer({ min: 1, max: 6 }), { nil: null }),
          status_id: fc.integer({ min: 1, max: 5 }),
          type_id: fc.integer({ min: 1, max: 3 }),
          model_id: fc.integer({ min: 1, max: 10 })
        })
      )
    );
  };

  // Helper function to generate user objects with different roles
  const generateUser = () => {
    return fc.record({
      user_id: fc.integer({ min: 1, max: 6 }),
      user_type: fc.constantFrom('Администратор', 'Менеджер', 'Специалист', 'Заказчик', 'Оператор', 'Менеджер по качеству')
    });
  };

  /**
   * Property 4: Role-based data filtering
   * For any user with a specific role, the data returned should only include information 
   * that the user's role is authorized to access
   */
  test('Property 4: Role-based data filtering', () => {
    fc.assert(
      fc.property(
        // Generate an array of repair requests and a user with a specific role
        fc.array(generateRequest(), { minLength: 5, maxLength: 30 }),
        generateUser(),
        (requests, user) => {
          // Clear existing data
          testDb.prepare('DELETE FROM repair_requests').run();

          // Insert generated requests
          const insertStmt = testDb.prepare(`
            INSERT INTO repair_requests (
              request_number, start_date, completion_date, problem_description,
              priority_level, client_id, master_id, status_id, type_id, model_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          `);

          requests.forEach((request, index) => {
            insertStmt.run(
              `REQ-${String(index + 1).padStart(6, '0')}`,
              request.start_date,
              request.completion_date,
              request.problem_description,
              request.priority_level,
              request.client_id,
              request.master_id,
              request.status_id,
              request.type_id,
              request.model_id
            );
          });

          // Get data filters for the user role
          const filters = RoleAccessManager.getDataFilters(user);

          // Calculate statistics with role-based filtering
          const generalStats = statsService.calculateGeneralStatistics(filters);
          const equipmentStats = statsService.calculateEquipmentStatistics(filters);
          const statusStats = statsService.calculateStatusStatistics(filters);
          const workshopStats = statsService.calculateWorkshopStatistics(filters);

          // Verify role-based access control based on user type
          switch (user.user_type.trim()) {
            case 'Заказчик':
              // Client should only see their own requests
              const clientRequests = requests.filter(r => r.client_id === user.user_id);
              expect(generalStats.totalRequests).toBe(clientRequests.length);
              
              // Verify active requests count for client
              const clientActiveRequests = clientRequests.filter(r => [1, 2, 3].includes(r.status_id));
              expect(generalStats.activeRequests).toBe(clientActiveRequests.length);
              
              // Verify completed requests count for client
              const clientCompletedRequests = clientRequests.filter(r => r.status_id === 5);
              expect(generalStats.completedRequests).toBe(clientCompletedRequests.length);
              
              // Equipment stats should only reflect client's requests
              equipmentStats.forEach(stat => {
                const expectedCount = clientRequests.filter(r => {
                  const typeMap = { 1: 'Кондиционер', 2: 'Вентилятор', 3: 'Обогреватель' };
                  return typeMap[r.type_id] === stat.type_name;
                }).length;
                expect(stat.count).toBe(expectedCount);
              });
              
              // Status stats should only reflect client's requests
              statusStats.forEach(stat => {
                const statusMap = { 1: 'Новая', 2: 'В работе', 3: 'Ожидание', 4: 'Отменена', 5: 'Завершена' };
                const expectedCount = clientRequests.filter(r => {
                  return statusMap[r.status_id] === stat.status_name;
                }).length;
                expect(stat.count).toBe(expectedCount);
              });
              
              // Workshop stats should be empty for clients
              expect(workshopStats).toEqual([]);
              break;

            case 'Специалист':
              // Master should only see requests assigned to them
              const masterRequests = requests.filter(r => r.master_id === user.user_id);
              expect(generalStats.totalRequests).toBe(masterRequests.length);
              
              // Verify active requests count for master
              const masterActiveRequests = masterRequests.filter(r => [1, 2, 3].includes(r.status_id));
              expect(generalStats.activeRequests).toBe(masterActiveRequests.length);
              
              // Verify completed requests count for master
              const masterCompletedRequests = masterRequests.filter(r => r.status_id === 5);
              expect(generalStats.completedRequests).toBe(masterCompletedRequests.length);
              
              // Equipment stats should only reflect master's requests
              equipmentStats.forEach(stat => {
                const typeMap = { 1: 'Кондиционер', 2: 'Вентилятор', 3: 'Обогреватель' };
                const expectedCount = masterRequests.filter(r => typeMap[r.type_id] === stat.type_name).length;
                expect(stat.count).toBe(expectedCount);
              });
              
              // Workshop stats should only show the master's own statistics
              const masterWorkshopStats = workshopStats.filter(ws => ws.workshop_id === user.user_id);
              expect(masterWorkshopStats.length).toBeLessThanOrEqual(1);
              if (masterWorkshopStats.length === 1) {
                expect(masterWorkshopStats[0].assigned_count).toBe(masterRequests.length);
                expect(masterWorkshopStats[0].completed_count).toBe(masterCompletedRequests.length);
              }
              break;

            case 'Менеджер':
            case 'Менеджер по качеству':
            case 'Администратор':
            case 'Оператор':
              // These roles should see all requests (full access)
              expect(generalStats.totalRequests).toBe(requests.length);
              
              // Verify active requests count for full access roles
              const allActiveRequests = requests.filter(r => [1, 2, 3].includes(r.status_id));
              expect(generalStats.activeRequests).toBe(allActiveRequests.length);
              
              // Verify completed requests count for full access roles
              const allCompletedRequests = requests.filter(r => r.status_id === 5);
              expect(generalStats.completedRequests).toBe(allCompletedRequests.length);
              
              // Equipment stats should reflect all requests
              equipmentStats.forEach(stat => {
                const typeMap = { 1: 'Кондиционер', 2: 'Вентилятор', 3: 'Обогреватель' };
                const expectedCount = requests.filter(r => typeMap[r.type_id] === stat.type_name).length;
                expect(stat.count).toBe(expectedCount);
              });
              
              // Status stats should reflect all requests
              statusStats.forEach(stat => {
                const statusMap = { 1: 'Новая', 2: 'В работе', 3: 'Ожидание', 4: 'Отменена', 5: 'Завершена' };
                const expectedCount = requests.filter(r => statusMap[r.status_id] === stat.status_name).length;
                expect(stat.count).toBe(expectedCount);
              });
              break;

            default:
              // Unknown roles should have no access (empty results)
              expect(generalStats.totalRequests).toBe(0);
              expect(generalStats.activeRequests).toBe(0);
              expect(generalStats.completedRequests).toBe(0);
              expect(equipmentStats.every(stat => stat.count === 0)).toBe(true);
              expect(statusStats.every(stat => stat.count === 0)).toBe(true);
              break;
          }

          // Verify that all returned counts are non-negative
          expect(generalStats.totalRequests).toBeGreaterThanOrEqual(0);
          expect(generalStats.activeRequests).toBeGreaterThanOrEqual(0);
          expect(generalStats.completedRequests).toBeGreaterThanOrEqual(0);
          expect(generalStats.avgCompletionTime).toBeGreaterThanOrEqual(0);

          // Verify that active + completed <= total
          expect(generalStats.activeRequests + generalStats.completedRequests).toBeLessThanOrEqual(generalStats.totalRequests);

          // Verify that equipment and status stats have non-negative counts
          equipmentStats.forEach(stat => {
            expect(stat.count).toBeGreaterThanOrEqual(0);
          });
          
          statusStats.forEach(stat => {
            expect(stat.count).toBeGreaterThanOrEqual(0);
          });

          // Verify that workshop stats have valid completion rates
          workshopStats.forEach(stat => {
            expect(stat.completion_rate).toBeGreaterThanOrEqual(0);
            expect(stat.completion_rate).toBeLessThanOrEqual(100);
            expect(stat.assigned_count).toBeGreaterThanOrEqual(0);
            expect(stat.completed_count).toBeGreaterThanOrEqual(0);
            expect(stat.completed_count).toBeLessThanOrEqual(stat.assigned_count);
            expect(stat.avg_time).toBeGreaterThanOrEqual(0);
          });
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Additional test for report access permissions
   */
  test('Report access permissions are correctly enforced', () => {
    fc.assert(
      fc.property(
        generateUser(),
        fc.constantFrom('general', 'equipment', 'status', 'workshop', 'product', 'system', 'personal'),
        (user, reportType) => {
          const hasAccess = RoleAccessManager.checkReportAccess(user.user_type, reportType);
          
          // Verify access permissions based on role
          switch (user.user_type.trim()) {
            case 'Администратор':
              // Admin should have access to all report types except personal
              if (reportType === 'personal') {
                expect(hasAccess).toBe(false);
              } else {
                expect(hasAccess).toBe(true);
              }
              break;
              
            case 'Менеджер':
            case 'Менеджер по качеству':
              // Managers should have access to most reports except system
              if (reportType === 'system') {
                expect(hasAccess).toBe(false);
              } else if (reportType === 'personal') {
                expect(hasAccess).toBe(false);
              } else {
                expect(hasAccess).toBe(true);
              }
              break;
              
            case 'Специалист':
            case 'Заказчик':
              // Specialists and clients should only have access to personal reports
              if (reportType === 'personal') {
                expect(hasAccess).toBe(true);
              } else {
                expect(hasAccess).toBe(false);
              }
              break;
              
            case 'Оператор':
              // Operators should have limited access
              if (['general', 'equipment', 'status'].includes(reportType)) {
                expect(hasAccess).toBe(true);
              } else {
                expect(hasAccess).toBe(false);
              }
              break;
              
            default:
              // Unknown roles should have no access
              expect(hasAccess).toBe(false);
              break;
          }
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Test for data filter generation consistency
   */
  test('Data filters are generated consistently for each role', () => {
    fc.assert(
      fc.property(
        generateUser(),
        (user) => {
          const filters = RoleAccessManager.getDataFilters(user);
          
          // Verify filter structure
          expect(filters).toHaveProperty('type');
          expect(filters).toHaveProperty('userId');
          expect(filters).toHaveProperty('whereClause');
          expect(filters).toHaveProperty('params');
          
          // Verify filter consistency based on role
          switch (user.user_type.trim()) {
            case 'Заказчик':
              expect(filters.type).toBe('client');
              expect(filters.userId).toBe(user.user_id);
              expect(filters.whereClause).toBe('WHERE r.client_id = ?');
              expect(filters.params).toEqual([user.user_id]);
              break;
              
            case 'Специалист':
              expect(filters.type).toBe('master');
              expect(filters.userId).toBe(user.user_id);
              expect(filters.whereClause).toBe('WHERE r.master_id = ?');
              expect(filters.params).toEqual([user.user_id]);
              break;
              
            case 'Менеджер':
            case 'Менеджер по качеству':
            case 'Администратор':
            case 'Оператор':
              expect(filters.type).toBe('full');
              expect(filters.userId).toBe(null);
              expect(filters.whereClause).toBe('');
              expect(filters.params).toEqual([]);
              break;
              
            default:
              expect(filters.type).toBe('none');
              expect(filters.userId).toBe(null);
              expect(filters.whereClause).toBe('WHERE 1 = 0');
              expect(filters.params).toEqual([]);
              break;
          }
        }
      ),
      { numRuns: 100 }
    );
  });
});

/**
 * **Feature: reporting-system, Property 6: PDF content preservation**
 * **Validates: Requirements 4.1, 4.2, 4.3**
 */
describe('PDF Content Preservation Property Tests', () => {
  let testDb;
  let testDbPath;
  let pdfService;

  beforeEach(() => {
    // Create a temporary test database
    testDbPath = path.join(__dirname, 'test_pdf_content.db');
    testDb = new Database(testDbPath);
    
    // Create the necessary tables for testing
    testDb.exec(`
      CREATE TABLE IF NOT EXISTS repair_requests (
        request_id INTEGER PRIMARY KEY AUTOINCREMENT,
        request_number TEXT NOT NULL,
        start_date TEXT NOT NULL,
        completion_date TEXT,
        problem_description TEXT,
        priority_level INTEGER DEFAULT 1,
        client_id INTEGER NOT NULL,
        master_id INTEGER,
        status_id INTEGER NOT NULL,
        type_id INTEGER NOT NULL,
        model_id INTEGER NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS equipment_types (
        type_id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_name TEXT NOT NULL UNIQUE
      );

      CREATE TABLE IF NOT EXISTS request_statuses (
        status_id INTEGER PRIMARY KEY AUTOINCREMENT,
        status_name TEXT NOT NULL UNIQUE,
        status_color TEXT NOT NULL
      );
    `);

    // Insert basic reference data
    testDb.prepare(`
      INSERT INTO equipment_types (type_id, type_name) VALUES 
      (1, 'Кондиционер'),
      (2, 'Вентилятор'),
      (3, 'Обогреватель')
    `).run();

    testDb.prepare(`
      INSERT INTO request_statuses (status_id, status_name, status_color) VALUES 
      (1, 'Новая', '#007bff'),
      (2, 'В работе', '#ffc107'),
      (3, 'Ожидание', '#6c757d'),
      (4, 'Отменена', '#dc3545'),
      (5, 'Завершена', '#28a745')
    `).run();

    // Initialize PDF service
    const PDFService = require('../services/pdfService');
    pdfService = new PDFService();
  });

  afterEach(async () => {
    if (pdfService) {
      await pdfService.close();
    }
    if (testDb) {
      testDb.close();
    }
    // Clean up test database file
    if (fs.existsSync(testDbPath)) {
      fs.unlinkSync(testDbPath);
    }
  });

  // Helper function to generate valid date strings
  const generateDateString = () => {
    return fc.integer({ min: 0, max: 1000 }).map(days => {
      const baseDate = new Date('2020-01-01');
      baseDate.setDate(baseDate.getDate() + days);
      return baseDate.toISOString().split('T')[0];
    });
  };

  // Helper function to generate completion date that's after start date
  const generateCompletionDate = (startDate) => {
    return fc.option(
      fc.integer({ min: 0, max: 365 }).map(additionalDays => {
        const completionDate = new Date(startDate);
        completionDate.setDate(completionDate.getDate() + additionalDays);
        return completionDate.toISOString().split('T')[0];
      }),
      { nil: null }
    );
  };

  // Helper function to generate a request with valid dates
  const generateRequest = () => {
    return generateDateString().chain(startDate =>
      generateCompletionDate(startDate).chain(completionDate =>
        fc.record({
          request_number: fc.string({ minLength: 1, maxLength: 20 }),
          start_date: fc.constant(startDate),
          completion_date: fc.constant(completionDate),
          problem_description: fc.string({ minLength: 1, maxLength: 100 }),
          priority_level: fc.integer({ min: 1, max: 5 }),
          client_id: fc.integer({ min: 1, max: 100 }),
          master_id: fc.option(fc.integer({ min: 1, max: 50 }), { nil: null }),
          status_id: fc.integer({ min: 1, max: 5 }),
          type_id: fc.integer({ min: 1, max: 3 }),
          model_id: fc.integer({ min: 1, max: 10 })
        })
      )
    );
  };

  /**
   * Property 6: PDF content preservation
   * For any report data, the generated PDF should contain all the same information as the web version of the report
   */
  test('Property 6: PDF content preservation', async () => {
    await fc.assert(
      fc.asyncProperty(
        // Generate an array of repair requests with various properties
        fc.array(generateRequest(), { minLength: 1, maxLength: 20 }),
        async (requests) => {
          // Clear existing data
          testDb.prepare('DELETE FROM repair_requests').run();

          // Insert generated requests
          const insertStmt = testDb.prepare(`
            INSERT INTO repair_requests (
              request_number, start_date, completion_date, problem_description,
              priority_level, client_id, master_id, status_id, type_id, model_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          `);

          requests.forEach((request, index) => {
            insertStmt.run(
              `REQ-${String(index + 1).padStart(6, '0')}`,
              request.start_date,
              request.completion_date,
              request.problem_description,
              request.priority_level,
              request.client_id,
              request.master_id,
              request.status_id,
              request.type_id,
              request.model_id
            );
          });

          // Calculate statistics using the service (simulating web version data)
          const StatisticsService = require('../services/statisticsService');
          const statsService = new StatisticsService(testDbPath);
          
          const generalStats = statsService.calculateGeneralStatistics();
          const equipmentStats = statsService.calculateEquipmentStatistics();
          const statusStats = statsService.calculateStatusStatistics();
          
          statsService.close();

          // Prepare report data (same as server.js)
          const reportData = {
            totalRequests: generalStats.totalRequests,
            completedRequests: generalStats.completedRequests,
            activeRequests: generalStats.activeRequests,
            avgCompletionTime: generalStats.avgCompletionTime,
            equipmentStats,
            statusStats
          };

          // Generate PDF
          const pdfBuffer = await pdfService.generateReportPDF(reportData, 'Test Report');
          
          // Verify PDF was generated successfully
          expect(pdfBuffer).toBeDefined();
          expect(pdfBuffer.length).toBeGreaterThan(0);
          
          // Accept both Buffer and Uint8Array (Puppeteer returns Uint8Array)
          const isValidPDFData = Buffer.isBuffer(pdfBuffer) || 
                                 (pdfBuffer && typeof pdfBuffer === 'object' && 
                                  typeof pdfBuffer.length === 'number' && pdfBuffer.length > 0);
          expect(isValidPDFData).toBe(true);

          // Generate HTML content for comparison (what would be shown in web version)
          const formattedData = pdfService.formatReportData(reportData);
          const htmlContent = pdfService.generateHTMLContent(formattedData, 'Test Report');

          // Verify that HTML content contains all the key data points
          // Total requests
          expect(htmlContent).toContain(String(reportData.totalRequests));
          
          // Active requests
          expect(htmlContent).toContain(String(reportData.activeRequests));
          
          // Completed requests
          expect(htmlContent).toContain(String(reportData.completedRequests));
          
          // Average completion time
          expect(htmlContent).toContain(String(reportData.avgCompletionTime));

          // Equipment statistics
          reportData.equipmentStats.forEach(stat => {
            expect(htmlContent).toContain(stat.type_name);
            expect(htmlContent).toContain(String(stat.count));
          });

          // Status statistics
          reportData.statusStats.forEach(stat => {
            expect(htmlContent).toContain(stat.status_name);
            expect(htmlContent).toContain(String(stat.count));
            expect(htmlContent).toContain(stat.status_color);
          });

          // Verify generation timestamp is included
          expect(htmlContent).toMatch(/Сгенерировано:/);
          expect(htmlContent).toMatch(/Дата генерации:/);

          // Verify report title is included
          expect(htmlContent).toContain('Test Report');

          // Verify structured sections are present
          if (reportData.equipmentStats && reportData.equipmentStats.length > 0) {
            expect(htmlContent).toContain('Статистика по типам оборудования');
          }
          
          if (reportData.statusStats && reportData.statusStats.length > 0) {
            expect(htmlContent).toContain('Статистика по статусам заявок');
          }

          // Verify that percentages are calculated correctly in HTML
          if (reportData.totalRequests > 0) {
            reportData.equipmentStats.forEach(stat => {
              const expectedPercentage = Math.round((stat.count / reportData.totalRequests) * 100);
              expect(htmlContent).toContain(`${expectedPercentage}%`);
            });

            reportData.statusStats.forEach(stat => {
              const expectedPercentage = Math.round((stat.count / reportData.totalRequests) * 100);
              expect(htmlContent).toContain(`${expectedPercentage}%`);
            });
          }
        }
      ),
      { numRuns: 10 } // Reduced runs due to PDF generation overhead
    );
  }, 30000); // 30 second timeout for PDF generation

  /**
   * Additional test for PDF content structure and formatting
   */
  test('PDF content includes required formatting and structure', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.record({
          totalRequests: fc.integer({ min: 0, max: 100 }),
          activeRequests: fc.integer({ min: 0, max: 50 }),
          completedRequests: fc.integer({ min: 0, max: 50 }),
          avgCompletionTime: fc.float({ min: 0, max: 30 }),
          equipmentStats: fc.array(
            fc.record({
              type_name: fc.constantFrom('Кондиционер', 'Вентилятор', 'Обогреватель'),
              count: fc.integer({ min: 0, max: 20 })
            }),
            { minLength: 1, maxLength: 3 }
          ),
          statusStats: fc.array(
            fc.record({
              status_name: fc.constantFrom('Новая', 'В работе', 'Ожидание', 'Отменена', 'Завершена'),
              status_color: fc.constantFrom('#007bff', '#ffc107', '#6c757d', '#dc3545', '#28a745'),
              count: fc.integer({ min: 0, max: 20 })
            }),
            { minLength: 1, maxLength: 5 }
          )
        }),
        async (reportData) => {
          // Generate PDF
          const pdfBuffer = await pdfService.generateReportPDF(reportData, 'Formatted Test Report');
          
          // Verify PDF was generated
          expect(pdfBuffer).toBeDefined();
          expect(pdfBuffer.length).toBeGreaterThan(0);

          // Generate and verify HTML content structure
          const formattedData = pdfService.formatReportData(reportData);
          const htmlContent = pdfService.generateHTMLContent(formattedData, 'Formatted Test Report');

          // Verify HTML structure includes required elements
          expect(htmlContent).toContain('<!DOCTYPE html>');
          expect(htmlContent).toContain('<html lang="ru">');
          expect(htmlContent).toContain('<head>');
          expect(htmlContent).toContain('<body>');
          expect(htmlContent).toContain('class="header"');
          expect(htmlContent).toContain('class="stats-grid"');
          expect(htmlContent).toContain('class="footer"');

          // Verify CSS styling is included
          expect(htmlContent).toContain('<style>');
          expect(htmlContent).toContain('font-family:');
          expect(htmlContent).toContain('grid-template-columns:');

          // Verify all data is properly formatted and escaped
          expect(formattedData.generatedAt).toBeDefined();
          expect(formattedData.generatedDate).toBeDefined();
          expect(typeof formattedData.generatedAt).toBe('string');
          expect(typeof formattedData.generatedDate).toBe('string');

          // Verify that the formatted data preserves all original data
          expect(formattedData.totalRequests).toBe(reportData.totalRequests);
          expect(formattedData.activeRequests).toBe(reportData.activeRequests);
          expect(formattedData.completedRequests).toBe(reportData.completedRequests);
          expect(formattedData.avgCompletionTime).toBe(reportData.avgCompletionTime);
          expect(formattedData.equipmentStats).toEqual(reportData.equipmentStats);
          expect(formattedData.statusStats).toEqual(reportData.statusStats);
        }
      ),
      { numRuns: 5 } // Reduced runs for performance
    );
  }, 30000); // 30 second timeout for PDF generation
});

/**
 * **Feature: reporting-system, Property 7: Database schema completeness**
 * **Validates: Requirements 7.1, 7.2, 7.3, 7.4**
 */
describe('Database Schema Completeness Property Tests', () => {
  let testDb;
  let testDbPath;

  beforeEach(() => {
    // Create a temporary test database with the actual schema
    testDbPath = path.join(__dirname, 'test_schema_completeness.db');
    testDb = new Database(testDbPath);
    
    // Load the actual schema from schema.sql
    const schemaPath = path.join(__dirname, '../database/schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    
    // Execute the schema to create all tables
    const statements = schema.split(';').filter(stmt => stmt.trim().length > 0);
    statements.forEach(statement => {
      try {
        testDb.exec(statement);
      } catch (error) {
        // Ignore DROP TABLE errors and duplicate table creation errors
        if (!error.message.includes('no such table') && 
            !error.message.includes('already exists')) {
          console.error('Schema execution error:', error.message);
        }
      }
    });
  });

  afterEach(() => {
    if (testDb) {
      testDb.close();
    }
    // Clean up test database file
    if (fs.existsSync(testDbPath)) {
      fs.unlinkSync(testDbPath);
    }
  });

  /**
   * Property 7: Database schema completeness
   * For any ER diagram generation, all tables, fields, primary keys, and foreign key relationships 
   * from the actual database schema should be represented
   */
  test('Property 7: Database schema completeness', () => {
    fc.assert(
      fc.property(
        // We don't need random data for this test - we're testing schema completeness
        fc.constant(true),
        () => {
          // Get actual database schema information
          const actualSchema = getDatabaseSchemaInfo(testDb);
          
          // Load the ER diagram documentation
          const erDiagramPath = path.join(__dirname, '../docs/er_diagram.md');
          const erDiagramContent = fs.readFileSync(erDiagramPath, 'utf8');
          
          // Verify all tables are documented
          actualSchema.tables.forEach(tableName => {
            expect(erDiagramContent).toMatch(new RegExp(`\\b${tableName}\\b`, 'i'));
          });
          
          // Verify all primary keys are documented
          actualSchema.primaryKeys.forEach(({ table, column }) => {
            // Look for PK notation in the ER diagram
            const pkPattern = new RegExp(`${column}.*PK|${column}.*PRIMARY KEY|PRIMARY KEY.*${column}`, 'i');
            expect(erDiagramContent).toMatch(pkPattern);
          });
          
          // Verify all foreign keys are documented
          actualSchema.foreignKeys.forEach(({ table, column, referencedTable, referencedColumn }) => {
            // Look for FK notation in the ER diagram
            const fkPattern = new RegExp(`${column}.*FK|${column}.*FOREIGN KEY|FOREIGN KEY.*${column}`, 'i');
            expect(erDiagramContent).toMatch(fkPattern);
            
            // Verify the relationship is documented
            expect(erDiagramContent).toMatch(new RegExp(`${table}.*${referencedTable}|${referencedTable}.*${table}`, 'i'));
          });
          
          // Verify all columns are documented for each table
          Object.entries(actualSchema.columns).forEach(([tableName, columns]) => {
            columns.forEach(columnName => {
              // Check if column is mentioned in the table section
              const tableSection = extractTableSection(erDiagramContent, tableName);
              if (tableSection) {
                expect(tableSection).toMatch(new RegExp(`\\b${columnName}\\b`, 'i'));
              }
            });
          });
          
          // Verify relationships cardinalities are documented
          actualSchema.relationships.forEach(({ fromTable, toTable, type }) => {
            // Look for relationship documentation between tables in the cardinalities section
            const cardinalityPattern = new RegExp(
              `${fromTable}.*${toTable}.*1:M|${toTable}.*${fromTable}.*1:M|` +
              `${fromTable}.*${toTable}.*1:1|${toTable}.*${fromTable}.*1:1|` +
              `${fromTable}.*${toTable}|${toTable}.*${fromTable}`,
              'i'
            );
            expect(erDiagramContent).toMatch(cardinalityPattern);
          });
          
          // Verify that documented tables actually exist in the database
          const documentedTables = extractDocumentedTables(erDiagramContent);
          documentedTables.forEach(tableName => {
            expect(actualSchema.tables).toContain(tableName);
          });
        }
      ),
      { numRuns: 1 } // Only need to run once since we're testing static schema
    );
  });

  /**
   * Helper function to extract database schema information
   */
  function getDatabaseSchemaInfo(db) {
    const schema = {
      tables: [],
      columns: {},
      primaryKeys: [],
      foreignKeys: [],
      relationships: []
    };

    // Get all tables
    const tables = db.prepare(`
      SELECT name FROM sqlite_master 
      WHERE type='table' AND name NOT LIKE 'sqlite_%'
    `).all();
    
    schema.tables = tables.map(t => t.name);

    // For each table, get column information
    schema.tables.forEach(tableName => {
      const tableInfo = db.prepare(`PRAGMA table_info(${tableName})`).all();
      schema.columns[tableName] = tableInfo.map(col => col.name);
      
      // Find primary keys
      tableInfo.forEach(col => {
        if (col.pk === 1) {
          schema.primaryKeys.push({
            table: tableName,
            column: col.name
          });
        }
      });
      
      // Get foreign key information
      const foreignKeys = db.prepare(`PRAGMA foreign_key_list(${tableName})`).all();
      foreignKeys.forEach(fk => {
        schema.foreignKeys.push({
          table: tableName,
          column: fk.from,
          referencedTable: fk.table,
          referencedColumn: fk.to
        });
        
        // Add relationship information
        schema.relationships.push({
          fromTable: tableName,
          toTable: fk.table,
          type: '1:M' // Most relationships in this schema are 1:M
        });
      });
    });

    return schema;
  }

  /**
   * Helper function to extract table section from ER diagram content
   */
  function extractTableSection(content, tableName) {
    const tablePattern = new RegExp(`${tableName}\\s*\\{[^}]*\\}`, 'is');
    const match = content.match(tablePattern);
    return match ? match[0] : null;
  }

  /**
   * Helper function to extract documented table names from ER diagram
   */
  function extractDocumentedTables(content) {
    const tables = [];
    
    // Extract table names from mermaid diagram
    const mermaidMatch = content.match(/```mermaid([\s\S]*?)```/);
    if (mermaidMatch) {
      const mermaidContent = mermaidMatch[1];
      const tablePattern = /^\s*(\w+)\s*\{/gm;
      let match;
      
      while ((match = tablePattern.exec(mermaidContent)) !== null) {
        tables.push(match[1]);
      }
    }
    
    return tables;
  }
});