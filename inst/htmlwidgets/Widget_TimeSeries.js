HTMLWidgets.widget({
    name: 'Widget_TimeSeries',
    type: 'output',
    factory: function(el, width, height) {
        return {
            renderValue: function(input) {
                if (input.bDebug)
                    console.log(input);

                // Coerce `input.lChartConfig` to an object if it is not already.
                if (Object.prototype.toString.call(input.lChartConfig) !== '[object Object]') {
                    input.lChartConfig = {};
                };

                // Assign a unique ID to the element.
                el.id = `timeSeries--${input.lChartConfig.MetricID}_${input.strOutcome}`;

                // Add click event listener to chart.
                input.lChartConfig.clickCallback = clickCallback(el, input);

                // Generate time series.
                const instance = gsmViz.default.timeSeries(
                    el,
                    input.dfResults,
                    input.lChartConfig,
                    input.vThreshold,
                    null, // confidence intervals parameter
                    input.dfGroups
                );

                // Add dropdowns that highlight group IDs.
                const { widgetControls } = addWidgetControls(
                    el,
                    input.dfResults,
                    input.lChartConfig,
                    input.dfGroups,
                    input.bAddGroupSelect
                );

                // Add a dropdown that changes the outcome variable.
                const outcomeSelect = addOutcomeSelect(
                    widgetControls,
                    input.dfResults,
                    input.lChartConfig,
                    input.dfGroups,
                    input.strOutcome
                );
            },
            resize: function(width, height) {
            }
        };
    }
});
