#!/usr/bin/env bash
# Copyright 2024 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT license: http://opensource.org/licenses/mit-license

# @file core/log.sh
# @brief Neobash core logging library
# @description
# The neobash core logging library provides structured log output for bash scripts.
# It supports multiple severity levels, optional stack traces, configurable output
# destinations, and both plain and JSON formatting.
#
# Features:
# * Output logs of various types: debug, info, notice, warn, error, crit, and stacktrace.
# * Log format can be `plain` or `json`.
# * Log messages are colored and timestamped by default when writing to a terminal.
# * Control characters in log messages are removed.
# * Output destination can be stdout, stderr, and/or a file.
# * Unexpected SIGINT, SIGTERM, and SIGERR signals are caught and logged with a stack trace.
#
# The behavior of this library is controlled by environment variables.
#
# ## Log level switches
# Set each variable to `true` or `false`.
# * `LOG_CRIT`: Enable CRIT log output. default: `true`
# * `LOG_ERROR`: Enable ERROR log output. default: `true`
# * `LOG_WARN`: Enable WARN log output. default: `true`
# * `LOG_NOTICE`: Enable NOTICE log output. default: `true`
# * `LOG_INFO`: Enable INFO log output. default: `true`
# * `LOG_DEBUG`: Enable DEBUG log output. default: `false`
# * `LOG_STDERR`: Enable stderr capture log output. default: `true`
# * `LOG_SIGERR`: Enable SIGERR log output. default: `true`
# * `LOG_SIGTERM`: Enable SIGTERM log output. default: `true`
#
# ## Log format settings
# * `LOG_FORMAT`: Set the log format to `plain` or `json`. default: `plain`
# * `LOG_STACK_TRACE`: Enable stack traces for CRIT, DEBUG, and ERROR logs. default: `true`
# * `LOG_TIMESTAMP`: Enable timestamps on all logs. default: `true`
# * `LOG_TIMESTAMP_FORMAT`: Set the timestamp format using printf formatting. default: `%F-%T%z`
# * `LOG_ESCAPE_LINE_BREAK`: Escape line breaks and `\n` to `\\n`. default: `true`
#
# ## Log output destinations
# * `LOG_TERMINAL`: Enable output to the terminal. default: `true`
# * `LOG_FILE`: Set the log file path. default: empty (no file output)
#
# ## Log prefixes
# * `LOG_PREFIX_CRIT`: Prefix for CRIT logs. default: `CRIT`
# * `LOG_PREFIX_ERROR`: Prefix for ERROR logs. default: `ERROR`
# * `LOG_PREFIX_WARN`: Prefix for WARN logs. default: `WARN`
# * `LOG_PREFIX_NOTICE`: Prefix for NOTICE logs. default: `NOTICE`
# * `LOG_PREFIX_INFO`: Prefix for INFO logs. default: `INFO`
# * `LOG_PREFIX_DEBUG`: Prefix for DEBUG logs. default: `DEBUG`
# * `LOG_PREFIX_TRACE`: Prefix for TRACE logs. default: `TRACE`
# * `LOG_PREFIX_STDERR`: Prefix for stderr capture logs. default: `STDERR`
# * `LOG_PREFIX_SIGNAL`: Prefix for signal logs. default: `SIGNAL`
#
# ## Debug log filters
# * `LOG_DEBUG_FUNC`: Output debug logs only from matching function names. default: `""`
# * `LOG_DEBUG_FILE`: Output debug logs only from matching file or directory names. default: `""`
# * `LOG_DEBUG_NO_FUNC`: Suppress debug logs from matching function names. default: `""`
# * `LOG_DEBUG_NO_FILE`: Suppress debug logs from matching file or directory names. default: `""`
#
# Example: enable debug log and disable stack trace.
# ```bash
# LOG_DEBUG=true LOG_STACK_TRACE=false ./myscript.sh
# ```
#
# Example: enable debug log for specific functions.
# ```bash
# LOG_DEBUG_FUNC="mylib::get_xxx mylib::set_xxx" ./myscript.sh
# ```
#
# Example: enable debug log for a specific file.
# ```bash
# LOG_DEBUG_FILE="mylib/myutil.sh" ./myscript.sh
# ```

#### Logging Parameters ####
readonly CORE_LOG_COLOR_ESC="\x1B["
readonly CORE_LOG_COLOR_DEFAULT=0
# Foreground color palette
readonly CORE_LOG_COLOR_BLACK=30
readonly CORE_LOG_COLOR_RED=31
readonly CORE_LOG_COLOR_GREEN=32
readonly CORE_LOG_COLOR_YELLOW=33
readonly CORE_LOG_COLOR_BLUE=34
readonly CORE_LOG_COLOR_MAGENTA=35
readonly CORE_LOG_COLOR_CYAN=36
readonly CORE_LOG_COLOR_WHITE=37
# Background color palette
readonly CORE_LOG_BCOLOR_BLACK=40
readonly CORE_LOG_BCOLOR_RED=41
readonly CORE_LOG_BCOLOR_GREEN=42
readonly CORE_LOG_BCOLOR_YELLOW=43
readonly CORE_LOG_BCOLOR_BLUE=44
readonly CORE_LOG_BCOLOR_MAGENTA=45
readonly CORE_LOG_BCOLOR_CYAN=46
readonly CORE_LOG_BCOLOR_WHITE=47
# Text decorations
readonly CORE_LOG_DECO_BOLD=1
readonly CORE_LOG_DECO_LIGHT=2
readonly CORE_LOG_DECO_ITALIC=3
readonly CORE_LOG_DECO_UNDERLINE=4
readonly CORE_LOG_DECO_SLOW_BLINK=5
readonly CORE_LOG_DECO_FALST_BLINK=6
readonly CORE_LOG_DECO_REVERSE=7
readonly CORE_LOG_DECO_CONCEAL=8
readonly CORE_LOG_DECO_STRIKE=9


### Logging Settings
# Log level switches
: "${LOG_CRIT:=true}"
: "${LOG_ERROR:=true}"
: "${LOG_WARN:=true}"
: "${LOG_NOTICE:=true}"
: "${LOG_INFO:=true}"
: "${LOG_DEBUG:=false}"
: "${LOG_STDERR:=true}"
: "${LOG_SIGERR:=true}"
: "${LOG_SIGTERM:=true}"

# Stack trace switch
: "${LOG_STACK_TRACE:=true}"

# Log format (plain or json)
: "${LOG_FORMAT:=plain}"

# Timestamp switches
: "${LOG_TIMESTAMP:=true}"
: "${LOG_TIMESTAMP_FORMAT:=%F-%T%z}"

# Line break escaping
: "${LOG_ESCAPE_LINE_BREAK:=true}"

# Terminal output switch
: "${LOG_TERMINAL:=true}"
# Log file path
: "${LOG_FILE:=""}"

# Debug log filters
: "${LOG_DEBUG_FUNC:=}"
: "${LOG_DEBUG_FILE:=}"
: "${LOG_DEBUG_NO_FUNC:=}"
: "${LOG_DEBUG_NO_FILE:=}"

declare -g LOG_COLOR_STDOUT
declare -g LOG_COLOR_STDERR

# Level color settings
declare -g CORE_LOG_COLOR_CRIT="${CORE_LOG_DECO_REVERSE}"
declare -g CORE_LOG_COLOR_ERROR="${CORE_LOG_BCOLOR_RED};${CORE_LOG_DECO_BOLD};${CORE_LOG_COLOR_WHITE}"
declare -g CORE_LOG_COLOR_WARN="${CORE_LOG_COLOR_RED}"
declare -g CORE_LOG_COLOR_NOTICE="${CORE_LOG_COLOR_CYAN}"
declare -g CORE_LOG_COLOR_INFO="${CORE_LOG_COLOR_GREEN}"
declare -g CORE_LOG_COLOR_DEBUG="${CORE_LOG_COLOR_YELLOW}"
declare -g CORE_LOG_COLOR_TRACE="${CORE_LOG_DECO_UNDERLINE}"
declare -g CORE_LOG_COLOR_STDERR="${CORE_LOG_BCOLOR_MAGENTA};${CORE_LOG_DECO_BOLD}"
declare -g CORE_LOG_COLOR_SIGNAL="${CORE_LOG_BCOLOR_BLUE};${CORE_LOG_DECO_BOLD}"

# Output stream settings
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
: "${CORE_LOG_IO_SIGNAL:=$CORE_LOG_STDERR}"

# Log prefix settings
: "${LOG_PREFIX_CRIT:=CRIT}"
: "${LOG_PREFIX_ERROR:=ERROR}"
: "${LOG_PREFIX_WARN:=WARN}"
: "${LOG_PREFIX_NOTICE:=NOTICE}"
: "${LOG_PREFIX_INFO:=INFO}"
: "${LOG_PREFIX_DEBUG:=DEBUG}"
: "${LOG_PREFIX_TRACE:=TRACE}"
: "${LOG_PREFIX_STDERR:=STDERR}"
: "${LOG_PREFIX_SIGNAL:=SIGNAL}"
#### Logging Parameters End ####

# @internal
# @description Print a log message with ANSI color escape sequences.
# @arg $1 string SGR color/style code.
# @arg $2 string Message to print.
# @stdout none.
# @stderr none.
__core::log::color_terminal__() {
    local COLOR="$1"
    local LOG="$2"
    echo -e "${CORE_LOG_COLOR_ESC}${COLOR}m${LOG}${CORE_LOG_COLOR_ESC}${CORE_LOG_COLOR_DEFAULT}m"
    return 0
}

# @internal
# @description Output a log message to the saved stdout stream.
# @arg $1 string SGR color/style code.
# @arg $2 string Message to print.
# @stdout Formatted message when terminal output is enabled.
# @stderr none.
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
    [[ -n "$LOG_FILE" ]] && echo -e "$LOG" >> "$LOG_FILE"
    return 0
}

# @internal
# @description Output a log message to the saved stderr stream.
# @arg $1 string SGR color/style code.
# @arg $2 string Message to print.
# @stdout none.
# @stderr Formatted message when terminal output is enabled.
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
    [[ -n "$LOG_FILE" ]] && echo -e "$LOG" >> "$LOG_FILE"
    return 0
}

# @internal
# @description Core log formatter and dispatcher.
# Builds the final log string with timestamp, level prefix, and message,
# then dispatches it to stdout or stderr according to the caller.
# @arg $1 string Log level prefix (may be empty).
# @arg $2 string Log message.
# @arg $3 string Optional JSON snippet appended when LOG_FORMAT is json.
# @stdout Formatted log when the caller routes to stdout.
# @stderr Formatted log when the caller routes to stderr.
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
         [[ -n "${LEVEL}" ]] && LEVEL+=" "
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
            __core::log::stderr__ "${CORE_LOG_COLOR_SIGNAL}" "$LOG"
            ;;
        "core::log::sig_term")
            __core::log::stderr__ "${CORE_LOG_COLOR_SIGNAL}" "$LOG"
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
                "core::log::sig_error" | "core::log::sig_term" )
                    [[ "${CORE_LOG_IO_SIGNAL}" == "${CORE_LOG_STDOUT}" ]] && __core::log::stdout__ "${CORE_LOG_COLOR_SIGNAL}" "$LOG"
                    [[ "${CORE_LOG_IO_SIGNAL}" == "${CORE_LOG_STDERR}" ]] && __core::log::stderr__ "${CORE_LOG_COLOR_SIGNAL}" "$LOG"
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

# @description Print a stack trace.
# Used internally by CRIT, DEBUG, and ERROR log functions when LOG_STACK_TRACE is enabled.
# In JSON mode, the trace is appended to the log message passed to this function.
# @arg $1 string Log level prefix used in JSON output.
# @arg $2 string Log message used in JSON output.
# @stdout Stack trace frames in plain mode.
# @stderr none.
# @exitcode 0 Always.
core::log::stack_trace() {
    local LEVEL=""
    local MESSAGE=""
    local caller="${FUNCNAME[1]}"
    local i
    local space=""
    local LOG_JSON_STACK_TRACE=",\"stack_trace\": ["
    local IS_JSON_FIRST_STACK=true
    local TRACE_FILE_NAME=""
    local TRACE_LINE_NO=""
    local TRACE_FUNC_NAME=""

    if [[ "$LOG_FORMAT" == "json" ]]; then
        LEVEL="${1:-none}"
        MESSAGE="${2:-none}"
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
                [[ "$IS_JSON_FIRST_STACK" == "false" ]] && LOG_JSON_STACK_TRACE="$LOG_JSON_STACK_TRACE,"
                [[ "$IS_JSON_FIRST_STACK" == "true" ]]  && IS_JSON_FIRST_STACK=false
                # escape double quote
                TRACE_FILE_NAME="${BASH_SOURCE[$i]}" && TRACE_FILE_NAME="${TRACE_FILE_NAME//\\n/\\\\n}"
                TRACE_LINE_NO="${BASH_LINENO[$i-1]}" && TRACE_LINE_NO="${TRACE_LINE_NO//\\n/\\\\n}"
                TRACE_FUNC_NAME="${FUNCNAME[$i]}"    && TRACE_FUNC_NAME="${TRACE_FUNC_NAME//\\n/\\\\n}"
                LOG_JSON_STACK_TRACE="${LOG_JSON_STACK_TRACE}{\"file\": \"${TRACE_FILE_NAME}\", \"line\": \"${TRACE_LINE_NO}\", \"function\": \"${TRACE_FUNC_NAME}\"}"
            fi
        done
        if [[ "$LOG_FORMAT" == "json" ]]; then
            LOG_JSON_STACK_TRACE="$LOG_JSON_STACK_TRACE]"
            __core::log__ "${LEVEL}" "$MESSAGE" "$LOG_JSON_STACK_TRACE"
        fi
    fi
    return 0
}

# @description Log a critical message and exit the script.
# Alias: `log::crit`.
# @arg $1 string Log message.
# @stderr Critical log message and stack trace.
# @exitcode 1 Always.
core::log::crit() {
    if [[ "$LOG_CRIT" == "true" ]]; then
        [[ "$LOG_STACK_TRACE" != "true" ]] || [[ "$LOG_FORMAT" != "json" ]] && __core::log__ "${LOG_PREFIX_CRIT}" "${1:-}"
        core::log::stack_trace "${LOG_PREFIX_CRIT}" "${1:-}"
    fi
    exit 1
}

# @description Log a SIGERR signal event.
# This function is invoked by the ERR trap when a command returns a non-zero exit code unexpectedly.
# @arg $1 string Log message.
# @stderr Signal log message and stack trace.
# @exitcode 0 Always.
core::log::sig_error() {
    if [[ "$LOG_SIGERR" == "true" ]]; then
        [[ "$LOG_STACK_TRACE" != "true" ]] || [[ "$LOG_FORMAT" != "json" ]] && __core::log__ "${LOG_PREFIX_SIGNAL}" "${1:-}"
        core::log::stack_trace "${LOG_PREFIX_SIGNAL}" "${1:-}"
    fi
    return 0
}

# @description Log a SIGTERM signal event.
# This function is invoked by the TERM trap.
# @arg $1 string Log message.
# @stderr Signal log message and stack trace.
# @exitcode 0 Always.
core::log::sig_term() {
    if [[ "$LOG_SIGTERM" == "true" ]]; then
        [[ "$LOG_STACK_TRACE" != "true" ]] || [[ "$LOG_FORMAT" != "json" ]] && __core::log__ "${LOG_PREFIX_SIGNAL}" "${1:-}"
        core::log::stack_trace "${LOG_PREFIX_SIGNAL}" "${1:-}"
    fi
    return 0
}

# @description Log an error message.
# Alias: `log::error`.
# @arg $1 string Log message.
# @stderr Error log message and stack trace.
# @exitcode 0 Always.
core::log::error() {
    if [[ "$LOG_ERROR" == "true" ]]; then
        [[ "$LOG_STACK_TRACE" != "true" ]] || [[ "$LOG_FORMAT" != "json" ]] && __core::log__ "${LOG_PREFIX_ERROR}" "${1:-}"
        core::log::stack_trace "${LOG_PREFIX_ERROR}" "${1:-}"
    fi
    return 0
}

# @description Log an error message and exit the script.
# Alias: `log::error_exit`.
# @arg $1 string Log message.
# @arg $2 int Exit code. default: `1`.
# @stderr Error log message and stack trace.
# @exitcode $2 The supplied exit code, or `1` by default.
# @see core::log::error
core::log::error_exit() {
    core::log::error "${1:-}"
    exit "${2:-1}"
}

# @internal
# @description Read redirected stderr lines and prefix them with the STDERR log level.
# This function runs in a subprocess created by `exec 2> >(...)`.
# @stdin Raw stderr lines from the script.
# @stdout none.
# @stderr Prefixed stderr log messages.
__core::log::read_stderr__() {
    while read -r line; do
        [[ "$LOG_STDERR" == "true" ]] && __core::log__ "${LOG_PREFIX_STDERR}" "${line}"
    done
}

# @description Print a message to the original stdout.
# Use this instead of plain `echo` inside functions to avoid having the output
# captured by the library's stderr redirection.
# Alias: `log::echo`.
# @arg $@ string Arguments forwarded to `echo`.
# @stdout The supplied message.
# @stderr none.
# @exitcode 0 Always.
core::log::echo() {
    echo "$@" >&$core_log_saved_stdout
    return 0
}

# @description Print a message to the original stderr.
# Use this instead of plain `echo >&2` inside functions to avoid having the output
# captured by the library's stderr redirection.
# Alias: `log::echo_err`.
# @arg $@ string Arguments forwarded to `echo`.
# @stderr The supplied message.
# @stdout none.
# @exitcode 0 Always.
core::log::echo_err() {
    echo "$@" >&$core_log_saved_stderr
    return 0
}

# @description Log a warning message.
# Alias: `log::warn`.
# @arg $1 string Log message.
# @stdout Warning log.
# @stderr none.
# @exitcode 0 Always.
core::log::warn() {
    [[ "$LOG_WARN" == "true" ]] && __core::log__ "${LOG_PREFIX_WARN}" "${1:-}"
    return 0
}

# @description Log a notice message.
# Alias: `log::notice`.
# @arg $1 string Log message.
# @stdout Notice log.
# @stderr none.
# @exitcode 0 Always.
core::log::notice() {
    [[ "$LOG_NOTICE" == "true" ]] && __core::log__ "${LOG_PREFIX_NOTICE}" "${1:-}"
    return 0
}

# @description Log an informational message.
# Alias: `log::info`.
# @arg $1 string Log message.
# @stdout Info log.
# @stderr none.
# @exitcode 0 Always.
core::log::info() {
    [[ "$LOG_INFO" == "true" ]] && __core::log__ "${LOG_PREFIX_INFO}" "${1:-}"
    return 0
}

# @description Log a debug message.
# Output is controlled by LOG_DEBUG and the debug filters (LOG_DEBUG_FUNC,
# LOG_DEBUG_FILE, LOG_DEBUG_NO_FUNC, LOG_DEBUG_NO_FILE).
# Alias: `log::debug`.
# @arg $1 string Log message.
# @arg $2 bool Whether to append a stack trace. default: `false`.
# @stderr Debug log.
# @exitcode 0 Always.
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

# @description Determine whether debug logging is enabled for the caller.
# Returns success when LOG_DEBUG is true, or when the caller matches one of the
# debug filters (LOG_DEBUG_FUNC or LOG_DEBUG_FILE).
# Alias: `log::is_debug`.
# @stdout none.
# @stderr none.
# @exitcode 0 If debug logging is enabled.
# @exitcode 1 If debug logging is disabled.
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
# @description Detect the output destination and enable or disable color accordingly.
# Colors are enabled when stdout/stderr is connected to a terminal, and disabled
# when they are redirected to a pipe or file.
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

# @description Enable the ERR trap.
# Unexpected non-zero return codes will be logged via `core::log::sig_error`.
# Alias: `log::enable_err_trap`.
# @stdout none.
# @stderr none.
# @exitcode 0 Always.
core::log::enable_err_trap() {
    trap 'core::log::sig_error "catch SIGERR (unexpected return code $?)"; [[ "$CORE_LOG_IS_SIGINT" == "true" ]] && exit 1' ERR
}

# @description Disable the ERR trap while preserving the SIGINT exit behavior.
# Alias: `log::disable_err_trap`.
# @stdout none.
# @stderr none.
# @exitcode 0 Always.
core::log::disable_err_trap() {
    trap '[[ "$CORE_LOG_IS_SIGINT" == "true" ]] && exit 1' ERR
}

# @description Enable the TERM trap.
# Received SIGTERM signals will be logged via `core::log::sig_term` and the
# script will exit with code 143.
# Alias: `log::enable_term_trap`.
# @stdout none.
# @stderr none.
# @exitcode 0 Always.
core::log::enable_term_trap() {
    trap 'core::log::sig_term "catch SIGTERM. exit 143"; exit 143' TERM
}

# @description Disable the TERM trap.
# Alias: `log::disable_term_trap`.
# @stdout none.
# @stderr none.
# @exitcode 0 Always.
core::log::disable_term_trap() {
    trap TERM
}

# @description Disable all log prefixes.
# Alias: `log::disable_prefixes`.
# @stdout none.
# @stderr none.
# @exitcode 0 Always.
core::log::disable_prefixes() {
    core::log::debug "disable all log prefixes"
    LOG_PREFIX_CRIT=""
    LOG_PREFIX_ERROR=""
    LOG_PREFIX_WARN=""
    LOG_PREFIX_NOTICE=""
    LOG_PREFIX_INFO=""
    LOG_PREFIX_DEBUG=""
    LOG_PREFIX_TRACE=""
    LOG_PREFIX_STDERR=""
    LOG_PREFIX_SIGNAL=""
}

# @description Disable all decorations such as color and timestamp.
# Alias: `log::disable_decorations`.
# @stdout none.
# @stderr none.
# @exitcode 0 Always.
core::log::disable_decorations() {
    core::log::debug "disable decorations"
    LOG_COLOR_STDOUT="false"
    LOG_COLOR_STDERR="false"
    LOG_TIMESTAMP="false"
}

#### main ####
set -o errtrace

# handle signals
CORE_LOG_IS_SIGINT="false"
core::log::enable_err_trap
core::log::enable_term_trap
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
alias log::enable_term_trap='core::log::enable_term_trap'
alias log::disable_term_trap='core::log::disable_term_trap'
alias core::log::disable_prefixes='log::disable_prefixes'
alias core::log::disable_decorations='log::disable_decorations'

#### init ####

# NOTE: need to call it before 'exec 2> >(__core::log::read_stderr__)'
__core::log::switch_terminal_color__

# save stdout
exec {core_log_saved_stdout}>&1
# save stderr
exec {core_log_saved_stderr}>&2
# redirect stderr to append header and color settings
exec 2> >(__core::log::read_stderr__)
