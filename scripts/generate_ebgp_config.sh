#!/bin/sh
# Path:         COMPX304-A2/scripts/generate_ebgp_config.sh
# Brief:        Generates commands for configuring external link interfaces.
# Usage:        `$ generate_ebgp_config.sh`

generated_dir="generated"
file_suffix="ebgp_config"
my_asn="29"


main() {
    if [ ! -d "$generated_dir" ]; then
        printf "ERROR: Generated directory %s does not exist.\n" "$generated_dir"
        main_exit 1
    else
        for location in HAML PARI BOST ATLA ZURI; do
            generate "$location"
        done
    fi
}


generate() {
    location=$1
    case "$location" in
        "BOST")
            neighbor="ZURI"
            neighbor_asn="27"
            neighbor_ip="179.27.29.1" ;;
        "HAML")
            neighbor="ZURI"
            neighbor_asn="28"
            neighbor_ip="179.28.29.1" ;;
        "PARI")
            neighbor="PARI"
            neighbor_asn="30"
            neighbor_ip="179.29.30.2" ;;
        "ZURI")
            neighbor="ZURI"
            neighbor_asn="31"
            neighbor_ip="179.29.31.2" ;;
        "ATLA")
            neighbor="ZURI"
            neighbor_asn="32"
            neighbor_ip="179.29.32.2" ;;
        *)
            printf "\nNo external connection on router %s\n" "$location"
            main_exit 1
            ;;
    esac

    generated_config=${generated_dir}/${location}_${file_suffix}

    printf "configure terminal\n" > $generated_config
    printf "router bgp %s\n" "$my_asn" >> $generated_config
    printf "neighbor %s remote-as %s\n" "$neighbor_ip" "$neighbor_asn" >> $generated_config
}
 

main_exit() {
    unset -f main
    unset generated_dir
    unset generated_config
    unset file_suffix
    exit $1
}

main
