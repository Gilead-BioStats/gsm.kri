// Faceted study-level scatter matrix.
// One mini SVG scatter per metric, one point per study at (Denominator, Numerator).
// Hovering a point highlights that study's points across every facet.
// A color-by control recolors points based on a study attribute (e.g. TA, phase).
function renderStudyScatterMatrix(el, input) {
  if (!input) {
    el.innerHTML = '<em>No input provided to widget</em>';
    return;
  }
  var perStudy = Array.isArray(input.dfPerStudy) ? input.dfPerStudy : [];
  if (perStudy.length === 0) {
    el.innerHTML = '<em>No per-study data found in widget input</em>';
    return;
  }
  var perSite = Array.isArray(input.dfPerSite) ? input.dfPerSite : [];
  var studyAttrs = Array.isArray(input.dfStudyAttrs) ? input.dfStudyAttrs : [];
  var metricOrder = Array.isArray(input.vMetricOrder) && input.vMetricOrder.length > 0
    ? input.vMetricOrder.slice().sort()
    : Array.from(new Set(perStudy.map(function(r) { return r.MetricID; }))).sort();
  var colorParams = Array.isArray(input.vColorParams) && input.vColorParams.length > 0
    ? input.vColorParams
    : ['therapeutic_area', 'phase', 'status', 'product', 'protocol_indication'];

  var studyAttrLookup = {};
  studyAttrs.forEach(function(row) {
    if (!studyAttrLookup[row.StudyID]) studyAttrLookup[row.StudyID] = {};
    studyAttrLookup[row.StudyID][row.Param] = row.Value;
  });

  var metricLabels = {};
  var metricsMeta = Array.isArray(input.dfMetrics) ? input.dfMetrics : [];
  metricsMeta.forEach(function(m) {
    if (m && m.MetricID) metricLabels[m.MetricID] = m.Abbreviation || m.Metric || m.MetricID;
  });
  function metricLabel(mid) { return metricLabels[mid] || mid; }

  // Color palette — categorical, friendly to repetition.
  var palette = [
    '#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd',
    '#8c564b', '#e377c2', '#7f7f7f', '#bcbd22', '#17becf',
    '#393b79', '#637939', '#8c6d31', '#843c39', '#7b4173'
  ];
  function colorFor(value, valuesIndex) {
    if (value == null || value === '') return '#bbb';
    return palette[valuesIndex[value] % palette.length];
  }

  function escAttr(s) {
    return String(s).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  var colorBy = '';

  // Layout container.
  el.innerHTML =
    '<style>' +
    '.ssm-container { font-family: sans-serif; }' +
    '.ssm-controls { display:flex; gap:6px; align-items:center; padding:4px 6px; background:#f5f5f5; border:1px solid #ddd; border-radius:3px; margin-bottom:4px; font-size:11px; }' +
    '.ssm-controls label { font-weight:bold; }' +
    '.ssm-controls select { padding:1px 4px; font-size:11px; }' +
    '.ssm-axes-note { color:#666; font-style:italic; margin-left:8px; }' +
    '.ssm-grid { display:grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap:2px; }' +
    '.ssm-facet { border:1px solid #ddd; padding:1px 2px 0; background:#fff; }' +
    '.ssm-facet h4 { margin:0; font-size:11px; color:#333; font-weight:600; line-height:1.3; }' +
    '.ssm-facet svg { width:100%; height:130px; display:block; }' +
    '.ssm-pt { cursor:pointer; transition: r 0.1s, stroke-width 0.1s; }' +
    '.ssm-pt-study { stroke:#fff; stroke-width:0.5; }' +
    '.ssm-pt-site { fill: none; stroke-width:1.2; }' +
    '.ssm-pt.dim { opacity: 0.15; }' +
    '.ssm-pt.hl { stroke:#000; stroke-width:1.8; }' +
    '.ssm-axis line, .ssm-axis path { stroke:#888; }' +
    '.ssm-axis text { fill:#555; font-size:9px; }' +
    '.ssm-legend { display:flex; flex-wrap:wrap; gap:8px; padding:6px 0; font-size:11px; }' +
    '.ssm-legend span.swatch { display:inline-block; width:10px; height:10px; border-radius:50%; margin-right:4px; vertical-align:middle; }' +
    '.ssm-tooltip { position:fixed; pointer-events:none; background:rgba(33,33,33,0.92); color:#fff; padding:4px 8px; border-radius:3px; font-size:11px; z-index:9999; white-space:pre; display:none; }' +
    '</style>' +
    '<div class="ssm-container">' +
    '<div class="ssm-controls">' +
    '<label for="ssm-color-by">Color by:</label>' +
    '<select id="ssm-color-by"><option value="">(none)</option>' +
    colorParams.map(function(p) { return '<option value="' + escAttr(p) + '">' + p + '</option>'; }).join('') +
    '</select>' +
    '<label for="ssm-chart-type" style="margin-left:8px;">Chart:</label>' +
    '<select id="ssm-chart-type">' +
    '<option value="scatter">Scatter</option>' +
    '<option value="bar-rate">Bar (Rate)</option>' +
    '<option value="bar-numerator">Bar (Numerator)</option>' +
    '</select>' +
    '<span id="ssm-axes-note" class="ssm-axes-note">x=denominator, y=numerator (log)</span>' +
    '<div id="ssm-legend" class="ssm-legend" style="margin-left:16px;"></div>' +
    '<button id="ssm-show-sites" style="margin-left:8px; padding:2px 8px; font-size:12px; border:1px solid #ccc; background:#f5f5f5; border-radius:3px; cursor:pointer;">Show all sites</button>' +
    '<button id="ssm-hide-sites" style="padding:2px 8px; font-size:12px; border:1px solid #ccc; background:#f5f5f5; border-radius:3px; cursor:pointer;">Hide all sites</button>' +
    '<div class="ssm-legend" style="margin-left:auto;">' +
    '<span style="color:#666;">Sites:</span>' +
    '<span><span class="swatch" style="background:#4caf50;"></span>flag 0</span>' +
    '<span><span class="swatch" style="background:#ffb300;"></span>flag ±1</span>' +
    '<span><span class="swatch" style="background:#e53935;"></span>flag ±2</span>' +
    '</div>' +
    '</div>' +
    '<div id="ssm-grid" class="ssm-grid"></div>' +
    '<div id="ssm-tooltip" class="ssm-tooltip"></div>' +
    '</div>';

  var grid = el.querySelector('#ssm-grid');
  var legendEl = el.querySelector('#ssm-legend');
  var tooltipEl = el.querySelector('#ssm-tooltip');

  // Group per-study rows by metric.
  var byMetric = {};
  perStudy.forEach(function(r) {
    if (!byMetric[r.MetricID]) byMetric[r.MetricID] = [];
    byMetric[r.MetricID].push(r);
  });
  var sitesByMetric = {};
  perSite.forEach(function(r) {
    if (!sitesByMetric[r.MetricID]) sitesByMetric[r.MetricID] = [];
    sitesByMetric[r.MetricID].push(r);
  });

  var expandedStudies = {};
  var chartType = 'scatter';

  function valueIndexFor(param) {
    var idx = {};
    var values = [];
    perStudy.forEach(function(r) {
      var v = (studyAttrLookup[r.StudyID] || {})[param];
      if (v == null || v === '') return;
      if (!(v in idx)) {
        idx[v] = values.length;
        values.push(v);
      }
    });
    return { idx: idx, values: values.sort(function(a, b) {
      return idx[a] - idx[b];
    })};
  }

  function pointColor(studyId) {
    if (!colorBy) return '#1f77b4';
    var v = (studyAttrLookup[studyId] || {})[colorBy];
    if (v == null || v === '') return '#bbb';
    return colorFor(v, currentColorIdx);
  }

  function flagColor(flag) {
    if (flag === null || flag === undefined || isNaN(flag)) return '#bbb';
    var a = Math.abs(flag);
    if (a >= 2) return '#e53935';
    if (a >= 1) return '#ffb300';
    return '#4caf50';
  }

  var currentColorIdx = {};

  function showTooltip(evt, lines) {
    tooltipEl.textContent = lines.join('\n');
    tooltipEl.style.display = 'block';
    tooltipEl.style.left = (evt.clientX + 10) + 'px';
    tooltipEl.style.top = (evt.clientY + 10) + 'px';
  }
  function hideTooltip() {
    tooltipEl.style.display = 'none';
  }

  function buildLegend() {
    if (!colorBy) {
      legendEl.innerHTML = '';
      return;
    }
    var info = valueIndexFor(colorBy);
    currentColorIdx = info.idx;
    legendEl.innerHTML = info.values.map(function(v) {
      return '<span><span class="swatch" style="background:' + colorFor(v, info.idx) + ';"></span>' + escAttr(v) + '</span>';
    }).join('');
  }

  function renderFacet(metricId) {
    if (chartType === 'bar-rate' || chartType === 'bar-numerator') return renderBarFacet(metricId);
    return renderScatterFacet(metricId);
  }

  function renderScatterFacet(metricId) {
    var rows = byMetric[metricId] || [];
    var siteRowsAll = sitesByMetric[metricId] || [];
    var siteRows = siteRowsAll.filter(function(r) { return expandedStudies[r.StudyID]; });

    var facet = document.createElement('div');
    facet.className = 'ssm-facet';
    facet.setAttribute('data-metric-id', metricId);
    facet.innerHTML = '<h4>' + escAttr(metricLabel(metricId)) + '</h4>';

    var W = 240, H = 130;
    var padL = 24, padR = 4, padT = 2, padB = 12;
    var innerW = W - padL - padR;
    var innerH = H - padT - padB;

    var maxX = 0, maxY = 0;
    var minXPos = Infinity, minYPos = Infinity;
    function trackExtent(r) {
      var d = r.Denominator || 0, n = r.Numerator || 0;
      if (d > maxX) maxX = d;
      if (n > maxY) maxY = n;
      if (d > 0 && d < minXPos) minXPos = d;
      if (n > 0 && n < minYPos) minYPos = n;
    }
    rows.forEach(trackExtent);
    siteRows.forEach(trackExtent);
    if (maxX <= 0) maxX = 1;
    if (maxY <= 0) maxY = 1;
    if (!isFinite(minXPos)) minXPos = 1;
    if (!isFinite(minYPos)) minYPos = 1;

    // Log10 scales. Domain is [floor(log10(min)), ceil(log10(max))] in decades;
    // zeros are pinned to the lower edge so they remain plottable.
    var xLo = Math.floor(Math.log10(minXPos));
    var xHi = Math.ceil(Math.log10(maxX));
    if (xHi <= xLo) xHi = xLo + 1;
    var yLo = Math.floor(Math.log10(minYPos));
    var yHi = Math.ceil(Math.log10(maxY));
    if (yHi <= yLo) yHi = yLo + 1;

    function sx(x) {
      var lx = x > 0 ? Math.log10(x) : xLo;
      return padL + ((lx - xLo) / (xHi - xLo)) * innerW;
    }
    function sy(y) {
      var ly = y > 0 ? Math.log10(y) : yLo;
      return padT + innerH - ((ly - yLo) / (yHi - yLo)) * innerH;
    }

    function logTicks(lo, hi) {
      var out = [];
      for (var p = lo; p <= hi; p += 1) out.push(Math.pow(10, p));
      return out;
    }
    function fmtTick(v) {
      if (v >= 1000) return v.toExponential(0).replace('+', '');
      if (v >= 1) return String(Math.round(v));
      return String(v);
    }

    var svgNS = 'http://www.w3.org/2000/svg';
    var svg = document.createElementNS(svgNS, 'svg');
    svg.setAttribute('viewBox', '0 0 ' + W + ' ' + H);
    svg.setAttribute('preserveAspectRatio', 'xMidYMid meet');

    // Axes
    var axes = document.createElementNS(svgNS, 'g');
    axes.setAttribute('class', 'ssm-axis');
    var axisX = document.createElementNS(svgNS, 'line');
    axisX.setAttribute('x1', padL); axisX.setAttribute('y1', H - padB);
    axisX.setAttribute('x2', W - padR); axisX.setAttribute('y2', H - padB);
    var axisY = document.createElementNS(svgNS, 'line');
    axisY.setAttribute('x1', padL); axisY.setAttribute('y1', padT);
    axisY.setAttribute('x2', padL); axisY.setAttribute('y2', H - padB);
    axes.appendChild(axisX); axes.appendChild(axisY);

    logTicks(xLo, xHi).forEach(function(t) {
      var tx = sx(t);
      var label = document.createElementNS(svgNS, 'text');
      label.setAttribute('x', tx); label.setAttribute('y', H - padB + 9);
      label.setAttribute('text-anchor', 'middle');
      label.textContent = fmtTick(t);
      axes.appendChild(label);
    });
    logTicks(yLo, yHi).forEach(function(t) {
      var ty = sy(t);
      var label = document.createElementNS(svgNS, 'text');
      label.setAttribute('x', padL - 3); label.setAttribute('y', ty + 3);
      label.setAttribute('text-anchor', 'end');
      label.textContent = fmtTick(t);
      axes.appendChild(label);
    });

    svg.appendChild(axes);

    // Points: sites first (below), then studies (above).
    var pts = document.createElementNS(svgNS, 'g');

    siteRows.forEach(function(r) {
      var c = document.createElementNS(svgNS, 'circle');
      c.setAttribute('cx', sx(r.Denominator || 0));
      c.setAttribute('cy', sy(r.Numerator || 0));
      c.setAttribute('r', 2.5);
      c.setAttribute('class', 'ssm-pt ssm-pt-site');
      c.setAttribute('data-study-id', r.StudyID);
      c.setAttribute('data-site-key', r.StudyID + '||' + r.GroupID);
      c.setAttribute('data-flag', r.Flag == null ? '' : r.Flag);
      c.setAttribute('stroke', flagColor(r.Flag));
      c.addEventListener('mouseenter', function(evt) {
        highlightSite(r.StudyID, r.GroupID);
        var lines = [
          'Site ' + r.GroupID,
          'Study ' + r.StudyID,
          metricLabel(metricId),
          'Numerator: ' + (r.Numerator || 0),
          'Denominator: ' + (r.Denominator || 0),
          'Rate: ' + (r.Denominator > 0 ? ((r.Numerator / r.Denominator) * 100).toFixed(1) + '%' : '-'),
          'Flag: ' + (r.Flag == null ? '-' : r.Flag)
        ];
        showTooltip(evt, lines);
      });
      c.addEventListener('mousemove', moveTooltip);
      c.addEventListener('mouseleave', function() {
        clearHighlight();
        hideTooltip();
      });
      pts.appendChild(c);
    });

    rows.forEach(function(r) {
      var c = document.createElementNS(svgNS, 'circle');
      c.setAttribute('cx', sx(r.Denominator || 0));
      c.setAttribute('cy', sy(r.Numerator || 0));
      c.setAttribute('r', 5);
      c.setAttribute('class', 'ssm-pt ssm-pt-study');
      c.setAttribute('data-study-id', r.StudyID);
      c.setAttribute('fill', pointColor(r.StudyID));
      c.addEventListener('mouseenter', function(evt) {
        highlightStudy(r.StudyID);
        var attrs = studyAttrLookup[r.StudyID] || {};
        var lines = [
          r.StudyID,
          metricLabel(metricId),
          'Numerator: ' + (r.Numerator || 0),
          'Denominator: ' + (r.Denominator || 0),
          'Rate: ' + (r.Denominator > 0 ? ((r.Numerator / r.Denominator) * 100).toFixed(1) + '%' : '-')
        ];
        if (colorBy && attrs[colorBy]) lines.push(colorBy + ': ' + attrs[colorBy]);
        if (expandedStudies[r.StudyID]) lines.push('(click to hide sites)');
        else lines.push('(click to show sites)');
        showTooltip(evt, lines);
      });
      c.addEventListener('mousemove', moveTooltip);
      c.addEventListener('mouseleave', function() {
        clearHighlight();
        hideTooltip();
      });
      c.addEventListener('click', function(evt) {
        evt.stopPropagation();
        expandedStudies[r.StudyID] = !expandedStudies[r.StudyID];
        if (!expandedStudies[r.StudyID]) delete expandedStudies[r.StudyID];
        rerender();
      });
      pts.appendChild(c);
    });

    svg.appendChild(pts);
    facet.appendChild(svg);
    grid.appendChild(facet);
  }

  function renderBarFacet(metricId) {
    function rateOf(r) {
      return (r.Denominator || 0) > 0 ? r.Numerator / r.Denominator : 0;
    }
    function yOf(r) {
      return chartType === 'bar-numerator' ? (r.Numerator || 0) : rateOf(r);
    }
    var studyRows = (byMetric[metricId] || []).slice().sort(function(a, b) {
      var ya = yOf(a), yb = yOf(b);
      if (yb !== ya) return yb - ya;
      return a.StudyID < b.StudyID ? -1 : a.StudyID > b.StudyID ? 1 : 0;
    });
    var siteRowsAll = sitesByMetric[metricId] || [];
    var sitesByStudy = {};
    siteRowsAll.forEach(function(r) {
      if (!sitesByStudy[r.StudyID]) sitesByStudy[r.StudyID] = [];
      sitesByStudy[r.StudyID].push(r);
    });

    var facet = document.createElement('div');
    facet.className = 'ssm-facet';
    facet.setAttribute('data-metric-id', metricId);
    facet.innerHTML = '<h4>' + escAttr(metricLabel(metricId)) + '</h4>';

    var W = 240, H = 130;
    var padL = 24, padR = 4, padT = 2, padB = 12;
    var innerW = W - padL - padR;
    var innerH = H - padT - padB;

    var maxY = 0;
    studyRows.forEach(function(r) {
      var v = yOf(r);
      if (v > maxY) maxY = v;
    });
    studyRows.forEach(function(s) {
      if (!expandedStudies[s.StudyID]) return;
      (sitesByStudy[s.StudyID] || []).forEach(function(r) {
        var v = yOf(r);
        if (v > maxY) maxY = v;
      });
    });
    if (maxY <= 0) maxY = 1;
    var niceMax = niceRate(maxY);

    var nStudies = studyRows.length || 1;
    var slotW = innerW / nStudies;

    function sy(v) { return padT + innerH - (v / niceMax) * innerH; }
    function yTicks(maxVal) {
      var n = 4;
      var step = maxVal / n;
      var out = [];
      for (var i = 0; i <= n; i += 1) out.push(Math.round(step * i * 1000) / 1000);
      return out;
    }
    function fmtY(v) {
      return chartType === 'bar-numerator' ? String(Math.round(v)) : (v * 100).toFixed(v < 0.1 ? 1 : 0) + '%';
    }

    var svgNS = 'http://www.w3.org/2000/svg';
    var svg = document.createElementNS(svgNS, 'svg');
    svg.setAttribute('viewBox', '0 0 ' + W + ' ' + H);
    svg.setAttribute('preserveAspectRatio', 'xMidYMid meet');

    var axes = document.createElementNS(svgNS, 'g');
    axes.setAttribute('class', 'ssm-axis');
    var axisX = document.createElementNS(svgNS, 'line');
    axisX.setAttribute('x1', padL); axisX.setAttribute('y1', H - padB);
    axisX.setAttribute('x2', W - padR); axisX.setAttribute('y2', H - padB);
    var axisY = document.createElementNS(svgNS, 'line');
    axisY.setAttribute('x1', padL); axisY.setAttribute('y1', padT);
    axisY.setAttribute('x2', padL); axisY.setAttribute('y2', H - padB);
    axes.appendChild(axisX); axes.appendChild(axisY);

    yTicks(niceMax).forEach(function(t) {
      var ty = sy(t);
      var label = document.createElementNS(svgNS, 'text');
      label.setAttribute('x', padL - 3); label.setAttribute('y', ty + 3);
      label.setAttribute('text-anchor', 'end');
      label.textContent = fmtY(t);
      axes.appendChild(label);
    });
    svg.appendChild(axes);

    var bars = document.createElementNS(svgNS, 'g');

    studyRows.forEach(function(s, i) {
      var slotX = padL + i * slotW;
      var expanded = !!expandedStudies[s.StudyID];
      var sites = expanded
        ? (sitesByStudy[s.StudyID] || []).slice().sort(function(a, b) { return yOf(b) - yOf(a); })
        : [];

      // Bar widths: study bar + site bars share the slot.
      var totalBars = 1 + sites.length;
      var gap = Math.max(0.5, slotW * 0.05);
      var barW = (slotW - gap * (totalBars + 1)) / totalBars;
      if (barW < 0.5) barW = 0.5;

      // Study bar (filled).
      var studyY = yOf(s);
      var sBar = document.createElementNS(svgNS, 'rect');
      sBar.setAttribute('x', slotX + gap);
      sBar.setAttribute('y', sy(studyY));
      sBar.setAttribute('width', barW);
      sBar.setAttribute('height', Math.max(0, (H - padB) - sy(studyY)));
      sBar.setAttribute('class', 'ssm-pt ssm-pt-study');
      sBar.setAttribute('data-study-id', s.StudyID);
      sBar.setAttribute('fill', pointColor(s.StudyID));
      attachStudyHandlers(sBar, s, metricId);
      bars.appendChild(sBar);

      sites.forEach(function(site, j) {
        var v = yOf(site);
        var x = slotX + gap + (j + 1) * (barW + gap);
        var bar = document.createElementNS(svgNS, 'rect');
        bar.setAttribute('x', x);
        bar.setAttribute('y', sy(v));
        bar.setAttribute('width', barW);
        bar.setAttribute('height', Math.max(0, (H - padB) - sy(v)));
        bar.setAttribute('class', 'ssm-pt ssm-pt-site');
        bar.setAttribute('data-study-id', site.StudyID);
        bar.setAttribute('data-site-key', site.StudyID + '||' + site.GroupID);
        bar.setAttribute('data-flag', site.Flag == null ? '' : site.Flag);
        bar.setAttribute('fill', 'none');
        bar.setAttribute('stroke', flagColor(site.Flag));
        attachSiteHandlers(bar, site, metricId);
        bars.appendChild(bar);
      });
    });

    svg.appendChild(bars);
    facet.appendChild(svg);
    grid.appendChild(facet);
  }

  function niceRate(v) {
    if (v <= 0) return 1;
    var pow = Math.pow(10, Math.floor(Math.log10(v)));
    var n = v / pow;
    var nice = n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10;
    return nice * pow;
  }

  function attachStudyHandlers(node, r, metricId) {
    node.addEventListener('mouseenter', function(evt) {
      highlightStudy(r.StudyID);
      var attrs = studyAttrLookup[r.StudyID] || {};
      var lines = [
        r.StudyID,
        metricLabel(metricId),
        'Numerator: ' + (r.Numerator || 0),
        'Denominator: ' + (r.Denominator || 0),
        'Rate: ' + (r.Denominator > 0 ? ((r.Numerator / r.Denominator) * 100).toFixed(1) + '%' : '-')
      ];
      if (colorBy && attrs[colorBy]) lines.push(colorBy + ': ' + attrs[colorBy]);
      lines.push(expandedStudies[r.StudyID] ? '(click to hide sites)' : '(click to show sites)');
      showTooltip(evt, lines);
    });
    node.addEventListener('mousemove', moveTooltip);
    node.addEventListener('mouseleave', function() { clearHighlight(); hideTooltip(); });
    node.addEventListener('click', function(evt) {
      evt.stopPropagation();
      expandedStudies[r.StudyID] = !expandedStudies[r.StudyID];
      if (!expandedStudies[r.StudyID]) delete expandedStudies[r.StudyID];
      rerender();
    });
  }

  function attachSiteHandlers(node, r, metricId) {
    node.addEventListener('mouseenter', function(evt) {
      highlightSite(r.StudyID, r.GroupID);
      showTooltip(evt, [
        'Site ' + r.GroupID,
        'Study ' + r.StudyID,
        metricLabel(metricId),
        'Numerator: ' + (r.Numerator || 0),
        'Denominator: ' + (r.Denominator || 0),
        'Rate: ' + (r.Denominator > 0 ? ((r.Numerator / r.Denominator) * 100).toFixed(1) + '%' : '-'),
        'Flag: ' + (r.Flag == null ? '-' : r.Flag)
      ]);
    });
    node.addEventListener('mousemove', moveTooltip);
    node.addEventListener('mouseleave', function() { clearHighlight(); hideTooltip(); });
  }

  function moveTooltip(evt) {
    tooltipEl.style.left = (evt.clientX + 10) + 'px';
    tooltipEl.style.top = (evt.clientY + 10) + 'px';
  }

  function highlightStudy(studyId) {
    el.querySelectorAll('.ssm-pt').forEach(function(p) {
      if (p.getAttribute('data-study-id') === studyId) {
        p.classList.add('hl');
        p.classList.remove('dim');
      } else {
        p.classList.add('dim');
        p.classList.remove('hl');
      }
    });
  }
  function highlightSite(studyId, groupId) {
    var key = studyId + '||' + groupId;
    el.querySelectorAll('.ssm-pt').forEach(function(p) {
      if (p.getAttribute('data-site-key') === key) {
        p.classList.add('hl');
        p.classList.remove('dim');
      } else {
        p.classList.add('dim');
        p.classList.remove('hl');
      }
    });
  }
  function clearHighlight() {
    el.querySelectorAll('.ssm-pt').forEach(function(p) {
      p.classList.remove('hl');
      p.classList.remove('dim');
    });
  }

  function recolor() {
    el.querySelectorAll('.ssm-pt-study').forEach(function(p) {
      p.setAttribute('fill', pointColor(p.getAttribute('data-study-id')));
    });
    // Site colors stay driven by Flag, independent of the study Color-by control.
  }

  function rerender() {
    grid.innerHTML = '';
    metricOrder.forEach(renderFacet);
  }

  buildLegend();
  metricOrder.forEach(renderFacet);

  el.querySelector('#ssm-color-by').addEventListener('change', function(evt) {
    colorBy = evt.target.value;
    buildLegend();
    recolor();
  });

  function updateNote() {
    var note = el.querySelector('#ssm-axes-note');
    if (!note) return;
    if (chartType === 'bar-rate') note.textContent = 'x=studies, y=rate';
    else if (chartType === 'bar-numerator') note.textContent = 'x=studies, y=numerator';
    else note.textContent = 'x=denominator, y=numerator (log)';
  }

  el.querySelector('#ssm-chart-type').addEventListener('change', function(evt) {
    chartType = evt.target.value;
    updateNote();
    rerender();
  });

  el.querySelector('#ssm-show-sites').addEventListener('click', function() {
    perStudy.forEach(function(r) { expandedStudies[r.StudyID] = true; });
    rerender();
  });
  el.querySelector('#ssm-hide-sites').addEventListener('click', function() {
    expandedStudies = {};
    rerender();
  });
}
