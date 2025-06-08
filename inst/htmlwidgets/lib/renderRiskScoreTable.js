// Render a risk score table from an array of objects (data) and a DOM element (el)
function renderRiskScoreTable(el, data) {
    if (!data || !Array.isArray(data) || data.length === 0) {
        el.innerHTML = '<em>No data to display, sorry!</em>';
        return;
    }
    const columns = Object.keys(data[0]);
    // Combine RiskScore, RiskScoreMax, RiskScoreNormalized into a single column
    let thead = '<thead><tr>' + columns.map(col => {
        if (col === 'RiskScoreNormalized') {
            return `<th style="padding:4px;border:1px solid #ccc;">Risk Score</th>`;
        } else if (col === 'RiskScore' || col === 'RiskScoreMax') {
            return '';
        } else {
            return `<th style="padding:4px;border:1px solid #ccc;">${col}</th>`;
        }
    }).join('') + '</tr></thead>';
    let tbody = '<tbody>' + data.map(row => {
        return '<tr>' + columns.map(col => {
            if (col === 'RiskScoreNormalized') {
                // Compose combined value
                let score = row['RiskScore'] ?? '';
                let max = row['RiskScoreMax'] ?? '';
                let norm = row['RiskScoreNormalized'] ?? '';
                let normVal = norm !== '' ? Math.round(parseFloat(norm) * 10) / 10 : '';
                let combined = `${score} / ${max} (${normVal}%)`;
                // Color scale (same as R)
                const cuts = [2, 4, 6, 8, 10, 12.5, 15, 20, 25];
                const colors = [
                    '#00683777', '#1a985077', '#66bd6377', '#a6d96a77', '#d9ef8b77',
                    '#ffffbf77', '#fee08b77', '#fdae6177', '#f46d4377', '#d7302777'
                ];
                let idx = cuts.findIndex(cut => normVal <= cut);
                if (idx === -1) idx = colors.length - 1;
                let style = `padding:4px;border:1px solid #ccc;background:${colors[idx]};`;
                return `<td style="${style}">${combined}</td>`;
            } else if (col === 'RiskScore' || col === 'RiskScoreMax') {
                return '';
            } else {
                let val = row[col];
                return `<td style="padding:4px;border:1px solid #ccc;">${val == null ? '' : val}</td>`;
            }
        }).join('') + '</tr>';
    }).join('') + '</tbody>';
    // Add sorttable.js if not already loaded
    if (!window.__riskScoreSorttableLoaded) {
        var script = document.createElement('script');
        script.src = 'https://unpkg.com/sortablejs@1.15.0/Sortable.min.js';
        script.onload = function() { window.__riskScoreSorttableLoaded = true; };
        document.head.appendChild(script);
    }
    // Add a class to the table for targeting
    el.innerHTML = `<table class="risk-score-table sortable" style="border-collapse:collapse;width:100%">${thead}${tbody}</table>`;
    // Add timestamp above the risk score table
    const timestamp = new Date().toLocaleString();
    el.innerHTML = `<div style="font-size:0.9em;color:#666;margin-bottom:4px;">Report generated: ${timestamp}</div>` + el.innerHTML;
    // Wait for DOM update, then make sortable
    setTimeout(function() {
        var table = el.querySelector('table.risk-score-table');
        if (table && window.Sortable) {
            // Use Sortable.js to make the table sortable by rows
            // We'll use thead clicks to trigger sort
            let ths = table.querySelectorAll('th');
            ths.forEach((th, colIdx) => {
                th.style.cursor = 'pointer';
                th.addEventListener('click', function() {
                    let rows = Array.from(table.tBodies[0].rows);
                    let asc = th.classList.toggle('asc');
                    ths.forEach(other => { if (other !== th) other.classList.remove('asc'); });
                    rows.sort((a, b) => {
                        let aText = a.cells[colIdx].innerText;
                        let bText = b.cells[colIdx].innerText;
                        let aNum = parseFloat(aText.replace(/[^\d.-]/g, ''));
                        let bNum = parseFloat(bText.replace(/[^\d.-]/g, ''));
                        if (!isNaN(aNum) && !isNaN(bNum)) {
                            return asc ? aNum - bNum : bNum - aNum;
                        }
                        return asc ? aText.localeCompare(bText) : bText.localeCompare(aText);
                    });
                    rows.forEach(row => table.tBodies[0].appendChild(row));
                });
            });
        }
    }, 100);
}
