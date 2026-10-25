/**
 * Semantic design tokens for the mobile app.
 *
 * These tokens mirror the naming conventions used in web artifacts (index.css)
 * so that multi-artifact projects share a cohesive visual identity.
 *
 * Replace the placeholder values below with values that match the project's
 * brand. If a sibling web artifact exists, read its index.css and convert the
 * HSL values to hex so both artifacts use the same palette.
 *
 * To add dark mode, add a `dark` key with the same token names.
 * The useColors() hook will automatically pick it up.
 */

const colors = {
  light: {
    // Legacy aliases (kept for backward compatibility)
    text: '#153A38',
    tint: '#14756B',

    // Core surfaces
    background: '#F2F7F5',
    foreground: '#153A38',

    // Cards / elevated surfaces
    card: '#FFFFFF',
    cardForeground: '#153A38',

    // Primary action color (buttons, links, active states)
    primary: '#14756B',
    primaryForeground: '#FFFFFF',

    // Secondary / less-emphasis interactive surfaces
    secondary: '#E5F0EC',
    secondaryForeground: '#17433F',

    // Muted / subdued elements (dividers, timestamps, placeholders)
    muted: '#EAF1EF',
    mutedForeground: '#647C78',

    // Accent highlights (badges, selected items, focus rings)
    accent: '#CFE6DE',
    accentForeground: '#17433F',

    // Destructive actions (delete, error states)
    destructive: '#B74339',
    destructiveForeground: '#FFFFFF',

    // Borders and input outlines
    border: '#D9E5E1',
    input: '#D9E5E1',
    heroEnd: '#205D58',
    heroText: '#FFFFFF',
    heroMuted: '#D6E9E3',
    heroAccent: '#B8E2D7',
    heroOverlay: 'rgba(255,255,255,0.17)',
    heroOverlaySoft: 'rgba(255,255,255,0.14)',
  },
  dark: {
    text: '#EAF4F1',
    tint: '#6BC4B2',
    background: '#102522',
    foreground: '#EAF4F1',
    card: '#19332F',
    cardForeground: '#EAF4F1',
    primary: '#6BC4B2',
    primaryForeground: '#102522',
    secondary: '#24433D',
    secondaryForeground: '#DCECE7',
    muted: '#203A35',
    mutedForeground: '#A5BCB6',
    accent: '#2A534A',
    accentForeground: '#EAF4F1',
    destructive: '#E28277',
    destructiveForeground: '#102522',
    border: '#315049',
    input: '#315049',
    heroEnd: '#173B34',
    heroText: '#EAF4F1',
    heroMuted: '#C2D8D1',
    heroAccent: '#6BC4B2',
    heroOverlay: 'rgba(255,255,255,0.08)',
    heroOverlaySoft: 'rgba(255,255,255,0.06)',
  },

  // Border radius (in px). Sync from the sibling web artifact's --radius
  // CSS variable. This value applies to cards, buttons, inputs, and modals.
  radius: 8,
};

export default colors;
