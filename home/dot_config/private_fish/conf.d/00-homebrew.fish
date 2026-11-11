# Homebrew environment, loaded before every other conf.d snippet (fish sorts
# them by file name across all conf.d directories). It must run before
# Homebrew's vendor_conf.d/mise-activate.fish, so mise's tools end up ahead
# of Homebrew's in PATH.
test -x /opt/homebrew/bin/brew; and /opt/homebrew/bin/brew shellenv fish | source
