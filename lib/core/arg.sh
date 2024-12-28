#!/usr/bin/env bash
# Copyright 2024 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license

nb::require "core/log.sh"

#### Parsing args ####
# parse args
alias core::arg::init_global='
    CORE_ARG_LABEL=""
    declare -A CORE_ARG_OPTION_LABEL
    declare -A CORE_ARG_OPTION_SHORT
    declare -A CORE_ARG_OPTION_LONG
    declare -A CORE_ARG_TYPE
    declare -A CORE_ARG_REQUIRED
    declare -A CORE_ARG_HELP
    declare -A CORE_ARG_DEFAULT
    declare -A CORE_ARG_STORE
    declare -A CORE_ARG_VALUE
    declare -a ARG_OTHERS
    declare -n ARGS=CORE_ARG_VALUE
'

alias core::arg::init_local='
    local CORE_ARG_LABEL=""
    local -A CORE_ARG_OPTION_LABEL
    local -A CORE_ARG_OPTION_SHORT
    local -A CORE_ARG_OPTION_LONG
    local -A CORE_ARG_TYPE
    local -A CORE_ARG_REQUIRED
    local -A CORE_ARG_HELP
    local -A CORE_ARG_DEFAULT
    local -A CORE_ARG_STORE
    local -A CORE_ARG_VALUE
    local -a ARG_OTHERS
    local -n ARGS=CORE_ARG_VALUE
'

# show help
core::arg::help() {
    echo "Usage: source $0"
}

# cleck if label exists
__core::arg::has_label__() {
    local LABEL="$1"
    local label

    [[ -z "${LABEL:-}" ]] && core::log::error_exit "args is empty"
    for label in $CORE_ARG_LABEL; do
        [[ "$label" == "$LABEL" ]] && return 0
    done
    return 1
}

# cleck if option exists
__core::arg::has_option__() {
    local OPTION="$1"
    [[ -z "$OPTION" ]] && core::log::error_exit "args is empty"
    for label in $CORE_ARG_LABEL; do
        [[ "${CORE_ARG_OPTION_SHORT[$label]:-}" == "$OPTION" || "${CORE_ARG_OPTION_LONG[$label]:-}" == "$OPTION" ]] && return 0
    done
    return 1
}

# Add an option
# -l: label (required)
# -o: option name (required)
# -t: type
#     type can be one of: string, int, bool
#     default is string
# -r: required
#     required can be one of: true, false
#     default is false
# -h: help
#     deault is "no help message for this option"
# -s: store
#     store can be one of: none, true, false
#     default is none
# -d: default value (optional)
#     default is ""
core::arg::add_option() {
    local LABEL
    local OPTION
    local TYPE="string"
    local REQUIRED="false"
    local HELP="no help message for this option"
    local STORE="none"
    local DEFAULT=""
    local OPTIND
    local OPTARG
    local opt
    local options=":l:o:t:r:h:s:d:"
    while getopts "$options" opt; do
        case "$opt" in
        l)
            LABEL="$OPTARG"
            ;;
        o)
            OPTION="$OPTARG"
            ;;
        t)
            TYPE="$OPTARG"
            ;;
        r)
            REQUIRED="$OPTARG"
            ;;
        h)
            HELP="$OPTARG"
            ;;
        s)
            STORE="$OPTARG"
            ;;
        d)
            DEFAULT="$OPTARG"
            ;;
        \?)
            core::log::error_exit "invalid option: -$OPTARG"
            ;;
        :)
            core::log::error_exit "option -$OPTARG requires an argument"
        esac
    done

    # check option
    [[ -z "${LABEL:-}" ]] && core::log::error_exit "label(-l) is required"
    [[ "$LABEL" =~ " " ]] && core::log::error_exit "$LABEL must not contain spaces"
    [[ -z "${OPTION:-}" ]] && core::log::error_exit "$LABEL option(-o) is required"
    [[ ! "$OPTION" =~ ^-{1,2}[a-zA-Z]$ && ! "$OPTION" =~ ^--[a-zA-Z] ]] \
        && core::log::error_exit "\"$OPTION\" must start with \"-\" or \"--\", and \"-\" require 1 character"
    [[ -z "${TYPE:-}" ]] && core::log::error_exit "$OPTION type(-t) is required"
    [[ "$TYPE" != "string" && "$TYPE" != "int" && "$TYPE" != "bool" ]] \
        && core::log::error_exit "invalid type \"$TYPE\", $OPTION type(-t) needs 'string' or 'int' or 'bool'"
    [[ "$REQUIRED" != "true" && "$REQUIRED" != "false" ]] && core::log::error_exit "invalid required \"$REQUIRED\", $OPTION required(-r) needs 'true' or 'false'"
    [[ "$STORE" != "none" && "$STORE" != "true" && "$STORE" != "false" ]] \
        && core::log::error_exit "invalid store \"$STORE\", $OPTION store(-o) needs 'none' or 'true' or 'false'"
    if [[ "$STORE" == "true" || "$STORE" == "false" ]]; then
        TYPE="bool"
    fi

    # check label
    __core::arg::has_label__ "$LABEL" && core::log::error_exit "label \"$LABEL\" already exists"

    # check option
    __core::arg::has_option__ "$OPTION" && core::log::error_exit "option \"$OPTION\" already exists"

    # check default
    if [[ "$TYPE" == "int" ]]; then
        if [[ -n "${DEFAULT:-}" ]]; then
            [[ ! "$DEFAULT" =~ ^[0-9]+$ ]] && core::log::error_exit "$OPTION default \"$DEFAULT\" must be an integer"
        fi
    fi
    if [[ "$TYPE" == "bool" ]]; then
        if [[ -n "${DEFAULT:-}" ]]; then
            [[ "$DEFAULT" != "true" && "$DEFAULT" != "false" ]] \
                && core::log::error_exit "$OPTION default \"$DEFAULT\" must be \"true\" or \"false\""
        fi
    fi

    # add option
    core::log::debug "add LABEL: $LABEL, OPTION: $OPTION, TYPE: $TYPE, REQUIRED: $REQUIRED, HELP: $HELP, DEFAULT: $DEFAULT"
    CORE_ARG_LABEL="$CORE_ARG_LABEL $LABEL"
    CORE_ARG_OPTION_LABEL["$OPTION"]="$LABEL"
    if [[ "$OPTION" =~ ^-- ]]; then
        CORE_ARG_OPTION_LONG["$LABEL"]="$OPTION"
    else
        CORE_ARG_OPTION_SHORT["$LABEL"]="$OPTION"
    fi
    CORE_ARG_TYPE["$LABEL"]="$TYPE"
    CORE_ARG_REQUIRED["$LABEL"]="$REQUIRED"
    CORE_ARG_HELP["$LABEL"]="$HELP"
    CORE_ARG_STORE["$LABEL"]="$STORE"
    CORE_ARG_DEFAULT["$LABEL"]="$DEFAULT"
}

# add option alias
# -l: label (required)
# -a: alias (required)
core::arg::add_option_alias() {
    local LABEL
    local ALIAS
    local OPTIND
    local OPTARG
    local opt
    local options=":l:a:"
    while getopts "$options" opt; do
        case "$opt" in
        l)
            LABEL="$OPTARG"
            ;;
        a)
            ALIAS="$OPTARG"
            ;;
        \?)
            core::log::error_exit "invalid option: -$OPTARG"
            ;;
        :)
            core::log::error_exit "option -$OPTARG requires an argument"
        esac
    done
    [[ -z "${LABEL:-}" ]] && core::log::error_exit "label(-l) is required"
    [[ -z "${ALIAS:-}" ]] && core::log::error_exit "$LABEL alias(-a) is required"
    [[ ! "$ALIAS" =~ ^-{1,2}[a-zA-Z]$ && ! "$ALIAS" =~ ^--[a-zA-Z] ]] \
        && core::log::error_exit "\"$ALIAS\" must not start with \"-\" or \"--\", and \"-\" require 1 character"

    # check label
    __core::arg::has_label__ "$LABEL" || core::log::error_exit "label \"$LABEL\" dose not exist"
    # check alias
    __core::arg::has_option__ "$ALIAS" && core::log::error_exit "alias \"$ALIAS\" already exists"

    core::log::debug "add LABEL: $LABEL, ALIAS: $ALIAS"
    if [[ "$ALIAS" =~ ^-- ]]; then
        CORE_ARG_OPTION_LONG["$LABEL"]="$ALIAS"
        CORE_ARG_OPTION_LABEL["$ALIAS"]="$LABEL"
    else
        CORE_ARG_OPTION_SHORT["$LABEL"]="$ALIAS"
        CORE_ARG_OPTION_LABEL["$ALIAS"]="$LABEL"
    fi
}

# check if arg is option
__core::arg::is_option__() {
    local OPTION="$1"
    [[ -z "${OPTION:-}" ]] && core::log::error_exit "args is empty"
    [[ "$OPTION" =~ " " ]] && return 1
    [[ ! "$OPTION" =~ ^-{1,2}[a-zA-Z]$ && ! "$OPTION" =~ ^--[a-zA-Z] ]] && return 1
    return 0
}

# check value type
# arg1: type
# arg2: value
__core::arg::check_value_type__() {
    local TYPE="$1"
    local VALUE="$2"
    [[ -z "${TYPE:-}" ]] && core::log::error_exit "TYPE is empty"
    [[ -z "${VALUE:-}" ]] && core::log::error_exit "VALUE is empty"
    [[ "$TYPE" != "string" && "$TYPE" != "int" && "$TYPE" != "bool" ]] \
        && core::log::error_exit "type \"$TYPE\" is invalid"

    if [[ "$TYPE" == "int" ]]; then
        [[ ! "$VALUE" =~ ^[0-9]+$ ]] && core::log::error_exit "value \"$VALUE\" must be an integer"
    fi
    if [[ "$TYPE" == "bool" ]]; then
        [[ "$VALUE" != "true" && "$VALUE" != "false" ]] \
            && core::log::error_exit "value \"$VALUE\" must be \"true\" or \"false\""
    fi
    return 0
}

# parse args
core::arg::parse() {
    local ARGS=("$@")
    local arg
    local num="-1"
    local next_arg
    local skip=false
    local skip_all=false
    local label
    local option
    local arg_num=0
    local type

    core::log::debug "ARGS[*]=${ARGS[*]}"
    for arg in "${ARGS[@]}"; do
        num=$(( $num + 1 ))
        if [[ "$skip_all" == "true" ]]; then
            ARG_OTHERS[$arg_num]="$arg"
            arg_num=$(( $arg_num + 1 ))
            continue
        fi
        if [[ "$skip" == "true" ]]; then
            skip=false
            continue
        fi
        if [[ "$arg" == "--" ]]; then
            skip_all=true
            continue
        fi

        # fixed option
        if [[ "${FUNCNAME[1]}" == "main" ]]; then
            if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
                if [[ "$( type -t show_help )" == "function" ]]; then show_help; else core::arg::show_usage; fi
                exit 0
            fi
            if [[ "$arg" == "-v" || "$arg" == "--version" ]]; then
                if [[ "$( type -t show_version )" == "function" ]]; then show_version; else echo "no version"; fi
                exit 0
            fi
        else
            if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
                core::arg::show_usage ""
                exit 0
            fi
        fi

        core::log::debug "parsing: $arg"
        if __core::arg::is_option__ "$arg"; then
            label="${CORE_ARG_OPTION_LABEL[$arg]:-}"
            core::log::debug "label:$label arg:$arg"
            if [[ -z "${label:-}" ]]; then
                core::log::error_exit "LABEL of \"$arg\" dose not exist"
            fi
            if [[ "${CORE_ARG_STORE[$label]}" != "none" ]]; then
                [[ -n ${CORE_ARG_VALUE["$label"]:-} ]] && core::log::error_exit "$arg value is already set"
                core::log::debug "$label value is ${CORE_ARG_STORE[$label]}"
                CORE_ARG_VALUE["$label"]="${CORE_ARG_STORE[$label]}"
                skip=false
                continue
            fi
            next_arg="${ARGS[$(( $num + 1 ))]}"
            core::log::debug "next_arg: $next_arg"
            [[ -z "${next_arg:-}" ]] && core::log::error_exit "$arg value is empty"
            __core::arg::is_option__ "$next_arg" && core::log::error_exit "$arg value is empty"
            [[ -n ${CORE_ARG_VALUE["$label"]:-} ]] && core::log::error_exit "$arg value is already set"

            # check value type
            type="${CORE_ARG_TYPE["$label"]}"
            __core::arg::check_value_type__ "$type" "$next_arg" || exit 1

            CORE_ARG_VALUE["$label"]="$next_arg"
            skip=true
            continue
        else
            ARG_OTHERS[$arg_num]="$arg"
            arg_num=$(( $arg_num + 1 ))
        fi
    done

    # check required option
    for label in $CORE_ARG_LABEL; do
        # get label option name
        if [[ -n "${CORE_ARG_OPTION_SHORT[$label]:-}" ]]; then
            option="${CORE_ARG_OPTION_SHORT[$label]}"
            if [[ -n "${CORE_ARG_OPTION_LONG[$label]:-}" ]]; then
                [[ -z "${option:-}" ]] && option="${CORE_ARG_OPTION_LONG[$label]}"
                [[ -n "${option:-}" ]] && option="$option or ${CORE_ARG_OPTION_LONG[$label]}"
            fi
        else
            option="${CORE_ARG_OPTION_LONG[$label]}"
        fi
        core::log::debug "checking value: $label ($option)"

        # check required value is set
        [[ ${CORE_ARG_REQUIRED["$label"]} == "true" && -z ${CORE_ARG_VALUE["$label"]:-} ]] \
             && core::log::error_exit "required option \"$option\" is not set"

        # set default value if value is not set
        if [[ ${CORE_ARG_REQUIRED["$label"]} == "false" && -z ${CORE_ARG_VALUE["$label"]:-} ]]; then
            CORE_ARG_VALUE["$label"]="${CORE_ARG_DEFAULT["$label"]}"
            case ${CORE_ARG_TYPE["$label"]} in
                string) [[ ! -v ${CORE_ARG_DEFAULT["$label"]} ]] && CORE_ARG_VALUE["$label"]="";;
                int)    [[ ! -v ${CORE_ARG_DEFAULT["$label"]} ]] && CORE_ARG_VALUE["$label"]="0";;
                bool)   [[ ! -v ${CORE_ARG_DEFAULT["$label"]} ]] && CORE_ARG_VALUE["$label"]="false";;
                *) core::log::error_exit "invalid type: ${CORE_ARG_TYPE[$label]}";;
            esac
        fi
    done
}

# get value
# -l: label (required)
core::arg::get_value() {
    local LABEL
    local OPTIND
    local OPTARG
    local opt
    local options=":l:"
    while getopts "$options" opt; do
        case "$opt" in
        l)
            LABEL="$OPTARG"
            ;;
        \?)
            core::log::error_exit "invalid option: -$OPTARG"
            ;;
        :)
            core::log::error_exit "option -$OPTARG requires an argument"
        esac
    done
    [[ -z "${LABEL:-}" ]] && core::log::error_exit "label(-l) is required"

    if ! __core::arg::has_label__ "$LABEL"; then
        core::log::error_exit "label \"$LABEL\" dose not defined"
    fi
    echo "${CORE_ARG_VALUE[$LABEL]}"
}

# update value
# -l: label (required)
# -v: value (required)
core::arg::set_value() {
    local LABEL
    local VALUE
    local type
    local OPTIND
    local OPTARG
    local opt
    local options=":l:v:"
    while getopts "$options" opt; do
        case "$opt" in
        l)
            LABEL="$OPTARG"
            ;;
        v)
            VALUE="$OPTARG"
            ;;
        \?)
            core::log::error_exit "invalid option: -$OPTARG"
            ;;
        :)
            core::log::error_exit "option -$OPTARG requires an argument"
        esac
    done
    [[ -z "${LABEL:-}" ]] && core::log::error_exit "label(-l) is required"
    [[ -z "${VALUE:-}" ]] && core::log::error_exit "value(-v) is required"
    if ! __core::arg::has_label__ "$LABEL"; then
        core::log::error "label \"$LABEL\" dose not defined"
        return 1
    fi
    type="${CORE_ARG_TYPE[$LABEL]}"
    __core::arg::check_value_type__ "$type" "$VALUE" || exit 1
    CORE_ARG_VALUE["$LABEL"]="$VALUE"
}

# delete value
# -l label (required)
#
# if type is string, value set empty string.
# if type is int, value set 0.
# if type is bool, value set false.
core::arg::del_value() {
    local LABEL
    local OPTIND
    local OPTARG
    local opt
    local options=":l:v:"
    while getopts "$options" opt; do
        case "$opt" in
        l)
            LABEL="$OPTARG"
            ;;
        \?)
            core::log::error_exit "invalid option: -$OPTARG"
            ;;
        :)
            core::log::error_exit "option -$OPTARG requires an argument"
        esac
    done
    [[ -z "${LABEL:-}" ]] && core::log::error_exit "label(-l) is required"

    if ! __core::arg::has_label__ "$LABEL"; then
        core::log::error_exit "label \"$LABEL\" dose not defined"
    fi
    case ${CORE_ARG_TYPE["$label"]} in
        string) CORE_ARG_VALUE["$LABEL"]="";;
        int)    CORE_ARG_VALUE["$LABEL"]="0";;
        bool)   CORE_ARG_VALUE["$LABEL"]="false";;
        *) core::log::crit "invalid type: ${CORE_ARG_TYPE[$LABEL]}";;
    esac
}

# show all value
core::arg::get_all_value() {
    local label
    for label in $CORE_ARG_LABEL; do
        echo "$label=${CORE_ARG_VALUE["$label"]}"
    done
    echo "OTHER ARGS=${ARG_OTHERS[*]}"
}

# show all options as csv
core::arg::get_all_option() {
    local label
    echo -n "label,"
    echo -n "short option,"
    echo -n "long option,"
    echo -n "type,"
    echo -n "required,"
    echo -n "help message,"
    echo -n "store,"
    echo    "default"
    for label in $CORE_ARG_LABEL; do
        echo -n "$label,"
        echo -n "${CORE_ARG_OPTION_SHORT["$label"]:-},"
        echo -n "${CORE_ARG_OPTION_LONG["$label"]:-},"
        echo -n "${CORE_ARG_TYPE[$label]},"
        echo -n "${CORE_ARG_REQUIRED[$label]},"
        echo -n "\"${CORE_ARG_HELP[$label]}\","
        echo -n "${CORE_ARG_STORE[$label]},"
        echo    "\"${CORE_ARG_DEFAULT[$label]:-}\""
    done
}

# show usage for help message
core::arg::show_usage() {
    local PREFIX=""
    local label
    local required
    local value

    [[ -v 1 ]] && PREFIX="$1"

    for label in $CORE_ARG_LABEL; do
        value=""
        if [[ ${CORE_ARG_REQUIRED["$label"]} == "true" ]]; then
            required="(required)"
        else
            required="(optional)"
        fi
        [[ "${CORE_ARG_STORE["$label"]}" == "none" ]] && value=" VALUE"

        if [[ -n "${CORE_ARG_OPTION_SHORT["$label"]:-}" ]]; then
            echo -n "${PREFIX}* ${CORE_ARG_OPTION_SHORT["$label"]}"
            if [[ -n "${CORE_ARG_OPTION_LONG["$label"]:-}" ]]; then
                echo -n ", ${CORE_ARG_OPTION_LONG["$label"]}"
                echo -e "${value}\t${required}"
            else
                echo -e "${value}\t\t\t${required}"
            fi
        else
            echo -n "${PREFIX}* ${CORE_ARG_OPTION_LONG["$label"]}"
            echo -e "${value}\t\t${required}"
        fi
        echo "$PREFIX  * ${CORE_ARG_HELP[$label]}"
        if [[ "${CORE_ARG_STORE["$label"]}" == "none" ]]; then
            echo "$PREFIX  * VALUE: ${CORE_ARG_TYPE[$label]}"
        fi
        if [[ "${CORE_ARG_STORE["$label"]}" == "none" && "${CORE_ARG_REQUIRED["$label"]}" == "false" ]]; then
            echo "$PREFIX  * DEFAULT: \"${CORE_ARG_DEFAULT[$label]}\""
        fi
    done
}

# can omit core:: in core library
alias arg::init_global='core::arg::init_global'
alias arg::init_local='core::arg::init_local'
alias arg::help='core::arg::help'
alias arg::add_option='core::arg::add_option'
alias arg::add_option_alias='core::arg::add_option_alias'
alias arg::parse='core::arg::parse'
alias arg::get_value='core::arg::get_value'
alias arg::set_value='core::arg::set_value'
alias arg::del_value='core::arg::del_value'
alias arg::get_all_value='core::arg::get_all_value'
alias arg::get_all_option='core::arg::get_all_option'
alias arg::show_usage='core::arg::show_usage'
