#!/bin/bash

# TODO: hyper parameters
# Experiment parameters
days=2
topk=10

# Platform
PCI_Addr="0000:03:00.0"
NVMe_Dev="Nvme1n1"

# Path
## Script / Binary
project_root="/home/pc-sung/exp/SPFresh"
exp_root="${project_root}/Script_AE/Figure6"

## Data
data_type=uint8
data_path="${project_root}/dataset"
bin_path="${project_root}/Release"
base_vec="${data_path}/sift_data/sift100m_base.u8bin"
query_vec="${data_path}/sift_data/query.public.10K.u8bin"
full_vec="${data_path}/sift_data/sift200m_base.u8bin"
update_trace="${data_path}/sift_data/sift100m_update_trace"
tmp_path="${data_path}/tmp"
result_path="${exp_root}/result_overall_spfresh"
index_path="${project_root}/dataset/spann_index"
script_path="${project_root}/Script_AE"

## Data parameters
dimension=$(bash "${script_path}/vector_dim.sh" ${base_vec})
base_size=$(bash "${script_path}/vector_size.sh" ${base_vec})
query_size=$(bash "${script_path}/vector_size.sh" ${query_vec})
full_size=$(bash "${script_path}/vector_size.sh" ${full_vec})

# Setup ini file
mkdir -p "${result_path}"
cp "${project_root}/Script_AE/iniFile/store_spacev100m/indexloader_spfresh.ini" "${index_path}/indexloader.ini"
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
convert_datatype() {
  datatype=$1
  if [[ ${datatype} == "uint8" ]]; then
    echo "UInt8"
  elif [[ ${datatype} == "int8" ]]; then
    echo "Int8"
  else
    echo "Unsupported data type"
  fi 
}
config=(
  "3 ValueType=$(convert_datatype ${data_type})"
  "6 ValueType=$(convert_datatype ${data_type})"
  "9 Dim=${dimension}"
  "10 VectorPath=${base_vec}"
  "12 VectorSize=${base_size}"
  "14 QueryPath=${query_vec}"
  "16 QuerySize=${query_size}"
  "20 WarmupSize=${query_size}"
  "27 IndexDirectory=${index_path}"
  "36 NumberOfThreads=$(nproc)"
  "79 NumberOfThreads=$(nproc)"
  "96 NumberOfThreads=$(($(nproc) / 2))"
  "105 ResultNum=${topk}"
  "100 TmpDir=${tmp_path}"
  "110 Days=${days}"
  "116 FullVectorPath=${full_vec}"
  "124 UpdateFilePrefix=${update_trace}"
  "125 SearchResult=${result_path}"
  "129 EndVectorNum=${full_size}"
)
for item in "${config[@]}"; do
	IFS=" " read -r line text <<<"$item"
	replace "${line}" "${text}" "${index_path}/indexloader.ini"
done

PCI_ALLOWED="${PCI_Addr}" SPFRESH_SPDK_USE_SSD_IMPL=1 SPFRESH_SPDK_CONF="${project_root}/Script_AE/bdev.json" SPFRESH_SPDK_BDEV="${NVMe_Dev}" sudo -E "${bin_path}/spfresh" \
  "${index_path}" \
  2>&1 |tee "${result_path}/log_overall_performance_spacev_spfresh.log"

# python process_spfresh.py \
#   log_overall_performance_spacev_spfresh.log \
#   overall_performance_spacev_spfresh_result.csv
#
# mkdir spfresh_result
# mv /home/sosp/result_overall_spacev_spfresh* spfresh_result
#
# resultnamePrefix=/spfresh_result/
# i=-1
# for FILE in `ls -v1 ./spfresh_result/`
# do
#     if [ $i -eq -1 ];
#     then
#         /home/sosp/SPFresh/Release/usefultool -CallRecall true \
#           -resultNum 10 \
#           -queryPath /home/sosp/data/spacev_data/query.i8bin \
#           -searchResult $PWD$resultnamePrefix$FILE \
#           -truthType DEFAULT \
#           -truthPath /home/sosp/data/spacev_data/msspacev-100M \
#           -VectorPath /home/sosp/data/spacev_data/spacev200m_base.i8bin \
#           --vectortype int8 \
#           -d 100 \
#           -f DEFAULT \
#           |tee log_spfresh_$i
#     else
#         /home/sosp/SPFresh/Release/usefultool -CallRecall true \
#           -resultNum 10 \
#           -queryPath /home/sosp/data/spacev_data/query.i8bin \
#           -searchResult $PWD$resultnamePrefix$FILE \
#           -truthType DEFAULT \
#           -truthPath /home/sosp/data/spacev_data/spacev100m_update_truth_after$i \
#           -VectorPath /home/sosp/data/spacev_data/spacev200m_base.i8bin \
#           --vectortype int8 \
#           -d 100 \
#           -f DEFAULT \
#           |tee log_spfresh_$i
#     fi
#     let "i=i+1"
# done
