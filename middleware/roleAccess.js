/**
 * Role Access Middleware for Reports
 * Provides role-based access control and data filtering for reports
 */

class RoleAccessManager {
  /**
   * Check if user has access to specific report type
   * @param {string} userRole - User's role
   * @param {string} reportType - Type of report being accessed
   * @returns {boolean} - Whether user has access
   */
  static checkReportAccess(userRole, reportType) {
    const rolePermissions = {
      'Администратор': ['general', 'equipment', 'status', 'workshop', 'product', 'system'],
      'Менеджер': ['general', 'equipment', 'status', 'workshop', 'product'],
      'Менеджер по качеству': ['general', 'equipment', 'status', 'workshop', 'product'],
      'Специалист': ['personal'],
      'Заказчик': ['personal'],
      'Оператор': ['general', 'equipment', 'status']
    };

    const userPermissions = rolePermissions[userRole.trim()] || [];
    return userPermissions.includes(reportType);
  }

  /**
   * Get data filters based on user role
   * @param {Object} user - User object with user_id and user_type
   * @returns {Object} - Filter conditions for database queries
   */
  static getDataFilters(user) {
    const userRole = user.user_type.trim();
    
    switch (userRole) {
      case 'Заказчик':
        return {
          type: 'client',
          userId: user.user_id,
          whereClause: 'WHERE r.client_id = ?',
          params: [user.user_id]
        };
        
      case 'Специалист':
        return {
          type: 'master',
          userId: user.user_id,
          whereClause: 'WHERE r.master_id = ?',
          params: [user.user_id]
        };
        
      case 'Менеджер':
      case 'Менеджер по качеству':
      case 'Администратор':
      case 'Оператор':
        return {
          type: 'full',
          userId: null,
          whereClause: '',
          params: []
        };
        
      default:
        return {
          type: 'none',
          userId: null,
          whereClause: 'WHERE 1 = 0', // No access
          params: []
        };
    }
  }

  /**
   * Middleware function to check report access
   * @param {Array} allowedRoles - Array of roles allowed to access the report
   * @returns {Function} - Express middleware function
   */
  static requireReportAccess(allowedRoles = []) {
    return (req, res, next) => {
      if (!req.session.user) {
        return res.status(401).render('error', {
          title: 'Требуется авторизация',
          message: 'Для доступа к отчетам необходимо войти в систему',
          user: null
        });
      }

      const userRole = req.session.user.user_type.trim();
      
      if (allowedRoles.length > 0 && !allowedRoles.includes(userRole)) {
        return res.status(403).render('error', {
          title: 'Доступ запрещен',
          message: `У пользователей с ролью "${userRole}" нет доступа к данному разделу отчетов. Обратитесь к администратору для получения необходимых прав.`,
          user: req.session.user
        });
      }

      // Add user filters to request for use in route handlers
      req.userFilters = RoleAccessManager.getDataFilters(req.session.user);
      next();
    };
  }

  /**
   * Get user-specific data based on role
   * @param {Object} user - User object
   * @param {Object} db - Database connection
   * @returns {Object} - User-specific statistics
   */
  static getUserSpecificData(user, db) {
    const userRole = user.user_type.trim();
    
    try {
      switch (userRole) {
        case 'Заказчик':
          return {
            title: 'Мои заявки',
            totalRequests: db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE client_id = ?').get(user.user_id).count,
            activeRequests: db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE client_id = ? AND status_id IN (1, 2, 3)').get(user.user_id).count,
            completedRequests: db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE client_id = ? AND status_id = 5').get(user.user_id).count
          };
          
        case 'Специалист':
          return {
            title: 'Мои работы',
            totalRequests: db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE master_id = ?').get(user.user_id).count,
            activeRequests: db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE master_id = ? AND status_id IN (2, 3)').get(user.user_id).count,
            completedRequests: db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE master_id = ? AND status_id = 5').get(user.user_id).count
          };
          
        default:
          return {
            title: 'Общая статистика',
            totalRequests: db.prepare('SELECT COUNT(*) as count FROM repair_requests').get().count,
            activeRequests: db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE status_id IN (1, 2, 3)').get().count,
            completedRequests: db.prepare('SELECT COUNT(*) as count FROM repair_requests WHERE status_id = 5').get().count
          };
      }
    } catch (error) {
      throw new Error(`Failed to get user-specific data: ${error.message}`);
    }
  }
}

module.exports = RoleAccessManager;