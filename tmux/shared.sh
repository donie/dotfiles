#!/usr/bin/env bash

get_tmux_option() {
	local option=$1
	local default_value=$2
	local option_value=$(tmux show-option -gqv "$option")
	if [ -z "$option_value" ]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}

set_tmux_option() {
	local option=$1
	local value=$2
	tmux set-option -gq "$option" "$value"
}

parse_ssh_port() {
  # If there is a port get it
  local port=$(echo $1|grep -Eo '\-p\s*([0-9]+)'|sed 's/-p\s*//')

  if [ -z $port ]; then
    local port=22
  fi

  echo $port
}

get_ssh_user() {
  local ssh_user=$(whoami)

  for ssh_config in `awk '
    $1 == "Host" {
      gsub("\\\\.", "\\\\.", $2);
      gsub("\\\\*", ".*", $2);
      host = $2;
      next;
    }
    $1 == "User" {
      $1 = "";
      sub( /^[[:space:]]*/, "" );
      printf "%s|%s\n", host, $0;
    }' .ssh/config`; do
    local host_regex=${ssh_config%|*}
    local host_user=${ssh_config#*|}
    if [[ "$1" =~ $host_regex ]]; then
      ssh_user=$host_user
      break
    fi
  done

  echo $ssh_user
}

# Recursively find the SSH process by traversing the process tree
find_ssh_process() {
    local pid=$1
    for child in $(pgrep -P "$pid"); do
        local cmd=$(ps -o command= -p "$child")
        if echo "$cmd" | grep -q "ssh "; then
            echo "$cmd"
            return
        fi
        # Recursively search in the child processes
        find_ssh_process "$child"
    done
}

get_remote_info() {
    local command=$1
    echo "DEBUG: get_remote_info called with $command" >> /tmp/tmux-debug.log

    # Get the pane PID
    local pane_pid=$(tmux display-message -p "#{pane_pid}")
    echo "DEBUG: Pane PID: $pane_pid" >> /tmp/tmux-debug.log

    # Find the SSH process starting from the pane PID
    local ssh_cmd=$(find_ssh_process "$pane_pid")
    if [ -z "$ssh_cmd" ]; then
        echo "DEBUG: No SSH process found in descendants" >> /tmp/tmux-debug.log
        return
    fi
    echo "DEBUG: SSH Command: $ssh_cmd" >> /tmp/tmux-debug.log

    # Parse the SSH command arguments
    local user=""
    local host=""
    local port=""
    local args=($ssh_cmd) # Split the command into an array

    for ((i=1; i<${#args[@]}; i++)); do
        case "${args[i]}" in
            -p) # Handle custom port
                port="${args[i+1]}"
                ((i++)) # Skip next argument (port number)
                ;;
            *@*) # Handle user@host
                user=$(echo "${args[i]}" | cut -d@ -f1)
                host=$(echo "${args[i]}" | cut -d@ -f2)
                ;;
            -*)
                continue # Ignore other flags
                ;;
            *)
                if [[ -z "$host" ]]; then
                    host="${args[i]}" # First non-option argument is the hostname
                fi
                ;;
        esac
    done

    # Default to current user if no user was provided
    if [ -z "$user" ]; then
        user=$(whoami)
    fi

    echo "DEBUG: Parsed User: $user, Host: $host, Port: ${port:-22}" >> /tmp/tmux-debug.log

    case "$command" in
        "whoami")
            echo "$user"
            ;;
        "hostname")
            echo "$host"
            ;;
        "port")
            echo "${port:-22}" # Default to port 22 if not specified
            ;;
        *)
            echo "$user@$host:${port:-22}"
            ;;
    esac
}

get_info() {
  # If command is ssh do some magic
  if ssh_connected; then
    echo $(get_remote_info $1)
  else
    echo $($1)
  fi
}

ssh_connected() {
  # Get current pane command
  local cmd=$(tmux display-message -p "#{pane_current_command}")

  [ $cmd = "ssh" ] || [ $cmd = "sshpass" ]
}
