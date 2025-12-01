#!/bin/bash

# Initialize conda for bash shell
eval "$(conda shell.bash hook)"

# Download file if it doesn't already exist
download_if_missing() {
  local url=$1
  local filename=$2
  if [ ! -f "$filename" ]; then
    echo "Downloading $filename..."
    gdown "$url" -O "$filename" || echo "Warning: Failed to download $filename, continuing..."
  else
    echo "$filename already exists, skipping download."
  fi
}

# Displays information on how to use script
helpFunction()
{
  echo "Usage: $0 [-d small|all]"
  echo -e "\t-d small|all - Specify whether to download entire dataset (all) or just 1000 (small)"
  exit 1 # Exit script after printing help
}

# Get values of command line flags
while getopts d: flag
do
  case "${flag}" in
    d) data=${OPTARG};;
  esac
done

if [ -z "$data" ]; then
  echo "[ERROR]: Missing -d flag"
  helpFunction
fi

# Activate webshop conda environment
conda activate webshop

# Install Python Dependencies
python -m pip install -r requirements.txt;

# Install faiss-cpu via pip (conda version conflicts with Python)
python -m pip install faiss-cpu;

# Install openjdk via apt if not already installed
if ! command -v java &> /dev/null; then
    echo "Java not found, please install openjdk-11-jdk manually with: sudo apt install openjdk-11-jdk"
fi

# Download dataset into `data` folder via `gdown` command
mkdir -p data;
cd data;
if [ "$data" == "small" ]; then
  download_if_missing "https://drive.google.com/uc?id=1EgHdxQ_YxqIQlvvq5iKlCrkEKR6-j0Ib" "items_shuffle_1000.json"
  download_if_missing "https://drive.google.com/uc?id=1IduG0xl544V_A_jv3tHXC0kyFi7PnyBu" "items_ins_v2_1000.json"
elif [ "$data" == "all" ]; then
  download_if_missing "https://drive.google.com/uc?id=1A2whVgOO0euk5O13n2iYDM0bQRkkRduB" "items_shuffle.json"
  download_if_missing "https://drive.google.com/uc?id=1s2j6NgHljiZzQNL3veZaAiyW_qDEgBNi" "items_ins_v2.json"
else
  echo "[ERROR]: argument for `-d` flag not recognized"
  helpFunction
fi
download_if_missing "https://drive.google.com/uc?id=14Kb5SPBk_jfdLZ_CDBNitW98QLDlKR5O" "items_human_ins.json"
cd ..

# Download spaCy large NLP model
python -m spacy download en_core_web_lg

# Build search engine index
cd search_engine
mkdir -p resources resources_100 resources_1k resources_100k
python convert_product_file_format.py # convert items.json => required doc format
mkdir -p indexes
./run_indexing.sh
cd ..

# Create logging folder + samples of log data
get_human_trajs () {
  PYCMD=$(cat <<EOF
import gdown
url="https://drive.google.com/drive/u/1/folders/16H7LZe2otq4qGnKw_Ic1dkt-o3U9Zsto"
gdown.download_folder(url, quiet=True, remaining_ok=True)
EOF
  )
  python -c "$PYCMD"
}
mkdir -p user_session_logs/
cd user_session_logs/
echo "Downloading 50 example human trajectories..."
get_human_trajs
echo "Downloading example trajectories complete"
cd ..