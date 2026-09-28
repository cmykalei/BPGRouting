#!/bin/sh
# Path:         COMPX304-A1/scripts/reset.sh
# Brief:        Quick reset configuration on a given router with config.
# Usage:        `$ reset.sh <file_target> <file_suffix>`

local_ssh_config="local_ssh_config"
generated_dir="generated"

# Function:     main
# Brief:        Main function to start the update process.
main() {
    unset router
    if [ ! -d "$generated_dir" ] ; then
        error_exit "0" "Directory 'generated_dir' not found."
    elif [ ! -f "$local_ssh_config" ]; then
        error_exit "0" "File 'local_ssh_config' not found."
    else
        . "$local_ssh_config"      # Load local ssh configs file.
        file_suffix=""
        case "$1" in
        "ospf")
            file_suffix="ospf_config" ;;
        "ibgp")
            file_suffix="ibgp_config" ;;
        "ebgp")
            file_suffix="ebgp_config" ;;
        "route")
            file_suffix="route_map" ;;
            *)
                error_exit "33" "Usage: ./reset.sh <file_target> <file_suffix> (invalid file_suffix)."
                ;;
        esac
        SSH_ENV="export SSH_AUTH_SOCK=$SSH_AUTH_SOCK;"
        for router in LOND HAML PARI TRGA NEWY BOST ATLA ZURI; do
            config_file="${generated_dir}/${router}_${file_suffix}"
            if [ ! -f "$config_file" ]; then
                printf "No configuration for %s\n" "$config_file"
             else
                # Start tmux session if it doesn't exist
                if ! tmux has-session -t lab 2>/dev/null; then
                    tmux new-session -d -s lab "$SSH_ENV exec ssh $SSH_ALIAS"
                    sleep 1
                fi
                tmux new-window -t lab -n "$router" "$SSH_ENV exec ssh $SSH_ALIAS"
                printf "\nClearing %s's %s config\n" "$router" "$file_suffix"
                printf "%s > './goto.sh %s'\n" "$router" "$router"
                tmux send-keys -t lab:"$router" "./goto.sh $router" C-m
                sleep 1
                tmux send-keys -t lab:"$router" "configure terminal" C-m
                while IFS= read -r line; do
                    process_line "$line" "$router"
                    sleep 0.5
                done < $config_file
            fi
        done
        main_exit
    fi
}


process_line() {
    line="$1"
    router="$2"
    case "$line" in
    "configure terminal"|"router bgp 29"|"router ospf"|"exit")
        printf "%s > %s\n" "$router" "$line"
        tmux send-keys -t lab:"$router" "$line" C-m
        sleep 1 ;;
    "ip address"*|"network"*|"neighbor"*|"set"*|"route-map"*|"redistribute"*|"ip route"*|"bgp community"*|"bgp router-id"*|"ospf router-id"*)
        tmux send-keys -t lab:"$router" "no $line" C-m
        printf "%s >> %s\n" "$router" "no $line"
        sleep 1 ;;
    *)
        : ;;
    esac
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
    line="$1"
    message="$2"

    printf "Error (line %s) : %s\n" "$line" "$message"
    exit 1
}


# Call main to execute the script.
main "$@"
