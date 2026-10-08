-- Session snapshots for Rex: a tmux-resurrect style save/restore.
--
-- save:    every session -> windows -> layers -> split tree, plus each
--          terminal's working directory and foreground command.
-- restore: rebuilds sessions that aren't already running (matched by label),
--          starting a shell in each saved directory and re-launching
--          allowlisted programs. Coding agents resume their last chat.
--
-- Snapshots are Lua tables in $XDG_STATE_HOME/rex/snapshots/<name>.lua
-- (default ~/.local/state/rex/snapshots). They contain your paths and
-- commands, so they live outside the dotfiles repo.

local M = {}

local TERMINAL = "com.superlogical.terminal"
local SHELL_FLAVOR = TERMINAL .. ".shell"

-- Programs re-launched with their saved arguments.
M.allow = {
  nvim = true, vim = true, vi = true, htop = true, btop = true, top = true,
  less = true, man = true, tail = true, watch = true, lazygit = true,
  yazi = true, k9s = true,
}

-- Coding agents: re-launched with these commands instead (resume last chat
-- in that directory). Matched against the program name.
M.agents = {
  claude = "claude --continue",
  pi = "pi -c",
}

-- Foreground programs that just mean "idle at a prompt".
local SHELLS = { fish = true, zsh = true, bash = true, sh = true, login = true }

-- Labels Rex generates; not worth restoring as fixed labels.
local function is_default_window_label(label)
  return label == nil or label == "" or label:match("^Window %x+$") ~= nil
end
local function is_default_block_label(label)
  return label == nil or label == "" or label == "shell"
end

------------------------------------------------------------------------------
-- Helpers

local function snapshot_dir()
  local state = os.getenv("XDG_STATE_HOME")
  if state == nil or state == "" then
    state = os.getenv("HOME") .. "/.local/state"
  end
  return state .. "/rex/snapshots"
end

local function shell_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function snapshot_path(name)
  if not name:match("^[%w_.-]+$") then
    error("snapshot name may only contain letters, digits, '.', '_' and '-': " .. name, 0)
  end
  return snapshot_dir() .. "/" .. name .. ".lua"
end

local function url_decode(s)
  return (s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

-- file://host/Users/you/src -> /Users/you/src
local function path_from_url(url)
  if url == nil then return nil end
  local path = url:match("^file://[^/]*(/.*)$")
  return path and url_decode(path) or nil
end

local function command_of_pid(pid)
  local p = io.popen("ps -o args= -p " .. tonumber(pid) .. " 2>/dev/null")
  if p == nil then return nil end
  local out = p:read("*a") or ""
  p:close()
  out = out:gsub("%s+$", "")
  return out ~= "" and out or nil
end

local function basename(path)
  return (path:match("([^/]+)$") or path)
end

local function must(result, err, what)
  if err ~= nil then error((what or "rex call") .. ": " .. tostring(err), 0) end
  return result
end

-- Per-session calls (view, block methods, focus, layers...) need this
-- connection attached to the session. Returns the session's view.
local function attach(session_id)
  local r = must(rex.call("session.attach", { session_id = session_id }), nil, "session.attach")
  return r.view
end

local function detach(session_id)
  rex.call("session.detach", { session_id = session_id })
end

-- Serialize a plain Lua value (tables, strings, numbers, booleans).
local function serialize(v, indent)
  indent = indent or ""
  local t = type(v)
  if t == "string" then return string.format("%q", v) end
  if t == "number" or t == "boolean" then return tostring(v) end
  if t ~= "table" then return "nil" end
  local inner = indent .. "  "
  local parts = {}
  local n = #v
  for i = 1, n do parts[#parts + 1] = inner .. serialize(v[i], inner) end
  local keys = {}
  for k in pairs(v) do
    if type(k) == "string" then keys[#keys + 1] = k end
  end
  table.sort(keys)
  for _, k in ipairs(keys) do
    local key = k:match("^[%a_][%w_]*$") and k or ("[" .. string.format("%q", k) .. "]")
    parts[#parts + 1] = inner .. key .. " = " .. serialize(v[k], inner)
  end
  if #parts == 0 then return "{}" end
  return "{\n" .. table.concat(parts, ",\n") .. ",\n" .. indent .. "}"
end

------------------------------------------------------------------------------
-- Save

local function terminal_info(session_id, block_id)
  local info = {}
  local pwd = rex.call(TERMINAL .. ".pwd", { session_id = session_id, block_id = block_id, args = {} })
  if pwd then info.cwd = path_from_url(pwd.pwd) end

  local proc = rex.call(TERMINAL .. ".process", { session_id = session_id, block_id = block_id, args = {} })
  local fg = proc and proc.foreground
  if fg then
    info.cwd = info.cwd or fg.cwd
    local cmd = fg.pid and command_of_pid(fg.pid)
    local prog = basename((cmd and cmd:match("^(%S+)")) or fg.argv0 or fg.name or "")
    if not SHELLS[prog] and not SHELLS[fg.argv0 or ""] then
      info.prog = prog
      info.cmd = cmd
      if fg.argv0 and fg.argv0 ~= prog then info.argv0 = fg.argv0 end
    end
  end
  return info
end

local function save_node(node, blocks, session_id, window)
  if node == nil then return nil end
  if node.split then
    local s = node.split
    return {
      split = {
        direction = s.direction,
        ratio = s.ratio,
        before = save_node(s.before, blocks, session_id, window),
        after = save_node(s.after, blocks, session_id, window),
      },
    }
  end
  if node.block_id then
    local b = blocks[node.block_id] or {}
    local leaf = {
      flavor = b.flavor or SHELL_FLAVOR,
      label = (not is_default_block_label(b.label)) and b.label or nil,
    }
    if leaf.flavor:sub(1, #TERMINAL) == TERMINAL then
      local info = terminal_info(session_id, node.block_id)
      leaf.cwd, leaf.prog, leaf.cmd, leaf.argv0 = info.cwd, info.prog, info.cmd, info.argv0
    end
    if node.block_id == window.focused_block_id then leaf.focused = true end
    if node.block_id == window.zoomed_block_id then leaf.zoomed = true end
    return { block = leaf }
  end
  return nil
end

function M.capture()
  local list = must(rex.call("session.list"), nil, "session.list")
  local snap = { version = 1, saved_at = os.date("!%Y-%m-%dT%H:%M:%SZ"), sessions = {} }
  for _, s in ipairs(list.sessions or {}) do
    local view = attach(s.session_id)
    local sess = { label = view.label or s.label, windows = {} }
    for _, w in ipairs(view.windows or {}) do
      local win = {
        label = (not is_default_window_label(w.label)) and w.label or nil,
        active = (w.window_id == view.active_window_id) or nil,
        layers = {},
      }
      for _, layer in ipairs(w.layers or {}) do
        local blocks = {}
        for _, b in ipairs(layer.blocks or {}) do blocks[b.block_id] = b end
        local layout = save_node(layer.layout, blocks, s.session_id, w)
        if layout then
          win.layers[#win.layers + 1] = {
            kind = layer.kind,
            bounds = layer.kind ~= "tiled" and layer.bounds or nil,
            layout = layout,
          }
        end
      end
      if #win.layers > 0 then sess.windows[#sess.windows + 1] = win end
    end
    detach(s.session_id)
    if #sess.windows > 0 then snap.sessions[#snap.sessions + 1] = sess end
  end
  return snap
end

function M.save(name)
  name = name or "last"
  local snap = M.capture()
  local path = snapshot_path(name)
  os.execute("mkdir -p " .. shell_quote(snapshot_dir()))
  local f = assert(io.open(path, "w"))
  f:write("-- Rex session snapshot \"", name, "\"\nreturn ", serialize(snap), "\n")
  f:close()
  local windows = 0
  for _, s in ipairs(snap.sessions) do windows = windows + #s.windows end
  return { saved = name, path = path, sessions = #snap.sessions, windows = windows }
end

------------------------------------------------------------------------------
-- Restore

-- What to type into a restored terminal, or nil for a plain shell.
local function relaunch_input(leaf)
  local prog = leaf.prog
  if prog == nil then return nil end
  local agent = M.agents[prog] or (leaf.argv0 and M.agents[leaf.argv0])
  if agent then return agent .. "\n" end
  if M.allow[prog] and leaf.cmd then return leaf.cmd .. "\n" end
  return nil
end

-- Build a layout for session.create / new_layer, collecting leaves in the
-- same depth-first order Rex returns block_ids.
local function build_layout(node, leaves)
  if node.split then
    local s = node.split
    local before = build_layout(s.before, leaves)
    local after = build_layout(s.after, leaves)
    local make = s.direction == "vertical" and rex.layout.vertical or rex.layout.horizontal
    return make(s.ratio, before, after)
  end
  local leaf = node.block
  leaves[#leaves + 1] = leaf
  local options = {}
  if leaf.cwd then options.cwd = leaf.cwd end
  options.initial_input = relaunch_input(leaf)
  local block = rex.layout.block{ flavor = leaf.flavor or SHELL_FLAVOR, options = options }
  if leaf.label then block.block.label = leaf.label end
  return block
end

local function find_tiled(win)
  for _, layer in ipairs(win.layers) do
    if layer.kind == "tiled" then return layer end
  end
  return nil
end

local function restore_session(sess)
  local initial, tiled_leaves = {}, {}
  for i, win in ipairs(sess.windows) do
    local tiled = find_tiled(win)
    local leaves = {}
    local layout = tiled and build_layout(tiled.layout, leaves)
      or rex.layout.block{ flavor = SHELL_FLAVOR }
    initial[i] = { window_label = win.label, layout = layout }
    tiled_leaves[i] = leaves
  end

  local created = must(rex.call("session.create", { label = sess.label, initial_windows = initial }),
    nil, "session.create " .. sess.label)
  local sid = created.session_id
  attach(sid)
  local focus_window, focus_block, zooms = nil, nil, {}

  local active_win
  local function note(leaf, block_id)
    -- Each window remembers a focused pane; only the active window's matters.
    if leaf.focused and active_win then focus_block = focus_block or block_id end
    if leaf.zoomed then zooms[#zooms + 1] = block_id end
  end

  for i, win in ipairs(sess.windows) do
    local made = created.initial_windows[i] or {}
    active_win = win.active
    for j, leaf in ipairs(tiled_leaves[i]) do
      if made.block_ids and made.block_ids[j] then note(leaf, made.block_ids[j]) end
    end
    for _, layer in ipairs(win.layers) do
      if layer.kind ~= "tiled" and made.window_id then
        local leaves = {}
        local res = rex.call("session.new_layer", {
          session_id = sid, window_id = made.window_id, bounds = layer.bounds,
          layout = build_layout(layer.layout, leaves), focus = false,
        })
        for j, leaf in ipairs(leaves) do
          if res and res.block_ids and res.block_ids[j] then note(leaf, res.block_ids[j]) end
        end
      end
    end
    if win.active then focus_window = made.window_id end
  end

  for _, b in ipairs(zooms) do
    rex.call("session.zoom_block", { session_id = sid, block_id = b, zoom = true })
  end
  if focus_window then rex.call("session.focus_window", { session_id = sid, window_id = focus_window }) end
  if focus_block then rex.call("session.focus_block", { session_id = sid, block_id = focus_block }) end
  detach(sid)
  return sid
end

function M.load(name)
  local path = snapshot_path(name or "last")
  local chunk, err = loadfile(path)
  if chunk == nil then error("cannot read snapshot " .. path .. ": " .. tostring(err), 0) end
  return chunk(), path
end

function M.restore(name)
  name = name or "last"
  local snap, path = M.load(name)
  local running = {}
  local list = must(rex.call("session.list"), nil, "session.list")
  for _, s in ipairs(list.sessions or {}) do
    if s.label then running[s.label:lower()] = true end
  end
  local restored, skipped, failed = {}, {}, {}
  for _, sess in ipairs(snap.sessions or {}) do
    if sess.label and running[sess.label:lower()] then
      skipped[#skipped + 1] = sess.label
    else
      local ok, err = pcall(restore_session, sess)
      if ok then restored[#restored + 1] = sess.label
      else failed[#failed + 1] = (sess.label or "?") .. ": " .. tostring(err) end
    end
  end
  return { snapshot = name, path = path, saved_at = snap.saved_at,
           restored = restored, skipped = skipped, failed = failed }
end

function M.list()
  local names = {}
  local p = io.popen("ls -1 " .. shell_quote(snapshot_dir()) .. " 2>/dev/null")
  if p then
    for line in p:lines() do
      local n = line:match("^(.+)%.lua$")
      if n then names[#names + 1] = n end
    end
    p:close()
  end
  return names
end

return M
