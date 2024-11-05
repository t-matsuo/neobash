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

#### Logging Parameters ####
# color palette
readonly CORE_LOG_COLOR_ESC="\x1B["
readonly CORE_LOG_COLOR_DEFAULT=0
readonly CORE_LOG_COLOR_BLACK=30
readonly CORE_LOG_COLOR_RED=31
readonly CORE_LOG_COLOR_GREEN=32
readonly CORE_LOG_COLOR_YELLOW=33
readonly CORE_LOG_COLOR_BLUE=34
readonly CORE_LOG_COLOR_MAGENTA=35
readonly CORE_LOG_COLOR_CYAN=36
readonly CORE_LOG_COLOR_WHITE=37

### Logging Settings
# switch log level
: "${LOG_CRIT:=true}"
: "${LOG_ERROR:=true}"
: "${LOG_NOTICE:=true}"
: "${LOG_INFO:=true}"
: "${LOG_DEBUG:=false}"

# show stack trace
: "${LOG_STACK_TRACE:=true}"

# log format (plain or json)
: "${LOG_FORMAT:=plain}"

# add timestamp to log
: "${LOG_TIMESTAMP:=true}"
: "${LOG_TIMESTAMP_FORMAT:=%F-%T%z}"

# switch terminal log
: "${LOG_TERMINAL:=true}"
# log file name
: "${LOG_FILE:=/dev/null}"

# filter for debug
: "${LOG_DEBUG_TARGET_FUNC:=}"
: "${LOG_DEBUG_TARGET_FILE:=}"
: "${LOG_DEBUG_UNTARGET_FUNC:=}"
: "${LOG_DEBUG_UNTARGET_FILE:=}"

declare -g LOG_COLOR_STDOUT
declare -g LOG_COLOR_STDERR

# Colors Settings
declare -i -g CORE_LOG_COLOR_CRIT="${CORE_LOG_COLOR_MAGENTA}"
declare -i -g CORE_LOG_COLOR_ERROR="${CORE_LOG_COLOR_RED}"
declare -i -g CORE_LOG_COLOR_NOTICE="${CORE_LOG_COLOR_CYAN}"
declare -i -g CORE_LOG_COLOR_INFO="${CORE_LOG_COLOR_GREEN}"
declare -i -g CORE_LOG_COLOR_DEBUG="${CORE_LOG_COLOR_YELLOW}"
declare -i -g CORE_LOG_COLOR_TRACE="${CORE_LOG_COLOR_YELLOW}"

# Log Prefix
: "${CORE_LOG_LEVEL_CRIT:=CRIT}"
: "${CORE_LOG_LEVEL_ERROR:=ERROR}"
: "${CORE_LOG_LEVEL_NOTICE:=NOTICE}"
: "${CORE_LOG_LEVEL_INFO:=INFO}"
: "${CORE_LOG_LEVEL_DEBUG:=DEBUG}"
: "${CORE_LOG_LEVEL_TRACE:=TRACE}"
#### Logging Parameters End ####

# wrapper for echo with color
__core::log::color_terminal__() {
    local COLOR="$1"
    local LOG="$2"
    echo -e "${CORE_LOG_COLOR_ESC}${COLOR}m${LOG}${CORE_LOG_COLOR_ESC}${CORE_LOG_COLOR_DEFAULT}m"
    return 0
}

# wrapper for echo with color for stdout
__core::log::stdout__() {
    local COLOR="$1"
    local LOG="$2"
    if [[ "$LOG_COLOR_STDOUT" == "true" ]]; then
        __core::log::color_terminal__ "$COLOR" "$LOG"
    else
        echo -e "$LOG"
    fi
    # output to file
    echo -e "$LOG" >> "$LOG_FILE"
    return 0
}

# wrapper for echo with color for stderr
__core::log::stderr__() {
    local COLOR="$1"
    local LOG="$2"
    if [[ "$LOG_COLOR_STDERR" == "true" ]]; then
        __core::log::color_terminal__ "$COLOR" "$LOG" >&$stderr
    else
        echo -e "$LOG" >&$stderr
    fi
    # output to file
    echo -e "$LOG" >> "$LOG_FILE"
    return 0
}

# wrapper for terminal output
__core::log__() {
    local DATE
    local LEVEL=$1
    local MESSAGE=$2
    local LOG
    local caller="${FUNCNAME[1]}"
    local caller2
    if [[ "$LOG_TERMINAL" == "true" ]]; then
        if [[ "$LOG_TIMESTAMP" == "true" ]]; then
            printf -v DATE "%($LOG_TIMESTAMP_FORMAT)T"
        fi
        if [[ "$LOG_FORMAT" == "plain" ]]; then
             [[ "$LOG_TIMESTAMP" == "true" ]] && DATE+=" "
             LEVEL+=" "
             LOG="${DATE}${LEVEL}${MESSAGE}"
        elif [[ "$LOG_FORMAT" == "json" ]]; then
            # escape double quote
            LEVEL=${LEVEL//\"/\\\"}
            DATE=${DATE//\"/\\\"}
            MESSAGE=${MESSAGE//\"/\\\"}
            LOG="{\"level\": \"${LEVEL}\", \"timestamp\": \"${DATE}\", \"message\": \"${MESSAGE}\"}"
        fi
        # output error and debug log to stderr
        case "$caller" in
            "core::log::crit")
                __core::log::stderr__ "${CORE_LOG_COLOR_CRIT}" "$LOG"
                ;;
            "core::log::error")
                __core::log::stderr__ "${CORE_LOG_COLOR_ERROR}" "$LOG"
                ;;
            "core::log::stderr")
                # for ERR trap
                __core::log::stderr__ "${CORE_LOG_COLOR_ERROR}" "$LOG"
                ;;
            "core::log::notice")
                __core::log::stdout__ "${CORE_LOG_COLOR_NOTICE}" "$LOG"
                ;;
            "core::log::info")
                __core::log::stdout__ "${CORE_LOG_COLOR_INFO}" "$LOG"
                ;;
            "core::log::debug")
                __core::log::stderr__ "${CORE_LOG_COLOR_DEBUG}" "$LOG"
                ;;
            "core::log::stack_trace")
                caller2="${FUNCNAME[2]}"
                case "$caller2" in
                    "core::log::crit")
                        __core::log::stderr__ "${CORE_LOG_COLOR_CRIT}" "$LOG"
                        ;;
                    "core::log::error")
                        __core::log::stderr__ "${CORE_LOG_COLOR_ERROR}" "$LOG"
                        ;;
                    *)
                        __core::log::stderr__ "${CORE_LOG_COLOR_TRACE}" "$LOG"
                        ;;
                esac
                ;;
            *)
                core::log::crit "Unknown caller: $caller"
                ;;
        esac
    fi
    return 0
}

# logging stack trace
core::log::stack_trace() {
    local caller="${FUNCNAME[1]}"
    local i
    local space=""

    if [[ "$LOG_STACK_TRACE" == "true" ]]; then
        for ((i=1;i<${#FUNCNAME[*]}; i++)); do
            __core::log__ "${CORE_LOG_LEVEL_TRACE}" "${space}${FUNCNAME[$i]}() ${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]}"
            space="  $space"
        done
    fi
    return 0
}

# logging crit
# arg1: message
core::log::crit() {
    __core::log__ "${CORE_LOG_LEVEL_CRIT}" "${1:-}"
    core::log::stack_trace
    exit 1
}

# logging error
# arg1: message
core::log::error() {
    __core::log__ "${CORE_LOG_LEVEL_ERROR}" "${1:-}"
    core::log::stack_trace
    return 0
}

# logging error and exit
# arg1: message
core::log::error_exit() {
    core::log::error "${1:-}"
    exit 1
}

# catch unexpected stderr
core::log::stderr() {
    while read -r line; do
        __core::log__ "${CORE_LOG_LEVEL_ERROR}" "${line}"
    done
}

# logging info
# arg1: message
core::log::notice() {
    [[ "$LOG_NOTICE" == "true" ]] && __core::log__ "${CORE_LOG_LEVEL_NOTICE}" "${1:-}"
    return 0
}

# logging info
# arg1: message
core::log::info() {
    [[ "$LOG_INFO" == "true" ]] && __core::log__ "${CORE_LOG_LEVEL_INFO}" "${1:-}"
    return 0
}

# logging debug
# arg1: message
# arg2: if true, show stackstrace
core::log::debug() {
    local target
    local SHOW_STACK_TRACE=${2:-}

    if [[ "$LOG_DEBUG" == "true" ]]; then
        # supress debug log for specified function name
        if [[ -n "${LOG_DEBUG_UNTARGET_FUNC:-}" ]]; then
            for target in ${LOG_DEBUG_UNTARGET_FUNC}; do
                if [[ ${FUNCNAME[1]} =~ $target ]]; then
                    return 0
                fi
            done
        fi
        # supress debug log for specified file or directory name
        if [[ -n "${LOG_DEBUG_UNTARGET_FILE:-}" ]]; then
            for target in ${LOG_DEBUG_UNTARGET_FILE}; do
                if [[ ${BASH_SOURCE[1]} =~ $target ]]; then
                    return 0
                fi
            done
        fi
         __core::log__ "${CORE_LOG_LEVEL_DEBUG}" "$1   [${FUNCNAME[1]}() ${BASH_SOURCE[1]}:${BASH_LINENO[0]}]"
         [[ "$SHOW_STACK_TRACE" == "true" ]] && core::log::stack_trace
         return 0
    fi

    # debug log for specified function name
    if [[ -n "${LOG_DEBUG_TARGET_FUNC:-}" ]]; then
        for target in ${LOG_DEBUG_TARGET_FUNC}; do
            if [[ ${FUNCNAME[1]} =~ $target ]]; then
                __core::log__ "${CORE_LOG_LEVEL_DEBUG}" "$*   [${FUNCNAME[1]}() ${BASH_SOURCE[1]}:${BASH_LINENO[0]}]"
                [[ "$SHOW_STACK_TRACE" == "true" ]] && core::log::stack_trace
            fi
        done
    fi

    # debug log for specified file or directory name
    if [[ -n "${LOG_DEBUG_TARGET_FILE:-}" ]]; then
        for target in ${LOG_DEBUG_TARGET_FILE}; do
            if [[ ${BASH_SOURCE[1]} =~ $target ]]; then
                __core::log__ "${CORE_LOG_LEVEL_DEBUG}" "$*   [${FUNCNAME[1]}() ${BASH_SOURCE[1]}:${BASH_LINENO[0]}]"
                [[ "$SHOW_STACK_TRACE" == "true" ]] && core::log::stack_trace
            fi
        done
    fi
    return 0
}

# switch terminal log color
__core::log::switch_terminal_color__() {
    if [[ -z "${LOG_COLOR_STDOUT:-}" ]]; then
        # switch stdout color
        if [ -t 1 ]; then
            # output to terminal
            LOG_COLOR_STDOUT=true
        elif [ -p /dev/stdout ]; then
            # output to pipe
            LOG_COLOR_STDOUT=false
        elif [ -f /dev/stdout ]; then
            # output to file
            LOG_COLOR_STDOUT=false
        else
            # output to others
            LOG_COLOR_STDOUT=false
        fi
    fi

    if [[ -z "${LOG_COLOR_STDERR:-}" ]]; then
        # switch stderr color
        if [ -t 2 ]; then
            # output to terminal
            LOG_COLOR_STDERR=true
        elif [ -p /dev/stderr ]; then
            # output to pipe"
            LOG_COLOR_STDERR=false
        elif [ -f /dev/stderr ]; then
            # output to file
            LOG_COLOR_STDERR=false
        else
            # output to others
            LOG_COLOR_STDERR=false
        fi
    fi
}

#### main ####
set -o errtrace

# handle signals
CORE_LOG_IS_SIGINT="false"
trap 'core::log::error "catch SIGERR (unexpected return code $?)"; [[ "$CORE_LOG_IS_SIGINT" == "true" ]] && exit 1' ERR
trap 'core::log::debug "catch SIGTERM"; core::log::stack_trace; exit 1' TERM
trap 'core::log::debug "catch SIGINT";  CORE_LOG_IS_SIGINT="true"' INT

# can omit core:: in core library
alias log::enable_stack_trace='core::log::enable_stack_trace'
alias log::disable_stack_trace='core::log::disable_stack_trace'
alias log::enable_stdout_color='core::log::enable_stdout_color'
alias log::disable_stdout_color='core::log::disable_stdout_color'
alias log::enable_stderr_color='core::log::enable_stderr_color'
alias log::disable_stderr_color='core::log::disable_stderr_color'
alias log::stack_trace='core::log::stack_trace'
alias log::crit='core::log::crit'
alias log::error='core::log::error'
alias log::error_exit='core::log::error_exit'
alias log::stderr='core::log::stderr'
alias log::notice='core::log::notice'
alias log::info='core::log::info'
alias log::debug='core::log::debug'

#### init ####

# NOTE: need to call it before 'exec 2> >(core::log::stderr)'
__core::log::switch_terminal_color__

# save stderr
exec {stderr}>&2
# redirect stderr to append header and color settings
exec 2> >(core::log::stderr)
