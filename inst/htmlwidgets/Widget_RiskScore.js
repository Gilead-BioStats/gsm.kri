HTMLWidgets.widget({
    name: 'Widget_RiskScore',
    type: 'output',
    factory: function(el, width, height) {
        return {
            renderValue: function(input) {
                // Accept both array-of-objects and array-of-arrays (from R data.frame)
                el.innerHTML = '';
                let data = input.data;
                if (typeof data === 'string') {
                    try { data = JSON.parse(data); } catch (e) { el.innerHTML = '<em>Malformed JSON</em>'; return; }
                }
                // Use the shared JS function
                if (typeof renderRiskScoreTable === 'function') {
                    renderRiskScoreTable(el, data);
                } else {
                    el.innerHTML = '<em>renderRiskScoreTable() not loaded</em>';
                }
            },
            resize: function(width, height) {
                // No-op for static table
            }
        };
    }
});
