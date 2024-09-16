import numpy as np
import argparse
import struct
import multiprocessing
from multiprocessing import Pool

def read_vectors(args_tuple):
    src, start_pos, num_vecs, dim = args_tuple
    vecs = b""
    with open(src, "rb") as f:
        f.seek(start_pos)
        for _ in range(num_vecs):
            vec = f.read(4 * dim)
            vecs += vec
    return vecs

def process_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--src", help="The input file (.fvecs)")
    parser.add_argument("--dst", help="The output file (.fvecs)")
    parser.add_argument("--topk", type=int, help="The number of elements to pick up")
    return parser.parse_args()

def main():
    args = process_args()

    # Determine the number of available CPU cores
    num_cores = multiprocessing.cpu_count() - 2

    # Read the dimensions of the vectors
    with open(args.src, "rb") as f:
        row_bin = f.read(4)
        assert row_bin != b''
        row, = struct.unpack('i', row_bin)

        dim_bin = f.read(4)
        assert dim_bin != b''
        dim, = struct.unpack('i', dim_bin)

    # Calculate the number of vectors to be processed by each core
    vectors_per_core = args.topk // num_cores
    extra = args.topk % num_cores

    args_list = []
    current_pos = 8  # Starting position after reading rows and dimensions
    for i in range(num_cores):
        if i < extra:
            num_vecs = vectors_per_core + 1
        else:
            num_vecs = vectors_per_core
        if num_vecs > 0:
            args_list.append((args.src, current_pos, num_vecs, dim))
            current_pos += num_vecs * dim

    # Use multiprocessing Pool to read vectors in parallel
    with Pool(processes=num_cores) as pool:
        results = pool.map(read_vectors, args_list)

    # Write the output
    with open(args.dst, "wb") as f:
        f.write(struct.pack('i', args.topk))
        f.write(dim_bin)
        for result in results:
            f.write(result)

if __name__ == "__main__":
    main()

