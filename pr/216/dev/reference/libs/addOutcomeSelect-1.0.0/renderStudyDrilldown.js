// Study Drilldown Panel
// Renders a detailed study-level view showing key metrics organized into
// tiles/cards with per-site bar charts. Called from renderPortfolioOverviewTable
// when a user clicks a study name in the expanded per-study rows.

function renderStudyDrilldown(container, opts) {
  var studyId = opts.studyId;
  var perStudyData = Array.isArray(opts.perStudyData) ? opts.perStudyData : [];
  var siteData = Array.isArray(opts.siteData) ? opts.siteData : [];
  var attrs = opts.studyAttrs || {};
  var metricsMeta = Array.isArray(opts.metricsMeta) ? opts.metricsMeta : [];
  var portfolioTotals = opts.portfolioTotals || {};
  var onBack = opts.onBack;

  // Filter data to this study.
  var studyMetrics = perStudyData.filter(function(r) { return r.StudyID === studyId; });
  var siteRows = siteData.filter(function(r) { return r.StudyID === studyId; });

  // Build metric metadata lookup.
  var metaLookup = {};
  metricsMeta.forEach(function(m) {
    if (m && m.MetricID) metaLookup[m.MetricID] = m;
  });

  // Get all MetricIDs for this study.
  var metricIds = studyMetrics.map(function(r) { return r.MetricID; }).sort();

  // Define metric groups — any MetricID not listed falls into "Other Metrics".
  var GROUPS = [
    { name: 'Enrollment', ids: ['Analysis_kri0012', 'Analysis_kri0014'] },
    { name: 'Safety', ids: ['Analysis_kri0001', 'Analysis_kri0002', 'Analysis_kri0005', 'Analysis_kri0015'] },
    { name: 'Protocol Compliance', ids: ['Analysis_kri0003', 'Analysis_kri0004', 'Analysis_kri0006', 'Analysis_kri0007'] },
    { name: 'Data Management', ids: ['Analysis_kri0008', 'Analysis_kri0009', 'Analysis_kri0010', 'Analysis_kri0011', 'Analysis_kri0013'] }
  ];

  var assignedIds = new Set();
  GROUPS.forEach(function(g) { g.ids.forEach(function(id) { assignedIds.add(id); }); });
  var otherIds = metricIds.filter(function(id) { return !assignedIds.has(id); });
  if (otherIds.length > 0) {
    GROUPS.push({ name: 'Other Metrics', ids: otherIds });
  }

  // Build study metric data lookup.
  var studyMetricLookup = {};
  studyMetrics.forEach(function(r) { studyMetricLookup[r.MetricID] = r; });

  // Build site data lookup: { MetricID: [rows] }.
  var siteByMetric = {};
  siteRows.forEach(function(r) {
    if (!siteByMetric[r.MetricID]) siteByMetric[r.MetricID] = [];
    siteByMetric[r.MetricID].push(r);
  });

  // --- Helpers ---
  function escAttr(s) {
    return String(s).replace(/&/g, '&amp;').replace(/"/g, '&quot;')
      .replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function fmtRate(rate) {
    if (rate === null || rate === undefined || isNaN(rate)) return '\u2014';
    return (rate * 100).toFixed(1) + '%';
  }

  function fmtCount(n) {
    if (n === null || n === undefined) return '\u2014';
    return String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  }

  function flagColor(flag) {
    if (flag === -2 || flag === 2) return '#e53935';
    if (flag === -1 || flag === 1) return '#ffb300';
    return '#4caf50';
  }

  // --- Build tile HTML for a single metric ---
  function buildTile(data, meta, sites) {
    var abbr = meta.Abbreviation || meta.Metric || data.MetricID;
    var fullName = meta.Metric || data.MetricID;
    var rate = data.Rate;
    var num = data.Numerator;
    var den = data.Denominator;

    var n2 = data.FlagN2 || 0;
    var n1 = data.FlagN1 || 0;
    var z = data.Flag0 || 0;
    var p1 = data.FlagP1 || 0;
    var p2 = data.FlagP2 || 0;
    var totalFlags = n2 + n1 + z + p1 + p2;
    var red = n2 + p2;
    var amber = n1 + p1;
    var green = z;

    // Compare to portfolio.
    var pTotal = portfolioTotals[data.MetricID];
    var pRate = pTotal ? pTotal.Rate : null;
    var cmpIcon = '';
    var cmpTip = '';
    if (rate != null && !isNaN(rate) && pRate != null && !isNaN(pRate)) {
      var diff = rate - pRate;
      if (Math.abs(diff) < 0.001) {
        cmpIcon = '<span class="sd-cmp-icon sd-cmp-eq" title="Same as portfolio (' + fmtRate(pRate) + ')">=</span>';
      } else if (diff > 0) {
        cmpIcon = '<span class="sd-cmp-icon sd-cmp-up" title="Above portfolio (' + fmtRate(pRate) + ')">&uarr;</span>';
      } else {
        cmpIcon = '<span class="sd-cmp-icon sd-cmp-down" title="Below portfolio (' + fmtRate(pRate) + ')">&darr;</span>';
      }
    }

    var t = '<div class="sd-tile" data-metric-id="' + escAttr(data.MetricID) + '" style="cursor:pointer;">';
    t += '<div class="sd-tile-header">';
    t += '<div><div class="sd-tile-abbr">' + escAttr(abbr) + '</div>';
    t += '<div class="sd-tile-name">' + escAttr(fullName) + '</div></div>';
    t += '</div>';

    t += '<div class="sd-tile-rate">' + fmtRate(rate) + ' ' + cmpIcon + '</div>';
    t += '<div class="sd-tile-counts sd-detail">' + fmtCount(num) + ' / ' + fmtCount(den);
    if (pRate != null && !isNaN(pRate)) {
      t += ' <span class="sd-portfolio-rate">portfolio: ' + fmtRate(pRate) + '</span>';
    }
    t += '</div>';

    // Flag distribution bar.
    if (totalFlags > 0) {
      t += '<div class="sd-detail"><div class="sd-flag-bar" title="Flag distribution across ' + totalFlags + ' sites">';
      var segments = [
        { count: n2, color: 'rgba(229,57,53,0.7)', label: '-2' },
        { count: n1, color: 'rgba(255,179,0,0.7)', label: '-1' },
        { count: z, color: 'rgba(76,175,80,0.5)', label: '0' },
        { count: p1, color: 'rgba(255,179,0,0.7)', label: '+1' },
        { count: p2, color: 'rgba(229,57,53,0.7)', label: '+2' }
      ];
      segments.forEach(function(seg) {
        if (seg.count > 0) {
          var pct = (seg.count / totalFlags * 100).toFixed(1);
          t += '<div class="sd-flag-bar-seg" style="width:' + pct +
            '%; background:' + seg.color + ';" title="Flag ' + seg.label +
            ': ' + seg.count + ' sites (' + pct + '%)"></div>';
        }
      });
      t += '</div>';

      // Flag legend.
      t += '<div class="sd-flag-legend">';
      if (red > 0) t += '<span><span class="sd-flag-dot" style="background:#e53935;"></span>' + red + ' red</span>';
      if (amber > 0) t += '<span><span class="sd-flag-dot" style="background:#ffb300;"></span>' + amber + ' amber</span>';
      if (green > 0) t += '<span><span class="sd-flag-dot" style="background:#4caf50;"></span>' + green + ' green</span>';
      t += '</div></div>';
    }

    // Site-level bar chart.
    if (sites.length > 0) {
      var sortedSites = sites.slice().sort(function(a, b) {
        var rateA = a.Denominator > 0 ? a.Numerator / a.Denominator : 0;
        var rateB = b.Denominator > 0 ? b.Numerator / b.Denominator : 0;
        return rateA - rateB;
      });

      var maxRate = 0;
      sortedSites.forEach(function(s) {
        var r = s.Denominator > 0 ? s.Numerator / s.Denominator : 0;
        if (r > maxRate) maxRate = r;
      });
      if (maxRate === 0) maxRate = 1;

      t += '<div class="sd-site-chart sd-detail">';
      t += '<div style="font-size:11px; color:#888; margin-bottom:4px;">Per-site rates (' + sites.length + ' sites)</div>';
      t += '<div class="sd-site-bars">';
      sortedSites.forEach(function(s) {
        var sRate = s.Denominator > 0 ? s.Numerator / s.Denominator : 0;
        var h = Math.max(2, (sRate / maxRate * 100));
        var color = flagColor(s.Flag != null ? s.Flag : 0);
        var tip = s.GroupID + ': ' + (sRate * 100).toFixed(1) + '% (' +
          s.Numerator + '/' + s.Denominator + ') Flag: ' + (s.Flag != null ? s.Flag : 'NA');
        t += '<div class="sd-site-bar" style="height:' + h.toFixed(0) +
          '%; background:' + color + ';" title="' + escAttr(tip) + '"></div>';
      });
      t += '</div></div>';
    }

    t += '</div>';
    return t;
  }

  // --- Build header HTML ---
  var headerAttrs = [
    'status', 'phase', 'therapeutic_area', 'product',
    'protocol_indication', 'nickname', 'protocol_title'
  ];
  var attrPills = [];
  headerAttrs.forEach(function(key) {
    var val = attrs[key];
    if (!val || val === 'NA') return;
    var label = key.replace(/_/g, ' ').replace(/\b\w/g, function(c) { return c.toUpperCase(); });
    attrPills.push('<span class="sd-attr-pill"><strong>' + escAttr(label) +
      ':</strong> ' + escAttr(val) + '</span>');
  });

  var siteCount = new Set(siteRows.map(function(r) { return r.GroupID; })).size;

  // --- Assemble HTML ---
  var html = '<style>' +
    '.sd-panel { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }' +
    '.sd-back-btn { background: none; border: none; color: #2196f3; cursor: pointer; font-size: 14px; padding: 8px 0; margin-bottom: 8px; }' +
    '.sd-back-btn:hover { text-decoration: underline; }' +
    '.sd-header { background: linear-gradient(135deg, #1a237e 0%, #283593 100%); color: white; padding: 20px 24px; border-radius: 8px; margin-bottom: 24px; }' +
    '.sd-study-id { font-size: 24px; font-weight: 700; margin-bottom: 8px; }' +
    '.sd-attr-pills { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 8px; }' +
    '.sd-attr-pill { background: rgba(255,255,255,0.15); padding: 4px 10px; border-radius: 12px; font-size: 12px; }' +
    '.sd-header-meta { font-size: 13px; opacity: 0.85; }' +
    '.sd-section { margin-bottom: 24px; }' +
    '.sd-section-title { font-size: 16px; font-weight: 600; color: #37474f; border-bottom: 2px solid #e0e0e0; padding-bottom: 6px; margin-bottom: 12px; }' +
    '.sd-tile-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 16px; }' +
    '.sd-tile { background: #fff; border: 1px solid #e0e0e0; border-radius: 8px; padding: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.08); }' +
    '.sd-tile-header { display: flex; justify-content: space-between; align-items: baseline; margin-bottom: 4px; }' +
    '.sd-tile-abbr { font-size: 16px; font-weight: 700; color: #1a237e; }' +
    '.sd-tile-name { font-size: 11px; color: #666; margin-top: 2px; }' +
    '.sd-tile-rate { font-size: 32px; font-weight: 700; color: #263238; text-align: center; margin: 8px 0; }' +
    '.sd-mode-metric .sd-tile-rate { font-size: 24px; margin: 4px 0; }' +
    '.sd-tile-counts { text-align: center; font-size: 13px; color: #666; margin-bottom: 12px; }' +
    '.sd-mode-metric .sd-tile { padding: 10px 14px; }' +
    '.sd-mode-metric .sd-tile-grid { grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 10px; }' +
    '.sd-detail { }' +
    '.sd-mode-metric .sd-detail { display: none; }' +
    '.sd-toggle-bar { display: flex; gap: 8px; align-items: center; margin-bottom: 16px; }' +
    '.sd-toggle-btn { padding: 4px 12px; font-size: 13px; border: 1px solid #ccc; border-radius: 4px; cursor: pointer; background: #f5f5f5; color: #333; }' +
    '.sd-toggle-btn.sd-active { background: #1a237e; color: white; border-color: #1a237e; }' +
    '.sd-site-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.4); z-index: 1000; display: flex; align-items: center; justify-content: center; }' +
    '.sd-site-modal { background: white; border-radius: 10px; box-shadow: 0 8px 32px rgba(0,0,0,0.25); max-width: 800px; width: 90%; max-height: 80vh; display: flex; flex-direction: column; }' +
    '.sd-site-modal-header { padding: 16px 20px; border-bottom: 1px solid #e0e0e0; display: flex; justify-content: space-between; align-items: center; }' +
    '.sd-site-modal-header h3 { margin: 0; font-size: 16px; color: #1a237e; }' +
    '.sd-site-modal-close { background: none; border: none; font-size: 22px; cursor: pointer; color: #999; padding: 0 4px; }' +
    '.sd-site-modal-close:hover { color: #333; }' +
    '.sd-site-modal-body { padding: 16px 20px; overflow-y: auto; }' +
    '.sd-site-table { width: 100%; border-collapse: collapse; font-size: 13px; }' +
    '.sd-site-table th, .sd-site-table td { border: 1px solid #e0e0e0; padding: 6px 10px; text-align: right; }' +
    '.sd-site-table th { background: #f5f5f5; text-align: center; position: sticky; top: 0; }' +
    '.sd-site-table td:first-child { text-align: left; font-weight: 500; }' +
    '.sd-site-table tr:hover { background: #f9f9f9; }' +
    '.sd-flag-cell { display: inline-block; padding: 2px 8px; border-radius: 3px; font-weight: 600; font-size: 12px; }' +
    '.sd-flag-bar { display: flex; height: 16px; border-radius: 3px; overflow: hidden; margin-bottom: 8px; }' +
    '.sd-flag-bar-seg { height: 100%; min-width: 1px; }' +
    '.sd-flag-legend { display: flex; gap: 8px; font-size: 11px; color: #666; justify-content: center; flex-wrap: wrap; }' +
    '.sd-flag-dot { display: inline-block; width: 8px; height: 8px; border-radius: 50%; margin-right: 3px; vertical-align: middle; }' +
    '.sd-site-chart { margin-top: 12px; }' +
    '.sd-site-bars { display: flex; align-items: flex-end; gap: 1px; height: 50px; }' +
    '.sd-site-bar { flex: 1; min-width: 3px; max-width: 20px; border-radius: 1px 1px 0 0; }' +
    '.sd-cmp-icon { display: inline-block; font-size: 20px; font-weight: 700; vertical-align: middle; margin-left: 4px; }' +
    '.sd-cmp-up { color: #e53935; }' +
    '.sd-cmp-down { color: #2196f3; }' +
    '.sd-cmp-eq { color: #9e9e9e; font-size: 16px; }' +
    '.sd-portfolio-rate { color: #999; font-size: 11px; }' +
    '</style>';

  html += '<div class="sd-panel sd-mode-metric">';
  html += '<button class="sd-back-btn" id="sd-back-btn">\u2190 Back to Portfolio Overview</button>';

  // View toggle.
  html += '<div class="sd-toggle-bar">';
  html += '<span style="font-size:13px; color:#666;">View:</span>';
  html += '<button class="sd-toggle-btn sd-active" data-mode="metric">Metric Only</button>';
  html += '<button class="sd-toggle-btn" data-mode="detailed">Detailed</button>';
  html += '</div>';

  // Header.
  html += '<div class="sd-header">';
  html += '<div class="sd-study-id">' + escAttr(studyId) + '</div>';
  if (attrPills.length > 0) html += '<div class="sd-attr-pills">' + attrPills.join('') + '</div>';
  html += '<div class="sd-header-meta">' + siteCount + ' sites analyzed</div>';
  html += '</div>';

  // Metric sections.
  GROUPS.forEach(function(group) {
    var groupMetrics = group.ids.filter(function(mid) { return studyMetricLookup[mid]; });
    if (groupMetrics.length === 0) return;

    html += '<div class="sd-section">';
    html += '<div class="sd-section-title">' + escAttr(group.name) + '</div>';
    html += '<div class="sd-tile-grid">';

    groupMetrics.forEach(function(mid) {
      var data = studyMetricLookup[mid];
      var meta = metaLookup[mid] || {};
      var sites = siteByMetric[mid] || [];
      html += buildTile(data, meta, sites);
    });

    html += '</div></div>';
  });

  html += '</div>';
  html += '<div id="sd-site-overlay" class="sd-site-overlay" style="display:none;"></div>';

  container.innerHTML = html;

  // Wire back button.
  var backBtn = container.querySelector('#sd-back-btn');
  if (backBtn && onBack) {
    backBtn.addEventListener('click', onBack);
  }

  // Wire view toggle.
  var panel = container.querySelector('.sd-panel');
  container.querySelectorAll('.sd-toggle-btn').forEach(function(btn) {
    btn.addEventListener('click', function() {
      var mode = btn.getAttribute('data-mode');
      container.querySelectorAll('.sd-toggle-btn').forEach(function(b) { b.classList.remove('sd-active'); });
      btn.classList.add('sd-active');
      if (mode === 'metric') {
        panel.classList.add('sd-mode-metric');
      } else {
        panel.classList.remove('sd-mode-metric');
      }
    });
  });

  // Wire tile clicks to show site detail table.
  function flagBadge(flag) {
    if (flag === null || flag === undefined) return '<span class="sd-flag-cell" style="background:#eee; color:#999;">NA</span>';
    var bg, fg;
    if (flag === -2 || flag === 2) { bg = 'rgba(229,57,53,0.15)'; fg = '#c62828'; }
    else if (flag === -1 || flag === 1) { bg = 'rgba(255,179,0,0.15)'; fg = '#e65100'; }
    else { bg = 'rgba(76,175,80,0.15)'; fg = '#2e7d32'; }
    return '<span class="sd-flag-cell" style="background:' + bg + '; color:' + fg + ';">' + flag + '</span>';
  }

  function showSiteTable(metricId) {
    var sites = (siteByMetric[metricId] || []).slice().sort(function(a, b) {
      var rA = a.Denominator > 0 ? a.Numerator / a.Denominator : 0;
      var rB = b.Denominator > 0 ? b.Numerator / b.Denominator : 0;
      return rB - rA;
    });
    var meta = metaLookup[metricId] || {};
    var title = (meta.Abbreviation || metricId) + ' \u2014 ' + (meta.Metric || '');

    var modalHtml = '<div class="sd-site-modal">';
    modalHtml += '<div class="sd-site-modal-header"><h3>' + escAttr(title) + '</h3>';
    modalHtml += '<button class="sd-site-modal-close">&times;</button></div>';
    modalHtml += '<div class="sd-site-modal-body">';

    if (sites.length === 0) {
      modalHtml += '<p style="color:#999;">No site-level data available for this metric.</p>';
    } else {
      modalHtml += '<table class="sd-site-table"><thead><tr>';
      modalHtml += '<th>Site</th><th>Numerator</th><th>Denominator</th><th>Rate</th><th>Score</th><th>Flag</th>';
      modalHtml += '</tr></thead><tbody>';
      sites.forEach(function(s) {
        var sRate = s.Denominator > 0 ? s.Numerator / s.Denominator : null;
        modalHtml += '<tr>';
        modalHtml += '<td>' + escAttr(s.GroupID) + '</td>';
        modalHtml += '<td>' + fmtCount(s.Numerator) + '</td>';
        modalHtml += '<td>' + fmtCount(s.Denominator) + '</td>';
        modalHtml += '<td>' + fmtRate(sRate) + '</td>';
        modalHtml += '<td>' + (s.Score != null ? Number(s.Score).toFixed(2) : '\u2014') + '</td>';
        modalHtml += '<td style="text-align:center;">' + flagBadge(s.Flag) + '</td>';
        modalHtml += '</tr>';
      });
      modalHtml += '</tbody></table>';
    }
    modalHtml += '</div></div>';

    var overlay = container.querySelector('#sd-site-overlay');
    overlay.innerHTML = modalHtml;
    overlay.style.display = 'flex';

    overlay.querySelector('.sd-site-modal-close').addEventListener('click', function() {
      overlay.style.display = 'none';
      overlay.innerHTML = '';
    });
    overlay.addEventListener('click', function(e) {
      if (e.target === overlay) {
        overlay.style.display = 'none';
        overlay.innerHTML = '';
      }
    });
  }

  container.querySelectorAll('.sd-tile[data-metric-id]').forEach(function(tile) {
    tile.addEventListener('click', function() {
      showSiteTable(tile.getAttribute('data-metric-id'));
    });
  });
}
