#!/usr/bin/env bash
# Copyright 2025 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license
#
# @file util/cmd.sh
# @brief Neobash util/cmd.sh library
# @description
# * library for executing command or function

nb::require "core/log.sh core/arg.sh"
nb::command_check "sleep kill ps timeout"
nb::check_bash_min_version "4.3.0" \
    || core::log::error_exit "bash version 4.3.0 or higher is required for using util/cmd.sh library to use nameref"

# @description Wrapper function for executing specified function or command. It can assign stdout/stderr output to separate variables.
#
# @option --stdout <string> Variable name to assign stdout. (required)
# @option -o <string> Alias for --stdout
# @option --stdout <string> Variable name to assign stderr. (required)
# @option -e <string> Alias for --stderr
# @option --catch-sigerr <true/false> False means drop SIGERR log (optional) DEFAULT:``true``
# @option -s <string> Alias for --catch-sigerr
# @option --clear-env <true/false> True means clearing all environment varialbes when executing command. you cannot use true when executing function. (optional) DEFAULT:``false``
# @option -c <string> Alias for --clear-env
# @option --timeout <int> Timeout(sec). 0 means no timeout.
# @option -t <int> Alias for --timeout
# @stdout None.
# @stderr Debug log.
# @exitcode exit code of specified function or command or timedout=124
util::cmd::exec() {
    local __CATCH_STDOUT_MSG__=""
    local __CATCH_ERR_MSG__=""
    local __CATCH_RETURN_CODE__=1
    local __CATCH_LOG_SIGERR_ORG__="$LOG_SIGERR"
    local __CATCH_CLEAR_ALL_ENV__=""
    local __CATCH_PID__=""
    local __CATCH_TIMEOUT__=""
    local __CATCH_RETRY_COUNT__=0

    core::arg::init_local
    arg::add_option       -l "STDOUT" -o "--stdout" -t "string" -r "true" -h "Stdout Variable"
    arg::add_option_alias -l "STDOUT" -o "-o"
    arg::add_option       -l "STDERR" -o "--stderr" -t "string" -r "true" -h "Stderr Variable"
    arg::add_option_alias -l "STDERR" -o "-e"
    arg::add_option       -l "CATCH_SIGERR" -o "--catch-sigerr" -t "bool" -r "false" -d "true"  -h "Catch SIGERR and output it"
    arg::add_option_alias -l "CATCH_SIGERR" -o "-s"
    arg::add_option       -l "CLEAR_ENV"    -o "--clear-env"    -t "bool" -r "false" -d "false" -h "Clear all environment variables using env -i"
    arg::add_option_alias -l "CLEAR_ENV"    -o "-c"
    arg::add_option       -l "TIMEOUT"      -o "--timeout"      -t "int"  -r "false" -d "0"     -h "command timeout (sec)"
    arg::add_option_alias -l "TIMEOUT"      -o "-t"
    arg::add_option       -l "RETRY_COUNT"    -o "--retry" -t "int" -r "false" -d "0" -h "Retry count. "
    arg::add_option_alias -l "RETRY_COUNT"    -o "-r"
    arg::add_option       -l "RETRY_INTERVAL" -o "--interval" -t "int" -r "false" -d "1" -h "Retry interval time (sec)"
    arg::add_option_alias -l "RETRY_INTERVAL" -o "-i"
    core::arg::parse "$@"

    core::log::debug "stdout val=${ARGS[STDOUT]}"
    core::log::debug "stderr val=${ARGS[STDERR]}"

    local -n __CORE_LOG_STDOUT_RESULT__="${ARGS[STDOUT]}"
    local -n __CORE_LOG_STDERR_RESULT__="${ARGS[STDERR]}"

    [[ "${ARGS[CLEAR_ENV]}" == "true" ]] && __CATCH_CLEAR_ALL_ENV__="env -i"
    if [[ "${ARGS[TIMEOUT]}" -gt 0 ]]; then
        if ( nb::command_check "timeout" ); then
            __CATCH_TIMEOUT__="timeout ${ARGS[TIMEOUT]}"
        else
            log::warn "timeout command not found so the timeout setting will be skipped"
        fi
    fi
    while true; do
        LOG_SIGERR="${ARGS[CATCH_SIGERR]}"
        eval "$(
            (
                $__CATCH_CLEAR_ALL_ENV__ $__CATCH_TIMEOUT__ "${ARG_OTHERS[@]}"
            ) \
            2> >( __CATCH_ERR_MSG__=$(cat);   typeset -p __CATCH_ERR_MSG__) \
            > >( __CATCH_STDOUT_MSG__=$(cat); typeset -p __CATCH_STDOUT_MSG__); \
            __CATCH_RETURN_CODE__=$?;         typeset -p __CATCH_RETURN_CODE__
        )"
        LOG_SIGERR="$__CATCH_LOG_SIGERR_ORG__"
        [[ $__CATCH_RETURN_CODE__ -eq 124 ]] && log::error "Timed out"

        [[ $__CATCH_RETRY_COUNT__ -ge ${ARGS[RETRY_COUNT]} ]] && break
        __CATCH_RETRY_COUNT__=$(( __CATCH_RETRY_COUNT__ + 1 ))
        core::log::debug "rc=$__CATCH_RETRY_COUNT__ retry... [count=$__CATCH_RETRY_COUNT__/${ARGS[RETRY_COUNT]}]"
        core::log::warn "command failed. retrying [$__CATCH_RETRY_COUNT__/${ARGS[RETRY_COUNT]}]...  rc=$__CATCH_RETRY_COUNT__ / dropped stdout="${__RETRY_STDOUT__:-}" / stderr=${__RETRY_STDERR__:-}"
        sleep ${ARGS[RETRY_INTERVAL]}
    done

    core::log::debug "stderr=$__CATCH_ERR_MSG__"
    core::log::debug "stdout=$__CATCH_STDOUT_MSG__"
    core::log::debug "rc=$__CATCH_RETURN_CODE__"

    __CORE_LOG_STDERR_RESULT__="$__CATCH_ERR_MSG__"
    __CORE_LOG_STDOUT_RESULT__="$__CATCH_STDOUT_MSG__"
    return $__CATCH_RETURN_CODE__
}

