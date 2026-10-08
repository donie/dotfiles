-- Rex configuration (https://www.superlogical.com/rex/docs/customize/config)
-- Linked to ~/.config/rex by dotbot. Apply changes with: rex config reload
--
-- tmux-style bindings migrated from tmux/tmux.conf.
-- tmux window == Rex tab; tmux session == Rex session.

local P = "ctrl+a>" -- prefix, same as tmux

-- Press the prefix twice to send ctrl+a to the terminal (shell line start)
rex.bind(P .. "ctrl+a", "pane.send_key", { key = "ctrl+a" })

-- Config ---------------------------------------------------------------------
rex.bind(P .. "r", "client.config.reload")
rex.bind(P .. "shift+;", "client.palette.toggle") -- ":" command prompt

-- Panes ----------------------------------------------------------------------
rex.bind(P .. "shift+\\", "pane.split.right") -- "|"
rex.bind(P .. "-", "pane.split.down")

rex.bind(P .. "h", "pane.focus.left")
rex.bind(P .. "j", "pane.focus.down")
rex.bind(P .. "k", "pane.focus.up")
rex.bind(P .. "l", "pane.focus.right")
rex.bind(P .. "o", "pane.focus_next")

rex.bind(P .. "z", "pane.zoom")
rex.bind(P .. "x", "pane.close")
rex.bind(P .. "shift+1", "pane.move_to_new_tab") -- "!"
rex.bind(P .. "g", "pane.go_to_directory")

-- One-shot resize (tmux: bind -r H/J/K/L resize-pane 5)
rex.bind(P .. "shift+h", "pane.resize", { direction = "left", amount = 5 })
rex.bind(P .. "shift+j", "pane.resize", { direction = "down", amount = 5 })
rex.bind(P .. "shift+k", "pane.resize", { direction = "up", amount = 5 })
rex.bind(P .. "shift+l", "pane.resize", { direction = "right", amount = 5 })

-- Resize mode: prefix R, then hjkl repeatedly; Esc/Enter to leave
rex.mode("resize", { exclusive = true })
rex.bind(P .. "shift+r", "client.mode.enter", { name = "resize" })
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("resize/" .. key, "pane.resize", { direction = dir, amount = 5 })
  rex.bind("resize/shift+" .. key, "pane.resize", { direction = dir, amount = 15 })
end
rex.bind("resize/=", "pane.balance")
rex.bind("resize/enter", "client.mode.exit")

-- Tabs (tmux windows) --------------------------------------------------------
rex.bind(P .. "c", "client.tab.new")
rex.bind(P .. ",", "client.tab.rename")
rex.bind(P .. "shift+7", "client.tab.close") -- "&"

rex.bind(P .. "n", "client.tab.next")
rex.bind(P .. "p", "client.tab.previous")
rex.bind(P .. "ctrl+n", "client.tab.next")
rex.bind(P .. "ctrl+p", "client.tab.previous")
rex.bind(P .. "ctrl+l", "client.tab.next")
rex.bind(P .. "ctrl+h", "client.tab.previous")
rex.bind(P .. "b", "client.tab.previous")

for i = 1, 9 do
  rex.bind(P .. i, "client.tab.goto", { index = i })
end

-- Sessions -------------------------------------------------------------------
rex.bind(P .. "s", "session.switch")
rex.bind(P .. "shift+4", "session.rename") -- "$"
rex.bind(P .. "shift+9", "session.previous") -- "("
rex.bind(P .. "shift+0", "session.next") -- ")"

-- Search (closest to tmux copy-mode search) ----------------------------------
rex.bind(P .. "/", "client.find.open")
