import argparse
import mmap
import struct
import sys

def main():
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Process and truncate a binary vector file.")
    parser.add_argument('--src', required=True, type=str, help='The path to the binary source file.')
    parser.add_argument('--dst', required=True, type=str, help='The destination path for the output file.')
    parser.add_argument('--topk', required=True, type=int, help='The number of top vectors to keep.')
    args = parser.parse_args()

    # Open source file and map it in memory
    with open(args.src, 'r+b') as src_file:
        src_map = mmap.mmap(src_file.fileno(), 0)

        # Read and unpack the header
        num, dim = struct.unpack('II', src_map[:8])
        
        # Modify num based on the topk argument
        num = min(num, args.topk)

        # Prepare the header with the new num value
        header = struct.pack('II', num, dim)

        # Calculate the amount of data to copy based on num and dim
        data_length = num * dim

        # Read the required part of the vectors
        vectors_data = src_map[8:8 + data_length]

        # Close the memory map and the source file
        src_map.close()

    # Write the modified content to the destination file
    with open(args.dst, 'wb') as dst_file:
        dst_file.write(header)
        dst_file.write(vectors_data)

if __name__ == "__main__":
    main()

