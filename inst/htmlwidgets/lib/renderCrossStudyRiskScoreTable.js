// Cross-Study Risk Score Table Widget
function renderCrossStudyRiskScoreTable(el, data) {
    console.log('renderCrossStudyRiskScoreTable called with data:', data);
    console.log('Data type:', typeof data);
    
    if (!data) {
        console.log('No data provided');
        el.innerHTML = '<em>No data provided to widget</em>';
        return;
    }
    
    if (!data.summary) {
        console.log('No summary data found. Available keys:', Object.keys(data));
        el.innerHTML = '<em>No summary data found in widget data</em>';
        return;
    }
    
    // Handle R data.frame structure (object with arrays) vs JavaScript array structure
    let summary;
    if (Array.isArray(data.summary)) {
        // Already in the right format (array of objects)
        summary = data.summary;
        console.log('Summary is already an array');
    } else if (typeof data.summary === 'object' && data.summary.GroupID && Array.isArray(data.summary.GroupID)) {
        // R data.frame format - convert to array of objects
        console.log('Converting R data.frame format to array of objects');
        const groupIds = data.summary.GroupID;
        const numStudies = data.summary.NumStudies;
        const avgRiskScore = data.summary.AvgRiskScore;
        const maxRiskScore = data.summary.MaxRiskScore;
        const minRiskScore = data.summary.MinRiskScore;
        const redFlags = data.summary.RedFlags;
        const amberFlags = data.summary.AmberFlags;
        const greenFlags = data.summary.GreenFlags;
        
        summary = [];
        for (let i = 0; i < groupIds.length; i++) {
            summary.push({
                GroupID: groupIds[i],
                NumStudies: numStudies[i],
                AvgRiskScore: avgRiskScore[i],
                MaxRiskScore: maxRiskScore[i],
                MinRiskScore: minRiskScore[i],
                RedFlags: redFlags[i],
                AmberFlags: amberFlags[i],
                GreenFlags: greenFlags[i]
            });
        }
        console.log('Converted summary:', summary);
    } else {
        console.log('Summary is not in expected format:', typeof data.summary, data.summary);
        el.innerHTML = '<em>Summary data is not in expected format</em>';
        return;
    }
    
    if (summary.length === 0) {
        console.log('Summary array is empty');
        el.innerHTML = '<em>Summary data array is empty</em>';
        return;
    }
    
    console.log('Summary data looks good, length:', summary.length);
    console.log('First summary item:', summary[0]);

    const details = data.details || [];

    // Create summary table
    let html = '<div class="cross-study-container">';
    html += '<h3>Cross-Study Site Risk Score Summary</h3>';
    html += '<table class="cross-study-summary" style="width:100%;border-collapse:collapse;margin-bottom:20px;">';
    
    // Header
    html += '<thead><tr>';
    html += '<th style="padding:8px;border:1px solid #ccc;background:#f5f5f5;">Site</th>';
    html += '<th style="padding:8px;border:1px solid #ccc;background:#f5f5f5;">Studies</th>';
    html += '<th style="padding:8px;border:1px solid #ccc;background:#f5f5f5;">Avg Risk Score</th>';
    html += '<th style="padding:8px;border:1px solid #ccc;background:#f5f5f5;">Max Risk Score</th>';
    html += '<th style="padding:8px;border:1px solid #ccc;background:#f5f5f5;">Min Risk Score</th>';
    html += '<th style="padding:8px;border:1px solid #ccc;background:#f5f5f5;">Red Flags</th>';
    html += '<th style="padding:8px;border:1px solid #ccc;background:#f5f5f5;">Amber Flags</th>';
    html += '<th style="padding:8px;border:1px solid #ccc;background:#f5f5f5;">Green Flags</th>';
    html += '<th style="padding:8px;border:1px solid #ccc;background:#f5f5f5;">Action</th>';
    html += '</tr></thead>';
    
    // Body
    html += '<tbody>';
    summary.forEach((row, index) => {
        const riskColor = getRiskScoreColor(row.AvgRiskScore);
        html += '<tr>';
        html += `<td style="padding:8px;border:1px solid #ccc;font-weight:bold;">${row.GroupID}</td>`;
        html += `<td style="padding:8px;border:1px solid #ccc;text-align:center;">${row.NumStudies}</td>`;
        html += `<td style="padding:8px;border:1px solid #ccc;text-align:center;background-color:${riskColor};">${row.AvgRiskScore.toFixed(1)}%</td>`;
        html += `<td style="padding:8px;border:1px solid #ccc;text-align:center;">${row.MaxRiskScore.toFixed(1)}%</td>`;
        html += `<td style="padding:8px;border:1px solid #ccc;text-align:center;">${row.MinRiskScore.toFixed(1)}%</td>`;
        html += `<td style="padding:8px;border:1px solid #ccc;text-align:center;color:#d32f2f;">${row.RedFlags}</td>`;
        html += `<td style="padding:8px;border:1px solid #ccc;text-align:center;color:#f57c00;">${row.AmberFlags}</td>`;
        html += `<td style="padding:8px;border:1px solid #ccc;text-align:center;color:#388e3c;">${row.GreenFlags}</td>`;
        html += `<td style="padding:8px;border:1px solid #ccc;text-align:center;">`;
        html += `<button onclick="toggleSiteDetails('${row.GroupID}', ${index})" class="details-btn" style="padding:4px 8px;background:#2196f3;color:white;border:none;border-radius:3px;cursor:pointer;">Show Details</button>`;
        html += `</td>`;
        html += '</tr>';
        
        // Hidden details row
        html += `<tr id="details-${index}" style="display:none;">`;
        html += `<td colspan="9" style="padding:12px;border:1px solid #ccc;background:#f9f9f9;">`;
        html += `<div id="details-content-${index}">Loading details...</div>`;
        html += `</td>`;
        html += '</tr>';
    });
    html += '</tbody></table>';
    html += '</div>';
    
    console.log('Generated HTML length:', html.length);
    el.innerHTML = html;
    
    // Store data for access by toggle function (convert summary to the right format)
    el._crossStudyData = {
        summary: summary,
        details: data.details
    };
}

function getRiskScoreColor(score) {
    if (score >= 75) return '#ffcdd2'; // Light red
    if (score >= 50) return '#ffe0b2'; // Light orange
    if (score >= 25) return '#fff3e0'; // Light amber
    return '#e8f5e8'; // Light green
}

function toggleSiteDetails(siteId, index) {
    const detailsRow = document.getElementById(`details-${index}`);
    const contentDiv = document.getElementById(`details-content-${index}`);
    const button = event.target;
    
    if (detailsRow.style.display === 'none') {
        // Show details
        detailsRow.style.display = '';
        button.textContent = 'Hide Details';
        
        // Get the container element to access stored data
        const container = button.closest('.cross-study-container').parentElement;
        const data = container._crossStudyData;
        
        if (data && data.details) {
            let siteDetails = [];
            
            // Handle R data.frame format vs JavaScript array format
            if (Array.isArray(data.details)) {
                // JavaScript array format
                siteDetails = data.details.filter(d => d.GroupID === siteId);
            } else if (typeof data.details === 'object' && data.details.GroupID && Array.isArray(data.details.GroupID)) {
                // R data.frame format - convert to array of objects and filter
                const groupIds = data.details.GroupID;
                const studyIds = data.details.StudyID;
                const snapshotDates = data.details.SnapshotDate;
                const scores = data.details.Score;
                const numerators = data.details.Numerator;
                const denominators = data.details.Denominator;
                const metricIds = data.details.MetricID;
                
                for (let i = 0; i < groupIds.length; i++) {
                    if (groupIds[i] === siteId && metricIds[i] === 'Analysis_srs0001') {
                        siteDetails.push({
                            GroupID: groupIds[i],
                            StudyID: studyIds[i],
                            SnapshotDate: snapshotDates[i],
                            Score: scores[i],
                            Numerator: numerators[i],
                            Denominator: denominators[i],
                            MetricID: metricIds[i]
                        });
                    }
                }
            }
            
            if (siteDetails.length > 0) {
                let detailsHTML = `<h4>Risk Score Details for ${siteId}</h4>`;
                detailsHTML += '<table style="width:100%;border-collapse:collapse;margin:10px 0;">';
                detailsHTML += '<thead><tr>';
                detailsHTML += '<th style="padding:6px;border:1px solid #ddd;background:#f0f0f0;">Study</th>';
                detailsHTML += '<th style="padding:6px;border:1px solid #ddd;background:#f0f0f0;">Snapshot Date</th>';
                detailsHTML += '<th style="padding:6px;border:1px solid #ddd;background:#f0f0f0;">Risk Score</th>';
                detailsHTML += '<th style="padding:6px;border:1px solid #ddd;background:#f0f0f0;">Raw Score</th>';
                detailsHTML += '<th style="padding:6px;border:1px solid #ddd;background:#f0f0f0;">Max Score</th>';
                detailsHTML += '</tr></thead><tbody>';
                
                siteDetails.forEach(detail => {
                    const riskColor = getRiskScoreColor(detail.Score);
                    detailsHTML += '<tr>';
                    detailsHTML += `<td style="padding:6px;border:1px solid #ddd;">${detail.StudyID}</td>`;
                    detailsHTML += `<td style="padding:6px;border:1px solid #ddd;">${detail.SnapshotDate}</td>`;
                    detailsHTML += `<td style="padding:6px;border:1px solid #ddd;text-align:center;background-color:${riskColor};">${detail.Score.toFixed(2)}%</td>`;
                    detailsHTML += `<td style="padding:6px;border:1px solid #ddd;text-align:center;">${detail.Numerator}</td>`;
                    detailsHTML += `<td style="padding:6px;border:1px solid #ddd;text-align:center;">${detail.Denominator}</td>`;
                    detailsHTML += '</tr>';
                });
                
                detailsHTML += '</tbody></table>';
                contentDiv.innerHTML = detailsHTML;
            } else {
                contentDiv.innerHTML = '<p>No details available for this site.</p>';
            }
        }
    } else {
        // Hide details
        detailsRow.style.display = 'none';
        button.textContent = 'Show Details';
    }
}