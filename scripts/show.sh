#!/bin/sh
# Path:         COMPX304-A1/scripts/show.sh
# Brief:        Shows configuration on all routers via SSH tmux.
# Usage:        `$ show.sh <option>`

local_ssh_config="local_ssh_config"

# Function:     main
# Brief:        Main function to start the update process.
main() {
    if [ ! -f "$local_ssh_config" ]; then
        printf "ERROR: SSH configuration file %s does not exist.\n" "$local_ssh_config"
        main_exit 1
    else
         # Start the process to ssh and record the specified commands.
        . "$local_ssh_config"      # Load local ssh configs file.
        option=$1
        case "$option" in
            "bgp")
                show "show ip bgp" ;;
            "bgp_summary")
                show "show ip bgp summary" ;;
            *)
                printf "\nERROR: Configuration type doesn't exist.\n"
                main_exit 1
                ;;
        esac
    fi
}

show() {
    command="$1"
    SSH_ENV="export SSH_AUTH_SOCK=$SSH_AUTH_SOCK;"

    # Start tmux session if it doesn't exist
    if ! tmux has-session -t lab 2>/dev/null; then
        tmux new-session -d -s lab "$SSH_ENV exec ssh $SSH_ALIAS"
        sleep 1
    fi

    for location in LOND HAML PARI TRGA NEWY BOST ATLA ZURI; do
        # Create a new tmux window for each location
        tmux new-window -t lab -n "$location" "$SSH_ENV exec ssh $SSH_ALIAS"
        sleep 1

        # Navigate to the router location
        tmux send-keys -t lab:"$location" "./goto.sh $location" C-m
        sleep 2
        tmux pipe-pane -t lab:"$location" -o "cat > ../logs/${location}_show_${option}.txt"
        tmux send-keys -t lab:"$location" "$command" C-m
        sleep 1
        tmux pipe-pane -t lab:"$location"

        # Exit after applying configs
        printf "%s > 'exit'\n" "$location"
        tmux send-keys -t lab:"$location" "exit" C-m
        sleep 1
    done

    # Kill the session after all updates
    tmux kill-session -t lab
}


# Function:     ssh_kill_pane
# Brief:        Sends clean exit commands to leave the session.
ssh_kill_pane() {
    pane=$1
    tmux send-keys -t 0 "exit" C-m      # Exit config mode cleanly
    sleep 0.5
    tmux send-keys -t 0 "exit" C-m      # Exit session
    sleep 0.5
}


# Function:     ssh_update_exit
# Brief:        Kills tmux session and exits successfully.
update_exit() {
    tmux kill-session -t lab 2>/dev/null
    printf "\nConfiguration updated successfully on all routers.\n"
    exit 0
}


# Function:     main_exit
# Brief:        Unsets all variables and exits with error.
main_exit() {
    tmux kill-session -t lab 2>/dev/null
    printf "\nERROR: Exiting with error code $1.\n"
    exit "$1"
}


# Call main to execute the script.
main "$@"
