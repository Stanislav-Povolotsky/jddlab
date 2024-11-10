#!/bin/bash
set -e
SCRIPT_FILE="$(readlink --canonicalize-existing "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_FILE")"
input_jar_file="$1"

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <input-jar-file>"
    exit 1
fi

if [[ ! -f "$input_jar_file" ]]; then
    echo "$input_jar_file: file not found"
    exit 1
fi

echo "Input file: $input_jar_file"

config_file=$(mktemp --suffix=".config.yml")
echo "input: $input_jar_file" >$config_file
cat $SCRIPT_DIR/config-detect.yml >>$config_file

command_result=0
java-deobfuscator --config $config_file || command_result=$?
rm -f $config_file
exit $command_result
