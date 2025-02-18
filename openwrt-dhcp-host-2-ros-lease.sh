#!/bin/ash
#
# Copyright 2025 Timandes White
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Script to convert OpenWrt DHCP static host configurations to RouterOS commands
# Processes an input file with OpenWrt-style DHCP host definitions and generates corresponding RouterOS lease add commands
#
# Usage: uci show dhcp | grep '@host' | $0 
#

tags_2_option_set() {
    # 读取输入
    input="$1"

    # 如果输入为空字符串，直接输出空字符串
    if [ -z "$input" ]; then
        echo ""
    else
        # 去掉单引号和多余空格，并替换为逗号分隔
        #result=$(echo "$input" | sed "s/[' ]//g; s/'/,/g")
        result=$(echo "$input" | tr -d "'" | tr ' ' ',' | sed 's/^,//; s/,$//')

        # 如果结果为空，输出空字符串
        if [ -z "$result" ]; then
            echo ""
        else
            echo "$result"
        fi
    fi
}

get_option_param_name() {
    option_or_set=$1

    if [ "${option_or_set}" = "option" ]; then
        echo "dhcp-option"
    else
        if [ "${option_or_set}" = "set" ]; then
            echo "dhcp-option-set"
        else
            echo "Uknown option|set" >&2
            exit 1
        fi
    fi
}

# Initialize variables to store current host information
current_name=""
current_mac=""
current_ip=""
current_tag=""
tag_list=""
lease_time=0  # Default is infinite lease time (0)
tmp_file=`mktemp`
option_or_set=set

# Process each line of input configuration
while IFS= read -r line; do
    # Remove leading whitespace from the line
    line=$(echo "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

    # Check for =host
    if echo "$line" | grep -q '=host'; then
        # When all required fields are collected, generate RouterOS command
        if [ -n "$current_ip" ] && [ -n "$current_mac" ]; then
            extra_params=""
            if [ "${current_tag}" != "" ]; then
                param_name=`get_option_param_name ${option_or_set}`
                extra_params=" ${param_name}=\"$current_tag\""
            fi
            echo "/ip dhcp-server lease add address=$current_ip mac-address=$current_mac lease-time=$lease_time comment=\"$current_name\"${extra_params}" >> "$tmp_file"
            
            # Reset variables for next host entry
            current_name=""
            current_mac=""
            current_ip=""
            current_tag=""
            lease_time=0
        fi
    fi

    # Check for host name field
    if echo "$line" | grep -q '\.name='; then
        current_name=$(echo "$line" | cut -d "'" -f 2)
    fi

    # Check for MAC address field
    if echo "$line" | grep -q '\.mac='; then
        current_mac=$(echo "$line" | cut -d "'" -f 2)
    fi

    # Check for Tag field
    if echo "$line" | grep -q '\.tag='; then
        raw_tag_list=$(echo "$line" | cut -d "=" -f 2)
        current_tag=`tags_2_option_set "$raw_tag_list"`
        tag_list="${tag_list} ${raw_tag_list}"
    fi

    # Check for IP address field
    if echo "$line" | grep -q '\.ip='; then
        current_ip=$(echo "$line" | cut -d "'" -f 2)
    fi

    # Check for lease time field
    if echo "$line" | grep -q '\.leasetime='; then
        if echo "$line" | grep -q "'infinite'"; then
            lease_time=0
        fi
    fi

done

# When all required fields are collected, generate RouterOS command
if [ -n "$current_ip" ] && [ -n "$current_mac" ]; then
    extra_params=""
    if [ "${current_tag}" != "" ]; then
        param_name=`get_option_param_name ${option_or_set}`
        extra_params=" ${param_name}=\"$current_tag\""
    fi
    echo "/ip dhcp-server lease add address=$current_ip mac-address=$current_mac lease-time=$lease_time comment=\"$current_name\"${extra_params}" >> "$tmp_file"
    
    # Reset variables for next host entry
    current_name=""
    current_mac=""
    current_ip=""
    current_tag=""
    lease_time=0
fi

for o in `echo "${tag_list}"| sed 's/^[[:space:]]*//' | sed -e 's/ /\n/g' |sort |uniq`
do
    name=`echo $o | sed "s/'//g"`
    echo "/ip dhcp-server option sets add name=\"$name\" options=\"\""
done
cat "$tmp_file"
rm "$tmp_file"
