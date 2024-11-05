#!/usr/bin/env bash

# Copyright 2024 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

nb::require "core/log.sh core/arg.sh"
nb::command_check "base64"

# get original value name of referenced variable
__util::series::get_original_val_name__() {
    local TYPE_OPTION
    local TYPE="string"
    local INPUT_VAR_NAME=$1
    local ORIGINAL_VAR_NAME
    while true; do
        TYPE_OPTION=$( declare -p $INPUT_VAR_NAME ) || return 1
        TYPE_OPTION=${TYPE_OPTION#declare -}
        ORIGINAL_VAR_NAME=${TYPE_OPTION}
        TYPE_OPTION=${TYPE_OPTION%% *}
        if [[ ! $TYPE_OPTION =~ n ]]; then
            echo "$INPUT_VAR_NAME"
            return 0
        fi
        ORIGINAL_VAR_NAME=${ORIGINAL_VAR_NAME#* }
        ORIGINAL_VAR_NAME=${ORIGINAL_VAR_NAME#*=}
        ORIGINAL_VAR_NAME=${ORIGINAL_VAR_NAME#\"}
        ORIGINAL_VAR_NAME=${ORIGINAL_VAR_NAME%\"}
        INPUT_VAR_NAME=$ORIGINAL_VAR_NAME
    done
}

__util::series::get_val_type__() {
    local ORIGINAL_VAR_NAME
    local TYPE_OPTION
    local TYPE="string"

    ORIGINAL_VAR_NAME=$( __util::series::get_original_val_name__ $1 )
    TYPE_OPTION=$( declare -p $ORIGINAL_VAR_NAME ) || return 1
    #echo "$TYPE_OPTION" >&2
    TYPE_OPTION=${TYPE_OPTION#declare -}
    #echo "$TYPE_OPTION" >&2
    TYPE_OPTION=${TYPE_OPTION%% *}
    #echo "$TYPE_OPTION" >&2
    [[ $TYPE_OPTION =~ a ]] && TYPE="array"
    [[ $TYPE_OPTION =~ A ]] && TYPE="assoc_array"
    [[ $TYPE_OPTION =~ n ]] && TYPE="nameref"
    echo $TYPE
}

__util::series::deep_copy__() {
    local -n FROM=$1
    local -n TO=$2
    local FROM_TYPE
    local TO_TYPE

    FROM_TYPE=$( __util::series::get_val_type__ FROM )
    #echo "FROM_TYPE=$FROM_TYPE"
    TO_TYPE=$( __util::series::get_val_type__ TO )
    #echo "TO_TYPE=$TO_TYPE"
    if [ "$FROM_TYPE" != "$TO_TYPE" ]; then
        core::log::error_exit "invalid variable type (FROM=$FROM_TYPE, TO=$TO_TYPE"
        return 1
    fi

    TO=$( echo "$FROM_TYPE"
    for i in "${!FROM[@]}"  ; do
        echo -n "$i" | base64 -w 0
        echo -n ":"
        echo "${FROM[$i]}" | base64
    done )
    return 0
}

util::series::serialize() {
    local -n FROM
    local -n TO
    local FROM_TYPE
    local TO_TYPE

    core::arg::init_local
    core::arg::add_option -l "ARG_FROM" -o "--from" -r "true" -h "value name to serialize"
    core::arg::add_option_alias -l "ARG_FROM" -a "-f"
    core::arg::add_option -l "ARG_TO" -o "--to" -r "true" -h "value name to serialized" none
    core::arg::add_option_alias -l "ARG_TO" -a "-t"
    core::arg::parse "$@"
    FROM=$( core::arg::get_value -l "ARG_FROM" )
    TO=$( core::arg::get_value -l "ARG_TO" )

    FROM_TYPE=$( __util::series::get_val_type__ FROM )
    #echo "FROM_TYPE=$FROM_TYPE"
    TO_TYPE=$( __util::series::get_val_type__ TO )
    #echo "TO_TYPE=$TO_TYPE"
    if [[ "$TO_TYPE" != "string" ]]; then
        core::log::error_exit "'$2' is not a string value"
    fi
    TO=$( echo "$FROM_TYPE"
    for i in "${!FROM[@]}"; do
        echo -n "$i" | base64 -w 0
        echo -n ":"
        echo -n "${FROM[$i]}" | base64
    done )
    return 0
}

util::series::deserialize() {
    local -n FROM
    local -n TO
    local i
    local INDEX
    local VALUE
    local is_type="true"

    core::arg::init_local
    core::arg::add_option -l "ARG_FROM" -o "--from" -r "true" -h "value name to deserialize"
    core::arg::add_option_alias -l "ARG_FROM" -a "-f"
    core::arg::add_option -l "ARG_TO" -o "--to" -r "true" -h "value name to deserialized"
    core::arg::add_option_alias -l "ARG_TO" -a "-t"
    core::arg::parse "$@"
    FROM=$( core::arg::get_value -l "ARG_FROM" )
    TO=$( core::arg::get_value -l "ARG_TO" )

    FROM_TYPE=$( __util::series::get_val_type__ FROM )
    #echo "FROM_TYPE=$FROM_TYPE"
    TO_TYPE=$( __util::series::get_val_type__ TO )
    #echo "TO_TYPE=$TO_TYPE"
    if [[ "$FROM_TYPE" != "string" ]]; then
        core::log::error_exit "'$1' is not a serialized value"
    fi

    # echo; echo -e "FROM=\n$FROM"; echo
    for i in ${FROM}; do
        if [ "$is_type" = "true" ]; then
            TYPE=$i
            if [[ "$TYPE" != "$TO_TYPE" ]]; then
                core::log::error_exit "invalid value type $2 (FROM=$TYPE, TO=$TO_TYPE)"
            fi
            is_type="false"
            #echo "TYPE=$TYPE"
            continue
        fi
        #echo "i=${i}"
        INDEX="$( echo ${i%:*} | base64 -d )"
        VALUE="$( echo ${i#*:} | base64 -d )"
        if [[ "$TYPE" = "string" ]]; then
            TO="$VALUE"
        else
            TO["$INDEX"]="$VALUE"
        fi
    done
}
