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

    // Get unique study IDs for the study filter
    const uniqueStudies = [...new Set(resultsArray.map(d => d.StudyID))].sort();
    
    // Calculate SRS range for slider
    const srsValues = input.dfSummary.map(s => s.AvgRiskScore);
    const minSRS = Math.floor(Math.min(...srsValues));
    const maxSRS = Math.ceil(Math.max(...srsValues));

    // Create controls and table
    let html = '<div class="cross-study-container">';
    html += '<h3>Cross-Study Site Risk Score Summary</h3>';
    
    // Add filter controls
    html += '<div class="filter-controls" style="background:#f5f5f5; padding:15px; margin-bottom:15px; border-radius:5px; border:1px solid #ddd;">';
    html += '<div style="display:flex; gap:20px; flex-wrap:wrap; align-items:center;">';
    
    // SRS Filter
    html += '<div style="flex:1; min-width:200px;">';
    html += '<label style="display:block; font-weight:bold; margin-bottom:5px;">Average SRS Range:</label>';
    html += `<input type="range" id="srs-min-slider" min="${minSRS}" max="${maxSRS}" value="${minSRS}" style="width:45%;" />`;
    html += '<span id="srs-min-value" style="margin:0 5px;">' + minSRS + '</span>';
    html += '<span style="margin:0 5px;">to</span>';
    html += `<input type="range" id="srs-max-slider" min="${minSRS}" max="${maxSRS}" value="${maxSRS}" style="width:45%;" />`;
    html += '<span id="srs-max-value" style="margin:0 5px;">' + maxSRS + '</span>';
    html += '</div>';
    
    // Study Count Filter
    html += '<div style="flex:1; min-width:150px;">';
    html += '<label style="display:block; font-weight:bold; margin-bottom:5px;">Min Study Count:</label>';
    html += '<input type="number" id="study-count-filter" min="1" value="1" style="width:80px; padding:4px;" />';
    html += '</div>';
    
    // Study Filter
    html += '<div style="flex:1; min-width:200px;">';
    html += '<label style="display:block; font-weight:bold; margin-bottom:5px;">Filter by Study:</label>';
    html += '<select id="study-filter" style="width:100%; padding:4px;">';
    html += '<option value="">All Studies</option>';
    uniqueStudies.forEach(study => {
        html += `<option value="${study}">${study}</option>`;
    });
    html += '</select>';
    html += '</div>';
    
    // Reset button
    html += '<div style="flex:0;">';
    html += '<button id="reset-filters" style="padding:8px 16px; background:#2196f3; color:white; border:none; border-radius:3px; cursor:pointer; margin-top:20px;">Reset Filters</button>';
    html += '</div>';
    
    html += '</div>';
    html += '<div id="filter-info" style="margin-top:10px; font-size:14px; color:#666;"></div>';
    html += '</div>';
    
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
        summaryRow.dataset.avgRiskScore = siteRow.AvgRiskScore;
        summaryRow.dataset.numStudies = siteRow.NumStudies;
        summaryRow.innerHTML = `
            <td colspan="100" style="text-align:left; padding:5px;">
                <span class="toggle-indicator" style="display:inline-block; width:20px; font-weight:bold;">−</span>
                ${siteRow.GroupID} (${investigatorName})
                ${studyCountBadge}
                ${avgRiskBadge}
            </td>
        `;
        
        // Get study-level data for this site (INCLUDING the risk score metric)
        const siteResults = resultsArray.filter(d => 
            d.GroupID === siteRow.GroupID && d.GroupLevel === 'Site'
        );
        
        console.log(`Site ${siteRow.GroupID}: Found ${siteResults.length} results`);
        console.log(`Site ${siteRow.GroupID}: All MetricIDs in siteResults:`, [...new Set(siteResults.map(r => r.MetricID))]);
        
        // Check if we have the SiteRiskMetric in the data
        const srsMetricID = input.strSiteRiskMetric || 'Analysis_srs0001';
        const hasSRS = siteResults.some(r => r.MetricID === srsMetricID);
        console.log(`Site ${siteRow.GroupID}: Has SiteRiskMetric (${srsMetricID}): ${hasSRS}`);
        
        if (!hasSRS) {
            console.warn(`Site ${siteRow.GroupID}: Missing ${srsMetricID} metric in data! This will prevent the SRS column from rendering.`);
        }
        
        // Store study IDs for this site
        const siteStudyIds = siteResults.map(r => r.StudyID);
        summaryRow.dataset.studies = JSON.stringify(siteStudyIds);
        
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
        
        // Transform data to use StudyID as GroupID (prepend as requested)
        const transformedResults = siteResults.map(d => ({
            ...d,
            GroupID: `${d.StudyID}_${d.GroupID}`//,
            //GroupLevel: 'Study'
        }));
        
        console.log(`Site ${siteRow.GroupID}: Transformed results count: ${transformedResults.length}`);
        console.log(`Site ${siteRow.GroupID}: Unique MetricIDs in transformed data:`, [...new Set(transformedResults.map(r => r.MetricID))]);
        
        // Count how many risk score records we have
        const srsRecords = transformedResults.filter(r => r.MetricID === srsMetricID);
        console.log(`Site ${siteRow.GroupID}: SRS records in transformed data: ${srsRecords.length}`);
        if (srsRecords.length > 0) {
            console.log(`Site ${siteRow.GroupID}: Sample SRS record:`, srsRecords[0]);
        }
        
        // Check if gsmViz is available
        if (typeof gsmViz !== 'undefined' && gsmViz.default && gsmViz.default.groupOverview) {
            try {
                // Create a temporary container for gsmViz to render into
                const tempContainer = document.createElement('div');
                
                console.log(`Site ${siteRow.GroupID}: Rendering gsmViz with SiteRiskMetric: ${input.strSiteRiskMetric || 'Analysis_srs0001'}`);
                console.log(`Site ${siteRow.GroupID}: transformedResults count: ${transformedResults.length}`);
                
                // Create the gsmViz groupOverview instance
                const instance = gsmViz.default.groupOverview(
                    tempContainer,
                    transformedResults,
                    {
                        GroupLevel: 'Site',
                        groupLabelKey: 'nickname',
                        SiteRiskScoreMetricID: input.strSiteRiskMetric || 'Analysis_srs0001'
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
    
    // Set up filter event listeners
    setupFilters(el, input.dfSummary);
}

function setupFilters(el, dfSummary) {
    const srsMinSlider = el.querySelector('#srs-min-slider');
    const srsMaxSlider = el.querySelector('#srs-max-slider');
    const srsMinValue = el.querySelector('#srs-min-value');
    const srsMaxValue = el.querySelector('#srs-max-value');
    const studyCountFilter = el.querySelector('#study-count-filter');
    const studyFilter = el.querySelector('#study-filter');
    const resetButton = el.querySelector('#reset-filters');
    const filterInfo = el.querySelector('#filter-info');
    
    function applyFilters() {
        const minSRS = parseFloat(srsMinSlider.value);
        const maxSRS = parseFloat(srsMaxSlider.value);
        const minStudyCount = parseInt(studyCountFilter.value);
        const selectedStudy = studyFilter.value;
        
        let visibleCount = 0;
        let totalCount = 0;
        
        // Get all site tbody elements
        const allTbodies = el.querySelectorAll('tbody[id^="site-tbody-"]');
        
        allTbodies.forEach(tbody => {
            const summaryRow = tbody.querySelector('.site-summary');
            if (!summaryRow) return;
            
            totalCount++;
            
            const avgRiskScore = parseFloat(summaryRow.dataset.avgRiskScore);
            const numStudies = parseInt(summaryRow.dataset.numStudies);
            const siteStudies = JSON.parse(summaryRow.dataset.studies || '[]');
            
            let show = true;
            
            // Check SRS range
            if (avgRiskScore < minSRS || avgRiskScore > maxSRS) {
                show = false;
            }
            
            // Check study count
            if (numStudies < minStudyCount) {
                show = false;
            }
            
            // Check study filter
            if (selectedStudy && !siteStudies.includes(selectedStudy)) {
                show = false;
            }
            
            // Show/hide the entire tbody
            if (show) {
                tbody.style.display = '';
                visibleCount++;
            } else {
                tbody.style.display = 'none';
            }
        });
        
        // Update filter info
        const filters = [];
        if (minSRS > parseFloat(srsMinSlider.min) || maxSRS < parseFloat(srsMaxSlider.max)) {
            filters.push(`SRS: ${minSRS.toFixed(1)}-${maxSRS.toFixed(1)}`);
        }
        if (minStudyCount > 1) {
            filters.push(`Min ${minStudyCount} studies`);
        }
        if (selectedStudy) {
            filters.push(`Study: ${selectedStudy}`);
        }
        
        if (filters.length > 0) {
            filterInfo.innerHTML = `<strong>Active filters:</strong> ${filters.join(', ')} | Showing ${visibleCount} of ${totalCount} sites`;
        } else {
            filterInfo.innerHTML = `Showing all ${totalCount} sites`;
        }
    }
    
    // Update SRS slider values
    srsMinSlider.addEventListener('input', function() {
        const minVal = parseFloat(this.value);
        const maxVal = parseFloat(srsMaxSlider.value);
        if (minVal > maxVal) {
            this.value = maxVal;
        }
        srsMinValue.textContent = this.value;
        applyFilters();
    });
    
    srsMaxSlider.addEventListener('input', function() {
        const minVal = parseFloat(srsMinSlider.value);
        const maxVal = parseFloat(this.value);
        if (maxVal < minVal) {
            this.value = minVal;
        }
        srsMaxValue.textContent = this.value;
        applyFilters();
    });
    
    studyCountFilter.addEventListener('input', applyFilters);
    studyFilter.addEventListener('change', applyFilters);
    
    // Reset button
    resetButton.addEventListener('click', function() {
        srsMinSlider.value = srsMinSlider.min;
        srsMaxSlider.value = srsMaxSlider.max;
        srsMinValue.textContent = srsMinSlider.min;
        srsMaxValue.textContent = srsMaxSlider.max;
        studyCountFilter.value = 1;
        studyFilter.value = '';
        applyFilters();
    });
    
    // Initialize filter info
    applyFilters();
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
