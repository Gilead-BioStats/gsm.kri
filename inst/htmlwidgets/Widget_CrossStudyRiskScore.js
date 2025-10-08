HTMLWidgets.widget({
  name: 'Widget_CrossStudyRiskScore',
  type: 'output',

  factory: function(el, width, height) {
    return {
      renderValue: function(input) {
        // Debug: Log the received data structure
        if (input.bDebug) {
          console.log('Widget received input:', input);
        }
        
        // Clear any existing content
        el.innerHTML = '';
        
        // Render the cross-study risk score table
        renderCrossStudyRiskScoreTable(el, input);
      },

      resize: function(width, height) {
        // Handle resize if needed
      }
    };
  }
});