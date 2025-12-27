const Database = require('better-sqlite3');
const path = require('path');

class StatisticsService {
  constructor(dbPath = null) {
    this.db = dbPath ? new Database(dbPath) : new Database(path.join(__dirname, '..', 'database', 'climate_repair.db'));
  }

  /**
   * Calculates general statistics for repair requests
   * @param {Object} filters - Optional filters for role-based access
   * @returns {Object} Statistics object with total, active, completed counts and average completion time
   */
  calculateGeneralStatistics(filters = null) {
    try {
      let whereClause = '';
      let params = [];
      
      if (filters && filters.whereClause) {
        whereClause = filters.whereClause;
        params = filters.params;
      }
      
      // Build base query with alias
      const baseQuery = 'SELECT COUNT(*) as count FROM repair_requests r';
      
      // Total requests count
      const totalQuery = whereClause ? `${baseQuery} ${whereClause}` : baseQuery;
      const totalRequests = this.db.prepare(totalQuery).get(...params).count;
      
      // Active requests count (status_id IN (1, 2, 3))
      const activeQuery = whereClause 
        ? `${baseQuery} ${whereClause} AND r.status_id IN (1, 2, 3)`
        : `${baseQuery} WHERE r.status_id IN (1, 2, 3)`;
      const activeRequests = this.db.prepare(activeQuery).get(...params).count;
      
      // Completed requests count (status_id = 5)
      const completedQuery = whereClause
        ? `${baseQuery} ${whereClause} AND r.status_id = 5`
        : `${baseQuery} WHERE r.status_id = 5`;
      const completedRequests = this.db.prepare(completedQuery).get(...params).count;
      
      // Average completion time calculation
      const avgTimeQuery = whereClause
        ? `SELECT AVG(julianday(r.completion_date) - julianday(r.start_date)) as avg_days
           FROM repair_requests r 
           ${whereClause} AND r.completion_date IS NOT NULL AND r.status_id = 5`
        : `SELECT AVG(julianday(completion_date) - julianday(start_date)) as avg_days
           FROM repair_requests 
           WHERE completion_date IS NOT NULL AND status_id = 5`;
      
      const avgTime = this.db.prepare(avgTimeQuery).get(...params);
      const avgCompletionTime = avgTime.avg_days ? Math.round(avgTime.avg_days * 10) / 10 : 0;
      
      return {
        totalRequests,
        activeRequests,
        completedRequests,
        avgCompletionTime
      };
    } catch (error) {
      throw new Error(`Statistics calculation failed: ${error.message}`);
    }
  }

  /**
   * Calculates statistics by equipment types
   * @param {Object} filters - Optional filters for role-based access
   * @returns {Array} Array of equipment statistics with type name and count
   */
  calculateEquipmentStatistics(filters = null) {
    try {
      let joinClause = 'LEFT JOIN repair_requests r ON et.type_id = r.type_id';
      let whereClause = '';
      let params = [];
      
      if (filters && filters.whereClause) {
        whereClause = filters.whereClause;
        params = filters.params;
      }
      
      const query = `
        SELECT 
          et.type_name,
          COUNT(r.request_id) as count
        FROM equipment_types et
        ${joinClause}
        ${whereClause}
        GROUP BY et.type_id, et.type_name
        ORDER BY count DESC
      `;
      
      const equipmentStats = this.db.prepare(query).all(...params);
      return equipmentStats;
    } catch (error) {
      throw new Error(`Equipment statistics calculation failed: ${error.message}`);
    }
  }

  /**
   * Calculates statistics by request statuses
   * @param {Object} filters - Optional filters for role-based access
   * @returns {Array} Array of status statistics with status name, color and count
   */
  calculateStatusStatistics(filters = null) {
    try {
      let joinClause = 'LEFT JOIN repair_requests r ON rs.status_id = r.status_id';
      let whereClause = '';
      let params = [];
      
      if (filters && filters.whereClause) {
        whereClause = filters.whereClause;
        params = filters.params;
      }
      
      const query = `
        SELECT 
          rs.status_name,
          rs.status_color,
          COUNT(r.request_id) as count
        FROM request_statuses rs
        ${joinClause}
        ${whereClause}
        GROUP BY rs.status_id, rs.status_name, rs.status_color
        ORDER BY count DESC
      `;
      
      const statusStats = this.db.prepare(query).all(...params);
      return statusStats;
    } catch (error) {
      throw new Error(`Status statistics calculation failed: ${error.message}`);
    }
  }

  /**
   * Calculates statistics by specialists (masters)
   * @param {Object} filters - Optional filters for role-based access
   * @returns {Array} Array of specialist statistics with name, assigned count, completed count, completion rate and average time
   */
  calculateWorkshopStatistics(filters = null) {
    try {
      let whereClause = '';
      let params = [];
      
      if (filters && filters.whereClause) {
        // For specialist statistics, we need to modify the filter to work with master_id
        if (filters.type === 'master') {
          whereClause = 'WHERE m.user_id = ?';
          params = filters.params;
        } else if (filters.type === 'client') {
          // Clients can't see workshop stats, return empty
          return [];
        }
        // For full access, no additional where clause needed
      }
      
      const query = `
        SELECT 
          m.user_id as workshop_id,
          m.full_name as workshop_name,
          COUNT(r.request_id) as assigned_count,
          COUNT(CASE WHEN r.status_id = 5 THEN 1 END) as completed_count,
          CASE 
            WHEN COUNT(r.request_id) > 0 
            THEN ROUND((COUNT(CASE WHEN r.status_id = 5 THEN 1 END) * 100.0) / COUNT(r.request_id), 1)
            ELSE 0 
          END as completion_rate,
          CASE 
            WHEN COUNT(CASE WHEN r.completion_date IS NOT NULL AND r.status_id = 5 THEN 1 END) > 0
            THEN ROUND(AVG(CASE 
              WHEN r.completion_date IS NOT NULL AND r.status_id = 5 
              THEN julianday(r.completion_date) - julianday(r.start_date)
            END), 1)
            ELSE 0 
          END as avg_time
        FROM users m
        LEFT JOIN repair_requests r ON m.user_id = r.master_id
        WHERE m.user_type = 'Специалист' AND m.is_active = 1
        ${whereClause ? 'AND ' + whereClause.replace('WHERE ', '') : ''}
        GROUP BY m.user_id, m.full_name
        ORDER BY assigned_count DESC
      `;
      
      const workshopStats = this.db.prepare(query).all(...params);
      return workshopStats;
    } catch (error) {
      throw new Error(`Workshop statistics calculation failed: ${error.message}`);
    }
  }

  /**
   * Closes the database connection
   */
  close() {
    if (this.db) {
      this.db.close();
    }
  }
}

module.exports = StatisticsService;