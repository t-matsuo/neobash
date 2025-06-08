#!/usr/bin/env bash
# Copyright 2025 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license

nb::require "core/log.sh core/arg.sh"
nb::check_bash_min_version "4.3.0" \
    || core::log::error_exit "bash version 4.3.0 or higher is required for using util/catch-err.sh library to use nameref"

util::catch_output() {
    local __CATCH_STDOUT_MSG__=""
    local __CATCH_ERR_MSG__=""
    local __CATCH_RETURN_CODE__=""

    core::arg::init_local
    arg::add_option       -l "STDOUT" -o "--stdout" -t "string" -r "true" -h "Stdout Variable"
    arg::add_option_alias -l "STDOUT" -o "-o"
    arg::add_option       -l "STDERR" -o "--stderr" -t "string" -r "true" -h "Stderr Variable"
    arg::add_option_alias -l "STDERR" -o "-e"
    core::arg::parse "$@"

    core::log::debug "stdout val=${ARGS[STDOUT]}"
    core::log::debug "stderr val=${ARGS[STDERR]}"

    local -n __CORE_LOG_STDOUT_RESULT__="${ARGS[STDOUT]}"
    local -n __CORE_LOG_STDERR_RESULT__="${ARGS[STDERR]}"

    eval " $(
        (
            "${ARG_OTHERS[@]}"
        ) \
        2> >( __CATCH_ERR_MSG__=$(cat); typeset -p __CATCH_ERR_MSG__) \
        > >( __CATCH_STDOUT_MSG__=$(cat); typeset -p __CATCH_STDOUT_MSG__); \
        __CATCH_RETURN_CODE__=$?; \
        typeset -p __CATCH_RETURN_CODE__
    )"

    core::log::debug "stderr=$__CATCH_ERR_MSG__"
    core::log::debug "stdout=$__CATCH_STDOUT_MSG__"
    core::log::debug "rc=$__CATCH_RETURN_CODE__"

    __CORE_LOG_STDERR_RESULT__="$__CATCH_ERR_MSG__"
    __CORE_LOG_STDOUT_RESULT__="$__CATCH_STDOUT_MSG__"
    return $__CATCH_RETURN_CODE__
}

