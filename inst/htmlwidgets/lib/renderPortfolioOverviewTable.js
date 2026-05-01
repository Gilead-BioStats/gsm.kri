// Portfolio Overview Table Widget
// D1: portfolio rollup table. One column per metric (sorted by MetricID).
// One row for the portfolio total plus drill-down rows grouped by
// study-level params (therapeutic_area, protocol_indication, phase, status,
// product). Each cell shows numerator / denominator / rate.
// D2: client-side filter bar layered above the table. Filtering a study set
// recomputes the total + drill-down buckets in place from the per-study
// contribution table.
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

  // Build study attribute lookup: { StudyID: { Param: Value } }.
  var studyAttrLookup = {};
  studyAttrs.forEach(function(row) {
    if (!studyAttrLookup[row.StudyID]) studyAttrLookup[row.StudyID] = {};
    studyAttrLookup[row.StudyID][row.Param] = row.Value;
  });

  // Build distinct values per filter param for the multi-selects.
  var allStudies = Array.from(new Set(perStudy.map(function(r) { return r.StudyID; }))).sort();
  var filterOptions = {};
  filterParams.forEach(function(p) {
    var values = new Set();
    Object.keys(studyAttrLookup).forEach(function(sid) {
      if (studyAttrLookup[sid][p] != null) values.add(studyAttrLookup[sid][p]);
    });
    filterOptions[p] = Array.from(values).sort();
  });

  // Filter state: empty selection means "no filter for this dimension".
  var filterState = {};
  filterParams.forEach(function(p) { filterState[p] = []; });
  filterState.StudyID = [];

  function fmtRate(rate) {
    if (rate === null || rate === undefined || isNaN(rate)) return '-';
    return (rate * 100).toFixed(1) + '%';
  }

  function fmtCell(cell) {
    if (!cell || cell.Denominator === 0) return '<span class="po-empty">-</span>';
    return (
      '<span class="po-num">' + cell.Numerator + '</span>' +
      ' / ' +
      '<span class="po-den">' + cell.Denominator + '</span>' +
      '<br><span class="po-rate">' + fmtRate(cell.Rate) + '</span>'
    );
  }

  // Apply current filter state to perStudy rows. Returns the surviving subset.
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

  // Recompute total + drill-down buckets from the filtered per-study set.
  function computeBuckets(rows) {
    var totalIdx = {}; // MetricID -> {num, den, studies:Set}
    var byCategory = {}; // category -> { value -> { metric -> {num, den, studies}}}

    rows.forEach(function(r) {
      if (!totalIdx[r.MetricID]) totalIdx[r.MetricID] = { num: 0, den: 0, studies: new Set() };
      totalIdx[r.MetricID].num += (r.Numerator || 0);
      totalIdx[r.MetricID].den += (r.Denominator || 0);
      totalIdx[r.MetricID].studies.add(r.StudyID);

      var attrs = studyAttrLookup[r.StudyID] || {};
      groupParams.forEach(function(cat) {
        var val = attrs[cat];
        if (val == null) return;
        if (!byCategory[cat]) byCategory[cat] = {};
        if (!byCategory[cat][val]) byCategory[cat][val] = {};
        if (!byCategory[cat][val][r.MetricID]) byCategory[cat][val][r.MetricID] = { num: 0, den: 0, studies: new Set() };
        byCategory[cat][val][r.MetricID].num += (r.Numerator || 0);
        byCategory[cat][val][r.MetricID].den += (r.Denominator || 0);
        byCategory[cat][val][r.MetricID].studies.add(r.StudyID);
      });
    });

    var buckets = [];
    var allStudiesInScope = new Set();
    rows.forEach(function(r) { allStudiesInScope.add(r.StudyID); });
    var totalRow = { category: 'Total', value: 'Total', numStudies: allStudiesInScope.size, cells: {} };
    Object.keys(totalIdx).forEach(function(mid) {
      var c = totalIdx[mid];
      totalRow.cells[mid] = {
        Numerator: c.num,
        Denominator: c.den,
        Rate: c.den > 0 ? c.num / c.den : null
      };
    });
    buckets.push(totalRow);

    groupParams.forEach(function(cat) {
      if (!byCategory[cat]) return;
      Object.keys(byCategory[cat]).sort().forEach(function(val) {
        var cells = {};
        var studies = new Set();
        Object.keys(byCategory[cat][val]).forEach(function(mid) {
          var c = byCategory[cat][val][mid];
          cells[mid] = {
            Numerator: c.num,
            Denominator: c.den,
            Rate: c.den > 0 ? c.num / c.den : null
          };
          c.studies.forEach(function(s) { studies.add(s); });
        });
        buckets.push({ category: cat, value: val, numStudies: studies.size, cells: cells });
      });
    });

    return buckets;
  }

  function buildTable(buckets) {
    var html = '<table class="po-table"><thead><tr>';
    html += '<th style="text-align:left;">Group</th>';
    html += '<th style="text-align:right;">Studies</th>';
    metricOrder.forEach(function(mid) { html += '<th>' + mid + '</th>'; });
    html += '</tr></thead><tbody>';

    var lastCategory = null;
    buckets.forEach(function(b) {
      if (b.category !== lastCategory && b.category !== 'Total') {
        html += '<tr class="po-category-header"><td colspan="' + (metricOrder.length + 2) + '">' +
          b.category + '</td></tr>';
      }
      lastCategory = b.category;

      var rowClass = b.category === 'Total' ? 'po-total-row' : 'po-bucket-row';
      html += '<tr class="' + rowClass + '">';
      html += '<td class="po-bucket-label">' + b.value + '</td>';
      html += '<td>' + (b.numStudies != null ? b.numStudies : '-') + '</td>';
      metricOrder.forEach(function(mid) {
        html += '<td>' + fmtCell(b.cells[mid]) + '</td>';
      });
      html += '</tr>';
    });

    html += '</tbody></table>';
    return html;
  }

  function buildFilterBar() {
    var html = '<div class="po-filter-bar" style="background:#f5f5f5; padding:12px; margin-bottom:10px; border:1px solid #ddd; border-radius:4px;">';
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
    // Study filter (always present per Q3 / D2 spec)
    html += '<div style="flex:1; min-width:160px;">';
    html += '<label style="display:block; font-weight:bold; margin-bottom:4px;">Study</label>';
    html += '<select multiple data-filter-param="StudyID" style="width:100%; min-height:90px;">';
    allStudies.forEach(function(s) {
      html += '<option value="' + s + '">' + s + '</option>';
    });
    html += '</select></div>';
    html += '<div style="flex:0; align-self:flex-end;">';
    html += '<button id="po-reset-filters" style="padding:6px 12px; background:#2196f3; color:white; border:none; border-radius:3px; cursor:pointer;">Reset</button>';
    html += '</div>';
    html += '</div></div>';
    return html;
  }

  var styleHtml = '<style>' +
    '.po-container { font-family: sans-serif; }' +
    '.po-table { width: 100%; border-collapse: collapse; margin-top: 10px; }' +
    '.po-table th, .po-table td { border: 1px solid #ddd; padding: 6px 8px; vertical-align: top; text-align: right; font-size: 13px; }' +
    '.po-table th { background: #f5f5f5; text-align: center; }' +
    '.po-table tr.po-total-row { background: #e8eef7; font-weight: bold; }' +
    '.po-table tr.po-category-header td { background: #fafafa; text-align: left; font-weight: bold; color: #555; }' +
    '.po-table td.po-bucket-label { text-align: left; }' +
    '.po-rate { color: #2c3e50; }' +
    '.po-empty { color: #aaa; }' +
    '</style>';

  el.innerHTML = styleHtml +
    '<div class="po-container"><h3>Portfolio Overview</h3>' +
    buildFilterBar() +
    '<div id="po-filter-info" style="margin-bottom:6px; font-size:12px; color:#666;"></div>' +
    '<div id="po-table-container">' + buildTable(computeBuckets(perStudy)) + '</div>' +
    '</div>';

  function rerender() {
    var rows = filteredPerStudy();
    var infoEl = el.querySelector('#po-filter-info');
    if (infoEl) {
      var nStudies = new Set(rows.map(function(r) { return r.StudyID; })).size;
      infoEl.textContent = 'Showing ' + nStudies + ' / ' + allStudies.length + ' studies';
    }
    var container = el.querySelector('#po-table-container');
    if (container) container.innerHTML = buildTable(computeBuckets(rows));
  }

  el.querySelectorAll('select[data-filter-param]').forEach(function(sel) {
    sel.addEventListener('change', function() {
      var p = sel.getAttribute('data-filter-param');
      filterState[p] = Array.from(sel.selectedOptions).map(function(o) { return o.value; });
      rerender();
    });
  });
  var resetBtn = el.querySelector('#po-reset-filters');
  if (resetBtn) {
    resetBtn.addEventListener('click', function() {
      Object.keys(filterState).forEach(function(k) { filterState[k] = []; });
      el.querySelectorAll('select[data-filter-param]').forEach(function(sel) { sel.selectedIndex = -1; });
      rerender();
    });
  }
  rerender();
}
