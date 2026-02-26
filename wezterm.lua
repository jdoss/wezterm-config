local wezterm = require "wezterm"
local act = wezterm.action
local config = wezterm.config_builder()

-- Misc config
config.initial_cols = 160
config.initial_rows = 48
config.adjust_window_size_when_changing_font_size = false
config.check_for_updates = false
config.check_for_updates_interval_seconds = 86400
config.audible_bell = "Disabled"
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.switch_to_last_active_tab_when_closing_tab = true
config.tab_max_width = 25
config.pane_focus_follows_mouse = false
config.swallow_mouse_click_on_pane_focus = true
config.enable_wayland = false
config.hyperlink_rules = wezterm.default_hyperlink_rules()
config.hide_mouse_cursor_when_typing = true
-- config.front_end = "WebGpu"

-- TUI compatibility (Claude Code, OpenCode, etc.)
config.enable_kitty_keyboard = true      -- Better key reporting for TUIs
config.enable_csi_u_key_encoding = false -- Disable CSI u to avoid escape sequences for modified keys
config.scrollback_lines = 10000          -- More scrollback for long sessions

-- RESIZE without TITLE removes the title bar on GNOME.
config.window_decorations="RESIZE"
-- config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }
-- config.window_decorations="TITLE|RESIZE"
-- integrated_title_button_style = "Gnome"

-- local window_min = ' 󰖰 '
-- local window_max = ' 󰖯 '
-- local window_close = ' 󰅖 '
-- config.tab_bar_style = {
--      window_hide = window_min,
--      window_hide_hover = window_min,
--      window_maximize = window_max,
--      window_maximize_hover = window_max,
--      window_close = window_close,
--      window_close_hover = window_close,
-- }

-- Color
config.color_scheme = "nord"
config.colors = {
  tab_bar = {
    -- The color of the inactive tab bar edge/divider
    inactive_tab_edge = "#575757",
  },
}

-- Font
-- wezterm ls-fonts --list-system
config.font = wezterm.font("Source Code Pro", {weight="Regular", stretch="Normal", style="Normal"})
config.font_size = 12.0
config.line_height = 1
config.window_frame = {
  -- The font used in the tab bar.
  -- Roboto Bold is the default; this font is bundled
  -- with wezterm.
  -- Whatever font is selected here, it will have the
  -- main font setting appended to it to pick up any
  -- fallback fonts you may have used there.
  font = wezterm.font { family = "Roboto", weight = "Bold" },

  -- The size of the font in the tab bar.
  -- Default to 10.0 on Windows but 12.0 on other systems
  font_size = 12.0,

  -- The overall background color of the tab bar when
  -- the window is focused
  active_titlebar_bg = "#333333",

  -- The overall background color of the tab bar when
  -- the window is not focused
  inactive_titlebar_bg = "#333333",
}


-- Reads profile names from ~/.claude-profiles/ at invocation time
local function get_claude_profiles()
  local choices = {}
  local dirs = wezterm.glob(wezterm.home_dir .. "/.claude-profiles/*/")
  for _, dir in ipairs(dirs) do
    local name = dir:match("([^/]+)/?$")
    if name then
      table.insert(choices, { id = name, label = name })
    end
  end
  return choices
end

-- Keys
config.disable_default_key_bindings = true
config.keys = {

  -- TUI compatibility keybindings
  { key = ' ', mods = 'SHIFT', action = act.SendKey { key = ' ' } },  -- Shift+Space as regular space
  { key = 'c', mods = 'CTRL', action = act.SendKey { key = 'c', mods = 'CTRL' } },  -- Ensure Ctrl+C passes through
  { key = 'C', mods = 'SHIFT|CTRL', action = act.CopyTo 'Clipboard' },  -- Ctrl+Shift+C for copy

  -- Keybinding cheatsheet (fuzzy searchable)
  {
    key = '/',
    mods = 'ALT',
    action = act.InputSelector {
      title = "Keybindings",
      fuzzy = true,
      fuzzy_description = "Search keybindings...",
      action = wezterm.action_callback(function() end),
      choices = {
        { id = "", label = "── GENERAL ───────────────────────────────────" },
        { id = "", label = "  ALT+/                 This cheatsheet" },
        { id = "", label = "  ALT+L                 Show launcher" },
        { id = "", label = "  ALT+N                 New window" },
        { id = "", label = "  SUPER+0               Reset font size" },
        { id = "", label = "  CTRL+Scroll            Increase/decrease font size" },
        { id = "", label = "── COPY & PASTE ──────────────────────────────" },
        { id = "", label = "  CTRL+SHIFT+C          Copy to clipboard" },
        { id = "", label = "  CTRL+SHIFT+V          Paste from clipboard" },
        { id = "", label = "  ALT+S                 Quick select (paths, URLs, hashes)" },
        { id = "", label = "── SCROLL ────────────────────────────────────" },
        { id = "", label = "  SHIFT+Up/Down         Jump to prev/next shell prompt" },
        { id = "", label = "  SHIFT+PageUp/Down     Scroll by page" },
        { id = "", label = "── PANES ─────────────────────────────────────" },
        { id = "", label = "  ALT+D                 Split pane vertically" },
        { id = "", label = "  ALT+C                 Split pane horizontally" },
        { id = "", label = "  ALT+SHIFT+C           Launch Claude Code (profile picker)" },
        { id = "", label = "  ALT+Arrows            Move focus between panes" },
        { id = "", label = "  CTRL+SHIFT+Arrows     Resize pane" },
        { id = "", label = "  ALT+SHIFT+S           Swap pane (label overlay, press letter to swap)" },
        { id = "", label = "  ALT+Enter             Zoom/unzoom pane" },
        { id = "", label = "  ALT+X                 Close pane" },
        { id = "", label = "── TABS ──────────────────────────────────────" },
        { id = "", label = "  ALT+T                 New tab" },
        { id = "", label = "  ALT+W                 Tab navigator" },
        { id = "", label = "  ALT+E / ALT+Q         Next/previous tab" },
        { id = "", label = "  CTRL+SHIFT+1-9        Go to tab N" },
        { id = "", label = "  ALT+R                 Rename tab" },
        { id = "", label = "  ALT+SHIFT+G           Close tab" },
        { id = "", label = "── WORKSPACES ────────────────────────────────" },
        { id = "", label = "  ALT+SHIFT+W           Show workspaces" },
        { id = "", label = "  ALT+SHIFT+E / Q       Next/previous workspace" },
        { id = "", label = "  ALT+SHIFT+T           New workspace" },
        { id = "", label = "  ALT+SHIFT+R           Rename workspace" },
      },
    },
  },

  -- Show launcher
  { key = 'l', mods = 'ALT', action = wezterm.action.ShowLauncher },

  -- Scroll to last command
  { key = 'UpArrow', mods = 'SHIFT', action = act.ScrollToPrompt(-1) },
  { key = 'DownArrow', mods = 'SHIFT', action = act.ScrollToPrompt(1) },

  -- Misc
  { key = 'V', mods = 'SHIFT|CTRL', action = act.PasteFrom 'Clipboard' },
  { key = '0', mods= 'SUPER', action = act.ResetFontSize },

  -- Pane Movement
  { key = 'LeftArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  -- Pane Resize
  { key = 'LeftArrow', mods = 'SHIFT|CTRL', action = act.AdjustPaneSize{ 'Left', 1 } },
  { key = 'RightArrow', mods = 'SHIFT|CTRL', action = act.AdjustPaneSize{ 'Right', 1 } },
  { key = 'UpArrow', mods = 'SHIFT|CTRL', action = act.AdjustPaneSize{ 'Up', 1 } },
  { key = 'DownArrow', mods = 'SHIFT|CTRL', action = act.AdjustPaneSize{ 'Down', 1 } },
  -- Pane Swap (shows label overlay, press a letter to swap active pane with that pane)
  { key = 's', mods = 'SHIFT|ALT', action = act.PaneSelect { mode = "SwapWithActive" } },

  -- Launch Claude Code in a right split, prompting for profile if claude-profile is installed
  {
    key = 'C',
    mods = 'ALT|SHIFT',
    action = wezterm.action_callback(function(window, pane)
      local has_claude_profile, _, _ = wezterm.run_child_process({ "which", "claude-profile" })
      if has_claude_profile then
        window:perform_action(
          act.InputSelector {
            title = "Claude Profile",
            choices = get_claude_profiles(),
            fuzzy = true,
            action = wezterm.action_callback(function(inner_window, inner_pane, id, _)
              if id then
                inner_window:perform_action(
                  act.SplitPane {
                    direction = "Right",
                    command = { args = { "bash", "-lc", "claude-profile " .. id } },
                    size = { Percent = 40 },
                  },
                  inner_pane
                )
              end
            end),
          },
          pane
        )
      else
        window:perform_action(
          act.SplitPane {
            direction = "Right",
            command = { args = { "bash", "-lc", "claude" } },
            size = { Percent = 40 },
          },
          pane
        )
      end
    end),
  },

  -- Close current pane
  { key = 'x', mods = 'ALT', action = act.CloseCurrentPane { confirm = true } },
  -- Zoom/unzoom current pane
  { key = 'Enter', mods = 'ALT', action = act.TogglePaneZoomState },
  -- Quick select: opens URLs in browser, copies everything else to clipboard
  {
    key = 's',
    mods = 'ALT',
    action = act.QuickSelectArgs {
      action = wezterm.action_callback(function(window, pane)
        local sel = window:get_selection_text_for_pane(pane)
        if sel then
          window:perform_action(act.CompleteSelection("ClipboardAndPrimarySelection"), pane)
          if sel:match("^https?://") then
            local url = sel:gsub('[,;"\')}>%]]+$', '')
            wezterm.open_with(url)
          end
        end
      end),
    },
  },

  -- Windows
  -- New Window
  { key = 'n', mods = 'ALT', action = act.SpawnWindow },

  -- Tabs
  -- Activate Tab Number
  { key = '1', mods = 'SHIFT|CTRL', action = act.ActivateTab(0) },
  { key = '2', mods = 'SHIFT|CTRL', action = act.ActivateTab(1) },
  { key = '3', mods = 'SHIFT|CTRL', action = act.ActivateTab(2) },
  { key = '4', mods = 'SHIFT|CTRL', action = act.ActivateTab(3) },
  { key = '5', mods = 'SHIFT|CTRL', action = act.ActivateTab(4) },
  { key = '6', mods = 'SHIFT|CTRL', action = act.ActivateTab(5) },
  { key = '7', mods = 'SHIFT|CTRL', action = act.ActivateTab(6) },
  { key = '8', mods = 'SHIFT|CTRL', action = act.ActivateTab(7) },
  { key = '9', mods = 'SHIFT|CTRL', action = act.ActivateTab(8) },
  -- Close current tab
  {
    key = 'g',
    mods = 'ALT|SHIFT',
    action = wezterm.action.CloseCurrentTab { confirm = true },
  },
  -- Activate the tab navigator UI in the current tab.
  { key = 'w', mods = 'ALT', action = wezterm.action.ShowTabNavigator },

  -- Create a new tab in the same domain as the current pane.
  {
    key = 't',
    mods = 'ALT',
    action = act.SpawnTab 'CurrentPaneDomain',
  },

  -- Tab switcher
  { key = 'e', mods = 'ALT', action = act.ActivateTabRelative(1) },
  { key = 'q', mods = 'ALT', action = act.ActivateTabRelative(-1) },

  -- Create a new split vertical in the current tab
  {
    key = 'd',
    mods = 'ALT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },

  -- Create a new split horizontal in the current tab
  {
    key = 'c',
    mods = 'ALT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },

  -- Rename current tab
  {
    key = 'r',
    mods = 'ALT',
    action = act.PromptInputLine {
      description = 'Enter new name for the current tab...',
      action = wezterm.action_callback(function(window, pane, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },
  -- Workspaces
  -- Show current workspaces to select or create a new one
  {
    key = 'w',
    mods = 'ALT|SHIFT',
    action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' },
  },
  -- Workspace switcher
  { key = 'e', mods = 'ALT|SHIFT', action = act.SwitchWorkspaceRelative(1) },
  { key = 'q', mods = 'ALT|SHIFT', action = act.SwitchWorkspaceRelative(-1) },
  -- Create new workspace and prompt for name
  {
    key = 't',
    mods = 'ALT|SHIFT',
    action = act.PromptInputLine {
      description = wezterm.format {
        { Attribute = { Intensity = 'Bold' } },
        { Foreground = { AnsiColor = 'Fuchsia' } },
        { Text = 'Enter name for new workspace' },
      },
      action = wezterm.action_callback(function(window, pane, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:perform_action(
            act.SwitchToWorkspace {
              name = line,
            },
            pane
          )
        end
      end),
    },
  },
  -- Rename workspace
  {
    key = "r",
    mods = "ALT|SHIFT",
    action = act.PromptInputLine {
      description = "Enter new name for the current workspace...",
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          wezterm.mux.rename_workspace(
            wezterm.mux.get_active_workspace(),
            line
          )
        end
      end)
    }
  },
  -- Terminal scroll up and down
  { key = 'PageUp', mods = 'SHIFT', action = act.ScrollByPage(-1) },
  { key = 'PageDown', mods = 'SHIFT', action = act.ScrollByPage(1) },
}

-- Mouse
config.mouse_bindings = {
  -- Bind middle click to send CTRL + SHIFT + V to paste. Broken.
  -- {
    --   event = { Up = { streak = 1, button = "Middle" } },
    --   mods = "NONE",
    --   action = act.SendKey { key = "V", mods = "CTRL|SHIFT" },
    -- },
    -- {
      --   event = { Down = { streak = 1, button = "Middle" } },
      --   mods = "NONE",
      --   action = act.Nop,
  -- },

  -- Change the default click behavior so that it only selects text and doesn"t open hyperlinks
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = act.CompleteSelection "ClipboardAndPrimarySelection",
  },

  -- Bind "Up" event of CTRL-Click to open hyperlinks
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = act.OpenLinkAtMouseCursor,
  },
  -- Disable the "Down" event of CTRL-Click to avoid weird program behaviors
  {
    event = { Down = { streak = 1, button = "Left" } },
    mods = "CTRL",
    action = act.Nop,
  },

  -- Scrolling up while holding CTRL increases the font size
  {
    event = { Down = { streak = 1, button = { WheelUp = 1 } } },
    mods = "CTRL",
    action = act.IncreaseFontSize,
  },

  -- Scrolling down while holding CTRL decreases the font size
  {
    event = { Down = { streak = 1, button = { WheelDown = 1 } } },
    mods = "CTRL",
    action = act.DecreaseFontSize,
  },
}

-- Show workspace name on left status
wezterm.on("update-status", function(window, pane)
  local ws = wezterm.mux.get_active_workspace()

  window:set_left_status(wezterm.format {
    { Text = " [Workspace: " .. ws .. "] " },
  })
end)

-- Show current directory, date and time on right status
wezterm.on("update-status", function(window, pane)
  local status = {}

  local cwd_uri = pane:get_current_working_dir()
  if (cwd_uri) then
    table.insert(status, { Text = wezterm.nerdfonts.cod_folder .. " " .. cwd_uri.file_path } )
    table.insert(status, { Text = "  " } )
  end

  local date = wezterm.strftime("%Y-%m-%d")
  table.insert(status, { Text = wezterm.nerdfonts.md_calendar .. " " .. date } )
  table.insert(status, { Text = "  " })

  local time = wezterm.strftime("%H:%M")
  table.insert(status, { Text = wezterm.nerdfonts.md_clock .. " " .. time } )
  table.insert(status, { Text = " " })

  window:set_right_status(wezterm.format(status))
end)


return config
