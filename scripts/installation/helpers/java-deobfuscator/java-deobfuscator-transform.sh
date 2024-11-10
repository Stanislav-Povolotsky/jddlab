#!/bin/bash
set -e
SCRIPT_FILE="$(readlink --canonicalize-existing "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_FILE")"
input_jar_file="$1"
output_jar_file="$2"
output_jar_file_default="${input_jar_file}.transformed.jar"
output_jar_file=${output_jar_file:-$output_jar_file_default}
user_config_file="$3"
user_config_file_default="$SCRIPT_DIR/config-transform.yml"
user_config_file=${user_config_file:-$user_config_file_default}

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <input-jar-file> <output-jar-file> <config-yml-file>"
    exit 1
fi

if [[ ! -f "$input_jar_file" ]]; then
    echo "'$input_jar_file': input file not found"
    exit 1
fi

if [[ ! -f "$user_config_file" ]]; then
    echo "'$user_config_file': config file not found"
    exit 1
fi

echo "Input file: $input_jar_file"
echo "Output file: $output_jar_file"
echo "Config file: $user_config_file"

config_file=$(mktemp --suffix=".config.yml")
echo "input: $input_jar_file"      >$config_file
echo "output: $output_jar_file"   >>$config_file
echo "path:"                      >>$config_file
echo "  - `echo /usr/local/android-sdk-linux/platforms/android-*/android.jar`" >>$config_file
cat $user_config_file             >>$config_file

command_result=0
java-deobfuscator --config $config_file || command_result=$?
rm -f $config_file
exit $command_result
