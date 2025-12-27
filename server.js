const express = require('express');
const Database = require('better-sqlite3');
const path = require('path');
const bodyParser = require('body-parser');
const expressLayouts = require('express-ejs-layouts');
const session = require('express-session');
const bcrypt = require('bcrypt');
const QRCode = require('qrcode');
const StatisticsService = require('./services/statisticsService');
const PDFService = require('./services/pdfService');
const RoleAccessManager = require('./middleware/roleAccess');

const app = express();
const PORT = 3001;

const db = new Database(path.join(__dirname, 'database', 'climate_repair.db'));

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(expressLayouts);
app.set('layout', 'base');

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

app.use(session({
  secret: 'climate_repair_secret_key_2023',
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false, maxAge: 24 * 60 * 60 * 1000 }
}));

function requireAuth(req, res, next) {
  if (req.session.user) {
    next();
  } else {
    res.redirect('/login');
  }
}

function requireRole(roles) {
  return (req, res, next) => {
    if (req.session.user) {
      const userType = req.session.user.user_type.trim();
      if (roles.includes(userType)) {
        next();
      } else {
        res.status(403).render('error', { 
          title: 'Доступ запрещен',
          message: 'У вас недостаточно прав для доступа к этой странице',
          user: req.session.user 
        });
      }
    } else {
      res.redirect('/login');
    }
  };
}

// Middleware для передачи пользователя в шаблоны
app.use((req, res, next) => {
  res.locals.user = req.session.user || null;
  next();
});




app.get('/login', (req, res) => {
  if (req.session.user) {
    return res.redirect('/');
  }
  res.render('login', { title: 'Вход в систему', layout: false });
});


app.post('/login', (req, res) => {
  const { login, password } = req.body;
  
  try {
    const user = db.prepare('SELECT * FROM users WHERE login = ? AND is_active = 1').get(login);
    
    if (user && bcrypt.compareSync(password, user.password_hash)) {
      req.session.user = user;
      res.redirect('/');
    } else {
      res.render('login', { 
        title: 'Вход в систему',
        layout: false,
        error: 'Неверный логин или пароль'
      });
    }
  } catch (error) {
    res.render('login', { 
      title: 'Вход в систему',
      layout: false,
      error: 'Ошибка авторизации: ' + error.message
    });
  }
});


app.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/login');
});




app.get('/', requireAuth, (req, res) => {
  try {
    const user = req.session.user;
    // Общая статистика
    const totalRequests = db.prepare('SELECT COUNT(*) as count FROM repair_requests').get().count;
    const activeRequests = db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE status_id IN (1, 2, 3)').get().count;
    const completedRequests = db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE status_id = 5').get().count;
    
    // Статистика для конкретного пользователя
    let userStats = {};
    if (user.user_type.trim() === 'Заказчик') {
      userStats = {
        myRequests: db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE client_id = ?').get(user.user_id).count,
        myActive: db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE client_id = ? AND status_id IN (1, 2, 3)').get(user.user_id).count,
        myCompleted: db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE client_id = ? AND status_id = 5').get(user.user_id).count
      };
    } else if (user.user_type.trim() === 'Специалист') {
      userStats = {
        assignedToMe: db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE master_id = ?').get(user.user_id).count,
        myActive: db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE master_id = ? AND status_id IN (2, 3)').get(user.user_id).count,
        myCompleted: db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE master_id = ? AND status_id = 5').get(user.user_id).count
      };
    }
    
    res.render('index', { 
      title: 'Главная страница',
      user: user,
      totalRequests,
      activeRequests,
      completedRequests,
      userStats
    });
  } catch (error) {
    res.status(500).send('Ошибка: ' + error.message);
  }
});




app.get('/requests', requireAuth, requireRole(['Оператор', 'Специалист', 'Менеджер', 'Менеджер по качеству']), (req, res) => {
  try {
    const search = req.query.search || '';
    const status = req.query.status || '';
    
    let query = `
      SELECT 
        r.*,
        c.full_name as client_name,
        c.phone as client_phone,
        m.full_name as master_name,
        et.type_name,
        em.model_name,
        rs.status_name,
        rs.status_color
      FROM repair_requests r
      JOIN users c ON r.client_id = c.user_id
      LEFT JOIN users m ON r.master_id = m.user_id
      JOIN equipment_types et ON r.type_id = et.type_id
      JOIN equipment_models em ON r.model_id = em.model_id
      JOIN request_statuses rs ON r.status_id = rs.status_id
      WHERE 1=1
    `;
    
    const params = [];
    
    if (search) {
      query += ` AND (r.request_number LIKE ? OR c.full_name LIKE ? OR r.problem_description LIKE ?)`;
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }
    
    if (status) {
      query += ` AND r.status_id = ?`;
      params.push(status);
    }
    
    query += ` ORDER BY r.created_at DESC`;
    
    const requests = db.prepare(query).all(...params);
    const statuses = db.prepare('SELECT * FROM request_statuses').all();
    
    res.render('requests/all_requests', { 
      title: 'Все заявки',
      requests,
      statuses,
      search,
      selectedStatus: status
    });
  } catch (error) {
    res.status(500).send('Ошибка: ' + error.message);
  }
});


app.get('/my-requests', requireAuth, requireRole(['Заказчик', 'Менеджер', 'Менеджер по качеству']), (req, res) => {
  try {
    const requests = db.prepare(`
      SELECT 
        r.*,
        et.type_name,
        em.model_name,
        rs.status_name,
        rs.status_color,
        m.full_name as master_name
      FROM repair_requests r
      JOIN equipment_types et ON r.type_id = et.type_id
      JOIN equipment_models em ON r.model_id = em.model_id
      JOIN request_statuses rs ON r.status_id = rs.status_id
      LEFT JOIN users m ON r.master_id = m.user_id
      WHERE r.client_id = ?
      ORDER BY r.created_at DESC
    `).all(req.session.user.user_id);
    
    res.render('requests/my_requests', { 
      title: 'Мои заявки',
      requests
    });
  } catch (error) {
    res.status(500).send('Ошибка: ' + error.message);
  }
});


app.get('/my-work', requireAuth, requireRole(['Специалист', 'Менеджер', 'Менеджер по качеству']), (req, res) => {
  try {
    const requests = db.prepare(`
      SELECT 
        r.*,
        c.full_name as client_name,
        c.phone as client_phone,
        et.type_name,
        em.model_name,
        rs.status_name,
        rs.status_color
      FROM repair_requests r
      JOIN users c ON r.client_id = c.user_id
      JOIN equipment_types et ON r.type_id = et.type_id
      JOIN equipment_models em ON r.model_id = em.model_id
      JOIN request_statuses rs ON r.status_id = rs.status_id
      WHERE r.master_id = ?
      ORDER BY r.created_at DESC
    `).all(req.session.user.user_id);
    
    res.render('requests/my_work', { 
      title: 'Мои работы',
      requests
    });
  } catch (error) {
    res.status(500).send('Ошибка: ' + error.message);
  }
});


app.get('/requests/create', requireAuth, requireRole(['Заказчик', 'Оператор', 'Менеджер', 'Менеджер по качеству']), (req, res) => {
  try {
    const equipmentTypes = db.prepare('SELECT * FROM equipment_types ORDER BY type_name').all();
    
    res.render('requests/create', { 
      title: 'Создание заявки',
      equipmentTypes
    });
  } catch (error) {
    res.status(500).send('Ошибка: ' + error.message);
  }
});


app.post('/requests/create', requireAuth, requireRole(['Заказчик', 'Оператор', 'Менеджер', 'Менеджер по качеству']), (req, res) => {
  try {
    const { equipment_type, equipment_model, problem_description, priority_level } = req.body;
    
    // Генерируем номер заявки
    const lastRequest = db.prepare('SELECT request_number FROM repair_requests ORDER BY request_id DESC LIMIT 1').get();
    let nextNumber = 1;
    if (lastRequest) {
      const lastNumber = parseInt(lastRequest.request_number.split('-')[1]);
      nextNumber = lastNumber + 1;
    }
    const requestNumber = `REQ-${String(nextNumber).padStart(6, '0')}`;
    
    // Создаем заявку
    const stmt = db.prepare(`
      INSERT INTO repair_requests (
        request_number, start_date, problem_description, priority_level,
        client_id, status_id, type_id, model_id
      ) VALUES (?, date('now'), ?, ?, ?, 1, ?, ?)
    `);
    
    stmt.run(requestNumber, problem_description, priority_level || 1, req.session.user.user_id, equipment_type, equipment_model);
    
    res.redirect('/my-requests');
  } catch (error) {
    res.status(500).send('Ошибка: ' + error.message);
  }
});


app.get('/requests/:id', requireAuth, async (req, res) => {
  try {
    const requestId = req.params.id;
    const user = req.session.user;
    
    // Получаем заявку с полной информацией
    const request = db.prepare(`
      SELECT 
        r.*,
        c.full_name as client_name,
        c.phone as client_phone,
        m.full_name as master_name,
        m.phone as master_phone,
        et.type_name,
        em.model_name,
        rs.status_name,
        rs.status_color
      FROM repair_requests r
      JOIN users c ON r.client_id = c.user_id
      LEFT JOIN users m ON r.master_id = m.user_id
      JOIN equipment_types et ON r.type_id = et.type_id
      JOIN equipment_models em ON r.model_id = em.model_id
      JOIN request_statuses rs ON r.status_id = rs.status_id
      WHERE r.request_id = ?
    `).get(requestId);
    
    if (!request) {
      return res.status(404).send('Заявка не найдена');
    }
    
    // Проверяем права доступа
    if (user.user_type.trim() === 'Заказчик' && request.client_id !== user.user_id) {
      return res.status(403).send('Доступ запрещен');
    }
    
    // Получаем комментарии
    const comments = db.prepare(`
      SELECT 
        c.*,
        u.full_name as author_name,
        u.user_type as author_type
      FROM request_comments c
      JOIN users u ON c.user_id = u.user_id
      WHERE c.request_id = ?
      ORDER BY c.created_at ASC
    `).all(requestId);
    
    // Получаем список специалистов для назначения
    const specialists = db.prepare(`
      SELECT user_id, full_name 
      FROM users 
      WHERE user_type = 'Специалист' AND is_active = 1
      ORDER BY full_name
    `).all();
    
    // Получаем статусы
    const statuses = db.prepare('SELECT * FROM request_statuses ORDER BY status_id').all();
    
    // Генерируем QR-код для завершенных заявок
    let qrCodeData = null;
    if (request.status_id === 5) { // Завершена
      const feedbackUrl = `${req.protocol}://${req.get('host')}/quality-rating/${requestId}`;
      qrCodeData = await QRCode.toDataURL(feedbackUrl);
    }
    
    res.render('requests/view', { 
      title: `Заявка ${request.request_number}`,
      request,
      comments,
      specialists,
      statuses,
      qrCodeData
    });
  } catch (error) {
    res.status(500).send('Ошибка: ' + error.message);
  }
});



// API: Получение моделей по типу оборудования
app.get('/api/equipment-models/:typeId', (req, res) => {
  try {
    const models = db.prepare('SELECT * FROM equipment_models WHERE type_id = ? ORDER BY model_name').all(req.params.typeId);
    res.json(models);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: Назначение специалиста
app.post('/api/assign-master', requireAuth, requireRole(['Оператор', 'Менеджер']), (req, res) => {
  try {
    const { request_id, master_id } = req.body;
    
    const stmt = db.prepare(`
      UPDATE repair_requests 
      SET master_id = ?, status_id = 2, updated_at = datetime('now')
      WHERE request_id = ?
    `);
    
    stmt.run(master_id, request_id);
    
    res.json({ success: true, message: 'Специалист назначен успешно' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: Обновление статуса заявки
app.post('/api/update-status', requireAuth, (req, res) => {
  try {
    const { request_id, status_id } = req.body;
    const user = req.session.user;
    
    // Проверяем права на изменение статуса
    const request = db.prepare('SELECT * FROM repair_requests WHERE request_id = ?').get(request_id);
    
    if (!request) {
      return res.status(404).json({ error: 'Заявка не найдена' });
    }
    
    // Специалист может менять статус только своих заявок
    if (user.user_type.trim() === 'Специалист' && request.master_id !== user.user_id) {
      return res.status(403).json({ error: 'Недостаточно прав' });
    }
    
    const stmt = db.prepare(`
      UPDATE repair_requests 
      SET status_id = ?, updated_at = datetime('now')
      WHERE request_id = ?
    `);
    
    stmt.run(status_id, request_id);
    
    res.json({ success: true, message: 'Статус обновлен успешно' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// API: Добавление комментария
app.post('/api/add-comment', requireAuth, (req, res) => {
  try {
    const { request_id, message } = req.body;
    
    const stmt = db.prepare(`
      INSERT INTO request_comments (request_id, user_id, message)
      VALUES (?, ?, ?)
    `);
    
    stmt.run(request_id, req.session.user.user_id, message);
    
    res.json({ success: true, message: 'Комментарий добавлен' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});



// Мои работы (для специалистов)
app.get('/my-work', requireAuth, (req, res) => {
  try {
    const requests = db.prepare(`
      SELECT 
        r.*,
        c.full_name as client_name,
        c.phone as client_phone,
        et.type_name,
        em.model_name,
        rs.status_name,
        rs.status_color
      FROM repair_requests r
      JOIN users c ON r.client_id = c.user_id
      JOIN equipment_types et ON r.type_id = et.type_id
      JOIN equipment_models em ON r.model_id = em.model_id
      JOIN request_statuses rs ON r.status_id = rs.status_id
      WHERE r.master_id = ?
      ORDER BY r.created_at DESC
    `).all(req.session.user.user_id);
    
    res.render('requests/my_work', { 
      title: 'Мои работы',
      requests
    });
  } catch (error) {
    res.status(500).send('Ошибка: ' + error.message);
  }
});

app.get('/reports', requireAuth, RoleAccessManager.requireReportAccess(['Менеджер', 'Менеджер по качеству', 'Администратор', 'Специалист', 'Заказчик']), (req, res) => {
  try {
    const statsService = new StatisticsService();
    const user = req.session.user;
    const userRole = user.user_type.trim();
    
    // Get user-specific filters
    const filters = req.userFilters;
    
    // Get general statistics with role-based filtering
    const generalStats = statsService.calculateGeneralStatistics(filters);
    
    // Get equipment statistics with role-based filtering
    const equipmentStats = statsService.calculateEquipmentStatistics(filters);
    
    // Get status statistics with role-based filtering
    const statusStats = statsService.calculateStatusStatistics(filters);
    
    // Get workshop statistics (only for certain roles)
    let workshopStats = [];
    if (['Менеджер', 'Менеджер по качеству', 'Администратор', 'Специалист'].includes(userRole)) {
      workshopStats = statsService.calculateWorkshopStatistics(filters);
    }
    
    statsService.close();
    
    // Determine report title based on user role
    let reportTitle = 'Отчеты и статистика';
    if (userRole === 'Заказчик') {
      reportTitle = 'Статистика по моим заявкам';
    } else if (userRole === 'Специалист') {
      reportTitle = 'Статистика по моим работам';
    }
    
    res.render('reports', { 
      title: reportTitle,
      userRole: userRole,
      totalRequests: generalStats.totalRequests,
      completedRequests: generalStats.completedRequests,
      activeRequests: generalStats.activeRequests,
      avgCompletionTime: generalStats.avgCompletionTime,
      equipmentStats,
      statusStats,
      workshopStats
    });
  } catch (error) {
    console.error('Reports error:', error);
    res.status(500).render('error', {
      title: 'Ошибка отчетов',
      message: 'Произошла ошибка при генерации отчетов: ' + error.message,
      user: req.session.user
    });
  }
});

// PDF Export route
app.get('/reports/export-pdf', requireAuth, RoleAccessManager.requireReportAccess(['Менеджер', 'Менеджер по качеству', 'Администратор', 'Специалист', 'Заказчик']), async (req, res) => {
  let pdfService = null;
  
  try {
    const statsService = new StatisticsService();
    const user = req.session.user;
    const userRole = user.user_type.trim();
    
    // Get user-specific filters
    const filters = req.userFilters;
    
    // Get all report data with role-based filtering
    const generalStats = statsService.calculateGeneralStatistics(filters);
    const equipmentStats = statsService.calculateEquipmentStatistics(filters);
    const statusStats = statsService.calculateStatusStatistics(filters);
    
    // Get workshop statistics (only for certain roles)
    let workshopStats = [];
    if (['Менеджер', 'Менеджер по качеству', 'Администратор', 'Специалист'].includes(userRole)) {
      workshopStats = statsService.calculateWorkshopStatistics(filters);
    }
    
    statsService.close();
    
    // Prepare data for PDF
    const reportData = {
      totalRequests: generalStats.totalRequests,
      completedRequests: generalStats.completedRequests,
      activeRequests: generalStats.activeRequests,
      avgCompletionTime: generalStats.avgCompletionTime,
      equipmentStats,
      statusStats,
      workshopStats
    };
    
    // Determine report title based on user role
    let reportTitle = 'Отчет системы управления заявками';
    if (userRole === 'Заказчик') {
      reportTitle = 'Отчет по моим заявкам';
    } else if (userRole === 'Специалист') {
      reportTitle = 'Отчет по моим работам';
    }
    
    // Generate PDF
    pdfService = new PDFService();
    const pdfBuffer = await pdfService.generateReportPDF(reportData, reportTitle);
    
    // Set response headers
    const filename = `report_${userRole}_${new Date().toISOString().split('T')[0]}.pdf`;
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.setHeader('Content-Length', pdfBuffer.length);
    
    // Send PDF
    res.send(pdfBuffer);
    
  } catch (error) {
    console.error('PDF generation error:', error);
    res.status(500).render('error', {
      title: 'Ошибка генерации PDF',
      message: 'Произошла ошибка при генерации PDF отчета: ' + error.message,
      user: req.session.user
    });
  } finally {
    if (pdfService) {
      await pdfService.close();
    }
  }
});



// Страница оценки качества
app.get('/quality-rating/:id', (req, res) => {
  try {
    const requestId = req.params.id;
    
    const request = db.prepare(`
      SELECT 
        r.*,
        c.full_name as client_name,
        m.full_name as master_name,
        et.type_name,
        em.model_name
      FROM repair_requests r
      JOIN users c ON r.client_id = c.user_id
      LEFT JOIN users m ON r.master_id = m.user_id
      JOIN equipment_types et ON r.type_id = et.type_id
      JOIN equipment_models em ON r.model_id = em.model_id
      WHERE r.request_id = ? AND r.status_id = 5
    `).get(requestId);
    
    if (!request) {
      return res.render('quality_rating', { 
        title: 'Оценка качества',
        request: null,
        layout: 'base'
      });
    }
    
    // Проверяем, не была ли уже оставлена оценка
    const existingRating = db.prepare('SELECT * FROM quality_ratings WHERE request_id = ?').get(requestId);
    if (existingRating) {
      return res.render('quality_rating', { 
        title: 'Оценка качества',
        request: request,
        success: true,
        layout: 'base'
      });
    }
    
    res.render('quality_rating', { 
      title: 'Оценка качества',
      request: request,
      layout: 'base'
    });
  } catch (error) {
    res.status(500).send('Ошибка: ' + error.message);
  }
});

// Обработка оценки качества
app.post('/quality-rating/:id', (req, res) => {
  try {
    const requestId = req.params.id;
    const { rating, comment } = req.body;
    
    // Проверяем, что заявка существует и завершена
    const request = db.prepare('SELECT * FROM repair_requests WHERE request_id = ? AND status_id = 5').get(requestId);
    if (!request) {
      return res.status(404).send('Заявка не найдена или не завершена');
    }
    
    // Проверяем, не была ли уже оставлена оценка
    const existingRating = db.prepare('SELECT * FROM quality_ratings WHERE request_id = ?').get(requestId);
    if (existingRating) {
      return res.redirect(`/quality-rating/${requestId}`);
    }
    
    // Сохраняем оценку
    const stmt = db.prepare(`
      INSERT INTO quality_ratings (request_id, rating, comment)
      VALUES (?, ?, ?)
    `);
    
    stmt.run(requestId, rating, comment || null);
    
    res.redirect(`/quality-rating/${requestId}`);
  } catch (error) {
    res.status(500).send('Ошибка: ' + error.message);
  }
});

app.listen(PORT, () => {
  console.log('\n' + '='.repeat(70));
  console.log('  СИСТЕМА УЧЕТА ЗАЯВОК НА РЕМОНТ КЛИМАТИЧЕСКОГО ОБОРУДОВАНИЯ');
  console.log('='.repeat(70));
  console.log(`\n  Откройте в браузере: http://localhost:${PORT}`);
  console.log('  Тестовые учетные записи:');
  console.log('     Заказчик: login7 / pass7');
  console.log('     Оператор: login4 / pass4');
  console.log('     Специалист: login2 / pass2');
  console.log('     Менеджер: login1 / pass1');
  console.log('\n  Нажмите Ctrl+C для остановки\n');
});

// Graceful shutdown
process.on('SIGINT', () => {
  db.close();
  console.log('\n\nСервер остановлен');
  process.exit(0);
});