#!/usr/bin/env bash
# Copyright 2025 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license
# shellcheck disable=SC2031,SC2030
#
# @file io/qa.sh
# @brief Neobash io/qa.sh library
# @description
# * waiting for user's y(yes) or n(no) input

nb::require "core/log.sh core/arg.sh"

# @description waiting for y(yes) or n(no) or q(quit). /dev/tty is used to input.
#
# @option --message <string> message to output to terminal. (option) DEFAULT: empty
# @option -m <string> Alias for --message
# @option --default <string> default value if input is empty. y/Y/yes or n/N/no or q/Q/quit are required. (option) DEFAULT: n
# @option -d <string> Alias for --default
# @option --timeout <int> timeout(sec). (option) DEFAULT: 120(sec)
# @option -t <int> Alias for --timeout
# @stdout y or n or q
# @stderr error log.
# @exitcode 0 OK
# @exitcode 1 Erro
# @exitcode 125 Quit
# @exitcode 142 Timed out
io::qa() {

    local __UTIL_QA_YN__=""
    local __UTIL_QA_INPUT__=""
    local __UTIL_QA_YN_MSG__=""

    core::arg::init_local
    arg::add_option       -l "MESSAGE" -o "--messags" -t "string" -r "false" -d "" -h "message"
    arg::add_option_alias -l "MESSAGE" -o "-m"
    arg::add_option       -l "DEFAULT" -o "--default" -t "string" -r "false" -d "n"   -h "default value. y/Y/yes or n/N/no or q/Q/quit"
    arg::add_option_alias -l "DEFAULT" -o "-d"
    arg::add_option       -l "TIMEOUT" -o "--timeout" -t "int" -r "false" -d "120"   -h "timeout (sec)"
    arg::add_option_alias -l "TIMEOUT" -o "-t"
    core::arg::parse "$@"

    case "${ARGS[DEFAULT]}" in
    "y" | "Y" | "yes")
        __UTIL_QA_YN__="y"
        __UTIL_QA_YN_MSG__="Y/n/q"
        ;;
    "n" | "N" | "no")
        __UTIL_QA_YN__="n"
        __UTIL_QA_YN_MSG__="y/N/q"
        ;;
    "q" | "Q" | "quit")
        __UTIL_QA_YN__="q"
        __UTIL_QA_YN_MSG__="y/n/Q"
        ;;
    *)
        core::log::error "--default requires 'y' or 'Y' or 'yes' or 'n' or 'N' or 'no' or 'q' or 'Q'"
        return 1
        ;;
    esac

    while true; do
        [[ -n "${ARGS[MESSAGE]}" ]] && echo "${ARGS[MESSAGE]}" >&$core_log_saved_stdout
        echo -n "$__UTIL_QA_YN_MSG__: " >&$core_log_saved_stdout
        if ! read -t "${ARGS[TIMEOUT]}" __UTIL_QA_INPUT__ </dev/tty; then
            core::log::error "Timedout"
            return 142
        fi
        case "$__UTIL_QA_INPUT__" in
        "")
            break
            ;;
        "y" | "Y" | "yes")
            __UTIL_QA_YN__="y"
            break
            ;;
        "n" | "N" | "no")
            __UTIL_QA_YN__="n"
            break
            ;;
        "q" | "Q" | "quit")
            __UTIL_QA_YN__="q"
            break
            ;;
        *)
            echo "Invalid input: $__UTIL_QA_INPUT__" >&$core_log_saved_stderr
            __UTIL_QA_INPUT__=""
            ;;
        esac
    done
    echo "$__UTIL_QA_YN__"
    [[ "$__UTIL_QA_YN__" == "q" ]] && return 125
    return 0
}
