#!/bin/bash

# Dataset related parameters, change if necessary
dataset="sift"
datatype="uint8"
dimension=128
update_size=1000000
base_size=100000000
reserve_size=100000000
query_size=10000
result_size=100

batch=99

# Path to the files, change if necessary
source_file="./dataset/sift_data/${dataset}200m_base.u8bin"
query_file="./dataset/sift_data/query.public.10K.u8bin"
ini_file="./iniFile/genTruth.ini"
binary_path="../Release"
trace_and_truth_path="./dataset/sift_data"

# File names, do not change
data_set_name="${trace_and_truth_path}/${dataset}100m_update_set"
truth_file_name="${trace_and_truth_path}/${dataset}100m_update_truth"
reserve_set_name="${trace_and_truth_path}/${dataset}100m_update_reserve"
current_set_name="${trace_and_truth_path}/${dataset}100m_update_current"
trace_file_name="${trace_and_truth_path}/${dataset}100m_update_trace"

if [[ ${datatype} == "uint8" ]]; then
	sed -i "2c ValueType=UInt8" ${ini_file}
elif [[ ${datatype} == "int8" ]]; then
	sed -i "2c VlueTyp=Int8" ${ini_file}
else
	echo "Unsupported data type"
	exit
fi

# Setup ini file
sed -i "5c Dim=${dimension}" ${ini_file}
sed -i "8c VectorSize=$((update_size * 2))" ${ini_file} # There are insertion and deletion for each update
sed -i "10c QueryPath=${query_file}" ${ini_file}
sed -i "12c QuerySize=${query_size}" ${ini_file}
sed -i "23c ResultNum=${result_size}" ${ini_file}

for i in $(seq 0 ${batch}); do
	# Generate the update trace
	${binary_path}/usefultool \
		-GenTrace true \
		--vectortype ${datatype} \
		--VectorPath ${source_file} \
		--filetype DEFAULT \
		--UpdateSize ${update_size} \
		--BaseNum ${base_size} \
		--ReserveNum ${reserve_size} \
		--CurrentListFileName ${current_set_name} \
		--ReserveListFileName ${reserve_set_name} \
		--TraceFileName ${trace_file_name} \
		-NewDataSetFileName ${data_set_name} \
		-d ${dimension} \
		--Batch "${i}" \
		-f DEFAULT

	# Setup ini file for truth calculation
	sed -i "6c VectorPath=${data_set_name}${i}" ${ini_file}
	sed -i "18c TruthPath=${truth_file_name}${i}" ${ini_file}

	# Calculate the truth
	${binary_path}/ssdserving ${ini_file}

	${binary_path}/usefultool \
		-ConvertTruth true \
		--vectortype ${datatype} \
		--VectorPath ${source_file} \
		--filetype DEFAULT \
		--UpdateSzie ${update_size} \
		--BaseNum ${base_size} \
		--ReserveNum ${base_size} \
		--CurrentListFileName ${current_set_name} \
		--ReserveListFileName ${reserve_set_name} \
		--TraceFileName ${trace_file_name} \
		-NewDataSetFileName ${data_set_name} \
		-d ${dimension} \
		--Batch "${i}" \
		-f DEFAULT \
		--truthPath ${truth_file_name} \
		--truthType DEFAULT \
		--querySize ${query_size} \
		--resultNum ${result_size}

	# Remove the temporary files
	if [[ $i -ne 0 ]]; then
		prev_reserve_set_name=${reserve_set_name}$((i - 1))
		prev_current_set_name=${current_set_name}$((i - 1))
		prev_data_set_name=${data_set_name}$((i - 1))
		echo "${prev_data_set_name}"
		echo "${prev_reserve_set_name}"
		echo "${prev_current_set_name}"
		rm "${prev_data_set_name}"
		rm "${prev_reserve_set_name}"
		rm "${prev_current_set_name}"
	fi
done

prev_reserve_set_name=${reserve_set_name}${batch}
prev_current_set_name=${current_set_name}${batch}
prev_data_set_name=${data_set_name}${batch}
rm "${prev_data_set_name}"
rm "${prev_reserve_set_name}"
rm "${prev_current_set_name}"
