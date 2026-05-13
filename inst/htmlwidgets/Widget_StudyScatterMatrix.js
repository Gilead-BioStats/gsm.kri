HTMLWidgets.widget({
  name: 'Widget_StudyScatterMatrix',
  type: 'output',

  factory: function(el, width, height) {
    return {
      renderValue: function(input) {
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
        renderStudyScatterMatrix(el, parsedInput);
      },
      resize: function(width, height) {}
    };
  }
});
