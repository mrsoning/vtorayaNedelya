const Database = require('better-sqlite3');
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcrypt');

// Создаем базу данных
const db = new Database(path.join(__dirname, 'climate_repair.db'));

console.log('Инициализация базы данных...');

try {
    // Читаем и выполняем схему
    const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
    
    // Разбиваем на отдельные команды и выполняем
    const statements = schema.split(';').filter(stmt => stmt.trim().length > 0);
    
    statements.forEach(statement => {
        try {
            db.exec(statement);
        } catch (error) {
            // Игнорируем ошибки DROP TABLE IF EXISTS
            if (!error.message.includes('no such table')) {
                console.error('Ошибка выполнения SQL:', error.message);
            }
        }
    });
    
    console.log('Схема базы данных создана');
    
    // Добавляем модели оборудования
    const equipmentModels = [
        { name: 'TCL TAC-12CHSA/TPG-W белый', type_id: 1, manufacturer: 'TCL' },
        { name: 'Electrolux EACS/I-09HAT/N3_21Y белый', type_id: 1, manufacturer: 'Electrolux' },
        { name: 'Xiaomi Smart Humidifier 2', type_id: 2, manufacturer: 'Xiaomi' },
        { name: 'Polaris PUH 2300 WIFI IQ Home', type_id: 2, manufacturer: 'Polaris' },
        { name: 'Ballu BAHD-1250', type_id: 3, manufacturer: 'Ballu' }
    ];
    
    const insertModel = db.prepare(`
        INSERT INTO equipment_models (model_name, type_id, manufacturer) 
        VALUES (?, ?, ?)
    `);
    
    equipmentModels.forEach(model => {
        insertModel.run(model.name, model.type_id, model.manufacturer);
    });
    
    console.log('Модели оборудования добавлены');
    
    // Загружаем данные из CSV файлов
    loadDataFromCSV();
    
    console.log('База данных успешно инициализирована!');
    
} catch (error) {
    console.error('Ошибка инициализации:', error.message);
} finally {
    db.close();
}

function loadDataFromCSV() {
    const csvPath = path.join(__dirname, '../../Ресурсы/Кондиционеры_данные');
    
    try {
        // Загружаем пользователей
        const usersCSV = fs.readFileSync(path.join(csvPath, 'Пользователи/inputDataUsers.csv'), 'utf8');
        const usersLines = usersCSV.split('\n').slice(1); // Пропускаем заголовок
        
        const insertUser = db.prepare(`
            INSERT INTO users (full_name, phone, login, password_hash, user_type) 
            VALUES (?, ?, ?, ?, ?)
        `);
        
        let userCount = 0;
        usersLines.forEach(line => {
            if (line.trim()) {
                const [userID, fio, phone, login, password, type] = line.split(';');
                const passwordHash = bcrypt.hashSync(password, 10);
                
                insertUser.run(fio, phone, login, passwordHash, type);
                userCount++;
            }
        });
        
        console.log(`Загружено ${userCount} пользователей`);
        
        // Загружаем заявки
        const requestsCSV = fs.readFileSync(path.join(csvPath, 'Заявки/inputDataRequests.csv'), 'utf8');
        const requestsLines = requestsCSV.split('\n').slice(1);
        
        const insertRequest = db.prepare(`
            INSERT INTO repair_requests (
                request_number, start_date, problem_description, repair_parts,
                client_id, master_id, status_id, type_id, model_id, completion_date
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `);
        
        let requestCount = 0;
        requestsLines.forEach(line => {
            if (line.trim()) {
                const [requestID, startDate, climateTechType, climateTechModel, problemDescription, requestStatus, completionDate, repairParts, masterID, clientID] = line.split(';');
                
                // Определяем тип оборудования
                const typeMap = {
                    'Кондиционер': 1,
                    'Увлажнитель воздуха': 2,
                    'Сушилка для рук': 3
                };
                const typeId = typeMap[climateTechType] || 1;
                
                // Находим или создаем модель
                let modelId = 1;
                const existingModel = db.prepare('SELECT model_id FROM equipment_models WHERE model_name = ?').get(climateTechModel);
                if (existingModel) {
                    modelId = existingModel.model_id;
                } else {
                    const newModel = db.prepare('INSERT INTO equipment_models (model_name, type_id) VALUES (?, ?)').run(climateTechModel, typeId);
                    modelId = newModel.lastInsertRowid;
                }
                
                // Определяем статус
                const statusMap = {
                    'Новая заявка': 1,
                    'В процессе ремонта': 2,
                    'Готова к выдаче': 4,
                    'Завершена': 5
                };
                const statusId = statusMap[requestStatus] || 1;
                
                const requestNumber = `REQ-${String(requestID).padStart(6, '0')}`;
                const completionDateValue = (completionDate && completionDate !== 'null') ? completionDate : null;
                const masterIdValue = (masterID && masterID !== 'null') ? masterID : null;
                
                insertRequest.run(
                    requestNumber, startDate, problemDescription, repairParts,
                    clientID, masterIdValue, statusId, typeId, modelId, completionDateValue
                );
                requestCount++;
            }
        });
        
        console.log(`Загружено ${requestCount} заявок`);
        
        // Загружаем комментарии
        const commentsCSV = fs.readFileSync(path.join(csvPath, 'Комментарии/inputDataComments.csv'), 'utf8');
        const commentsLines = commentsCSV.split('\n').slice(1);
        
        const insertComment = db.prepare(`
            INSERT INTO request_comments (message, request_id, user_id) 
            VALUES (?, ?, ?)
        `);
        
        let commentCount = 0;
        commentsLines.forEach(line => {
            if (line.trim()) {
                const [commentID, message, masterID, requestID] = line.split(';');
                
                insertComment.run(message, requestID, masterID);
                commentCount++;
            }
        });
        
        console.log(`Загружено ${commentCount} комментариев`);
        
        // Создаем таблицу оценок качества если её нет
        db.exec(`
            CREATE TABLE IF NOT EXISTS quality_ratings (
                rating_id INTEGER PRIMARY KEY AUTOINCREMENT,
                request_id INTEGER NOT NULL,
                rating VARCHAR(20) NOT NULL CHECK (rating IN ('Хорошо', 'Нормально', 'Плохо')),
                comment TEXT,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                
                FOREIGN KEY (request_id) REFERENCES repair_requests(request_id) ON DELETE CASCADE
            )
        `);
        
        console.log('Таблица оценок качества создана');
        
    } catch (error) {
        console.error('Ошибка загрузки данных из CSV:', error.message);
        console.log('Создаем тестовых пользователей напрямую...');
        
        // Создаем тестовых пользователей
        const bcrypt = require('bcrypt');
        const insertUser = db.prepare(`
            INSERT INTO users (full_name, phone, login, password_hash, user_type)
            VALUES (?, ?, ?, ?, ?)
        `);
        
        const testUsers = [
            ['Широков Василий Матвеевич', '89215567841', 'login1', 'pass1', 'Менеджер'],
            ['Кудрявцева Ева Ивановна', '89215567842', 'login2', 'pass2', 'Специалист'],
            ['Гончарова Ульяна Ярославовна', '89215567843', 'login3', 'pass3', 'Специалист'],
            ['Гусева Виктория Данииловна', '89215567844', 'login4', 'pass4', 'Оператор'],
            ['Баранов Артём Юрьевич', '89215567845', 'login5', 'pass5', 'Оператор'],
            ['Менеджер по качеству', '89215567846', 'login6', 'pass6', 'Менеджер по качеству'],
            ['Петров Никита Артёмович', '89215567847', 'login7', 'pass7', 'Заказчик'],
            ['Ковалева Софья Владимировна', '89215567848', 'login8', 'pass8', 'Заказчик']
        ];
        
        testUsers.forEach(([fullName, phone, login, password, userType]) => {
            const hashedPassword = bcrypt.hashSync(password, 10);
            insertUser.run(fullName, phone, login, hashedPassword, userType);
        });
        
        console.log(`Создано ${testUsers.length} тестовых пользователей`);
        
        // Создаем тестовые заявки
        const insertRequest = db.prepare(`
            INSERT INTO repair_requests (
                request_number, start_date, problem_description, 
                client_id, status_id, type_id, model_id, completion_date
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `);
        
        const testRequests = [
            ['REQ-000001', '2025-12-01', 'Не включается кондиционер', 7, 5, 1, 1, '2025-12-05'],
            ['REQ-000002', '2025-12-02', 'Слабо дует увлажнитель', 8, 2, 2, 2, null],
            ['REQ-000003', '2025-12-03', 'Шумит сушилка для рук', 7, 1, 3, 3, null],
            ['REQ-000004', '2025-12-04', 'Течет кондиционер', 8, 3, 1, 1, null],
            ['REQ-000005', '2025-12-05', 'Не работает пульт', 7, 4, 1, 1, null]
        ];
        
        testRequests.forEach(([number, date, problem, clientId, statusId, typeId, modelId, completion]) => {
            insertRequest.run(number, date, problem, clientId, statusId, typeId, modelId, completion);
        });
        
        console.log(`Создано ${testRequests.length} тестовых заявок`);
    }
}