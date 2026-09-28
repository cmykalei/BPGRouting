#!/bin/bash

port=$1
cd ../configs
rm -rf configs_*
ssh -t ke131@linux-labs.cms.waikato.ac.nz "scp -P $port root@mini.cms.waikato.ac.nz:'configs_*.tar.gz' configs.tar.gz"
scp ke131@linux-labs.cms.waikato.ac.nz:configs.tar.gz configs.tar.gz
scp ke131@linux-labs.cms.waikato.ac.nz:configs.tar.gz configs.tar.gz
tar -xvf configs.tar.gz
rm configs.tar.gz
