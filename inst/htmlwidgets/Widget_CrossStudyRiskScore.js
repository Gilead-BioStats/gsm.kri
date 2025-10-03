HTMLWidgets.widget({
  name: 'Widget_CrossStudyRiskScore',
  type: 'output',

  factory: function(el, width, height) {
    return {
      renderValue: function(x) {
        // Debug: Log the received data structure
        console.log('Widget received data:', x);
        console.log('Data type:', typeof x);
        console.log('Data keys:', Object.keys(x));
        
        // Handle data that might already be parsed or needs parsing
        let data;
        if (typeof x.data === 'string') {
          try {
            data = JSON.parse(x.data);
            console.log('Parsed JSON data:', data);
          } catch (e) {
            console.error('JSON parse error:', e);
            el.innerHTML = '<div style="color: red;">Error parsing data: ' + e.message + '</div>';
            return;
          }
        } else {
          data = x.data;
          console.log('Direct data:', data);
        }
        
        // Debug: Check data structure
        if (data) {
          console.log('Data keys:', Object.keys(data));
          console.log('Summary data:', data.summary);
          console.log('Summary type:', typeof data.summary);
          if (data.summary) {
            console.log('Summary length:', data.summary.length);
          }
        }
        
        // Clear any existing content
        el.innerHTML = '';
        
        // Render the cross-study risk score table
        renderCrossStudyRiskScoreTable(el, data);
      },

      resize: function(width, height) {
        // Handle resize if needed
      }
    };
  }
});