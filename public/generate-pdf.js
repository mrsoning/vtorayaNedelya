/**
 * Генерация PDF из HTML через браузер
 * Использует window.print() API
 */

function generateDiagramPDF() {
    // Открываем диаграмму в новом окне
    const diagramWindow = window.open('/diagrams/ER_diagram.html', '_blank');
    
    // Ждем загрузки и запускаем печать
    diagramWindow.onload = function() {
        setTimeout(function() {
            diagramWindow.print();
        }, 500);
    };
}

function generateReportPDF() {
    // Открываем отчет в новом окне для печати
    window.open('/report-pdf', '_blank');
}

// Добавляем стили для печати
const printStyles = `
@media print {
    body {
        margin: 0;
        padding: 20px;
    }
    
    .no-print {
        display: none !important;
    }
    
    @page {
        size: A4;
        margin: 15mm;
    }
}
`;

// Добавляем стили в документ
const styleSheet = document.createElement('style');
styleSheet.textContent = printStyles;
document.head.appendChild(styleSheet);
