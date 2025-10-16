HTMLWidgets.widget({
  name: 'Widget_CrossStudyRiskScore',
  type: 'output',

  factory: function(el, width, height) {
    return {
      renderValue: function(input) {
        // Parse JSON strings from R
        const parsedInput = {};
        Object.keys(input).forEach(key => {
          try {
            parsedInput[key] = typeof input[key] === 'string' ? JSON.parse(input[key]) : input[key];
          } catch (e) {
            parsedInput[key] = input[key];
          }
        });
        
        // Clear any existing content
        el.innerHTML = '';
        
        // Render the cross-study risk score table
        renderCrossStudyRiskScoreTable(el, parsedInput);
      },

      resize: function(width, height) {
        // Handle resize if needed
      }
    };
  }
});