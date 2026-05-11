local wezterm = require 'wezterm'
local config = wezterm.config_builder()
local act = wezterm.action

config.color_scheme = 'Builtin Solarized Light'
config.window_close_confirmation = 'AlwaysPrompt'
config.skip_close_confirmation_for_processes_named = {}
config.bypass_mouse_reporting_modifiers = 'SHIFT'
config.enable_scroll_bar = true
config.scrollback_lines = 100000

local tmux_tab_helper = wezterm.home_dir .. '/DEV/script/bin/wezterm-tmux-tab'

config.default_prog = { tmux_tab_helper, 'attach-new' }

local tmux_name_cache = {
  expires = 0,
  names = {},
}

local tab_tmux_sessions = {}

local function parse_tmux_sessions(stdout)
  local sessions = {}
  for line in stdout:gmatch('[^\r\n]+') do
    local session_name, display_name = line:match('^([^\t]+)\t(.*)$')
    if session_name then
      table.insert(sessions, {
        session_name = session_name,
        display_name = display_name ~= '' and display_name or session_name,
      })
    end
  end
  return sessions
end

local function tmux_sessions()
  local success, stdout = wezterm.run_child_process { tmux_tab_helper, 'startup-list' }
  if not success then
    return {}
  end
  return parse_tmux_sessions(stdout)
end

local function tmux_session_names()
  local now = os.time()
  if now < tmux_name_cache.expires then
    return tmux_name_cache.names
  end

  local success, stdout = wezterm.run_child_process { tmux_tab_helper, 'names' }
  if not success then
    return tmux_name_cache.names
  end

  local names = {}
  for _, session in ipairs(parse_tmux_sessions(stdout)) do
    names[session.session_name] = session.display_name
  end

  tmux_name_cache.names = names
  tmux_name_cache.expires = now + 2
  return names
end

local function tmux_session_name_from_pane_info(pane)
  if not pane or not pane.user_vars then
    return nil
  end
  return pane.user_vars.tmux_session_name
end

local function tmux_session_name_from_pane(pane)
  if not pane then
    return nil
  end

  local vars = pane:get_user_vars()
  return vars and vars.tmux_session_name or nil
end

local function tab_id(tab)
  if not tab then
    return nil
  end

  local value = tab.tab_id
  if type(value) == 'function' then
    return tab:tab_id()
  end

  return value
end

local function remember_tab_session(tab, session_name)
  local id = tab_id(tab)
  if id then
    tab_tmux_sessions[id] = session_name
  end
end

local function active_tmux_session(window, pane)
  local active_tab = window:active_tab()
  local remembered = active_tab and tab_tmux_sessions[tab_id(active_tab)] or nil
  return remembered or tmux_session_name_from_pane(pane)
end

local function first_line(value)
  return value and value:match('^%s*([^\r\n]+)') or nil
end

config.keys = {
  {
    key = 'o',
    mods = 'CTRL|ALT',
    action = act.ShowLauncherArgs {
      flags = 'DOMAINS',
      title = '连接/会话',
    },
  },
  {
    key = 'd',
    mods = 'CTRL|ALT',
    action = act.DetachDomain 'CurrentPaneDomain',
  },
  {
    key = 't',
    mods = 'CTRL|SHIFT',
    action = wezterm.action_callback(function(window)
      local success, stdout = wezterm.run_child_process { tmux_tab_helper, 'new' }
      if not success then
        window:perform_action(act.SpawnTab 'CurrentPaneDomain', window:active_pane())
        return
      end

      local session_name = first_line(stdout)
      if not session_name then
        return
      end

      local tab = window:mux_window():spawn_tab {
        args = { tmux_tab_helper, 'attach', session_name },
      }
      remember_tab_session(tab, session_name)
      tmux_name_cache.expires = 0
      tab:activate()
    end),
  },
  {
    key = 'r',
    mods = 'CTRL|SHIFT',
    action = act.PromptInputLine {
      description = 'Rename tmux session',
      action = wezterm.action_callback(function(window, pane, line)
        if not line or line == '' then
          return
        end

        local old_session = active_tmux_session(window, pane)
        if not old_session then
          return
        end

        local success, stdout = wezterm.run_child_process { tmux_tab_helper, 'rename', old_session, line }
        if not success then
          return
        end

        local new_session = first_line(stdout) or line
        remember_tab_session(window:active_tab(), new_session)
        tmux_name_cache.expires = 0
      end),
    },
  },
}

wezterm.on('format-tab-title', function(tab)
  local session_name = tab_tmux_sessions[tab_id(tab)] or tmux_session_name_from_pane_info(tab.active_pane)
  local title = session_name and tmux_session_names()[session_name] or nil
  if not title or title == '' then
    title = session_name or 'tmux'
  end

  return ' ' .. title .. ' '
end)

wezterm.on('gui-startup', function()
  local sessions = tmux_sessions()
  local first = sessions[1]
  if not first then
    return
  end

  local tab, _, window = wezterm.mux.spawn_window {
    args = { tmux_tab_helper, 'attach', first.session_name },
  }
  remember_tab_session(tab, first.session_name)

  for i = 2, #sessions do
    local tmux_session = sessions[i]
    local new_tab = window:spawn_tab {
      args = { tmux_tab_helper, 'attach', tmux_session.session_name },
    }
    remember_tab_session(new_tab, tmux_session.session_name)
  end
end)

return config
