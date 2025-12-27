const puppeteer = require('puppeteer');
const path = require('path');

class PDFService {
  constructor() {
    this.browser = null;
  }

  async initBrowser() {
    if (!this.browser) {
      this.browser = await puppeteer.launch({
        headless: 'new',
        args: ['--no-sandbox', '--disable-setuid-sandbox']
      });
    }
    return this.browser;
  }

  async generateReportPDF(reportData, reportTitle = 'Отчет системы') {
    const browser = await this.initBrowser();
    const page = await browser.newPage();

    // Format data for PDF
    const formattedData = this.formatReportData(reportData);
    
    // Generate HTML content
    const htmlContent = this.generateHTMLContent(formattedData, reportTitle);
    
    // Set content and generate PDF
    await page.setContent(htmlContent, { waitUntil: 'networkidle0' });
    
    const pdfBuffer = await page.pdf({
      format: 'A4',
      printBackground: true,
      margin: {
        top: '20mm',
        right: '15mm',
        bottom: '20mm',
        left: '15mm'
      }
    });

    await page.close();
    return pdfBuffer;
  }

  formatReportData(data) {
    const currentDate = new Date();
    
    return {
      ...data,
      generatedAt: currentDate.toLocaleDateString('ru-RU', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      }),
      generatedDate: currentDate.toLocaleDateString('ru-RU')
    };
  }

  generateHTMLContent(data, title) {
    return `
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
    <style>
        body {
            font-family: 'DejaVu Sans', Arial, sans-serif;
            margin: 0;
            padding: 20px;
            color: #333;
            line-height: 1.6;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
            border-bottom: 2px solid #2c3e50;
            padding-bottom: 20px;
        }
        
        .header h1 {
            color: #2c3e50;
            margin: 0;
            font-size: 24px;
        }
        
        .header .subtitle {
            color: #7f8c8d;
            margin: 5px 0;
            font-size: 14px;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
            border: 1px solid #e9ecef;
        }
        
        .stat-card h3 {
            font-size: 28px;
            margin: 0;
            color: #2c3e50;
        }
        
        .stat-card p {
            margin: 5px 0 0 0;
            color: #6c757d;
            font-size: 14px;
        }
        
        .section {
            margin-bottom: 30px;
            page-break-inside: avoid;
        }
        
        .section h2 {
            color: #2c3e50;
            border-bottom: 1px solid #bdc3c7;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        th {
            background-color: #f8f9fa;
            font-weight: bold;
            color: #2c3e50;
        }
        
        tr:nth-child(even) {
            background-color: #f8f9fa;
        }
        
        .badge {
            padding: 4px 8px;
            border-radius: 4px;
            color: white;
            font-size: 12px;
            font-weight: bold;
        }
        
        .footer {
            margin-top: 40px;
            text-align: center;
            font-size: 12px;
            color: #7f8c8d;
            border-top: 1px solid #bdc3c7;
            padding-top: 20px;
        }
        
        @media print {
            .stats-grid {
                grid-template-columns: repeat(2, 1fr);
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>${title}</h1>
        <div class="subtitle">Система управления заявками на ремонт климатического оборудования</div>
        <div class="subtitle">Сгенерировано: ${data.generatedAt}</div>
    </div>

    <div class="stats-grid">
        <div class="stat-card">
            <h3>${data.totalRequests || 0}</h3>
            <p>Всего заявок</p>
        </div>
        <div class="stat-card">
            <h3>${data.activeRequests || 0}</h3>
            <p>В работе</p>
        </div>
        <div class="stat-card">
            <h3>${data.completedRequests || 0}</h3>
            <p>Завершено</p>
        </div>
        <div class="stat-card">
            <h3>${data.avgCompletionTime || 0}</h3>
            <p>Среднее время (дни)</p>
        </div>
    </div>

    ${data.equipmentStats && data.equipmentStats.length > 0 ? `
    <div class="section">
        <h2>Статистика по типам оборудования</h2>
        <table>
            <thead>
                <tr>
                    <th>Тип оборудования</th>
                    <th>Количество заявок</th>
                    <th>Процент</th>
                </tr>
            </thead>
            <tbody>
                ${data.equipmentStats.map(stat => `
                <tr>
                    <td>${stat.type_name}</td>
                    <td>${stat.count}</td>
                    <td>${data.totalRequests > 0 ? Math.round((stat.count / data.totalRequests) * 100) : 0}%</td>
                </tr>
                `).join('')}
            </tbody>
        </table>
    </div>
    ` : ''}

    ${data.statusStats && data.statusStats.length > 0 ? `
    <div class="section">
        <h2>Статистика по статусам заявок</h2>
        <table>
            <thead>
                <tr>
                    <th>Статус</th>
                    <th>Количество</th>
                    <th>Процент</th>
                </tr>
            </thead>
            <tbody>
                ${data.statusStats.map(stat => `
                <tr>
                    <td>
                        <span class="badge" style="background-color: ${stat.status_color};">
                            ${stat.status_name}
                        </span>
                    </td>
                    <td>${stat.count}</td>
                    <td>${data.totalRequests > 0 ? Math.round((stat.count / data.totalRequests) * 100) : 0}%</td>
                </tr>
                `).join('')}
            </tbody>
        </table>
    </div>
    ` : ''}

    ${data.workshopStats && data.workshopStats.length > 0 ? `
    <div class="section">
        <h2>Статистика по мастерским</h2>
        <table>
            <thead>
                <tr>
                    <th>Мастерская</th>
                    <th>Назначено</th>
                    <th>Завершено</th>
                    <th>Процент выполнения</th>
                    <th>Среднее время (дни)</th>
                </tr>
            </thead>
            <tbody>
                ${data.workshopStats.map(stat => `
                <tr>
                    <td>${stat.workshop_name}</td>
                    <td>${stat.assigned_count}</td>
                    <td>${stat.completed_count}</td>
                    <td>${stat.completion_rate}%</td>
                    <td>${stat.avg_time}</td>
                </tr>
                `).join('')}
            </tbody>
        </table>
    </div>
    ` : ''}

    <div class="footer">
        <p>Отчет сгенерирован автоматически системой управления заявками</p>
        <p>Дата генерации: ${data.generatedDate}</p>
    </div>
</body>
</html>
    `;
  }

  async close() {
    if (this.browser) {
      await this.browser.close();
      this.browser = null;
    }
  }
}

module.exports = PDFService;