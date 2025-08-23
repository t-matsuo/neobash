#!/usr/bin/env bash
# Copyright 2024 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license

# @file core/log.sh
# @brief Neobash core logging library
# @description
# * Output logs of various types, such as debug, info, notice, error, crit, and stacktrace.
# * Log message format is plain or json.
# * Log message is formatted with color and timestamp by default.
# * Control characters in log message are removed.
# * Can select output destination of log to stdout/stderr or file.
# * Catch unexpected SIGINT, SIGTERM, and SIGERR, and output the stacktrace.
#
# This library can change its behavior by setting the following environment variables.
#
# Controlling log level. Set true or false.
# * LOG_CRIT : Switch the output of the CRIT log. default: ``true``
# * LOG_ERROR : Switch the output of the ERROR log. default: ``true``
# * LOG_NOTICE : Switch the output of the NOTICE log. default: ``true``
# * LOG_INFO : Switch the output of the INFO log. default: ``true``
# * LOG_DEBUG : Switch the output of the DEBUG log. default: ``false``
# * LOG_STDERR : Switch the output of the standard error log. default: ``true``
# * LOG_SIGERR : Switch the output of the SIGERROR log. default: ``true``
#
# Controlling log format.
# * LOG_FORMAT : Set the log format ``plain`` or ``json``. default: ``plain``
# * LOG_STACK_TRACE : Switch the output of the stack trace for CRIT, DEBUG, and ERROR logs. default: ``true``
# * LOG_TIMESTAMP : Switch the output of the timestamp to the all logs. default: ``true``
# * LOG_TIMESTAMP_FORMAT : Set the timestamp format. please specify the format using printf formatting. default: ``%F-%T%z``
# * LOG_ESCAPE_LINE_BREAK: switch escaping of line breaks and \n to \\n. default: ``true`` (escape line breaks and \n to \\n)
#
# Example: enable debug log and disable stack trace.
# ```bash
# LOG_DEBUG=true LOG_STACK_TRACE=false ./myscript.sh
# ````
#
# Controlling log output destination.
# * LOG_TERMINAL : switch the output of the log to the terminal. default: ``true``
# * LOG_FILE : Set the log file name. default: ``/dev/null`` (no output to file)
#
# Controlling log prefix.
# * LOG_PREFIX_CRIT : Set the log prefix for CRIT log. default: ``CRIT``
# * LOG_PREFIX_ERROR : Set the log prefix for ERROR log. default: ``ERROR``
# * LOG_PREFIX_WARN : Set the log prefix for ERROR log. default: ``WARN``
# * LOG_PREFIX_NOTICE : set the log prefix for NOTICE log. default: ``NOTICE``
# * LOG_PREFIX_INFO : set the log prefix for INFO log. default: ``INFO``
# * LOG_PREFIX_DEBUG : set the log prefix for DEBUG log. default: ``DEBUG``
# * LOG_PREFIX_TRACE : set the log prefix for TRACE log. default: ``TRACE``
# * LOG_PREFIX_STDERR : set the log prefix for stderr log default: ``STDERR``
# * LOG_PREFIX_SIGERR : set the log prefix for SIGERROR log default: ``SIGERR``
#
# Controlling debug log filter.
# * LOG_DEBUG_FUNC : select the debug log by function name. default: ``''``
# * LOG_DEBUG_FILE : select the debug log by file name. default: ``''``
# * LOG_DEBUG_NO_FUNC : drop the debug log by function name. default: ``''``
# * LOG_DEBUG_NO_FILE : drop the debug log by file name. default: ``''``
#
# Example: enable debug log for ``mylib::get_xxx`` function only.
# ```bash
# LOG_DEBUG_FUNC="mylib::get_xxx mylib:set_xxx" ./myscript.sh
# ```
#
# Example: enable debug log for ``mylib/myutil.sh`` file only.
# ```bash
# LOG_DEBUG_FILE="mylib/myutil.sh" ./myscript.sh
# ```

#### Logging Parameters ####
readonly CORE_LOG_COLOR_ESC="\x1B["
readonly CORE_LOG_COLOR_DEFAULT=0
# font color palette
readonly CORE_LOG_COLOR_BLACK=30
readonly CORE_LOG_COLOR_RED=31
readonly CORE_LOG_COLOR_GREEN=32
readonly CORE_LOG_COLOR_YELLOW=33
readonly CORE_LOG_COLOR_BLUE=34
readonly CORE_LOG_COLOR_MAGENTA=35
readonly CORE_LOG_COLOR_CYAN=36
readonly CORE_LOG_COLOR_WHITE=37
# back color palette
readonly CORE_LOG_BCOLOR_BLACK=40
readonly CORE_LOG_BCOLOR_RED=41
readonly CORE_LOG_BCOLOR_GREEN=42
readonly CORE_LOG_BCOLOR_YELLOW=43
readonly CORE_LOG_BCOLOR_BLUE=44
readonly CORE_LOG_BCOLOR_MAGENTA=45
readonly CORE_LOG_BCOLOR_CYAN=46
readonly CORE_LOG_BCOLOR_WHITE=47
# other decoration
readonly CORE_LOG_DECO_UNDERLINE=4
readonly CORE_LOG_DECO_SLOW_BLINK=5
readonly CORE_LOG_DECO_FALST_BLINK=6
readonly CORE_LOG_DECO_REVERSE=7


### Logging Settings
# switch log level
: "${LOG_CRIT:=true}"
: "${LOG_ERROR:=true}"
: "${LOG_WARN:=true}"
: "${LOG_NOTICE:=true}"
: "${LOG_INFO:=true}"
: "${LOG_DEBUG:=false}"
: "${LOG_STDERR:=true}"
: "${LOG_SIGERR:=true}"

# show stack trace
: "${LOG_STACK_TRACE:=true}"

# log format (plain or json)
: "${LOG_FORMAT:=plain}"

# add timestamp to log
: "${LOG_TIMESTAMP:=true}"
: "${LOG_TIMESTAMP_FORMAT:=%F-%T%z}"

# escape 'line break' and '\n' to '\\n'
: "${LOG_ESCAPE_LINE_BREAK:=true}"

# switch terminal log
: "${LOG_TERMINAL:=true}"
# log file name
: "${LOG_FILE:=/dev/null}"

# filter for debug
: "${LOG_DEBUG_FUNC:=}"
: "${LOG_DEBUG_FILE:=}"
: "${LOG_DEBUG_NO_FUNC:=}"
: "${LOG_DEBUG_NO_FILE:=}"

declare -g LOG_COLOR_STDOUT
declare -g LOG_COLOR_STDERR

# Colors Settings
declare -i -g CORE_LOG_COLOR_CRIT="${CORE_LOG_DECO_REVERSE}"
declare -i -g CORE_LOG_COLOR_ERROR="${CORE_LOG_BCOLOR_RED}"
declare -i -g CORE_LOG_COLOR_WARN="${CORE_LOG_COLOR_RED}"
declare -i -g CORE_LOG_COLOR_NOTICE="${CORE_LOG_COLOR_CYAN}"
declare -i -g CORE_LOG_COLOR_INFO="${CORE_LOG_COLOR_GREEN}"
declare -i -g CORE_LOG_COLOR_DEBUG="${CORE_LOG_COLOR_YELLOW}"
declare -i -g CORE_LOG_COLOR_TRACE="${CORE_LOG_DECO_UNDERLINE}"
declare -i -g CORE_LOG_COLOR_STDERR="${CORE_LOG_BCOLOR_MAGENTA}"
declare -i -g CORE_LOG_COLOR_SIGERR="${CORE_LOG_BCOLOR_BLUE}"

# stdout/stderr IO Settings
readonly CORE_LOG_STDOUT="1"
readonly CORE_LOG_STDERR="2"
: "${CORE_LOG_IO_CRIT:=$CORE_LOG_STDERR}"
: "${CORE_LOG_IO_ERROR:=$CORE_LOG_STDERR}"
: "${CORE_LOG_IO_WARN:=$CORE_LOG_STDERR}"
: "${CORE_LOG_IO_NOTICE:=$CORE_LOG_STDOUT}"
: "${CORE_LOG_IO_INFO:=$CORE_LOG_STDOUT}"
: "${CORE_LOG_IO_DEBUG:=$CORE_LOG_STDERR}"
: "${CORE_LOG_IO_TRACE:=$CORE_LOG_STDERR}"
: "${CORE_LOG_IO_STDERR:=$CORE_LOG_STDERR}"
: "${CORE_LOG_IO_SIGERR:=$CORE_LOG_STDERR}"

# Log Prefix
: "${LOG_PREFIX_CRIT:=CRIT}"
: "${LOG_PREFIX_ERROR:=ERROR}"
: "${LOG_PREFIX_WARN:=WARN}"
: "${LOG_PREFIX_NOTICE:=NOTICE}"
: "${LOG_PREFIX_INFO:=INFO}"
: "${LOG_PREFIX_DEBUG:=DEBUG}"
: "${LOG_PREFIX_TRACE:=TRACE}"
: "${LOG_PREFIX_STDERR:=STDERR}"
: "${LOG_PREFIX_SIGERR:=SIGERR}"
#### Logging Parameters End ####

# @internal
# @description wrapper for echo with color
__core::log::color_terminal__() {
    local COLOR="$1"
    local LOG="$2"
    echo -e "${CORE_LOG_COLOR_ESC}${COLOR}m${LOG}${CORE_LOG_COLOR_ESC}${CORE_LOG_COLOR_DEFAULT}m"
    return 0
}

# @internal
# @description wrapper for echo with color for stdout
__core::log::stdout__() {
    local COLOR="$1"
    local LOG="$2"
    if [[ "$LOG_TERMINAL" == "true" ]]; then
        if [[ "$LOG_COLOR_STDOUT" == "true" ]]; then
            __core::log::color_terminal__ "$COLOR" "$LOG" >&$core_log_saved_stdout
        else
            echo -e "$LOG"
        fi
    fi
    # output to file
    echo -e "$LOG" >> "$LOG_FILE"
    return 0
}

# @internal
# @description wrapper for echo with color for stderr
__core::log::stderr__() {
    local COLOR="$1"
    local LOG="$2"
    if [[ "$LOG_TERMINAL" == "true" ]]; then
        if [[ "$LOG_COLOR_STDERR" == "true" ]]; then
            __core::log::color_terminal__ "$COLOR" "$LOG" >&$core_log_saved_stderr
        else
            echo -e "$LOG" >&$core_log_saved_stderr
        fi
    fi
    # output to file
    echo -e "$LOG" >> "$LOG_FILE"
    return 0
}

# @internal
# @description wrapper for terminal output
__core::log__() {
    local DATE=""
    local LEVEL=$1
    local MESSAGE=$2
    local JSON=""
    local LOG
    local caller="${FUNCNAME[1]}"
    local caller2

    if [[ "$LOG_TERMINAL" != "true" ]] && [[ -z "$LOG_FILE" ]]; then
        return 0
    fi

    [[ $# -ge 3 ]] && JSON="$3"

    # convert to control characters to permit line break and tab escape sequences
    # \n -> line break control character
    MESSAGE="${MESSAGE//\\n/$'\n'}"
    # \t -> TAB control characterj
    MESSAGE="${MESSAGE//\\t/$'\t'}"

    # escape \ to \\  (withtou line break and tab)
    MESSAGE="${MESSAGE//\\/\\\\}"

    # convert to escape sequences to avoid matching [:print:]
    # line break -> \n
    MESSAGE="${MESSAGE//$'\n'/\\n}"
    # TAB -> \t
    MESSAGE="${MESSAGE//$'\t'/\\t}"

    # escape line break to \n
    if [[ "$LOG_ESCAPE_LINE_BREAK" == "true" ]]; then
        # escape non printable characters without line break
        MESSAGE="${MESSAGE//[^[:print:]]/}"
        # escape line break to \\n
        MESSAGE="${MESSAGE//\\n/\\\\n}"
    else
        # escape non printable characters without line break
        MESSAGE="${MESSAGE//[^[:print:]]/}"
    fi
    # escape control characters without line break and tab
    MESSAGE="${MESSAGE//[]/}"

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
        LOG="{\"level\": \"${LEVEL}\", \"timestamp\": \"${DATE}\", \"message\": \"${MESSAGE}\"$JSON}"
    fi
    # output error and debug log to stderr
    case "$caller" in
        "core::log::crit")
            [[ "${CORE_LOG_IO_CRIT}" == "${CORE_LOG_STDOUT}" ]] && __core::log::stdout__ "${CORE_LOG_COLOR_CRIT}" "$LOG"
            [[ "${CORE_LOG_IO_CRIT}" == "${CORE_LOG_STDERR}" ]] && __core::log::stderr__ "${CORE_LOG_COLOR_CRIT}" "$LOG"
            ;;
        "core::log::error")
            [[ "${CORE_LOG_IO_ERROR}" == "${CORE_LOG_STDOUT}" ]] && __core::log::stdout__ "${CORE_LOG_COLOR_ERROR}" "$LOG"
            [[ "${CORE_LOG_IO_ERROR}" == "${CORE_LOG_STDERR}" ]] && __core::log::stderr__ "${CORE_LOG_COLOR_ERROR}" "$LOG"
            ;;
        "core::log::stderr")
            # for ERR trap
            __core::log::stderr__ "${CORE_LOG_COLOR_STDERR}" "$LOG"
            ;;
        "core::log::sig_error")
            __core::log::stderr__ "${CORE_LOG_COLOR_SIGERR}" "$LOG"
            ;;
        "core::log::warn")
            [[ "${CORE_LOG_IO_WARN}" == "${CORE_LOG_STDOUT}" ]] && __core::log::stdout__ "${CORE_LOG_COLOR_WARN}" "$LOG"
            [[ "${CORE_LOG_IO_WARN}" == "${CORE_LOG_STDERR}" ]] && __core::log::stderr__ "${CORE_LOG_COLOR_WARN}" "$LOG"
            ;;
        "core::log::notice")
            [[ "${CORE_LOG_IO_NOTICE}" == "${CORE_LOG_STDOUT}" ]] && __core::log::stdout__ "${CORE_LOG_COLOR_NOTICE}" "$LOG"
            [[ "${CORE_LOG_IO_NOTICE}" == "${CORE_LOG_STDERR}" ]] && __core::log::stderr__ "${CORE_LOG_COLOR_NOTICE}" "$LOG"
            ;;
        "core::log::info")
            [[ "${CORE_LOG_IO_INFO}" == "${CORE_LOG_STDOUT}" ]] && __core::log::stdout__ "${CORE_LOG_COLOR_INFO}" "$LOG"
            [[ "${CORE_LOG_IO_INFO}" == "${CORE_LOG_STDERR}" ]] && __core::log::stderr__ "${CORE_LOG_COLOR_INFO}" "$LOG"
            ;;
        "core::log::debug")
            [[ "${CORE_LOG_IO_DEBUG}" == "${CORE_LOG_STDOUT}" ]] && __core::log::stdout__ "${CORE_LOG_COLOR_DEBUG}" "$LOG"
            [[ "${CORE_LOG_IO_DEBUG}" == "${CORE_LOG_STDERR}" ]] && __core::log::stderr__ "${CORE_LOG_COLOR_DEBUG}" "$LOG"
            ;;
        "__core::log::read_stderr__")
            __core::log::stderr__ "${CORE_LOG_COLOR_STDERR}" "$LOG"
            ;;
        "core::log::stack_trace")
            caller2="${FUNCNAME[2]}"
            case "$caller2" in
                "core::log::crit")
                    [[ "${CORE_LOG_IO_CRIT}" == "${CORE_LOG_STDOUT}" ]] && __core::log::stdout__ "${CORE_LOG_COLOR_CRIT}" "$LOG"
                    [[ "${CORE_LOG_IO_CRIT}" == "${CORE_LOG_STDERR}" ]] && __core::log::stderr__ "${CORE_LOG_COLOR_CRIT}" "$LOG"
                    ;;
                "core::log::error")
                    [[ "${CORE_LOG_IO_ERROR}" == "${CORE_LOG_STDOUT}" ]] && __core::log::stdout__ "${CORE_LOG_COLOR_ERROR}" "$LOG"
                    [[ "${CORE_LOG_IO_ERROR}" == "${CORE_LOG_STDERR}" ]] && __core::log::stderr__ "${CORE_LOG_COLOR_ERROR}" "$LOG"
                    ;;
                "core::log::sig_error")
                    [[ "${CORE_LOG_IO_SIGERR}" == "${CORE_LOG_STDOUT}" ]] && __core::log::stdout__ "${CORE_LOG_COLOR_SIGERR}" "$LOG"
                    [[ "${CORE_LOG_IO_SIGERR}" == "${CORE_LOG_STDERR}" ]] && __core::log::stderr__ "${CORE_LOG_COLOR_SIGERR}" "$LOG"
                    ;;
                *)
                    [[ "${CORE_LOG_IO_TRACE}" == "${CORE_LOG_STDOUT}" ]] && __core::log::stdout__ "${CORE_LOG_COLOR_TRACE}" "$LOG"
                    [[ "${CORE_LOG_IO_TRACE}" == "${CORE_LOG_STDERR}" ]] && __core::log::stderr__ "${CORE_LOG_COLOR_TRACE}" "$LOG"
                    ;;
            esac
            ;;
        *)
            core::log::crit "Unknown caller: $caller"
            ;;
    esac

    return 0
}

# @description Logger for stack trace.
# @arg $1 log level for json
# @arg $2 stack trace message for json
# @exitcode 0
core::log::stack_trace() {
    local LEVEL=""
    local MESSAGE=""
    local caller="${FUNCNAME[1]}"
    local i
    local space=""
    local LOG_JSON_STAcK_TRACE=",\"stack_trace\": ["
    local IS_JSON_FIRST_STACK=true
    local TRACE_FILE_NAME=""
    local TRACE_LINE_NO=""
    local TRACE_FUNC_NAME=""

    if [[ "$LOG_FORMAT" == "json" ]]; then
        [[ $# -lt 2 ]] && echo "Oops: core::log::stack_trace: no arg1 or arg2" >&$core_log_saved_stderr && exit 1
        LEVEL="$1"
        MESSAGE="$2"
    fi

    if [[ "$LOG_STACK_TRACE" == "true" ]]; then
        for ((i=1;i<${#FUNCNAME[*]}; i++)); do
            if [[ ${BASH_SOURCE[$i]} =~ /lib/core/log.sh$ ]]; then
                continue
            fi
            if [[ "$LOG_FORMAT" == "plain" ]]; then
                __core::log__ "${LOG_PREFIX_TRACE}" "${space}${FUNCNAME[$i]}() ${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]}"
                space="  $space"
            fi
            if [[ "$LOG_FORMAT" == "json" ]]; then
                [[ "$IS_JSON_FIRST_STACK" == "false" ]] && LOG_JSON_STAcK_TRACE="$LOG_JSON_STAcK_TRACE,"
                [[ "$IS_JSON_FIRST_STACK" == "true" ]]  && IS_JSON_FIRST_STACK=false
                # escape double quote
                TRACE_FILE_NAME="${BASH_SOURCE[$i]}" && TRACE_FILE_NAME="${TRACE_FILE_NAME//\\n/\\\\n}"
                TRACE_LINE_NO="${BASH_LINENO[$i-1]}" && TRACE_LINE_NO="${TRACE_LINE_NO//\\n/\\\\n}"
                TRACE_FUNC_NAME="${FUNCNAME[$i]}"    && TRACE_FUNC_NAME="${TRACE_FUNC_NAME//\\n/\\\\n}"
                LOG_JSON_STAcK_TRACE="${LOG_JSON_STAcK_TRACE}{\"file\": \"${TRACE_FILE_NAME}\", \"line\": \"${TRACE_LINE_NO}\", \"function\": \"${TRACE_FUNC_NAME}\"}"
            fi
        done
        if [[ "$LOG_FORMAT" == "json" ]]; then
            LOG_JSON_STAcK_TRACE="$LOG_JSON_STAcK_TRACE]"
            __core::log__ "${LEVEL}" "$MESSAGE" "$LOG_JSON_STAcK_TRACE"
        fi
    fi
    return 0
}

# @description Logger for crit.
#
# Alias is defined as ``log::crit``
# @arg $1 string log message.
# @stderr output critical log message and stack trace.
# @exitcode 1
core::log::crit() {
    if [[ "$LOG_CRIT" == "true" ]]; then
        [[ "$LOG_STACK_TRACE" != "true" ]] || [[ "$LOG_FORMAT" != "json" ]] && __core::log__ "${LOG_PREFIX_CRIT}" "${1:-}"
        core::log::stack_trace "${LOG_PREFIX_CRIT}" "${1:-}"
    fi
    exit 1
}

# @description Logger for SIGERR.
#
# @arg $1 string log message.
# @stderr output error log message and stack trace.
# @exitcode 0
core::log::sig_error() {
    if [[ "$LOG_SIGERR" == "true" ]]; then
        [[ "$LOG_STACK_TRACE" != "true" ]] || [[ "$LOG_FORMAT" != "json" ]] && __core::log__ "${LOG_PREFIX_SIGERR}" "${1:-}"
        core::log::stack_trace "${LOG_PREFIX_SIGERR}" "${1:-}"
    fi
    return 0
}

# @description Logger for error.
#
# Alias is defined as ``log::error``
# @arg $1 string log message.
# @stderr output error log message and stack trace.
# @exitcode 0
core::log::error() {
    if [[ "$LOG_ERROR" == "true" ]]; then
        [[ "$LOG_STACK_TRACE" != "true" ]] || [[ "$LOG_FORMAT" != "json" ]] && __core::log__ "${LOG_PREFIX_ERROR}" "${1:-}"
        core::log::stack_trace "${LOG_PREFIX_ERROR}" "${1:-}"
    fi
    return 0
}

# @description Logger for error and exit script.
#
# Alias is defined as ``log::error_exit``
# @arg $1 string log message.
# @stderr output error log message and stack trace.
# @exitcode 1
core::log::error_exit() {
    core::log::error "${1:-}"
    exit 1
}

# @internal
# @description reader for stderr.
__core::log::read_stderr__() {
    while read -r line; do
        [[ "$LOG_STDERR" == "true" ]] && __core::log__ "${LOG_PREFIX_STDERR}" "${line}"
    done
}

# @description print message to stdout to prevent mixing of function output.
#
# Alias is defined as ``log::echo``
# @args echo's args
# @stdout message.
# @exitcode 0
core::log::echo() {
    echo "$@" >&$core_log_saved_stdout
    return 0
}

# @description print message to stderr to prevent mixing of function output.
#
# Alias is defined as ``log::echo_err``
# @args echo's args
# @stdout message.
# @exitcode 0
core::log::echo_err() {
    echo "$@" >&$core_log_saved_stderr
    return 0
}

# @description Logger for warn.
#
# Alias is defined as ``log::warn``
# @arg $1 string log message.
# @stdout Warn log.
# @exitcode 0
core::log::warn() {
    [[ "$LOG_WARN" == "true" ]] && __core::log__ "${LOG_PREFIX_WARN}" "${1:-}"
    return 0
}

# @description Logger for notice.
#
# Alias is defined as ``log::notice``
# @arg $1 string log message.
# @stdout Notice log.
# @exitcode 0
core::log::notice() {
    [[ "$LOG_NOTICE" == "true" ]] && __core::log__ "${LOG_PREFIX_NOTICE}" "${1:-}"
    return 0
}

# @description Logger for info.
#
# Alias is defined as ``log::info``
# @arg $1 string log message.
# @stdout Info log.
# @exitcode 0
core::log::info() {
    [[ "$LOG_INFO" == "true" ]] && __core::log__ "${LOG_PREFIX_INFO}" "${1:-}"
    return 0
}

# @description Logger for debug.
#
# Alias is defined as ``log::debug``
# @arg $1 string log message.
# @arg $2 bool if true, show stackstrace. default: ``false``
# @stderr Debug log.
# @exitcode 0
core::log::debug() {
    local target
    local SHOW_STACK_TRACE=${2:-}

    if [[ "$LOG_DEBUG" == "true" ]]; then
        # supress debug log for specified function name
        if [[ -n "${LOG_DEBUG_NO_FUNC:-}" ]]; then
            for target in ${LOG_DEBUG_NO_FUNC}; do
                if [[ ${FUNCNAME[1]} =~ $target ]]; then
                    return 0
                fi
            done
        fi
        # supress debug log for specified file or directory name
        if [[ -n "${LOG_DEBUG_NO_FILE:-}" ]]; then
            for target in ${LOG_DEBUG_NO_FILE}; do
                if [[ ${BASH_SOURCE[1]} =~ $target ]]; then
                    return 0
                fi
            done
        fi
         [[ "$LOG_STACK_TRACE" != "true" ]] || [[ "$SHOW_STACK_TRACE" != "true" ]] || [[ "$LOG_FORMAT" != "json" ]] && \
            __core::log__ "${LOG_PREFIX_DEBUG}" "$1   [${FUNCNAME[1]}() ${BASH_SOURCE[1]}:${BASH_LINENO[0]}]"
         [[ "$SHOW_STACK_TRACE" == "true" ]] && core::log::stack_trace "${LOG_PREFIX_DEBUG}" "$1"
         return 0
    fi

    # debug log for specified function name
    if [[ -n "${LOG_DEBUG_FUNC:-}" ]]; then
        for target in ${LOG_DEBUG_FUNC}; do
            if [[ ${FUNCNAME[1]} =~ $target ]]; then
                [[ "$LOG_STACK_TRACE" != "true" ]] || [[ "$SHOW_STACK_TRACE" != "true" ]] || [[ "$LOG_FORMAT" != "json" ]] && \
                    __core::log__ "${LOG_PREFIX_DEBUG}" "$*   [${FUNCNAME[1]}() ${BASH_SOURCE[1]}:${BASH_LINENO[0]}]"
                [[ "$SHOW_STACK_TRACE" == "true" ]] && core::log::stack_trace "${LOG_PREFIX_DEBUG}" "$*"
            fi
        done
    fi

    # debug log for specified file or directory name
    if [[ -n "${LOG_DEBUG_FILE:-}" ]]; then
        for target in ${LOG_DEBUG_FILE}; do
            if [[ ${BASH_SOURCE[1]} =~ $target ]]; then
                [[ "$LOG_STACK_TRACE" != "true" ]] || [[ "$SHOW_STACK_TRACE" != "true" ]] || [[ "$LOG_FORMAT" != "json" ]] && \
                    __core::log__ "${LOG_PREFIX_DEBUG}" "$*   [${FUNCNAME[1]}() ${BASH_SOURCE[1]}:${BASH_LINENO[0]}]"
                [[ "$SHOW_STACK_TRACE" == "true" ]] && core::log::stack_trace "${LOG_PREFIX_DEBUG}" "$*"
            fi
        done
    fi
    return 0
}

# @description determine whether debug mode is enabled.
#
# Alias is defined as ``log::is_debug``
# @exitcode 0 if it debug mode is enabled
# @exitcode 1 if it debug mode is disabled
core::log::is_debug() {
    if [[ "$LOG_DEBUG" == "true" ]]; then
        return 0
    fi
    # debug log for specified function name
    if [[ -n "${LOG_DEBUG_FUNC:-}" ]]; then
        for target in ${LOG_DEBUG_FUNC}; do
            if [[ ${FUNCNAME[1]} =~ $target ]]; then
                return 0
            fi
        done
    fi

    # debug log for specified file or directory name
    if [[ -n "${LOG_DEBUG_FILE:-}" ]]; then
        for target in ${LOG_DEBUG_FILE}; do
            if [[ ${BASH_SOURCE[1]} =~ $target ]]; then
                return 0
            fi
        done
    fi
    return 1
}

# @internal
# @description Switching terminal log color.
# If output to terminal, enable log color, otherwise disable log color.
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

# @description Enable error trap
#
# Alias is defined as ``log::enable_err_trap``
# @arg none
# @stderr none
# @exitcode 0
core::log::enable_err_trap() {
    trap 'core::log::sig_error "catch SIGERR (unexpected return code $?)"; [[ "$CORE_LOG_IS_SIGINT" == "true" ]] && exit 1' ERR
}

# @description Disable error trap
#
# Alias is defined as ``log::disable_err_trap``
# @arg none
# @stderr none
# @exitcode 0
core::log::disable_err_trap() {
    trap '[[ "$CORE_LOG_IS_SIGINT" == "true" ]] && exit 1' ERR
}

#### main ####
set -o errtrace

# handle signals
CORE_LOG_IS_SIGINT="false"
core::log::enable_err_trap
trap 'core::log::debug "catch SIGTERM"; core::log::stack_trace; exit 1' TERM
trap 'core::log::debug "catch SIGINT";  CORE_LOG_IS_SIGINT="true"' INT

# can omit core:: in core library
alias log::stack_trace='core::log::stack_trace'
alias log::crit='core::log::crit'
alias log::error='core::log::error'
alias log::error_exit='core::log::error_exit'
alias log::echo='core::log::echo'
alias log::echo_err='core::log::echo_err'
alias log::warn='core::log::warn'
alias log::notice='core::log::notice'
alias log::info='core::log::info'
alias log::debug='core::log::debug'
alias log::is_debug='core::log::is_debug'
alias log::enable_err_trap='core::log::enable_err_trap'
alias log::disable_err_trap='core::log::disable_err_trap'

#### init ####

# NOTE: need to call it before 'exec 2> >(__core::log::read_stderr__)'
__core::log::switch_terminal_color__

# save stdout
exec {core_log_saved_stdout}>&1
# save stderr
exec {core_log_saved_stderr}>&2
# redirect stderr to append header and color settings
exec 2> >(__core::log::read_stderr__)
