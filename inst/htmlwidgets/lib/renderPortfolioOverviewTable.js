// Portfolio Overview Table Widget
// D1: portfolio rollup table. One column per metric (sorted by MetricID).
// One row for the portfolio total plus drill-down rows grouped by
// study-level params (therapeutic_area, protocol_indication, phase, status,
// product). Each cell shows numerator / denominator / rate.
// D2: client-side filter bar layered above the table. Filtering a study set
// recomputes the total + drill-down buckets in place from the per-study
// contribution table.
// D4: expandable rows. Click a drill-down row to reveal per-study
// numerator / denominator / rate values that rolled up into that bucket.
function renderPortfolioOverviewTable(el, input) {
  if (!input) {
    el.innerHTML = '<em>No input provided to widget</em>';
    return;
  }

  if (!Array.isArray(input.dfSummary) || input.dfSummary.length === 0) {
    el.innerHTML = '<em>No summary data found in widget input</em>';
    return;
  }

  var perStudy = Array.isArray(input.dfPerStudy) ? input.dfPerStudy : [];
  var studyAttrs = Array.isArray(input.dfStudyAttrs) ? input.dfStudyAttrs : [];
  var groupParams = Array.isArray(input.vGroupParams) && input.vGroupParams.length > 0
    ? input.vGroupParams
    : ['therapeutic_area', 'protocol_indication', 'phase', 'status', 'product'];
  var filterParams = Array.isArray(input.vFilterParams) && input.vFilterParams.length > 0
    ? input.vFilterParams
    : ['therapeutic_area', 'phase', 'status'];
  var metricOrder = Array.isArray(input.vMetricOrder) && input.vMetricOrder.length > 0
    ? input.vMetricOrder.slice().sort()
    : Array.from(new Set(input.dfSummary.map(function(r) { return r.MetricID; }))).sort();

  // Header label = Abbreviation; tooltip = full metric metadata.
  var metricLabels = {};
  var metricTooltips = {};
  var metricsMeta = Array.isArray(input.dfMetrics) ? input.dfMetrics : [];
  var tooltipFields = [
    'MetricID', 'Metric', 'Abbreviation', 'Type', 'GroupLevel',
    'Numerator', 'Denominator', 'Model', 'AnalysisType', 'Score',
    'Threshold', 'AccrualThreshold', 'AccrualMetric'
  ];
  metricsMeta.forEach(function(m) {
    if (!m || !m.MetricID) return;
    metricLabels[m.MetricID] = m.Abbreviation || m.Metric || m.MetricID;
    var lines = [];
    tooltipFields.forEach(function(f) {
      var v = m[f];
      if (v != null && v !== '' && v !== 'NA') lines.push(f + ': ' + v);
    });
    metricTooltips[m.MetricID] = lines.join('\n');
  });
  function metricLabel(mid) { return metricLabels[mid] || mid; }
  function metricTooltip(mid) { return metricTooltips[mid] || mid; }
  function escAttr(s) {
    return String(s).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  // Study attribute lookup: { StudyID: { Param: Value } }.
  var studyAttrLookup = {};
  studyAttrs.forEach(function(row) {
    if (!studyAttrLookup[row.StudyID]) studyAttrLookup[row.StudyID] = {};
    studyAttrLookup[row.StudyID][row.Param] = row.Value;
  });

  var allStudies = Array.from(new Set(perStudy.map(function(r) { return r.StudyID; }))).sort();
  var filterOptions = {};
  filterParams.forEach(function(p) {
    var values = new Set();
    Object.keys(studyAttrLookup).forEach(function(sid) {
      if (studyAttrLookup[sid][p] != null) values.add(studyAttrLookup[sid][p]);
    });
    filterOptions[p] = Array.from(values).sort();
  });

  var filterState = {};
  filterParams.forEach(function(p) { filterState[p] = []; });
  filterState.StudyID = [];

  // Tracks which (category|value) bucket rows are currently expanded so a
  // re-render after a filter change preserves user state where possible.
  var expandedBuckets = {};
  var heatmapOn = false;

  function bucketKey(category, value) {
    return category + '||' + value;
  }

  function fmtRate(rate) {
    if (rate === null || rate === undefined || isNaN(rate)) return '-';
    return (rate * 100).toFixed(1) + '%';
  }

  function fmtCell(cell) {
    if (!cell || cell.Denominator === 0) return '<div class="po-heat-cell"><span class="po-empty">-</span></div>';
    var red = cell.FlagRed || 0;
    var amber = cell.FlagAmber || 0;
    var green = cell.FlagGreen || 0;
    var total = red + amber + green;
    var tip = cell.Numerator + ' / ' + cell.Denominator;
    var style = '';
    if (total > 0) {
      tip += '\nFlags: ' + green + ' green, ' + amber + ' amber, ' + red + ' red (n=' + total + ')';
      if (heatmapOn) {
        var gPct = green / total * 100;
        var aPct = amber / total * 100;
        var stops = [
          'rgba(76,175,80,0.45) 0% ' + gPct + '%',
          'rgba(255,179,0,0.45) ' + gPct + '% ' + (gPct + aPct) + '%',
          'rgba(229,57,53,0.45) ' + (gPct + aPct) + '% 100%'
        ];
        style = ' style="background: linear-gradient(to right, ' + stops.join(', ') + ');"';
      }
    }
    return '<div class="po-heat-cell"' + style + ' title="' + escAttr(tip) + '">' +
      '<span class="po-rate">' + fmtRate(cell.Rate) + '</span></div>';
  }

  function filteredPerStudy() {
    return perStudy.filter(function(row) {
      if (filterState.StudyID.length > 0 && filterState.StudyID.indexOf(row.StudyID) === -1) {
        return false;
      }
      var attrs = studyAttrLookup[row.StudyID] || {};
      for (var i = 0; i < filterParams.length; i += 1) {
        var p = filterParams[i];
        if (filterState[p].length > 0 && filterState[p].indexOf(attrs[p]) === -1) {
          return false;
        }
      }
      return true;
    });
  }

  // Collect studies belonging to a (category, value) bucket from the filtered
  // per-study set. The "Total" bucket is the union of all surviving studies.
  function studiesInBucket(rows, category, value) {
    if (category === 'Total') {
      return Array.from(new Set(rows.map(function(r) { return r.StudyID; }))).sort();
    }
    var out = new Set();
    rows.forEach(function(r) {
      var attrs = studyAttrLookup[r.StudyID] || {};
      if (attrs[category] === value) out.add(r.StudyID);
    });
    return Array.from(out).sort();
  }

  // Build per-study rows for an expanded bucket: one tr per study with
  // numerator / denominator / rate per metric.
  function buildPerStudyRows(rows, studyIds) {
    var byStudy = {};
    rows.forEach(function(r) {
      if (studyIds.indexOf(r.StudyID) === -1) return;
      if (!byStudy[r.StudyID]) byStudy[r.StudyID] = {};
      byStudy[r.StudyID][r.MetricID] = r;
    });

    var html = '';
    studyIds.forEach(function(sid) {
      html += '<tr class="po-study-row" style="background:#fcfcfc;">';
      html += '<td class="po-bucket-label" style="padding-left:24px;">↳ ' + sid + '</td>';
      html += '<td>1</td>';
      metricOrder.forEach(function(mid) {
        var cell = byStudy[sid] && byStudy[sid][mid];
        var formatted = cell
          ? {
              Numerator: cell.Numerator,
              Denominator: cell.Denominator,
              Rate: cell.Rate,
              FlagRed: cell.FlagRed,
              FlagAmber: cell.FlagAmber,
              FlagGreen: cell.FlagGreen
            }
          : null;
        html += '<td class="po-cell-wrap">' + fmtCell(formatted) + '</td>';
      });
      html += '</tr>';
    });
    return html;
  }

  function computeBuckets(rows) {
    var totalIdx = {};
    var byCategory = {};

    function newAcc() { return { num: 0, den: 0, red: 0, amber: 0, green: 0, studies: new Set() }; }
    function addRow(acc, r) {
      acc.num += (r.Numerator || 0);
      acc.den += (r.Denominator || 0);
      acc.red += (r.FlagRed || 0);
      acc.amber += (r.FlagAmber || 0);
      acc.green += (r.FlagGreen || 0);
      acc.studies.add(r.StudyID);
    }
    function finalize(c) {
      return {
        Numerator: c.num,
        Denominator: c.den,
        Rate: c.den > 0 ? c.num / c.den : null,
        FlagRed: c.red,
        FlagAmber: c.amber,
        FlagGreen: c.green
      };
    }

    rows.forEach(function(r) {
      if (!totalIdx[r.MetricID]) totalIdx[r.MetricID] = newAcc();
      addRow(totalIdx[r.MetricID], r);

      var attrs = studyAttrLookup[r.StudyID] || {};
      groupParams.forEach(function(cat) {
        var val = attrs[cat];
        if (val == null) return;
        if (!byCategory[cat]) byCategory[cat] = {};
        if (!byCategory[cat][val]) byCategory[cat][val] = {};
        if (!byCategory[cat][val][r.MetricID]) byCategory[cat][val][r.MetricID] = newAcc();
        addRow(byCategory[cat][val][r.MetricID], r);
      });
    });

    var buckets = [];
    var allStudiesInScope = new Set();
    rows.forEach(function(r) { allStudiesInScope.add(r.StudyID); });
    var totalRow = { category: 'Total', value: 'Total', numStudies: allStudiesInScope.size, cells: {} };
    Object.keys(totalIdx).forEach(function(mid) {
      totalRow.cells[mid] = finalize(totalIdx[mid]);
    });
    buckets.push(totalRow);

    groupParams.forEach(function(cat) {
      if (!byCategory[cat]) return;
      Object.keys(byCategory[cat]).sort().forEach(function(val) {
        var cells = {};
        var studies = new Set();
        Object.keys(byCategory[cat][val]).forEach(function(mid) {
          var c = byCategory[cat][val][mid];
          cells[mid] = finalize(c);
          c.studies.forEach(function(s) { studies.add(s); });
        });
        buckets.push({ category: cat, value: val, numStudies: studies.size, cells: cells });
      });
    });

    return buckets;
  }

  function buildTable(rows, buckets) {
    var html = '<table class="po-table"><thead><tr>';
    html += '<th style="text-align:left;">Group</th>';
    html += '<th style="text-align:right;">Studies</th>';
    metricOrder.forEach(function(mid) {
      html += '<th title="' + escAttr(metricTooltip(mid)) + '">' + metricLabel(mid) + '</th>';
    });
    html += '</tr></thead><tbody>';

    var lastCategory = null;
    buckets.forEach(function(b) {
      if (b.category !== lastCategory && b.category !== 'Total') {
        html += '<tr class="po-category-header"><td colspan="' + (metricOrder.length + 2) + '">' +
          b.category + '</td></tr>';
      }
      lastCategory = b.category;

      var key = bucketKey(b.category, b.value);
      var isExpanded = !!expandedBuckets[key];
      var rowClass = b.category === 'Total' ? 'po-total-row' : 'po-bucket-row';
      var caret = isExpanded ? '▾' : '▸';

      html += '<tr class="' + rowClass + '" data-bucket-key="' + key + '" style="cursor:pointer;">';
      html += '<td class="po-bucket-label"><span class="po-caret">' + caret + '</span> ' + b.value + '</td>';
      html += '<td>' + (b.numStudies != null ? b.numStudies : '-') + '</td>';
      metricOrder.forEach(function(mid) {
        html += '<td class="po-cell-wrap">' + fmtCell(b.cells[mid]) + '</td>';
      });
      html += '</tr>';

      if (isExpanded) {
        var studyIds = studiesInBucket(rows, b.category, b.value);
        html += buildPerStudyRows(rows, studyIds);
      }
    });

    html += '</tbody></table>';
    return html;
  }

  function buildFilterBar() {
    var btnStyle = 'padding:2px 8px; font-size:12px; border-radius:3px; cursor:pointer;';
    var html = '<div class="po-filter-bar" style="background:#f5f5f5; padding:8px 12px; margin-bottom:10px; border:1px solid #ddd; border-radius:4px;">';
    html += '<div style="display:flex; gap:6px; align-items:center;">';
    html += '<button id="po-toggle-filters" style="' + btnStyle + ' background:#f5f5f5; color:#333; border:1px solid #ccc;">▸ Filters</button>';
    html += '<div style="flex:1;"></div>';
    html += '<button id="po-toggle-heatmap" style="' + btnStyle + ' background:#f5f5f5; color:#333; border:1px solid #ccc;">Heatmap: off</button>';
    html += '<button id="po-reset-filters" style="' + btnStyle + ' background:#2196f3; color:white; border:none;">Reset</button>';
    html += '<button id="po-expand-all" style="' + btnStyle + ' background:#f5f5f5; color:#333; border:1px solid #ccc;">+ Expand</button>';
    html += '<button id="po-collapse-all" style="' + btnStyle + ' background:#f5f5f5; color:#333; border:1px solid #ccc;">− Collapse</button>';
    html += '</div>';
    html += '<div id="po-filter-controls" style="display:none; margin-top:10px;">';
    html += '<div style="display:flex; gap:16px; flex-wrap:wrap; align-items:flex-start;">';
    filterParams.forEach(function(p) {
      html += '<div style="flex:1; min-width:160px;">';
      html += '<label style="display:block; font-weight:bold; margin-bottom:4px;">' + p + '</label>';
      html += '<select multiple data-filter-param="' + p + '" style="width:100%; min-height:90px;">';
      filterOptions[p].forEach(function(v) {
        html += '<option value="' + v + '">' + v + '</option>';
      });
      html += '</select></div>';
    });
    html += '<div style="flex:1; min-width:160px;">';
    html += '<label style="display:block; font-weight:bold; margin-bottom:4px;">Study</label>';
    html += '<select multiple data-filter-param="StudyID" style="width:100%; min-height:90px;">';
    allStudies.forEach(function(s) {
      html += '<option value="' + s + '">' + s + '</option>';
    });
    html += '</select></div>';
    html += '</div></div></div>';
    return html;
  }

  var styleHtml = '<style>' +
    '.po-container { font-family: sans-serif; }' +
    '.po-table { width: 100%; border-collapse: collapse; margin-top: 10px; }' +
    '.po-heat-cell { padding: 6px 8px; text-align: right; min-height: 20px; }' +
    '.po-table th, .po-table td { border: 1px solid #ddd; padding: 6px 8px; vertical-align: top; text-align: right; font-size: 13px; }' +
    '.po-table td.po-cell-wrap { padding: 0; }' +
    '.po-table th { background: #f5f5f5; text-align: center; }' +
    '.po-table tr.po-total-row { background: #e8eef7; font-weight: bold; }' +
    '.po-table tr.po-category-header td { background: #fafafa; text-align: left; font-weight: bold; color: #555; }' +
    '.po-table td.po-bucket-label { text-align: left; white-space: nowrap; }' +
    '.po-table tr.po-bucket-row:hover { background: #f9f9f9; }' +
    '.po-rate { color: #2c3e50; }' +
    '.po-empty { color: #aaa; }' +
    '.po-caret { display: inline-block; width: 14px; color: #888; }' +
    '</style>';

  el.innerHTML = styleHtml +
    '<div class="po-container"><h3>Portfolio Overview</h3>' +
    buildFilterBar() +
    '<div id="po-filter-info" style="margin-bottom:6px; font-size:12px; color:#666;"></div>' +
    '<div id="po-table-container"></div>' +
    '</div>';

  function rerender() {
    var rows = filteredPerStudy();
    var infoEl = el.querySelector('#po-filter-info');
    if (infoEl) {
      var nStudies = new Set(rows.map(function(r) { return r.StudyID; })).size;
      infoEl.textContent = 'Showing ' + nStudies + ' / ' + allStudies.length + ' studies';
    }
    var container = el.querySelector('#po-table-container');
    if (container) {
      var buckets = computeBuckets(rows);
      container.innerHTML = buildTable(rows, buckets);
      // Wire expand/collapse for the current pass.
      container.querySelectorAll('tr[data-bucket-key]').forEach(function(tr) {
        tr.addEventListener('click', function() {
          var key = tr.getAttribute('data-bucket-key');
          if (expandedBuckets[key]) {
            delete expandedBuckets[key];
          } else {
            expandedBuckets[key] = true;
          }
          rerender();
        });
      });
    }
  }

  el.querySelectorAll('select[data-filter-param]').forEach(function(sel) {
    sel.addEventListener('change', function() {
      var p = sel.getAttribute('data-filter-param');
      filterState[p] = Array.from(sel.selectedOptions).map(function(o) { return o.value; });
      rerender();
    });
  });
  var toggleBtn = el.querySelector('#po-toggle-filters');
  var filterControls = el.querySelector('#po-filter-controls');
  if (toggleBtn && filterControls) {
    toggleBtn.addEventListener('click', function() {
      var open = filterControls.style.display !== 'none';
      filterControls.style.display = open ? 'none' : 'block';
      toggleBtn.innerHTML = (open ? '▸' : '▾') + ' Filters';
    });
  }
  var heatBtn = el.querySelector('#po-toggle-heatmap');
  if (heatBtn) {
    heatBtn.addEventListener('click', function() {
      heatmapOn = !heatmapOn;
      heatBtn.textContent = 'Heatmap: ' + (heatmapOn ? 'on' : 'off');
      heatBtn.style.background = heatmapOn ? '#e8eef7' : '#f5f5f5';
      rerender();
    });
  }
  var resetBtn = el.querySelector('#po-reset-filters');
  if (resetBtn) {
    resetBtn.addEventListener('click', function() {
      Object.keys(filterState).forEach(function(k) { filterState[k] = []; });
      el.querySelectorAll('select[data-filter-param]').forEach(function(sel) { sel.selectedIndex = -1; });
      rerender();
    });
  }
  var expandAllBtn = el.querySelector('#po-expand-all');
  if (expandAllBtn) {
    expandAllBtn.addEventListener('click', function() {
      var rows = filteredPerStudy();
      computeBuckets(rows).forEach(function(b) {
        if (b.category !== 'Total') expandedBuckets[bucketKey(b.category, b.value)] = true;
      });
      rerender();
    });
  }
  var collapseAllBtn = el.querySelector('#po-collapse-all');
  if (collapseAllBtn) {
    collapseAllBtn.addEventListener('click', function() {
      expandedBuckets = {};
      rerender();
    });
  }
  rerender();
}
