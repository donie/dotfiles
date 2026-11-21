# Rex settings

A record of the Rex for Mac settings chosen in its Settings window, to set by
hand on a new Mac. They aren't synced: Rex is in beta, and these settings
aren't in a config file.

## Why they aren't synced

- `~/.config/rex/init.lua` (tracked in `rex/`) holds what Rex supports in
  files: key bindings, key modes, custom actions, hosts and scripts. The Lua
  API has nothing for themes, fonts or tabs.
- The Settings window saves to the macOS preferences domain
  `com.superlogical.rex`. That domain also holds machine state (window
  frames, update checks, onboarding, cached server routes, `RexSync.servers`),
  and its key names are undocumented and may change during the beta.
- Shortcuts changed in the Settings window are kept in the app's own settings
  too, not in `init.lua`. Define shortcuts in `init.lua` instead.

Revisit once Rex leaves beta: if it documents a settings file or an
export/import, track that. Otherwise, the keys below could be applied with
`defaults write com.superlogical.rex <key> <value>` from
`run_onchange_after_50-macos-defaults.sh.tmpl`.

## Settings

Read with `defaults read com.superlogical.rex` (recorded November 2026). Some
values may be Rex defaults rather than choices.

### Theme and appearance

| Key | Value |
|---|---|
| `Workspace.appearance` | `dark` |
| `Workspace.darkThemeID` | `petrol-lagoon` |
| `Workspace.darkUsesExtendedThemePalette` | `1` |
| `Workspace.lightThemeID` | `merino-light` |
| `Workspace.interfaceStyle` | `blendTheme` |
| `Workspace.appIcon` | `default` |
| `Workspace.showsMenuBarIcon` | `0` |

### Terminal

| Key | Value |
|---|---|
| `Workspace.terminalFontName` | `BerkeleyMono Nerd Font` |
| `Workspace.terminalFontPointSize` | `14.5` |
| `Workspace.terminalFontSmoothing` | `1` |
| `Workspace.terminalCursorStyle` | `bar` |
| `Workspace.terminalCursorStyleForced` | `0` |
| `Workspace.terminalUseThemePalette` | `1` |
| `Workspace.terminalUsesDisplayP3` | `1` |
| `Workspace.terminalPaddingColor` | `background` |

BerkeleyMono is a licensed font installed from iCloud Drive by `./install`;
until it's there, Rex falls back to another font.

### Panes

| Key | Value |
|---|---|
| `Workspace.paneDensity` | `comfortable` |
| `Workspace.usesPaneGlass` | `0` |
| `Workspace.inactivePaneFadeMode` | `both` |
| `Workspace.usesStandardInactiveWindowPaneStyles` | `1` |
| `Workspace.balancesSplitsOnCreation` | `0` |

### Tabs and sidebar

| Key | Value |
|---|---|
| `Workspace.tabStyle` | `horizontal` |
| `Workspace.tabsFillAvailableSpace` | `0` |
| `Workspace.sidebarPosition` | `left` |
| `Workspace.tabIconCount` | `3` |
| `Workspace.tabIconColorMode` | `activePanes` |
| `Workspace.tabIconTintMode` | `off` |
| `Workspace.showsProgramStatusInTabs` | `1` |
| `Workspace.activityGrouping` | `priority` |

Left out as machine state: `Workspace.lastFocusedSession`,
`Workspace.programActivitySeen`, `Workspace.activityGroupingResetToPriority`.
