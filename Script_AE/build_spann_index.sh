#!/bin/bash

# Dataset related parameters, change if necessary
dataset="sift"
datatype="uint8"
dimension=128
base_size=100000000
query_size=10000

current_path=$(pwd)
# Path to the files, change if necessary
base_file="${current_path}/dataset/sift_data/${dataset}100m_base.u8bin"
query_file="${current_path}/dataset/sift_data/query.public.10K.u8bin"
binary_path="${current_path}/../Release"
trace_and_truth_path="${current_path}/dataset/sift_data"
ini_file="${current_path}/iniFile/build_spann.ini"
index_path="${current_path}/dataset/spann_index"
tmp_path="${current_path}/dataset/tmp"

if [[ ${datatype} == "uint8" ]]; then
	value_type="UInt8"
elif [[ ${datatype} == "int8" ]]; then
	value_type="Int8"
else
	echo "Unsupported data type"
	exit
fi

replace() {
	local line=$1
	local text=$2
	local file=$3

	if [ ! -f "$file" ]; then
		echo "Error: File does not exist."
		return 1
	fi

	sed -i "${line}c ${text}" "${file}"
}

config=(
	"2 ValueType=${value_type}"
	"5 Dim=${dimension}"
	"6 VectorPath=${base_file}"
	"8 VectorSize=${base_size}"
	"10 QueryPath=${query_file}"
	"12 QuerySize=${query_size}"
	"16 WarmupSize=${query_size}"
	"18 TruthPath=${trace_and_truth_path}/"
	"23 IndexDirectory=${index_path}"
	"56 TmpDir=${tmp_path}"
)

for item in "${config[@]}"; do
	IFS=" " read -r line text <<<"$item"
	replace "${line}" "${text}" "${ini_file}"
done

time "${binary_path}/ssdserving" "${ini_file}" | tee build_index.log
