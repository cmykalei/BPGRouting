#!/bin/sh
# Path:         COMPX304-A2/scripts/generate_ospf_config.sh
# Brief:        Generates commands for configuring a router's OSPF network.
# Usage:        `$ generate-offset [1-8]`
#               offset {'1' '2' '3' '4' '5' '6' '7' '8'}

my_asn="29"
generated_dir="generated"
file_suffix="ospf_config"


# Function:     main
# Brief:        Starts the generation by calling script functions.
# Details:      Required variables should be set in config/local_ssh_config
main() {
    if [ ! -d "$generated_dir" ]; then
        printf "ERROR: Directory %s does not exist.\n" "$generated_dir"
        main_exit 1
    else
        i=1
        while [ "$i" -le 8 ]; do
            generate "$i"
            i=$((i+1))
        done

        main_exit 0
    fi
}

# Function:     generate
# Brief:        Sets router variable name based on offset.
#               Then sets that router's host subnetwork address, then finally
#               the router's available port subnetwork addresses.
#               Like 'my_asn.0.[1-13].0/subnet_router' based on router[1-8]
# Params:       $1=offset[1-8]
generate() {
    offset=$1
    #host_subnetwork="$my_asn.10${offset}.0.2/$SUBNET_Mmy_asnK_HOST" # Different mask!
    case "$offset" in
        1) router="LOND"
            port_HAML="$my_asn.0.2.0/30"
            port_PARI="$my_asn.0.4.0/30"
            port_BOST="$my_asn.0.7.0/30"
            port_NEWY="$my_asn.0.8.0/30" ;;
        2) router="HAML"
            port_PARI="$my_asn.0.1.0/30"
            port_LOND="$my_asn.0.2.0/30" ;;
        3) router="PARI"
            port_HAML="$my_asn.0.1.0/30"
            port_TRGA="$my_asn.0.3.0/30"
            port_LOND="$my_asn.0.4.0/30"
            port_NEWY="$my_asn.0.5.0/30"
            port_ZURI="$my_asn.0.6.0/30" ;;
        4) router="TRGA"
            port_PARI="$my_asn.0.3.0/30"
            port_ZURI="$my_asn.0.9.0/30" ;;
        5) router="NEWY"
            port_PARI="$my_asn.0.5.0/30"
            port_LOND="$my_asn.0.8.0/30"
            port_BOST="$my_asn.0.10.0/30"
            port_ATLA="$my_asn.0.11.0/30"
            port_ZURI="$my_asn.0.12.0/30" ;;
        6) router="BOST"
            port_LOND="$my_asn.0.7.0/30"
            port_NEWY="$my_asn.0.10.0/30" ;;
        7) router="ATLA"
           port_NEWY="$my_asn.0.11.0/30"
           port_ZURI="$my_asn.0.13.0/30" ;;
        8) router="ZURI"
            port_PARI="$my_asn.0.6.0/30"
            port_TRGA="$my_asn.0.9.0/30"
            port_NEWY="$my_asn.0.12.0/30"
            port_ATLA="$my_asn.0.13.0/30" ;;
        *)
            printf "\nERROR: offset must be a number between 1 and 8.\n"
            main_exit 1
            ;;
    esac

    generated_config="$generated_dir/${router}_${file_suffix}"

    printf "configure terminal\n" > $generated_config
    printf "router ospf\n" >> $generated_config
    printf "ospf router-id %s.15%s.0.1\n" "$my_asn" "$offset" >> $generated_config

    for port in port_LOND port_HAML port_PARI port_TRGA port_NEWY port_BOST port_ATLA port_ZURI; do
        if [ -n "${!port}" ]; then
            printf "network %s area 0.0.0.0\n" ${!port} >> $generated_config
        fi
    done

    printf "redistribute connected\n" >> $generated_config

    unset port_LOND port_HAML port_PARI port_TRGA port_NEWY port_BOST port_ATLA port_ZURI
}


# Function:     main_exit
# Brief:        Unsets script variables used for generate_ospf.
main_exit() {
    unset -f main
    unset -f init
    unset -f generate
    exit "$1"
}


# Call main function to begin process.
main
