/**
 * Accessible Glossary JavaScript
 * Provides WCAG 2.2 AA compliant interaction for glossary terms
 */

(function() {
  'use strict';

  let currentOpenPopup = null;

  /**
   * Close the currently open popup
   */
  function closeCurrentPopup() {
    if (currentOpenPopup) {
      const button = currentOpenPopup;
      const popup = button.querySelector('.def');
      
      button.setAttribute('aria-expanded', 'false');
      popup.style.display = 'none';
      currentOpenPopup = null;
    }
  }

  /**
   * Toggle popup for a glossary button
   * @param {HTMLElement} button - The glossary button element
   */
  function togglePopup(button) {
    const popup = button.querySelector('.def');
    const isExpanded = button.getAttribute('aria-expanded') === 'true';

    // Close any currently open popup
    closeCurrentPopup();

    if (!isExpanded) {
      // Open this popup
      button.setAttribute('aria-expanded', 'true');
      popup.style.display = 'block';
      currentOpenPopup = button;
      
      // Announce to screen readers that the popup opened
      popup.setAttribute('aria-live', 'polite');
    }
  }

  /**
   * Handle keyboard events for glossary buttons
   * @param {KeyboardEvent} event - The keyboard event
   */
  function handleKeydown(event) {
    const button = event.target;
    
    switch (event.key) {
      case 'Enter':
      case ' ': // Space key
        event.preventDefault();
        togglePopup(button);
        break;
      case 'Escape':
        event.preventDefault();
        closeCurrentPopup();
        button.focus(); // Return focus to the button
        break;
    }
  }

  /**
   * Handle click events for glossary buttons
   * @param {MouseEvent} event - The click event
   */
  function handleClick(event) {
    event.preventDefault();
    togglePopup(event.target);
  }

  /**
   * Close popup when clicking outside
   * @param {MouseEvent} event - The click event
   */
  function handleDocumentClick(event) {
    if (currentOpenPopup && !currentOpenPopup.contains(event.target)) {
      closeCurrentPopup();
    }
  }

  /**
   * Initialize glossary accessibility features
   */
  function initializeGlossary() {
    // Find all glossary buttons
    const glossaryButtons = document.querySelectorAll('.glossary[aria-expanded]');

    glossaryButtons.forEach(button => {
      // Add event listeners
      button.addEventListener('click', handleClick);
      button.addEventListener('keydown', handleKeydown);
      
      // Ensure button is focusable
      if (!button.hasAttribute('tabindex')) {
        button.setAttribute('tabindex', '0');
      }

      // Ensure proper button role
      if (!button.hasAttribute('role')) {
        button.setAttribute('role', 'button');
      }
    });

    // Add document click listener to close popups when clicking outside
    document.addEventListener('click', handleDocumentClick);

    // Close popup on Escape key anywhere in document
    document.addEventListener('keydown', function(event) {
      if (event.key === 'Escape' && currentOpenPopup) {
        closeCurrentPopup();
      }
    });
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeGlossary);
  } else {
    initializeGlossary();
  }

  // Re-initialize if new content is added dynamically
  const observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
        // Check if any new glossary buttons were added
        mutation.addedNodes.forEach(function(node) {
          if (node.nodeType === Node.ELEMENT_NODE) {
            const newButtons = node.querySelectorAll ? node.querySelectorAll('.glossary[aria-expanded]') : [];
            if (newButtons.length > 0 || (node.matches && node.matches('.glossary[aria-expanded]'))) {
              // Re-initialize for new buttons
              setTimeout(initializeGlossary, 0);
            }
          }
        });
      }
    });
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true
  });

})();