HTMLWidgets.widget({
  name: 'Widget_PortfolioOverview',
  type: 'output',

  factory: function(el, width, height) {
    return {
      renderValue: function(input) {
        // Parse JSON strings sent from R.
        var parsedInput = {};
        Object.keys(input).forEach(function(key) {
          try {
            parsedInput[key] = typeof input[key] === 'string'
              ? JSON.parse(input[key])
              : input[key];
          } catch (e) {
            parsedInput[key] = input[key];
          }
        });

        el.innerHTML = '';
        renderPortfolioOverviewTable(el, parsedInput);
      },

      resize: function(width, height) {
        // No-op; table flows with container width.
      }
    };
  }
});
