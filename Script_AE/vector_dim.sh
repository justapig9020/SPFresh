#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

file="$1"

value=$(od -An -t u4 -N 4 -v --endian=little --skip-bytes=4 "$file")

value=$(echo "${value}" | tr -d ' ')

echo "${value}"

