#!/bin/sh
# Path:         COMPX304-A1/scripts/update.sh
# Brief:        Updates configuration on all routers via SSH tmux.
# Usage:        `$ update.sh <file_suffix>`

local_ssh_config="local_ssh_config"
generated_dir="generated"

# Function:     main
# Brief:        Main function to start the update process.
main() {
    if [ ! -d "$generated_dir" ]; then
        printf "ERROR: Generated directory %s does not exist.\n" "$generated_dir"
        error_exit
    elif [ ! -f "$local_ssh_config" ]; then
        printf "ERROR: SSH configuration file %s does not exist.\n" "$local_ssh_config"
        error_exit
    else
        . "$local_ssh_config"      # Load local ssh configs file.
        option=""
        case "$1" in
            # "network")
            #     type="router bgp 29"
            #     option="no network 29.0.0.0/8" ;;
            "ospf")
                type="router bgp 29"
                option="no redistribute ospf" ;;
            # "route")
            #     type=""
            #     option="no ip route 29.0.0.0/8 blackhole" ;;
            # "bgp")
            #     type=""
            #     option="no router bgp 29" ;;
            *)
                printf "\nERROR: Configuration type doesn't exist.\n"
                error_exit
                ;;
        esac
        SSH_ENV="export SSH_AUTH_SOCK=$SSH_AUTH_SOCK;"
        # Start tmux session if it doesn't exist
        if ! tmux has-session -t lab 2>/dev/null; then
            tmux new-session -d -s lab "$SSH_ENV exec ssh $SSH_ALIAS"
            sleep 1
        fi

        for location in LOND HAML PARI TRGA NEWY BOST ATLA ZURI; do
            tmux new-window -t lab -n "$location" "$SSH_ENV exec ssh $SSH_ALIAS"
            clear "$location" "$option"
        done

        # Kill the session after all updates
        tmux kill-session -t lab
        main_exit
    fi
}

clear() {
    router=$1
    command=$2
    printf "\nClearing %s config for %s...\n" "$config" "$router"
    printf "%s > './goto.sh %s'\n" "$router" "$router"
    tmux send-keys -t lab:"$router" "./goto.sh $router" C-m
    sleep 1
    printf "%s > 'configure terminal'\n" "$router" "$router"
    tmux send-keys -t lab:"$router" "configure terminal" C-m
    if [ -n "$type" ]; then
         printf "%s > '%s'\n" "$router" "$type"
        tmux send-keys -t lab:"$router" "$type" C-m
    fi
    printf "%s > '%s'\n" "$router" "$command"
    tmux send-keys -t lab:"$router" "$command" C-m
    tmux send-keys -t lab:"$router" "no redistribute ${option}" C-m
    sleep 0.5
    printf "%s > 'exit'\n" "$router"
    tmux send-keys -t lab:"$router" "exit" C-m
    sleep 1
}


# Function:     main_exit
# Brief:        Kills tmux session and exits successfully.
main_exit() {
    tmux kill-session -t lab 2>/dev/null
    printf "\nConfiguration updated successfully on all routers.\n"
    exit 0
}


# Function:     main_exit
# Brief:        Unsets all variables and exits with error.
error_exit() {
    tmux kill-session -t lab 2>/dev/null
    printf "\nERROR: Exiting with error code $1.\n"
    exit 1
}


# Call main to execute the script.
main "$@"
