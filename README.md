# Glossary Extension for Quarto


This extension provides shortcodes for defining terms and creating glossaries 
in quarto. You can use this to mark terms in your text, which can display a popup 
definition, and to create table of defined terms at the end of a document.

See <https://debruine.github.io/quarto-glossary> for examples.

## Installing

```sh
quarto install extension debruine/quarto-glossary
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Accessibility

This extension is designed to meet WCAG 2.2 AA accessibility standards:

- **Full keyboard support**: Navigate with Tab, activate with Enter or Space, dismiss with Escape
- **Screen reader compatible**: Uses proper ARIA attributes and roles
- **Visible focus indicators**: Clear focus outlines for keyboard navigation
- **Dismissible content**: Popups can be closed by clicking outside, pressing Escape, or clicking another term
- **No hover-only content**: All functionality is available through keyboard and mouse interaction

Note: The previous "hover" popup mode has been removed as it did not meet accessibility standards.



