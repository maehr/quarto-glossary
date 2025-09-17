/**
 * Bootstrap Popover Initialization for Glossary
 * Uses Quarto's built-in Bootstrap functionality
 */

(function() {
  'use strict';

  /**
   * Initialize Bootstrap popovers for glossary terms
   */
  function initializeGlossaryPopovers() {
    // Check if Bootstrap is available
    if (typeof window.bootstrap === 'undefined') {
      console.warn('Bootstrap not found. Popovers will not work.');
      return;
    }

    // Initialize all glossary popovers
    const glossaryElements = document.querySelectorAll('.glossary[data-bs-toggle="popover"]');
    
    glossaryElements.forEach(function(element) {
      // Skip if already initialized
      if (window.bootstrap.Popover.getInstance(element)) {
        return;
      }

      new window.bootstrap.Popover(element, {
        trigger: 'click',
        placement: 'top',
        html: false,
        sanitize: true,
        container: 'body'
      });
    });

    // Close other popovers when one is opened (only one at a time)
    glossaryElements.forEach(function(element) {
      element.addEventListener('show.bs.popover', function() {
        // Hide all other popovers
        glossaryElements.forEach(function(otherElement) {
          if (otherElement !== element) {
            const popover = window.bootstrap.Popover.getInstance(otherElement);
            if (popover) {
              popover.hide();
            }
          }
        });
      });
    });
  }

  /**
   * Initialize Glossary Listing functionality
   */
  function initializeGlossaryListing() {
    const listingContainer = document.getElementById('glossary-listing');
    if (!listingContainer) {
      return; // No listing on this page
    }

    const dataScript = listingContainer.querySelector('script[data-glossary-items]');
    if (!dataScript) {
      console.warn('No glossary data found for listing');
      return;
    }

    let glossaryItems;
    try {
      glossaryItems = JSON.parse(dataScript.textContent);
    } catch (e) {
      console.error('Failed to parse glossary data:', e);
      return;
    }

    const searchInput = document.getElementById('glossary-search');
    const sortSelect = document.getElementById('glossary-sort');
    const itemsContainer = document.getElementById('glossary-items');

    if (!searchInput || !sortSelect || !itemsContainer) {
      console.warn('Glossary listing elements not found');
      return;
    }

    let currentItems = [...glossaryItems];

    // Render items function
    function renderItems(items) {
      if (items.length === 0) {
        itemsContainer.innerHTML = '<div class="alert alert-info">No terms found matching your search.</div>';
        return;
      }

      const itemsHtml = items.map(item => `
        <div class="list-group-item">
          <h6 class="mb-1">${escapeHtml(item.term)}</h6>
          <p class="mb-1">${escapeHtml(item.definition)}</p>
        </div>
      `).join('');

      itemsContainer.innerHTML = itemsHtml;
    }

    // Helper function to escape HTML
    function escapeHtml(text) {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    }

    // Search functionality
    function filterItems() {
      const searchTerm = searchInput.value.toLowerCase();
      currentItems = glossaryItems.filter(item => 
        item.term.toLowerCase().includes(searchTerm) || 
        item.definition.toLowerCase().includes(searchTerm)
      );
      sortItems();
    }

    // Sort functionality
    function sortItems() {
      const sortValue = sortSelect.value;
      
      currentItems.sort((a, b) => {
        if (sortValue === 'term-asc') {
          return a.term.localeCompare(b.term);
        } else if (sortValue === 'term-desc') {
          return b.term.localeCompare(a.term);
        }
        return 0;
      });

      renderItems(currentItems);
    }

    // Event listeners
    searchInput.addEventListener('input', filterItems);
    sortSelect.addEventListener('change', sortItems);

    // Initial render
    sortItems();
  }

  // Initialize when DOM is ready
  function initialize() {
    initializeGlossaryPopovers();
    initializeGlossaryListing();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initialize);
  } else {
    initialize();
  }

  // Re-initialize if new content is added dynamically
  const observer = new MutationObserver(function(mutations) {
    let shouldReinitialize = false;
    
    mutations.forEach(function(mutation) {
      if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
        mutation.addedNodes.forEach(function(node) {
          if (node.nodeType === Node.ELEMENT_NODE) {
            if (node.matches && node.matches('.glossary[data-bs-toggle="popover"]')) {
              shouldReinitialize = true;
            } else if (node.matches && node.matches('#glossary-listing')) {
              shouldReinitialize = true;
            } else if (node.querySelectorAll) {
              const newElements = node.querySelectorAll('.glossary[data-bs-toggle="popover"], #glossary-listing');
              if (newElements.length > 0) {
                shouldReinitialize = true;
              }
            }
          }
        });
      }
    });

    if (shouldReinitialize) {
      setTimeout(initialize, 0);
    }
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true
  });

})();