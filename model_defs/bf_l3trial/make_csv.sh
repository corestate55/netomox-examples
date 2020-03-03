#!/bin/bash

# venv path to activate pybatfish
VENV_PATH="${HOME}/batfish/bf-venv/bin"
. ${VENV_PATH}/activate

# data directory
CSV_DIR='./csv'
CSV_POST="_ep"

# cleaning
rm ${CSV_DIR}/*.csv

# generate tables as answer of each batfish-queries.
python bf_make_edge_info_tables.py

# complement peer-config (non-existent config file)
python ebgp_peer_data.py

# overwrite data include complemented-peer configs
csvs=(config_bgp_proc edges_bgp edges_layer3 ip_owners)
for csv in "${csvs[@]}"; do
  cp ${CSV_DIR}/${csv}${CSV_POST}.csv ${CSV_DIR}/${csv}.csv
done

# remove if needed (-c:clean)
if [[ "${1}" == "-c" ]]; then
  for csv in "${csvs[@]}"; do
    rm ${CSV_DIR}/${csv}${CSV_POST}.csv
  done
fi

echo '# run rake'
