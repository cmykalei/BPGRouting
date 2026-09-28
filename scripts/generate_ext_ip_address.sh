#!/bin/sh
# Path:         COMPX304-A2/scripts/generate_ext_ip_address.sh
# Brief:        Generates commands for configuring external link interfaces.
# Usage:        `$ generate_ext_ip_address.sh`

generated_dir="generated"
file_suffix="ext_ip_address"
my_asn="29"


main() {
    if [ ! -d "$generated_dir" ]; then
        printf "ERROR: Generated directory %s does not exist.\n" "$generated_dir"
        main_exit 1
    else
        generate_customer_to_provider "BOST" "ZURI" "27"
        generate_customer_to_provider "HAML" "ZURI" "28"
        generate_provider_to_customer "ATLA" "ZURI" "32"
        generate_provider_to_customer "ZURI" "ZURI" "31"
        generate_peer_to_peer "PARI" "PARI" "30"
        generate_peer_to_ixp "NEWY" "122"
    fi
}


generate_customer_to_provider() {
    customer_router=$1
    provider_router=$2
    provider_asn=$3

    ip_address="179.$provider_asn.$my_asn.2/30"
    ext_link="ext_${provider_asn}_${provider_router}"
    generated_config="${generated_dir}/${customer_router}_${file_suffix}"

    printf "configure terminal\n" > $generated_config
    printf "interface %s\n" "$ext_link" >> $generated_config
    printf "ip address %s\n" "$ip_address" >> $generated_config
}


generate_provider_to_customer() {
    provider_router=$1
    customer_router=$2
    customer_asn=$3

    ip_address="179.$my_asn.$customer_asn.1/30"
    ext_link="ext_${customer_asn}_${customer_router}"
    generated_config="${generated_dir}/${provider_router}_${file_suffix}"

    printf "configure terminal\n" > $generated_config
    printf "interface %s\n" "$ext_link" >> $generated_config
    printf "ip address %s\n" "$ip_address" >> $generated_config
}


generate_peer_to_peer() {
    local_router=$1
    peer_router=$2
    peer_asn=$3

    ip_address="179.$my_asn.$peer_asn.1/30"
    ext_link="ext_${peer_asn}_${peer_router}"
    generated_config="${generated_dir}/${local_router}_${file_suffix}"

    printf "configure terminal\n" > $generated_config
    printf "interface %s\n" "$ext_link" >> $generated_config
    printf "ip address %s\n" "$ip_address" >> $generated_config
}


generate_peer_to_ixp() {
    ixp_router=$1
    ixp_asn=$2

    ip_address="180.${ixp_asn}.0.${my_asn}/24"
    ext_link="ixp_${ixp_asn}"
    generated_config="${generated_dir}/${ixp_router}_${file_suffix}"

    printf "configure terminal\n" > $generated_config
    printf "interface %s\n" "$ext_link" >> $generated_config
    printf "ip address %s\n" "$ip_address" >> $generated_config
}


main_exit() {
    unset -f main
    unset generated_dir
    unset generated_config
    unset file_suffix
    exit $1
}

main
