#!/bin/sh
# Path:         COMPX304-A2/scripts/generate_ibgp_config.sh
# Brief:        Generates commands for configuring external link interfaces.
# Usage:        `$ generate_bgp_config.sh`

generated_dir="generated"
file_suffix="ibgp_config"
my_asn="29"


main() {
    if [ ! -d "$generated_dir" ]; then
        printf "ERROR: Generated directory %s does not exist.\n" "$generated_dir"
        main_exit 1
    else
        i=1
        while [ "$i" -le 8 ]; do
            generate "$i"
            i=$((i+1))
        done
    fi
}


generate() {
    offset=$1
    case "$offset" in
        1) location="LOND" ;;
        2) location="HAML" ;;
        3) location="PARI" ;;
        4) location="TRGA" ;;
        5) location="NEWY" ;;
        6) location="BOST" ;;
        7) location="ATLA" ;;
        8) location="ZURI" ;;
        *)
            printf "\nERROR: OFFSET must be a number between 1 and 8.\n"
            main_exit 1
            ;;
    esac

    ip_address=${my_asn}.15${offset}.0.1
    generated_config=${generated_dir}/${location}_${file_suffix}

    printf "configure terminal\n" > $generated_config
    printf "router bgp %s\n" "$my_asn" >> $generated_config
    printf "bgp router-id %s\n" "$ip_address" >> $generated_config

    j=1
    while [ "$j" -le 8 ]; do
        if [ "$j" != "$offset" ]; then
            neighbor="${my_asn}.15${j}.0.1"
            printf "neighbor %s remote-as %s\n" "$neighbor" "$my_asn" >> $generated_config
            printf "neighbor %s update-source lo\n" "$neighbor" >> $generated_config
        fi
        j=$((j+1))
    done
}
 

main_exit() {
    unset -f main
    unset generated_dir
    unset generated_config
    unset file_suffix
    exit $1
}

main
