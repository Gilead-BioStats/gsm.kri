// Render a risk score table from an array of objects (data) and a DOM element (el)
function renderRiskScoreTable(el, data) {
    if (!data || !Array.isArray(data) || data.length === 0) {
        el.innerHTML = '<em>No data to display, sorry!</em>';
        return;
    }
    const columns = Object.keys(data[0]);
    // Use only columns present in dfRiskScores_Wide (which includes the renamed columns)
    // These are: StudyID, SnapshotDate, GroupID, GroupLevel, 'Risk Score', 'Raw Risk Score', 'Max Risk Score', and all Label_* columns
    const groupCols = ['StudyID', 'SnapshotDate', 'GroupID', 'GroupLevel'];
    const mainScoreCols = ['Risk Score', 'Raw Risk Score', 'Max Risk Score'];
    const labelCols = columns.filter(col => col.startsWith('Label_'));
    const displayCols = groupCols.filter(col => columns.includes(col))
        .concat(mainScoreCols.filter(col => columns.includes(col)))
        .concat(labelCols);

    let thead = '<thead><tr>' + displayCols.map(col => {
        if (col.startsWith('Label_')) {
            return `<th style="padding:4px;border:1px solid #ccc;">${col.replace('Label_', '')}</th>`;
        } else {
            return `<th style="padding:4px;border:1px solid #ccc;">${col}</th>`;
        }
    }).join('') + '</tr></thead>';

    let tbody = '<tbody>' + data.map(row => {
        return '<tr>' + displayCols.map(col => {
            let val = row[col];
            // Round 'Risk Score' to 1 decimal place if numeric
            if (col === 'Risk Score' && val != null && !isNaN(val)) {
                val = Math.round(parseFloat(val) * 10) / 10;
            }
            // Prevent line breaks between <svg> and <sup> in label columns using CSS
            if (col.startsWith('Label_') && typeof val === 'string') {
                val = `<span style="white-space:nowrap;">${val}</span>`;
            }
            return `<td style="padding:4px;border:1px solid #ccc;">${val == null ? '' : val}</td>`;
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
