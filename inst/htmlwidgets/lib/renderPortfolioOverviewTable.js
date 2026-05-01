// Portfolio Overview Table Widget
// D1: portfolio rollup table. One column per metric (sorted by MetricID).
// One row for the portfolio total plus drill-down rows grouped by
// study-level params (therapeutic_area, protocol_indication, phase, status,
// product). Each cell shows numerator / denominator / rate.
function renderPortfolioOverviewTable(el, input) {
  if (!input) {
    el.innerHTML = '<em>No input provided to widget</em>';
    return;
  }

  if (!Array.isArray(input.dfSummary) || input.dfSummary.length === 0) {
    el.innerHTML = '<em>No summary data found in widget input</em>';
    return;
  }

  var summary = input.dfSummary;
  var metricOrder = Array.isArray(input.vMetricOrder) && input.vMetricOrder.length > 0
    ? input.vMetricOrder.slice().sort()
    : Array.from(new Set(summary.map(function(r) { return r.MetricID; }))).sort();

  // Build a lookup keyed by GroupCategory|GroupValue|MetricID for O(1) cell access.
  var summaryIndex = {};
  summary.forEach(function(row) {
    var key = row.GroupCategory + '||' + row.GroupValue + '||' + row.MetricID;
    summaryIndex[key] = row;
  });

  // Distinct (GroupCategory, GroupValue) buckets, preserving the order produced by R.
  var buckets = [];
  var seenBuckets = {};
  summary.forEach(function(row) {
    var key = row.GroupCategory + '||' + row.GroupValue;
    if (!seenBuckets[key]) {
      seenBuckets[key] = true;
      buckets.push({
        category: row.GroupCategory,
        value: row.GroupValue,
        numStudies: row.NumStudies
      });
    }
  });

  function fmtRate(rate) {
    if (rate === null || rate === undefined || isNaN(rate)) {
      return '-';
    }
    return (rate * 100).toFixed(1) + '%';
  }

  function fmtCell(cell) {
    if (!cell) {
      return '<span class="po-empty">-</span>';
    }
    return (
      '<span class="po-num">' + cell.Numerator + '</span>' +
      ' / ' +
      '<span class="po-den">' + cell.Denominator + '</span>' +
      '<br><span class="po-rate">' + fmtRate(cell.Rate) + '</span>'
    );
  }

  var html = '';
  html += '<style>';
  html += '.po-container { font-family: sans-serif; }';
  html += '.po-table { width: 100%; border-collapse: collapse; margin-top: 10px; }';
  html += '.po-table th, .po-table td { border: 1px solid #ddd; padding: 6px 8px; vertical-align: top; text-align: right; font-size: 13px; }';
  html += '.po-table th { background: #f5f5f5; text-align: center; }';
  html += '.po-table tr.po-total-row { background: #e8eef7; font-weight: bold; }';
  html += '.po-table tr.po-category-header td { background: #fafafa; text-align: left; font-weight: bold; color: #555; }';
  html += '.po-table td.po-bucket-label { text-align: left; }';
  html += '.po-rate { color: #2c3e50; }';
  html += '.po-empty { color: #aaa; }';
  html += '</style>';

  html += '<div class="po-container">';
  html += '<h3>Portfolio Overview</h3>';
  html += '<table class="po-table"><thead><tr>';
  html += '<th style="text-align:left;">Group</th>';
  html += '<th style="text-align:right;">Studies</th>';
  metricOrder.forEach(function(metricId) {
    html += '<th>' + metricId + '</th>';
  });
  html += '</tr></thead><tbody>';

  // Total row first.
  var lastCategory = null;
  buckets.forEach(function(bucket) {
    if (bucket.category !== lastCategory && bucket.category !== 'Total') {
      html += '<tr class="po-category-header"><td colspan="' + (metricOrder.length + 2) + '">' +
        bucket.category + '</td></tr>';
    }
    lastCategory = bucket.category;

    var rowClass = bucket.category === 'Total' ? 'po-total-row' : 'po-bucket-row';
    html += '<tr class="' + rowClass + '">';
    html += '<td class="po-bucket-label">' + bucket.value + '</td>';
    html += '<td>' + (bucket.numStudies != null ? bucket.numStudies : '-') + '</td>';
    metricOrder.forEach(function(metricId) {
      var cell = summaryIndex[bucket.category + '||' + bucket.value + '||' + metricId];
      html += '<td>' + fmtCell(cell) + '</td>';
    });
    html += '</tr>';
  });

  html += '</tbody></table></div>';

  el.innerHTML = html;
}
