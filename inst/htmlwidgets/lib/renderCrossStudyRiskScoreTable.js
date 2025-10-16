// Cross-Study Risk Score Table Widget
function renderCrossStudyRiskScoreTable(el, input) {
    if (!input) {
        el.innerHTML = '<em>No input provided to widget</em>';
        return;
    }
    
    if (!input.dfSummary) {
        el.innerHTML = '<em>No summary data found in widget input</em>';
        return;
    }
    
    // Check that dfSummary is properly formatted as an array
    if (!Array.isArray(input.dfSummary)) {
        el.innerHTML = '<div style="padding: 20px; background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; color: #856404;"><h4>⚠️ Data Format Warning</h4><p><strong>Summary data must be provided as an array.</strong></p><p>Expected: Array of objects with GroupID, NumStudies, AvgRiskScore, etc.</p><p>Received: ' + typeof input.dfSummary + '</p></div>';
        return;
    }
    
    if (input.dfSummary.length === 0) {
        el.innerHTML = '<em>Summary data array is empty</em>';
        return;
    }

    // Check that dfResults is properly formatted as an array
    if (!Array.isArray(input.dfResults)) {
        el.innerHTML = '<div style="padding: 20px; background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; color: #856404;"><h4>⚠️ Data Format Error</h4><p><strong>Results data must be provided as an array.</strong></p><p>Expected: Array of objects with StudyID, GroupID, MetricID, etc.</p><p>Received: ' + typeof input.dfResults + '</p></div>';
        return;
    }
    
    const resultsArray = input.dfResults;

    // Create single unified table with one thead and multiple tbody elements
    let html = '<div class="cross-study-container">';
    html += '<h3>Cross-Study Site Risk Score Summary</h3>';
    html += '<table class="cross-study-unified-table group-overview" style="width:100%;border-collapse:collapse;">';
    html += '<thead id="unified-thead"></thead>';
    
    // Create a tbody for each site
    input.dfSummary.forEach((siteRow, siteIndex) => {
        html += `<tbody id="site-tbody-${siteIndex}"></tbody>`;
    });
    
    html += '</table>';
    html += '</div>';
    
    // Set initial HTML
    el.innerHTML = html;
    
    // Flag to track if we've set the unified header
    let headerSet = false;
    
    // Now render gsmViz tables for each site
    input.dfSummary.forEach((siteRow, siteIndex) => {
        const siteTbody = document.getElementById(`site-tbody-${siteIndex}`);
        
        if (!siteTbody) return;
        
        // Create site summary row
        const investigatorName = siteRow.InvestigatorName || 'Unknown';
        const avgRiskBadge = getRiskScoreBadge(siteRow.AvgRiskScore);
        const studyCountBadge = getStudyCountBadge(siteRow.NumStudies);
        
        const summaryRow = document.createElement('tr');
        summaryRow.className = 'site-summary';
        summaryRow.style.cssText = 'background:#bbb; font-weight:bold; cursor:pointer;';
        summaryRow.dataset.siteIndex = siteIndex;
        summaryRow.innerHTML = `
            <td colspan="100" style="text-align:left; padding:5px;">
                <span class="toggle-indicator" style="display:inline-block; width:20px; font-weight:bold;">−</span>
                ${siteRow.GroupID} (${investigatorName})
                ${studyCountBadge}
                ${avgRiskBadge}
            </td>
        `;
        
        // Add click event to toggle visibility
        summaryRow.addEventListener('click', function() {
            const tbody = this.parentElement;
            const studyRows = Array.from(tbody.querySelectorAll('tr:not(.site-summary)'));
            const indicator = this.querySelector('.toggle-indicator');
            
            studyRows.forEach(row => {
                if (row.style.display === 'none') {
                    row.style.display = '';
                    indicator.textContent = '−';
                } else {
                    row.style.display = 'none';
                    indicator.textContent = '+';
                }
            });
        });
        
        siteTbody.appendChild(summaryRow);
        
        // Get study-level data for this site
        const siteResults = resultsArray.filter(d => 
            d.GroupID === siteRow.GroupID && d.GroupLevel === 'Site'
        );
        
        // Transform data to use StudyID as GroupID (prepend as requested)
        const transformedResults = siteResults.map(d => ({
            ...d,
            GroupID: `${d.StudyID}_${d.GroupID}`,
            GroupLevel: 'Study'
        }));
        
        // Check if gsmViz is available
        if (typeof gsmViz !== 'undefined' && gsmViz.default && gsmViz.default.groupOverview) {
            try {
                // Create a temporary container for gsmViz to render into
                const tempContainer = document.createElement('div');
                
                // Create the gsmViz groupOverview instance
                const instance = gsmViz.default.groupOverview(
                    tempContainer,
                    transformedResults,
                    {
                        GroupLevel: 'Study',
                        groupLabelKey: 'nickname',
                        SiteRiskMetric: 'Analysis_srs0001'
                    },
                    input.dfGroups,
                    input.dfMetrics
                );
                
                // Extract the table created by gsmViz
                const gsmVizTable = tempContainer.querySelector('table.group-overview');
                
                if (gsmVizTable) {
                    // Copy header to unified thead (only once)
                    if (!headerSet) {
                        const unifiedThead = document.getElementById('unified-thead');
                        const gsmVizThead = gsmVizTable.querySelector('thead');
                        if (gsmVizThead) {
                            unifiedThead.innerHTML = gsmVizThead.innerHTML;
                            headerSet = true;
                        }
                    }
                    
                    // Move body rows from gsmViz table to our site tbody
                    const gsmVizTbody = gsmVizTable.querySelector('tbody');
                    if (gsmVizTbody) {
                        const rows = Array.from(gsmVizTbody.querySelectorAll('tr'));
                        rows.forEach(row => {
                            siteTbody.appendChild(row);
                        });
                    }
                }
                
                console.log(`Created gsmViz groupOverview for site ${siteRow.GroupID}:`, instance);
            } catch (error) {
                console.error(`Error creating gsmViz for site ${siteRow.GroupID}:`, error);
                const errorRow = document.createElement('tr');
                errorRow.innerHTML = `<td colspan="100" style="padding:10px;color:#d32f2f;">Error rendering table: ${error.message}</td>`;
                siteTbody.appendChild(errorRow);
            }
        } else {
            console.warn('gsmViz library not available');
            const warningRow = document.createElement('tr');
            warningRow.innerHTML = `<td colspan="100" style="padding:10px;color:#856404;">gsmViz library not loaded. Please ensure gsmViz is included in dependencies.</td>`;
            siteTbody.appendChild(warningRow);
        }
    });
    
    console.log('Generated HTML and initialized gsmViz tables');
}

function getRiskScoreColor(score) {
    if (score >= 75) return '#ffcdd2'; // Light red
    if (score >= 50) return '#ffe0b2'; // Light orange
    if (score >= 25) return '#fff3e0'; // Light amber
    return '#e8f5e8'; // Light green
}

function getRiskScoreBadge(score) {
    let bgColor, textColor;
    if (score >= 75) {
        bgColor = '#d32f2f'; // Red
        textColor = '#fff';
    } else if (score >= 50) {
        bgColor = '#f57c00'; // Orange
        textColor = '#fff';
    } else if (score >= 25) {
        bgColor = '#ffa726'; // Amber
        textColor = '#000';
    } else {
        bgColor = '#388e3c'; // Green
        textColor = '#fff';
    }
    
    return `<span class="gsm-srs" style="background-color:${bgColor};color:${textColor};padding:4px 8px; border-radius:4px;font-weight:bold;font-size:12px;margin-left:5px;">${score.toFixed(1)} SRS</span>`;
}

function getStudyCountBadge(count) {
    const studyLabel = count === 1 ? 'Study' : 'Studies';
    return `<span class="gsm-studyCount" style="background-color:#757575;color:#fff;padding:4px 8px;border-radius:4px;font-weight:bold;font-size:12px;margin-left:8px;">${count} ${studyLabel}</span>`;
}
