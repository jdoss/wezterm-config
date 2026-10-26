-- Claude Code sessions through claude-profile. ALT+SHIFT+C (claude.split) asks for a profile
-- and opens it in a split beside the current pane, in that pane's directory. bin/claude-tab
-- <profile> (deckbro's Personal and Work keys run it) sets the claude_tab user var on the
-- focused pane, and claude.on_user_var_changed asks there for a directory and opens a new
-- tab. Both ask whether to use the sandbox for profiles with a .sandbox marker.
local wezterm = require "wezterm"
local act = wezterm.action

local M = {}

local home = wezterm.home_dir
local profiles_dir = home .. "/.claude-profiles/"
local OTHER_DIR = "other"

local function is_dir(path)
  return (pcall(wezterm.read_dir, path))
end

local function exists(path)
  local file = io.open(path)
  if file then
    file:close()
  end
  return file ~= nil
end

local function is_profile(name)
  return name:match "^%w[%w._-]*$" ~= nil and is_dir(profiles_dir .. name)
end

local function with_tilde(path)
  if path == home then
    return "~"
  elseif path:sub(1, #home + 1) == home .. "/" then
    return "~" .. path:sub(#home + 1)
  end
  return path
end

local function without_tilde(path)
  if path == "~" then
    return home
  elseif path:sub(1, 2) == "~/" then
    return home .. path:sub(2)
  end
  return path
end

-- On macOS, Homebrew's bash. Apps started from the Dock get PATH /usr/bin:/bin:/usr/sbin:/sbin,
-- where bash is Apple's 3.2, too old for ~/.bashrc.
local bash = wezterm.target_triple:find "darwin" and "/opt/homebrew/bin/bash" or "bash"

-- An interactive login shell, like a new tab's, so the CLAUDE_PROFILE_* settings in
-- ~/.bashrc apply. The command is one string because arguments after it would reach
-- ~/.bashrc, where ble.sh reads them as its own options. Profile names are checked by
-- is_profile first, so they are safe in it.
local function in_login_shell(command)
  return { bash, "-lic", "exec " .. command }
end

local function profile_choices()
  local choices = {}
  for _, path in ipairs(wezterm.glob(profiles_dir .. "*")) do
    local name = path:match "([^/]+)$"
    if is_profile(name) then
      table.insert(choices, { id = name, label = name })
    end
  end
  return choices
end

-- The directories the profile's sessions ran in that still exist, most recently started
-- first, from the projects Claude Code keeps in the profile's .claude.json.
local function recent_dirs(profile)
  local file = io.open(profiles_dir .. profile .. "/.claude.json")
  if not file then
    return {}
  end
  local text = file:read "a"
  file:close()
  local ok, state = pcall(wezterm.json_parse, text)
  if not ok then
    wezterm.log_warn(
      "claude: can't parse " .. profile .. "'s .claude.json: " .. tostring(state)
    )
    return {}
  end
  local projects = {}
  for path, project in pairs(state.projects or {}) do
    if is_dir(path) then
      table.insert(projects, { path = path, started = project.lastStartTime or 0 })
    end
  end
  table.sort(projects, function(a, b)
    if a.started ~= b.started then
      return a.started > b.started
    end
    return a.path < b.path
  end)
  local dirs = {}
  for _, project in ipairs(projects) do
    table.insert(dirs, project.path)
  end
  return dirs
end

-- Git repositories one and two levels under ~/src, such as ~/src/personal/deckbro.
local function src_repos()
  local repos = {}
  for _, pattern in ipairs { "/src/*/.git", "/src/*/*/.git" } do
    for _, git in ipairs(wezterm.glob(home .. pattern)) do
      table.insert(repos, git:match "^(.*)/%.git$")
    end
  end
  table.sort(repos)
  return repos
end

local function dir_choices(profile)
  local choices, listed = {}, {}
  local function add(path)
    if not listed[path] then
      listed[path] = true
      table.insert(choices, { id = path, label = with_tilde(path) })
    end
  end
  for _, path in ipairs(recent_dirs(profile)) do
    add(path)
  end
  for _, path in ipairs(src_repos()) do
    add(path)
  end
  table.insert(choices, { id = OTHER_DIR, label = "Other directory…" })
  return choices
end

-- Asks whether to use the sandbox when the profile has one, then calls
-- open(window, pane, env) with the environment for the answer.
local function choose_sandbox(window, pane, profile, dir, open)
  if not exists(profiles_dir .. profile .. "/.sandbox") then
    open(window, pane, {})
    return
  end
  local place = dir and " in " .. with_tilde(dir) or ""
  window:perform_action(
    act.InputSelector {
      title = "Claude Code: " .. profile,
      description = "Where should the " .. profile .. " session" .. place
        .. " run?  Enter = accept,  Esc = cancel",
      choices = {
        { id = "1", label = "Sandbox (microVM)" },
        { id = "0", label = "Host" },
      },
      action = wezterm.action_callback(function(inner_window, inner_pane, id)
        if id then
          open(inner_window, inner_pane, { CLAUDE_PROFILE_SANDBOX = id })
        end
      end),
    },
    pane
  )
end

local function open_tab(window, pane, profile, dir)
  choose_sandbox(window, pane, profile, dir, function(inner_window, inner_pane, env)
    inner_window:perform_action(
      act.SpawnCommandInNewTab {
        cwd = dir,
        args = in_login_shell("claude-profile " .. profile),
        set_environment_variables = env,
      },
      inner_pane
    )
  end)
end

local function ask_other_dir(window, pane, profile)
  window:perform_action(
    act.PromptInputLine {
      description = "Directory for the new " .. profile .. " session:",
      initial_value = "~/",
      action = wezterm.action_callback(function(inner_window, inner_pane, line)
        if not line or line == "" then
          return
        end
        local dir = without_tilde(line)
        if is_dir(dir) then
          open_tab(inner_window, inner_pane, profile, dir)
        else
          inner_window:toast_notification("Claude Code", line .. " isn't a directory", nil, 4000)
        end
      end),
    },
    pane
  )
end

local function ask_dir(window, pane, profile)
  window:perform_action(
    act.InputSelector {
      title = "Claude Code: " .. profile,
      fuzzy = true,
      fuzzy_description = "New " .. profile .. " session in: ",
      choices = dir_choices(profile),
      action = wezterm.action_callback(function(inner_window, inner_pane, id)
        if id == OTHER_DIR then
          ask_other_dir(inner_window, inner_pane, profile)
        elseif id then
          open_tab(inner_window, inner_pane, profile, id)
        end
      end),
    },
    pane
  )
end

function M.on_user_var_changed(window, pane, name, value)
  if name ~= "claude_tab" then
    return
  end
  if not is_profile(value) then
    window:toast_notification("Claude Code", "There's no claude-profile named " .. value, nil, 4000)
    return
  end
  ask_dir(window, pane, value)
end

local function open_split(window, pane, args, env)
  window:perform_action(
    act.SplitPane {
      direction = "Right",
      command = { args = args, set_environment_variables = env },
      size = { Percent = 40 },
    },
    pane
  )
end

-- Without claude-profile installed, this opens plain claude instead, without asking.
function M.split(window, pane)
  if not wezterm.run_child_process { "which", "claude-profile" } then
    open_split(window, pane, in_login_shell "claude", {})
    return
  end
  window:perform_action(
    act.InputSelector {
      title = "Claude Profile",
      choices = profile_choices(),
      fuzzy = true,
      action = wezterm.action_callback(function(inner_window, inner_pane, profile)
        if not profile then
          return
        end
        local cwd = inner_pane:get_current_working_dir()
        local dir = cwd and cwd.file_path
        choose_sandbox(inner_window, inner_pane, profile, dir, function(w, p, env)
          open_split(w, p, in_login_shell("claude-profile " .. profile), env)
        end)
      end),
    },
    pane
  )
end

return M
