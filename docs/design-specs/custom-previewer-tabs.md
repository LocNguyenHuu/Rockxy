# Custom Previewer Tabs — Design Spec

## Overview

Add user-configurable preview tabs to the Request and Response inspector panels. Users select which body preview formats to display (JSON Treeview, HTML Preview, Hex, etc.) as appended tabs alongside the native inspector tabs.

## Apple HIG References

- **Tab Views (macOS)**: Use text-only tab labels for compact bars in inspector contexts. Avoid icons in tab labels when space is tight. Tabs should be horizontally scrollable when they exceed available width.
- **Inspectors**: Keep inspector content dense and scannable. Use segmented or text-button tab bars, not full TabView chrome. Inspector panels should adapt to narrow widths gracefully.
- **Menus**: Use standard NSMenu for the "+" button popover — native menus are faster and more accessible than custom popovers for checkbox lists.
- **Settings Windows**: Use Form-based layouts with grouped sections. Two-column layouts work well for paired configurations.

## Reference Analysis

Design patterns observed in leading macOS developer tools:

1. **Inspector tab bar**: Native tabs (Request, Header, Query, Body, Raw) followed by custom tabs with a `+` button at the trailing edge. Custom tabs appear with accent styling to distinguish them from built-in tabs.
2. **Settings window**: "Custom Body Previewer Tabs" title, two-column checkbox grid (Request Panel | Response Panel), "Auto beautify" toggle, "+ Add Custom Tabs" button.
3. **Add dialog**: Simple sheet with radio (Request/Response Panel), text field for name, Cancel/Add buttons.
4. **JSON Treeview**: Key/Type/Value three-column table with disclosure triangles, color-coded values, search at bottom.

---

## Component 1: Inspector Tab Bar (Request & Response)

### Layout

```
┌──────────────────────────────────────────────────────────────┐
│ Request                                                      │
├──────────────────────────────────────────────────────────────┤
│ Headers  Query  Body  Cookies  Raw  Synopsis  Comments │ Treeview  Hex │ + │
│                                                    ↑ separator    ↑ custom   ↑ add │
└──────────────────────────────────────────────────────────────┘
```

### Behavior

- Native tabs render first (unchanged from current `RequestInspectorTab.allCases` / `ResponseInspectorTab.allCases`)
- A thin 1pt vertical divider separates native tabs from custom preview tabs (height 12pt, `.separatorColor`)
- Custom preview tabs appear after the divider, using the same `InspectorTabButton` component
- A `+` button sits at the trailing edge, always visible
- When total tabs exceed available width, the tab bar scrolls horizontally (`.horizontal` ScrollView, no indicators)
- Tab selection is unified: only one tab active at a time (native OR custom)

### Typography & Styling

| Element | Font | Size | Weight | Color |
|---------|------|------|--------|-------|
| Native tab (active) | .system | 11pt | .bold | `Theme.Inspector.tabActive` (.primary) |
| Native tab (inactive) | .system | 11pt | .regular | `Theme.Inspector.tabInactive` (.secondary) |
| Custom tab (active) | .system | 11pt | .bold | `.accentColor` |
| Custom tab (inactive) | .system | 11pt | .regular | `Theme.Inspector.tabInactive` (.secondary) |
| `+` button icon | SF Symbol `plus` | 10pt | .medium | `.tertiaryLabelColor` |

### Spacing

| Property | Value | Notes |
|----------|-------|-------|
| Tab bar height | 24pt | Matches current tab bar |
| Tab horizontal padding | 6pt | Per `InspectorTabButton` existing |
| Separator width | 1pt | Vertical divider |
| Separator height | 12pt | Centered vertically |
| Separator horizontal margin | 4pt each side | |
| `+` button frame | 20x20pt | Compact, no visible background |
| `+` button trailing padding | 4pt | |
| Tab bar container padding | 4pt vertical, 4pt horizontal | Matches current |

### `+` Button Menu

Clicking `+` opens a native `NSMenu` (not a popover) with:

```
┌─────────────────────────┐
│ ✓ JSON Treeview         │
│   Form URL-Encoded      │
│   HTML                  │
│   HTML Preview          │
│   CSS                   │
│   JavaScript            │
│   XML                   │
│   Hex                   │
│   Raw                   │
│ ──────────────────────  │
│   Manage Tabs…          │
└─────────────────────────┘
```

- Checkmarks toggle preview tabs on/off for the current panel (Request or Response)
- "Manage Tabs..." opens the Custom Previewer Tab settings window
- Menu items use system font at standard menu size
- When a tab is toggled on, it appears immediately in the tab bar
- When toggled off, it removes from the tab bar; if that tab was active, selection falls back to the first native tab

### States

1. **Default (no custom tabs)**: Tab bar looks exactly like today — no divider, no `+` button shown. The `+` button appears only when explicitly enabled in settings or on first interaction.
   - **Revised**: Always show the `+` button. It's a 10pt icon, costs 24pt width, and signals extensibility.

2. **With custom tabs**: Divider + custom tabs + `+` button appended.

3. **Narrow width (< 250pt usable)**: ScrollView kicks in, user can scroll tabs horizontally. `+` button stays pinned at trailing edge outside the scroll.

4. **Long tab names**: Truncated with `.lineLimit(1)` and `.truncationMode(.tail)`. Max tab label width: 80pt.

---

## Component 2: Custom Previewer Tab Settings Window

### Access Points

- Tools menu → "Custom Previewer Tabs..." (new menu item)
- `+` button menu → "Manage Tabs..."
- Keyboard shortcut: none (infrequently used)

### Window Properties

| Property | Value |
|----------|-------|
| Title | "Custom Previewer Tabs" |
| Window ID | `"customPreviewerTabs"` |
| Style | `.windowResizability(.contentSize)` |
| Position | `.defaultPosition(.center)` |
| Min width | 520pt |
| Content | SwiftUI `Form` |

### Layout

```
┌──────────────────────────────────────────────────────────────┐
│  Custom Body Previewer Tabs                                  │
│  Select tabs to render body content as a specific format     │
│                                                              │
│  Request Panel              Response Panel                   │
│  ┌────────────────────┐     ┌────────────────────┐          │
│  │ ☐ JSON             │     │ ☐ JSON             │          │
│  │ ☐ JSON Treeview    │     │ ☐ JSON Treeview    │          │
│  │ ☐ Form URL-Encoded │     │ ☐ Form URL-Encoded │          │
│  │ ☐ HTML             │     │ ☐ HTML             │          │
│  │ ☐ HTML Preview     │     │ ☐ HTML Preview     │          │
│  │ ☐ CSS              │     │ ☐ CSS              │          │
│  │ ☐ JavaScript       │     │ ☐ JavaScript       │          │
│  │ ☐ XML              │     │ ☐ XML              │          │
│  │ ☐ Images           │     │ ☐ Images           │          │
│  │ ☐ Hex              │     │ ☐ Hex              │          │
│  │ ☐ Raw              │     │ ☐ Raw              │          │
│  └────────────────────┘     └────────────────────┘          │
│                                                              │
│  ☑ Auto beautify minified content                           │
│  Only applies to HTML, CSS, and JavaScript                  │
│                                                              │
│                                       [+ Add Custom Tabs]    │
└──────────────────────────────────────────────────────────────┘
```

### Typography

| Element | Font | Size | Weight | Color |
|---------|------|------|--------|-------|
| Window title ("Custom Body Previewer Tabs") | .system | 13pt | .semibold | `.labelColor` |
| Subtitle | .system | 11pt | .regular | `.secondaryLabelColor` |
| Section headers ("Request Panel", "Response Panel") | .system | 12pt | .medium | `.labelColor` |
| Checkbox labels | .system | 12pt | .regular | `.labelColor` |
| Auto-beautify label | .system | 12pt | .regular | `.labelColor` |
| Auto-beautify hint | .system | 11pt | .regular | `.tertiaryLabelColor` |
| Add button | .system | 12pt | .regular | `.accentColor` |

### Controls

| Element | Control | Framework | Notes |
|---------|---------|-----------|-------|
| Checkbox | `Toggle` with `.toggleStyle(.checkbox)` | SwiftUI | macOS native checkbox |
| Column container | `HStack` of two `VStack`s | SwiftUI | Equal width via `.frame(maxWidth: .infinity)` |
| Grouped border | `GroupBox` or `.background` with `.controlBackgroundColor` + border | SwiftUI | Subtle grouped appearance |
| Auto-beautify | `Toggle` with `.toggleStyle(.checkbox)` | SwiftUI | Outside the columns |
| Add button | `Button` with `+` icon | SwiftUI | Disabled for v1, future scripted tabs |

### Spacing

| Property | Value |
|----------|-------|
| Content padding | 20pt |
| Column spacing | 16pt |
| Checkbox vertical spacing | 6pt |
| Section header to first checkbox | 8pt |
| Columns to auto-beautify | 16pt |
| Auto-beautify to button | 16pt |

---

## Component 3: Add Custom Tab Dialog (Future — design now, implement later)

### Layout

```
┌──────────────────────────────────────┐
│  Create New Custom Tab               │
│  ┌──────────────────────────────┐    │
│  │ Tab Location:                │    │
│  │   ● Request Panel            │    │
│  │   ○ Response Panel           │    │
│  │                              │    │
│  │ Custom Tab Name:             │    │
│  │ ┌────────────────────────┐   │    │
│  │ │ mytab                  │   │    │
│  │ └────────────────────────┘   │    │
│  │ Use short name (< 10 chars)  │    │
│  └──────────────────────────────┘    │
│                                      │
│  [Cancel]   [Learn More…]   [Add]    │
└──────────────────────────────────────┘
```

### Controls

| Element | Control | Notes |
|---------|---------|-------|
| Panel selection | `Picker` with `.radioGroup` style | Two options |
| Tab name | `TextField` | Placeholder "Tab name" |
| Cancel | `Button` role `.cancel` | Dismisses sheet |
| Add | `Button` prominent | Disabled when name is empty |

### Window Properties

| Property | Value |
|----------|-------|
| Presentation | `.sheet` on settings window |
| Width | 340pt |
| Padding | 20pt |

---

## Component 4: Preview Tab Content Views

### 4a. JSON Treeview

Reuse the existing `JSONInspector` tree rendering pattern from `Core/Plugins/BuiltInPlugins/JSONInspector.swift`.

```
┌──────────────────────────────────────────────────┐
│  Key              Type        Value              │
├──────────────────────────────────────────────────┤
│ ▼ Root            Object      Dictionary         │
│   ▼ posts         Array       Array(20 items)    │
│     ▼ Index 0     Object      Dictionary         │
│       slug        String      growthlist-2-0     │
│       ▶ thumbnail Object      Dictionary         │
│       redirect_url String     https://www.pro... │
│       maker_inside Number     true               │
│       comments_count Number   25                 │
└──────────────────────────────────────────────────┘
```

| Element | Font | Size | Color |
|---------|------|------|-------|
| Key names | .monospaced | 12pt | `.labelColor` |
| Type column | .monospaced | 12pt | `.secondaryLabelColor` |
| String values | .monospaced | 12pt | `.systemRed` / `#C23010` |
| Number values | .monospaced | 12pt | `.systemBlue` |
| Boolean values | .monospaced | 12pt | `.systemOrange` |
| Null values | .monospaced | 12pt | `.systemGray` |
| Object/Array counts | .monospaced | 11pt | `.tertiaryLabelColor` |

- Three-column layout: Key (flexible, min 120pt), Type (80pt fixed), Value (flexible)
- Disclosure triangles for objects/arrays (standard `DisclosureGroup`)
- Text selection enabled on values
- ScrollView with both axes

### 4b. HTML Preview

- `WKWebView` wrapped via `NSViewRepresentable`
- Load response body HTML directly: `webView.loadHTMLString(html, baseURL: transaction.request.url)`
- Sandbox: disable JavaScript execution by default (`.javaScriptEnabled = false`)
- Background: match system appearance (inject CSS `prefers-color-scheme`)
- Empty state: "No HTML body to preview"

### 4c. Hex View

```
┌────────────────────────────────────────────────────────────────┐
│ Offset     00 01 02 03 04 05 06 07  08 09 0A 0B 0C 0D 0E 0F  │
├────────────────────────────────────────────────────────────────┤
│ 00000000   7B 22 6E 61 6D 65 22 3A  22 74 65 73 74 22 7D 0A  │ {"name":"test"}.
│ 00000010   7B 22 74 79 70 65 22 3A  22 6A 73 6F 6E 22 7D 0A  │ {"type":"json"}.
└────────────────────────────────────────────────────────────────┘
```

| Element | Font | Size | Color |
|---------|------|------|-------|
| Offset | .monospaced | 11pt | `.tertiaryLabelColor` |
| Hex bytes | .monospaced | 11pt | `.labelColor` |
| ASCII column | .monospaced | 11pt | `.secondaryLabelColor` |
| Non-printable chars | .monospaced | 11pt | `.tertiaryLabelColor` (shown as `.`) |
| Header row | .monospaced | 11pt | `.secondaryLabelColor` |

- 16 bytes per row
- Space between 8th and 9th byte for readability
- Vertical separator between hex and ASCII
- ScrollView vertical only
- Padding: 12pt

### 4d. Raw Text

- `ScrollView` containing `Text` with `.monospaced` font
- Font: 11pt monospaced
- Text selection enabled (`.textSelection(.enabled)`)
- If "Auto beautify" is on and content is HTML/CSS/JS: attempt basic indentation
- Padding: 12pt

### 4e. Image Preview

- Center the image in available space
- Show image dimensions and file size below: "1024 × 768 — 245 KB"
- Use `Image(nsImage:)` for rendering
- Fit to available width, maintain aspect ratio
- Background: `.windowBackgroundColor`

### 4f. Empty / Error States

Use `ContentUnavailableView` consistently:

| State | Icon | Title | Description |
|-------|------|-------|-------------|
| No body | `doc.text` | "No Body" | "This request/response has no body data" |
| Incompatible | `exclamationmark.triangle` | "Cannot Preview" | "Body content is not valid [format]" |
| Binary body | `doc.zipper` | "Binary Data" | "Body contains binary data (X bytes)" |

---

## Component 5: Menu Bar Integration

### Tools Menu Addition

Add after existing "Block List..." item:

```
Tools
  ...
  Block List…              ⌘⌥[
  ──────────────────────────
  Custom Previewer Tabs…
```

No keyboard shortcut (infrequently accessed).

---

## Interaction Summary

| Action | Trigger | Result |
|--------|---------|--------|
| Enable preview tab (quick) | Click `+` → check item | Tab appears in bar, auto-selected |
| Disable preview tab (quick) | Click `+` → uncheck item | Tab removed from bar |
| Open settings | `+` → "Manage Tabs..." or Tools menu | Settings window opens |
| Select preview tab | Click tab label | Content switches to preview renderer |
| Switch back to native tab | Click native tab label | Content switches back |

## Accessibility

- All tab buttons: VoiceOver label "[Tab Name] tab, [position] of [total]"
- `+` button: VoiceOver label "Add preview tab"
- Checkbox toggles: standard macOS accessibility, no custom work needed
- Preview content: text selection enabled for copying
- Keyboard: Tab key cycles through tabs, Space/Enter activates

## Dark Mode

All colors use system semantic names — no custom colors needed. The existing `Theme.Inspector` system handles both appearances.
