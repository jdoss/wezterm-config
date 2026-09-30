# WezTerm Config

My personal WezTerm configuration for Fedora Workstation with GNOME, optimized for AI-assisted development workflows using [Claude Code](https://github.com/anthropics/claude-code) and [claude-profile](https://github.com/quickvm/claude-profile).

## General Settings

| Setting | Value | Reason |
|---|---|---|
| `initial_cols` / `initial_rows` | 160 × 48 | Wider default window for split pane workflows |
| `audible_bell` | Disabled | No terminal bell sounds |
| `use_fancy_tab_bar` | false | Simple tab bar without the gradient/rounded style |
| `tab_bar_at_bottom` | false | Tab bar stays at the top |
| `tab_max_width` | 25 | Prevents tab labels from getting too wide |
| `switch_to_last_active_tab_when_closing_tab` | true | Closes a tab and returns to where you were |
| `pane_focus_follows_mouse` | false | Click to focus panes — mouse hover focus has an unfixed bug that causes panes to flash focus back and forth ([WezTerm issue #4484](https://github.com/wezterm/wezterm/issues/4484)) |
| `swallow_mouse_click_on_pane_focus` | true | First click on an inactive pane focuses it without also passing the click to the app |
| `enable_wayland` | false | Forces X11/XWayland — GNOME Wayland has open WezTerm crash bugs ([issue #6191](https://github.com/wezterm/wezterm/issues/6191)) |
| `hyperlink_rules` | defaults | Uses WezTerm's built-in URL detection rules |
| `hide_mouse_cursor_when_typing` | true | Hides the mouse pointer while you type |
| `check_for_updates` | false | Disabled — WezTerm is installed via RPM (nightly), the built-in updater can't update RPM packages |
| `window_decorations` | `RESIZE` | Removes the title bar on GNOME. `RESIZE` without `TITLE` is what achieves this |

## TUI Compatibility

Settings tuned for running TUI applications like Claude Code and OpenCode inside WezTerm.

| Setting | Value | Reason |
|---|---|---|
| `enable_kitty_keyboard` | true | Enables the Kitty keyboard protocol for better key reporting in TUI apps |
| `enable_csi_u_key_encoding` | false | Disables CSI u encoding to avoid escape sequence conflicts with modified keys |
| `scrollback_lines` | 10000 | Extra scrollback for long AI sessions with lots of output |

## Colors & Font

- **Color scheme:** Nord
- **Tab bar inactive edge:** `#575757` — slightly lighter divider between inactive tabs
- **Tab bar background:** `#333333` (both focused and unfocused windows)
- **Terminal font:** Source Code Pro Regular 12pt
- **Tab bar font:** Roboto Bold 12pt (WezTerm default, explicitly set)
- **Line height:** 1 (no extra spacing)

To list fonts available on your system: `wezterm ls-fonts --list-system`

## Status Bar

Two `update-status` event handlers update the left and right status bars on every tick.

**Left status:** Current workspace name — `[Workspace: name]`

**Right status:** Current pane directory (with folder icon), date, and time — updated live.

The right status uses Nerd Fonts glyphs (`cod_folder`, `md_calendar`, `md_clock`) — these require a Nerd Fonts patched font or a fallback font that includes them.

Shell integration (OSC 133) is required for the directory to update correctly as you `cd`. On Fedora, the WezTerm RPM automatically activates this for bash and zsh.

## Claude Code Integration

[`claude.lua`](claude.lua) starts Claude Code sessions through [`claude-profile`](https://github.com/quickvm/claude-profile) in two ways: `ALT+SHIFT+C` next to the current pane, and `bin/claude-tab` from outside WezTerm. Both read the profiles in `~/.claude-profiles/` each time, so new profiles show up without config changes.

For profiles with a `.sandbox` marker (`claude-profile sandbox <name> --on`), both then ask **Sandbox or host**. The answer sets `CLAUDE_PROFILE_SANDBOX` for that launch only, so the profile's default stays as it is. Profiles without a marker aren't asked. Esc at any step cancels without opening anything.

Sessions run `claude-profile <profile>` in an interactive login shell (`bash -lic`), like a new tab's, so the `CLAUDE_PROFILE_*` settings in `~/.bashrc` apply.

### Profile Launcher (`ALT+SHIFT+C`)

Picks a profile from a fuzzy list and asks sandbox or host if the profile has a sandbox. It then splits the current pane 40% to the right and starts the session there, in the current pane's directory. If `claude-profile` isn't installed, the pane splits immediately and launches `claude` directly.

### New tab from outside WezTerm (`bin/claude-tab`)

`bin/claude-tab <profile>` opens a new Claude Code tab in the current window from anywhere else, such as a Stream Deck key (deckbro's Personal and Work keys run it) or a desktop shortcut.

It asks for the directory first. The fuzzy list starts with the directories the profile has run sessions in, most recently started first (from the profile's `.claude.json`), then every git repository one and two levels under `~/src`. **Other directory…** at the bottom takes any path.

The script sets the `claude_tab` [user var](https://wezterm.org/config/lua/window-events/user-var-changed.html) on WezTerm's focused pane by writing its escape sequence to that pane's tty. WezTerm reads it, and the program in the pane never sees it. `claude.on_user_var_changed` handles it. The script needs `jq`.

## Keybindings

All default WezTerm keybindings are disabled (`disable_default_key_bindings = true`). Every binding is explicitly defined below.

### TUI Passthrough

These ensure common key combinations reach TUI applications instead of being intercepted.

| Key | Action |
|---|---|
| `SHIFT+Space` | Send Space (prevents WezTerm from consuming it) |
| `SHIFT+Enter` | Send Enter (used for newlines in Claude Code) |
| `CTRL+C` | Pass Ctrl+C through to the terminal application |

### General

| Key | Action |
|---|---|
| `ALT+/` | Fuzzy-searchable keybinding cheatsheet |
| `ALT+L` | Show WezTerm launcher |
| `ALT+N` | Open a new window |
| `SUPER+0` | Reset font size to default |

### Copy & Paste

| Key | Action |
|---|---|
| `CTRL+SHIFT+C` | Copy selection to clipboard |
| `CTRL+SHIFT+V` | Paste from clipboard |
| `ALT+S` | Quick select — highlights paths, URLs, git hashes, and other patterns on screen. Press a letter to select. URLs open in the default browser and are also copied to clipboard. Everything else is copied to clipboard only. Trailing punctuation (`"`, `'`, `)`, `]`, etc.) is stripped from URLs before opening. |

### Scrolling

Requires shell integration (OSC 133) for prompt-based scrolling. Automatically active on Fedora with bash/zsh.

| Key | Action |
|---|---|
| `SHIFT+Up` | Scroll to previous shell prompt |
| `SHIFT+Down` | Scroll to next shell prompt |
| `SHIFT+PageUp` | Scroll up one page |
| `SHIFT+PageDown` | Scroll down one page |

### Panes

| Key | Action |
|---|---|
| `ALT+D` | Split current pane vertically (top/bottom) |
| `ALT+C` | Split current pane horizontally (left/right) |
| `ALT+SHIFT+C` | Launch Claude Code in a right split: pick a profile, then sandbox or host if it has a sandbox |
| `ALT+←/→/↑/↓` | Move focus to the pane in that direction |
| `CTRL+SHIFT+←/→/↑/↓` | Resize current pane in that direction (1 cell per press) |
| `ALT+Enter` | Zoom/unzoom current pane (temporarily maximize) |
| `ALT+X` | Close current pane (with confirmation prompt) |
| `ALT+SHIFT+S` | Swap pane — shows label overlay, press a letter to swap active pane with that pane |
| `ALT+SHIFT+M` | Move active pane into a new tab |

### Tabs

| Key | Action |
|---|---|
| `ALT+T` | New tab (in current pane domain) |
| `ALT+W` | Tab navigator (fuzzy tab switcher UI) |
| `ALT+E` | Next tab |
| `ALT+Q` | Previous tab |
| `CTRL+SHIFT+1-9` | Jump directly to tab 1–9 |
| `ALT+R` | Rename current tab |
| `ALT+SHIFT+G` | Close current tab (with confirmation prompt) |

### Workspaces

Workspaces are WezTerm's named session groups — each workspace has its own set of windows and tabs.

| Key | Action |
|---|---|
| `ALT+SHIFT+W` | Show workspace picker (fuzzy search) |
| `ALT+SHIFT+E` | Switch to next workspace |
| `ALT+SHIFT+Q` | Switch to previous workspace |
| `ALT+SHIFT+T` | Create a new named workspace |
| `ALT+SHIFT+R` | Rename current workspace |

## Mouse Bindings

| Action | Binding |
|---|---|
| Select text | Left click drag — copies to both clipboard and primary selection |
| Open hyperlink | `CTRL+Click` (Up event) — opens URL under cursor |
| Increase font size | `CTRL+Scroll Up` |
| Decrease font size | `CTRL+Scroll Down` |

`CTRL+Click` Down is bound to `Nop` to prevent the click-down event from being passed to the terminal application before the Up event fires.

Left click Up is bound explicitly to `CompleteSelection` so that releasing the mouse button after a drag copies the selection, rather than triggering the default hyperlink behavior on single clicks.

## License

[MIT](LICENSE) — Copyright (c) 2026 Joe Doss
