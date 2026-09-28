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
        main_exit 1
    elif [ ! -f "$local_ssh_config" ]; then
        printf "ERROR: SSH configuration file %s does not exist.\n" "$local_ssh_config"
        main_exit 1
    else
        . $local_ssh_config
        file_suffix=""
        option=$1
        case "$option" in
            "policy")
                file_suffix="policy" ;;
            "route")
                file_suffix="route_map" ;;
            "ospf") 
                file_suffix="ospf_config" ;;
            "ibgp")
                file_suffix="ibgp_config" ;;
            "ebgp") 
                file_suffix="ebgp_config" ;;
            "prefix") 
                file_suffix="prefix_config" ;;
            "redistribute") 
                file_suffix="redistribute_config" ;;
            "blackhole") 
                file_suffix="ip_route_config" ;;
            # "ospf_config") file_suffix="ospf_config" ;;
            # "ixp_config") file_suffix="ixp_config" ;;
            # "ext_ip_address") file_suffix="ext_ip_address" ;;
            *)
                printf "\nERROR: Configuration type doesn't exist.\n"
                main_exit 1
                ;;
        esac
        # Start the process to ssh and update specified configs.
        . "$local_ssh_config"      # Load local ssh configs file.
        update                     # Update configs for all routers.
        update_exit                # Exit successfully.
    fi
}

update_line() {
    SSH_ENV="export SSH_AUTH_SOCK=$SSH_AUTH_SOCK;"
    # Start tmux session if it doesn't exist
    if ! tmux has-session -t lab 2>/dev/null; then
        tmux new-session -d -s lab "$SSH_ENV exec ssh $SSH_ALIAS"
        sleep 1
    fi

    line=$1
    for location in LOND HAML PARI TRGA NEWY BOST ATLA ZURI; do
        tmux new-window -t lab -n "$location" "$SSH_ENV exec ssh $SSH_ALIAS"
        sleep 1
        printf "%s > './goto.sh %s'\n" "$location" "$location"
        tmux send-keys -t lab:"$location" "./goto.sh $location" C-m
        sleep 0.5
        printf "%s > '%s'\n" "$location" "configure terminal"
        tmux send-keys -t lab:"$location" "configure terminal" C-m
        sleep 0.5
        printf "%s > '%s'\n" "$location" "$line"
        tmux send-keys -t lab:"$location" "$line" C-m
        sleep 0.5
        printf "%s > '%s'\n" "$location" "exit"
        tmux send-keys -t lab:"$location" "exit" C-m
    done

    # Exit after applying configs
    printf "%s > 'exit'\n" "$location"
    tmux send-keys -t lab:"$location" "exit" C-m
    sleep 1
}

update() {
    SSH_ENV="export SSH_AUTH_SOCK=$SSH_AUTH_SOCK;"
    # Start tmux session if it doesn't exist
    if ! tmux has-session -t lab 2>/dev/null; then
        tmux new-session -d -s lab "$SSH_ENV exec ssh $SSH_ALIAS"
        sleep 1
    fi

    for location in LOND HAML PARI TRGA NEWY BOST ATLA ZURI; do
        # Get config file and apply commands
        config_file="${generated_dir}/${location}_${file_suffix}"
        if [ -f "$config_file" ]; then
            # Create a new tmux window for each location
            tmux new-window -t lab -n "$location" "$SSH_ENV exec ssh $SSH_ALIAS"
            sleep 1

            # Navigate to the router location
            printf "\nUpdating '%s' config for %s...\n" "$file_suffix" "$location"
            printf "%s > './goto.sh %s'\n" "$location" "$location"
            tmux send-keys -t lab:"$location" "./goto.sh $location" C-m
            sleep 2

            # Send each line to the pane to execute
            while IFS= read -r line; do
                printf "%s > '%s'\n" "$location" "$line"
                tmux send-keys -t lab:"$location" "$line" C-m
                tmux send-keys -t lab:"$location" "" C-m
                sleep 0.5
            done < "$config_file"
        else
            printf "\nNo '%s' configuration for %s\n" "$file_suffix" "$location"
        fi

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
