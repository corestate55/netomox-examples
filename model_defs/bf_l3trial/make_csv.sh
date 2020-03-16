#!/bin/bash

# venv path to activate pybatfish
. "${HOME}/batfish/bf-venv/bin/activate"

# data directory
CSV_BASEDIR='./csv'
CSV_DIRS=("${CSV_BASEDIR}/example" "${CSV_BASEDIR}/sample1b")
CSVS=(config_bgp_proc edges_bgp edges_layer3 ip_owners)
CSV_POST="_ep"

# cleaning
for csv_dir in "${CSV_DIRS[@]}"; do
  rm ${csv_dir}/*.csv
done

# generate tables as answer of each batfish-queries.
# it create CSV_DIRS/*.csv (see config in it).
python exec_l3queries.py

# complement peer-config (non-existent config file)
for csv_dir in "${CSV_DIRS[@]}"; do
  python ebgp_peer_data.py "${csv_dir}"
done

# overwrite data include complemented-peer configs
for csv_dir in "${CSV_DIRS[@]}"; do
  for csv in "${CSVS[@]}"; do
    cp "${csv_dir}/${csv}${CSV_POST}.csv" "${csv_dir}/${csv}.csv"
  done
done

# remove if needed (-c:clean)
if [[ "${1}" == "-c" ]]; then
  for csv_dir in "${CSV_DIRS[@]}"; do
    rm ${csv_dir}/*${CSV_POST}.csv
  done
fi

echo '# NEXT: run rake and generate topology jsons.'
