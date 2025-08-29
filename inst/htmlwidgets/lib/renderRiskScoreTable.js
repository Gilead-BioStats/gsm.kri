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
    let displayCols = groupCols.filter(col => columns.includes(col))
        .concat(mainScoreCols.filter(col => columns.includes(col)))
        .concat(labelCols);
 

    let thead = '<thead><tr>' + displayCols.map(col => {
        if (col.startsWith('Label_')) {
            return `<th style="padding:4px;border:1px solid #ccc;">${col.replace('Label_', '')}</th>`;
        } else {
            return `<th style="padding:4px;border:1px solid #ccc;">${col}</th>`;
        }
    }).join('') + '</tr></thead>';

    // Move studyIDs declaration here, before it is used
    const studyIDs = [...new Set(data.map(row => row.StudyID))];

    // Compute summary rows (overall) for each GroupID if more than one StudyID
    let summaryRows = [];
    let detailRows = [];
    if (studyIDs.length > 1 && data.length > 0) {
        const groupIDs = [...new Set(data.map(row => row.GroupID))];
        groupIDs.forEach(groupID => {
            const groupRows = data.filter(row => row.GroupID === groupID);
            if (groupRows.length > 0) {
                // Compute mean for each numeric main score column
                const meanScores = {};
                mainScoreCols.forEach(col => {
                    const vals = groupRows.map(row => parseFloat(row[col])).filter(v => !isNaN(v));
                    meanScores[col] = vals.length ? (Math.round((vals.reduce((a, b) => a + b, 0) / vals.length) * 10) / 10) : '';
                });
                // Compute mean for each metric label column (from <sup>value</sup>)
                const meanMetricSup = {};
                labelCols.forEach(col => {
                    // Extract <sup>value</sup> from each row[col]
                    const supVals = groupRows.map(row => {
                        const val = row[col];
                        if (typeof val === 'string') {
                            const match = val.match(/<sup>([\d.\-eE]+)<\/sup>/);
                            if (match) return parseFloat(match[1]);
                        }
                        return NaN;
                    }).filter(v => !isNaN(v));
                    meanMetricSup[col] = supVals.length ? (Math.round((supVals.reduce((a, b) => a + b, 0) / supVals.length) * 10) / 10) : '';
                });
                // Compute nStudies for the group
                const nStudies = new Set(groupRows.map(row => row.StudyID)).size;
                // Build summary row
                const summaryRow = {};
                groupCols.forEach(col => {
                    if (col === 'GroupID') summaryRow[col] = groupID;
                    else if (col === 'StudyID') summaryRow[col] = `Overall (N=${nStudies})`;
                    else summaryRow[col] = 'Overall';
                });
                if (displayCols.includes('nStudies')) {
                    summaryRow['nStudies'] = nStudies;
                }
                mainScoreCols.forEach(col => { summaryRow[col] = meanScores[col]; });
                // For label columns, show mean in <sup>...</sup> (no icon)
                labelCols.forEach(col => {
                    summaryRow[col] = meanMetricSup[col] !== '' ? `<sup>${meanMetricSup[col]}</sup>` : '';
                });
                summaryRow.__isOverall = true;
                summaryRows.push(summaryRow);
                // Add detail rows for this group
                groupRows.forEach(row => {
                    let detailRow = { ...row, __isDetail: true, __groupID: groupID };
                    detailRows.push(detailRow);
                });
            }
        });
    }

    // Compose rows: overall first, then details (hidden by default)
    let tbody = '<tbody>';
    if (summaryRows.length > 0) {
        summaryRows.forEach(summaryRow => {
            tbody += '<tr class="overall-row" style="font-weight:bold;background:#f5f5f5;cursor:pointer;">' + displayCols.map(col => {
                let val = summaryRow[col];
                if (col === 'Risk Score' && val != null && !isNaN(val)) {
                    val = Math.round(parseFloat(val) * 10) / 10;
                }
                return `<td style="padding:4px;border:1px solid #ccc;">${val == null ? '' : val}</td>`;
            }).join('') + '</tr>';
            // Add detail rows for this group, hidden by default
            detailRows.filter(r => r.GroupID === summaryRow.GroupID).forEach(row => {
                tbody += '<tr class="detail-row" data-group="' + summaryRow.GroupID + '" style="display:none;">' + displayCols.map(col => {
                    let val = row[col];
                    // Round 'Risk Score' to 1 decimal place if numeric
                    if (col === 'Risk Score' && val != null && !isNaN(val)) {
                        val = Math.round(parseFloat(val) * 10) / 10;
                    }
                    // Prevent line breaks between <svg> and <sup> in label columns using CSS
                    let tdAttrs = '';
                    if (col.startsWith('Label_') && typeof val === 'string') {
                        val = `<span style="white-space:nowrap;">${val}</span>`;
                        // Find corresponding _Details column
                        const detailsCol = col.replace('Label_', 'Details_');
                        if (detailsCol in row && row[detailsCol]) {
                            tdAttrs = ` title="${String(row[detailsCol]).replace(/"/g, '&quot;')}"`;
                        }
                    }
                    return `<td style="padding:4px;border:1px solid #ccc;"${tdAttrs}>${val == null ? '' : val}</td>`;
                }).join('') + '</tr>';
            });
        });
    } else {
        // Fallback: just show all rows as before
        tbody += data.map(row => {
            return '<tr>' + displayCols.map(col => {
                let val = row[col];
                // Round 'Risk Score' to 1 decimal place if numeric
                if (col === 'Risk Score' && val != null && !isNaN(val)) {
                    val = Math.round(parseFloat(val) * 10) / 10;
                }
                // Prevent line breaks between <svg> and <sup> in label columns using CSS
                let tdAttrs = '';
                if (col.startsWith('Label_') && typeof val === 'string') {
                    val = `<span style="white-space:nowrap;">${val}</span>`;
                    // Find corresponding _Details column
                    const detailsCol = col.replace('Label_', 'Details_');
                    if (detailsCol in row && row[detailsCol]) {
                        tdAttrs = ` title="${String(row[detailsCol]).replace(/"/g, '&quot;')}"`;
                    }
                }
                return `<td style="padding:4px;border:1px solid #ccc;"${tdAttrs}>${val == null ? '' : val}</td>`;
            }).join('') + '</tr>';
        }).join('');
    }
    tbody += '</tbody>';

    // If more than one StudyID, add a summary row for each GroupID with mean Risk Score and nStudies
    if (studyIDs.length > 1 && data.length > 0) {
        const groupIDs = [...new Set(data.map(row => row.GroupID))];
        groupIDs.forEach(groupID => {
            const groupRows = data.filter(row => row.GroupID === groupID);
            if (groupRows.length > 0) {
                // Compute mean for each numeric main score column
                const meanScores = {};
                mainScoreCols.forEach(col => {
                    const vals = groupRows.map(row => parseFloat(row[col])).filter(v => !isNaN(v));
                    meanScores[col] = vals.length ? (Math.round((vals.reduce((a, b) => a + b, 0) / vals.length) * 10) / 10) : '';
                });
                // Compute mean for each metric label column (from <sup>value</sup>)
                const meanMetricSup = {};
                labelCols.forEach(col => {
                    // Extract <sup>value</sup> from each row[col]
                    const supVals = groupRows.map(row => {
                        const val = row[col];
                        if (typeof val === 'string') {
                            const match = val.match(/<sup>([\d.\-eE]+)<\/sup>/);
                            if (match) return parseFloat(match[1]);
                        }
                        return NaN;
                    }).filter(v => !isNaN(v));
                    meanMetricSup[col] = supVals.length ? (Math.round((supVals.reduce((a, b) => a + b, 0) / supVals.length) * 10) / 10) : '';
                });
                // Compute nStudies for the group
                const nStudies = new Set(groupRows.map(row => row.StudyID)).size;
                // Build summary row
                const summaryRow = {};
                groupCols.forEach(col => {
                    if (col === 'GroupID') summaryRow[col] = groupID;
                    else if (col === 'StudyID') summaryRow[col] = `Overall (N=${nStudies})`;
                    else summaryRow[col] = 'Overall';
                });
                if (displayCols.includes('nStudies')) {
                    summaryRow['nStudies'] = nStudies;
                }
                mainScoreCols.forEach(col => { summaryRow[col] = meanScores[col]; });
                // For label columns, show mean in <sup>...</sup> (no icon)
                labelCols.forEach(col => {
                    summaryRow[col] = meanMetricSup[col] !== '' ? `<sup>${meanMetricSup[col]}</sup>` : '';
                });
                summaryRow.__isOverall = true;
                summaryRows.push(summaryRow);
                // Add detail rows for this group
                groupRows.forEach(row => {
                    let detailRow = { ...row, __isDetail: true, __groupID: groupID };
                    detailRows.push(detailRow);
                });
            }
        });
    }

    // Add a class to the table for targeting
    el.innerHTML = `<table class="risk-score-table" style="border-collapse:collapse;width:100%">${thead}${tbody}</table>`;
    // Add timestamp above the risk score table
    const timestamp = new Date().toLocaleString();
    el.innerHTML = `<div style="font-size:0.9em;color:#666;margin-bottom:4px;">Report generated: ${timestamp}</div>` + el.innerHTML;
    // Add click handler to toggle detail rows
    setTimeout(function() {
        var overallRows = el.querySelectorAll('tr.overall-row');
        overallRows.forEach(function(row) {
            row.addEventListener('click', function() {
                var groupID = row.querySelector('td:nth-child(' + (displayCols.indexOf('GroupID') + 1) + ')').innerText;
                var detailRows = el.querySelectorAll('tr.detail-row[data-group="' + groupID + '"]');
                detailRows.forEach(function(drow) {
                    drow.style.display = drow.style.display === 'none' ? '' : 'none';
                });
            });
        });
    }, 100);
}
