// Cross-Study Risk Score Table Widget
function renderCrossStudyRiskScoreTable(el, input) {
    console.log('renderCrossStudyRiskScoreTable called with input:', input);
    
    if (!input) {
        console.log('No input provided');
        el.innerHTML = '<em>No input provided to widget</em>';
        return;
    }
    
    if (!input.dfSummary) {
        console.log('No summary data found. Available keys:', Object.keys(input));
        el.innerHTML = '<em>No summary data found in widget input</em>';
        return;
    }
    
    // Check that dfSummary is properly formatted as an array
    if (!Array.isArray(input.dfSummary)) {
        console.warn('dfSummary is not an array. Expected array format, got:', typeof input.dfSummary);
        el.innerHTML = '<div style="padding: 20px; background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; color: #856404;"><h4>⚠️ Data Format Warning</h4><p><strong>Summary data must be provided as an array.</strong></p><p>Expected: Array of objects with GroupID, NumStudies, AvgRiskScore, etc.</p><p>Received: ' + typeof input.dfSummary + '</p></div>';
        return;
    }
    
    if (input.dfSummary.length === 0) {
        console.log('Summary array is empty');
        el.innerHTML = '<em>Summary data array is empty</em>';
        return;
    }
    
    console.log('Summary data looks good, length:', input.dfSummary.length);
    console.log('First summary item:', input.dfSummary[0]);

    // Store the input data for access by toggle function
    el._crossStudyInput = input;

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
    input.dfSummary.forEach((row, index) => {
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
        
        // Get the container element to access stored input data
        const container = button.closest('.cross-study-container').parentElement;
        const input = container._crossStudyInput;
        
        if (input && input.dfResults) {
            // Clear the content div and create a new container for the gsmViz widget
            contentDiv.innerHTML = `<h4>KRI Details for ${siteId}</h4><div id="gsm-viz-container-${index}" style="width: 100%;"></div>`;
            
            // Get the container for the gsmViz widget
            const gsmVizContainer = document.getElementById(`gsm-viz-container-${index}`);
            
            // Check if gsmViz is available
            if (typeof gsmViz !== 'undefined' && gsmViz.default && gsmViz.default.groupOverview) {
                try {
                    // Filter results to only include this site's data
                    let filteredResults;
                    if (Array.isArray(input.dfResults)) {
                        filteredResults = input.dfResults.filter(d => d.GroupID === siteId);
                    } else if (typeof input.dfResults === 'object' && input.dfResults.GroupID && Array.isArray(input.dfResults.GroupID)) {
                        // Convert R data.frame format to array and filter
                        const results = convertDataFrameToArray(input.dfResults);
                        filteredResults = results.filter(d => d.GroupID === siteId);
                    }
                    
                    // We want to render study metadata with group results for the selected study, so we're going to manually set GroupID/GroupLevel to Study Level info so that the Study metadata will show up in the summary table
                    // Use StudyID for the grouping variable in results
                    filteredResults = filteredResults.map(d => {
                        return {
                            ...d,
                            GroupID: `${d.StudyID}`,
                            GroupLevel: "Study"
                        };
                    });

                    //Update Metrics to GroupLevel = "Study" (even though we're still using the site flags)
                    input.dfMetrics = input.dfMetrics.map(d => {
                        return {
                            ...d,
                            GroupLevel: "Study"
                        };
                    });


                    console.log('Filtered results for gsmViz:', filteredResults);
                    console.log('Filtered groups for gsmViz:', input.dfGroups);
                    console.log('Metrics for gsmViz:', input.dfMetrics);
                    
                    // Create the gsmViz groupOverview instance using the same pattern as Widget_GroupOverview
                    const instance = gsmViz.default.groupOverview(
                        gsmVizContainer,
                        filteredResults,
                        {
                            GroupLevel: "Study",
                            groupLabelKey: "nickname",
                            SiteRiskMetric: "Analysis_srs0001"
                        },
                        input.dfGroups,
                        input.dfMetrics
                    );
                    
                    // Hide the enrollment column by adding CSS
                    setTimeout(() => {
                        const style = document.createElement('style');
                        style.textContent = `
                            #gsm-viz-container-${index} .group-overview th:nth-child(2),
                            #gsm-viz-container-${index} .group-overview td:nth-child(2) {
                                display: none !important;
                            }
                        `;
                        document.head.appendChild(style);
                    }, 100);
                    
                    console.log('Created gsmViz groupOverview instance for site:', siteId, instance);
                } catch (error) {
                    console.error('Error creating gsmViz groupOverview:', error);
                    console.error('Error stack:', error.stack);
                    // Show error message
                    contentDiv.innerHTML = `
                        <div style="padding: 20px; background: #fff3cd; border: 1px solid #ffeaa7; border-radius: 5px; color: #856404;">
                            <h4>⚠️ gsmViz Error</h4>
                            <p><strong>Failed to initialize gsmViz groupOverview widget.</strong></p>
                            <p>Error: ${error.message}</p>
                            <p>Please ensure gsmViz library is properly loaded and compatible with this data structure.</p>
                        </div>
                    `;
                }
            } else {
                console.warn('gsmViz not available');
                // Show warning message
                contentDiv.innerHTML = `
                    <div style="padding: 20px; background: #f8d7da; border: 1px solid #f5c6cb; border-radius: 5px; color: #721c24;">
                        <h4>⚠️ gsmViz Not Available</h4>
                        <p><strong>The gsmViz library is required to display detailed KRI analysis.</strong></p>
                        <p>Please ensure the gsmViz library is loaded before using this widget.</p>
                        <p>Checked locations: <code>gsmViz</code>, <code>window.gsmViz</code></p>
                        <details style="margin-top: 10px;">
                            <summary style="cursor: pointer; font-weight: bold;">Debug Information</summary>
                            <pre style="background: #f8f9fa; padding: 10px; margin-top: 5px; border-radius: 3px; font-size: 12px;">
Available globals: ${Object.keys(window).slice(0, 20).join(', ')}...
Site ID: ${siteId}
Input keys: ${Object.keys(input).join(', ')}
                            </pre>
                        </details>
                    </div>
                `;
            }
        } else {
            contentDiv.innerHTML = '<p>No details available for this site.</p>';
        }
    } else {
        // Hide details
        detailsRow.style.display = 'none';
        button.textContent = 'Show Details';
    }
}

// Helper function to convert R data.frame format to JavaScript array format
function convertDataFrameToArray(dataFrame) {
    if (!dataFrame || typeof dataFrame !== 'object') return [];
    
    const keys = Object.keys(dataFrame);
    if (keys.length === 0) return [];
    
    const firstKey = keys[0];
    if (!Array.isArray(dataFrame[firstKey])) return [];
    
    const length = dataFrame[firstKey].length;
    const result = [];
    
    for (let i = 0; i < length; i++) {
        const row = {};
        keys.forEach(key => {
            row[key] = dataFrame[key][i];
        });
        result.push(row);
    }
    
    return result;
}

// Helper function to get flag colors
function getFlagColor(flag) {
    if (flag >= 2) return '#ffcdd2'; // Light red
    if (flag >= 1) return '#ffe0b2'; // Light orange
    if (flag <= -2) return '#ffcdd2'; // Light red for negative flags
    if (flag <= -1) return '#ffe0b2'; // Light orange for negative flags
    return '#e8f5e8'; // Light green for normal flags
}

// Helper function to get readable metric names
function getMetricDisplayName(metricId) {
    const metricNames = {
        'Analysis_srs0001': '🎯 Site Risk Score',
        'Analysis_kri0001': 'Adverse Events',
        'Analysis_kri0002': 'Serious Adverse Events', 
        'Analysis_kri0003': 'Protocol Deviations',
        'Analysis_kri0004': 'Important Protocol Deviations',
        'Analysis_kri0005': 'Lab Abnormalities',
        'Analysis_kri0006': 'Study Discontinuation',
        'Analysis_kri0007': 'Treatment Discontinuation',
        'Analysis_kri0008': 'Query Rates',
        'Analysis_kri0009': 'Data Entry Lag',
        'Analysis_kri0010': 'Screen Failure',
        'Analysis_kri0011': 'Missing Data',
        'Analysis_kri0012': 'Other KRI'
    };
    return metricNames[metricId] || metricId;
}