#!/usr/bin/env bash
# Copyright 2025 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license
#
# @file util/catch-err.sh
# @brief Neobash util/catch-err.sh library
# @description
# * Provides a wrapper function "util::catch_output" for executing functions and commands.
# * You can assign the stdout and stderr output during function execution to separate variables.

nb::require "core/log.sh core/arg.sh"
nb::check_bash_min_version "4.3.0" \
    || core::log::error_exit "bash version 4.3.0 or higher is required for using util/catch-err.sh library to use nameref"

# @description wrapper function for executing specified function or command
#
# @option --stdout <string> Variable name to assign stdout. (required)
# @option --stdout <string> Variable name to assign stderr. (required)
# @option --catch-sigerr <true/false> False means drop SIGERR log (optional) DEFAULT:``true``
# @option --clear-env <true/false> True means clearing all environment varialbes when executing command. you cannot use true when executing function. (optional) DEFAULT:``false``
# @stdout None.
# @stderr Debug log.
# @exitcode exit code of specified function or command
util::catch_output() {
    local __CATCH_STDOUT_MSG__=""
    local __CATCH_ERR_MSG__=""
    local __CATCH_RETURN_CODE__=""
    local __CATCH_LOG_SIGERR_ORG__="$LOG_SIGERR"
    local __CLEAR_ALL_ENV__=""

    core::arg::init_local
    arg::add_option       -l "STDOUT" -o "--stdout" -t "string" -r "true" -h "Stdout Variable"
    arg::add_option_alias -l "STDOUT" -o "-o"
    arg::add_option       -l "STDERR" -o "--stderr" -t "string" -r "true" -h "Stderr Variable"
    arg::add_option_alias -l "STDERR" -o "-e"
    arg::add_option       -l "CATCH_SIGERR" -o "--catch-sigerr" -t "bool" -r "false" -d "true"  -h "Catch SIGERR and output it"
    arg::add_option       -l "CLEAR_ENV"    -o "--clear-env"    -t "bool" -r "false" -d "false" -h "Clear all environment variables using env -i"
    core::arg::parse "$@"

    core::log::debug "stdout val=${ARGS[STDOUT]}"
    core::log::debug "stderr val=${ARGS[STDERR]}"

    local -n __CORE_LOG_STDOUT_RESULT__="${ARGS[STDOUT]}"
    local -n __CORE_LOG_STDERR_RESULT__="${ARGS[STDERR]}"

    [[ "${ARGS[CLEAR_ENV]}" == "true" ]] && __CLEAR_ALL_ENV__="env -i"
    LOG_SIGERR="${ARGS[CATCH_SIGERR]}"
    eval " $(
        (
            $__CLEAR_ALL_ENV__ "${ARG_OTHERS[@]}"
        ) \
        2> >( __CATCH_ERR_MSG__=$(cat); typeset -p __CATCH_ERR_MSG__) \
        > >( __CATCH_STDOUT_MSG__=$(cat); typeset -p __CATCH_STDOUT_MSG__); \
        __CATCH_RETURN_CODE__=$?; \
        typeset -p __CATCH_RETURN_CODE__
    )"
    LOG_SIGERR="$__CATCH_LOG_SIGERR_ORG__"

    core::log::debug "stderr=$__CATCH_ERR_MSG__"
    core::log::debug "stdout=$__CATCH_STDOUT_MSG__"
    core::log::debug "rc=$__CATCH_RETURN_CODE__"

    __CORE_LOG_STDERR_RESULT__="$__CATCH_ERR_MSG__"
    __CORE_LOG_STDOUT_RESULT__="$__CATCH_STDOUT_MSG__"
    return $__CATCH_RETURN_CODE__
}

