#!/bin/bash
set -e

SCRIPT_FILE="$(readlink --canonicalize-existing "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_FILE")"
PROJECT_DIR=`mktemp -d`

input_file="$1"
output_file="$2"
if [ -z "${output_file}" ]; then
    output_file="${input_file}.c"
fi

if [ -z "${input_file}" ]; then
    echo "Command-line tool to decompile binary file with ghidra"
    echo "Format: $0 <input-binary-file> [<output-file-for-c-code>]"
    echo "Example: $0 test.so test.code.c"
    exit 1
fi

echo "Input file: $input_file"
echo "Output file: $output_file"

ghidra $PROJECT_DIR DecompilationProject -import $input_file -scriptPath $SCRIPT_DIR/custom-scripts -postScript CustomDecompileScript.java $output_file
rm -rf $PROJECT_DIR