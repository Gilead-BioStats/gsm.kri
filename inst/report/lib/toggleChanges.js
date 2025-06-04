// Toggle visibility of nested flag change lists

document.addEventListener('DOMContentLoaded', function() {
  // Hide all nested lists by default
  document.querySelectorAll('.flag-change-nested, .flag-change-details').forEach(function(ul) {
    ul.style.display = 'none';
  });

  // Add click event to parent items to toggle nested list
  document.querySelectorAll('.flag-change-parent').forEach(function(li) {
    li.style.cursor = 'pointer';
    li.addEventListener('click', function(e) {
      // Only toggle if clicking the parent, not a nested item
      if (e.target === li) {
        var nested = li.querySelector('.flag-change-nested');
        if (nested) {
          nested.style.display = (nested.style.display === 'none') ? 'block' : 'none';
        }
      }
    });
  });

  // Add click event to flag-change-item to toggle details
  document.querySelectorAll('.flag-change-item').forEach(function(li) {
    li.style.cursor = 'pointer';
    li.addEventListener('click', function(e) {
      // Only toggle if clicking the item, not a nested detail
      if (e.target === li) {
        var details = li.querySelector('.flag-change-details');
        if (details) {
          details.style.display = (details.style.display === 'none') ? 'block' : 'none';
        }
      }
      e.stopPropagation();
    });
  });
});
