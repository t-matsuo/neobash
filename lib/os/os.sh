#!/usr/bin/env bash
# Copyright 2025 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license
#
# @file os/os.sh
# @brief Neobash os/os.sh library
# @description
# * library about os

nb::require "core/log.sh core/arg.sh"

# @description check if the variable is defined or not
#
# @option --name <string> Variable name to assign stdout. If it is not specified, messages output to stdout. (required)
# @option -n <string> Alias for --name
# @option --enable-error <bool> If true, enable error message when the variable is not defined. (option) DEFAULT:``true``
# @option -r <bool> Alias for --enable-error
# @option --exit <bool> If true, exit 1 instead of return 1, when the variable is not defined. (option) DEFAULT:``false``
# @option -e <bool> Alias for --exit
# @stdout None.
# @stderr Error message if the variable is not define and --enable-error is true.
# @exitcode 0 The variable is defined.
# @exitcode 1 The variable is not defined.
os::check_var() {
    core::arg::init_local
    arg::add_option       -l "NAME" -o "--name" -t "string" -r "true" -h "Variable name"
    arg::add_option_alias -l "NAME" -o "-n"
    arg::add_option       -l "ENABLE_ERROR" -o "--enable-error" -t "bool" -r "false" -d "true" -h "if true, enable error message when the variable is not defined"
    arg::add_option_alias -l "ENABLE_ERROR" -o "-r"
    arg::add_option       -l "EXIT" -o "--exit" -t "bool" -r "false" -d "false" -h "if true, exit when the variable is not defined"
    arg::add_option_alias -l "EXIT" -o "-e"
    core::arg::parse "$@"

    [[ -v "${ARGS[NAME]}" ]] && return 0

    [[ "${ARGS[ENABLE_ERROR]}" == true ]] && core::log::error "variable ${ARGS[NAME]} is not defined"
    [[ "${ARGS[EXIT]}" == "true" ]] && exit 1
    return 1
}

# @description check if the function is defined or not
#
# @option --name <string> Function name to check. (required)
# @option -n <string> Alias for --name
# @option --enable-error <bool> If true, enable error message when the function is not defined. (option) DEFAULT:``true``
# @option -r <bool> Alias for --enable-error
# @option --exit <bool> If true, exit 1 instead of return 1, when the function is not defined. (option) DEFAULT:``false``
# @option -e <bool> Alias for --exit
# @stdout None.
# @stderr Error message if the function is not defined and --enable-error is true.
# @exitcode 0 The function is defined.
# @exitcode 1 The function is not defined.
os::check_func() {
    core::arg::init_local
    arg::add_option       -l "NAME" -o "--name" -t "string" -r "true" -h "Function name"
    arg::add_option_alias -l "NAME" -o "-n"
    arg::add_option       -l "ENABLE_ERROR" -o "--enable-error" -t "bool" -r "false" -d "true" -h "if true, enable error message when the function is not defined"
    arg::add_option_alias -l "ENABLE_ERROR" -o "-r"
    arg::add_option       -l "EXIT" -o "--exit" -t "bool" -r "false" -d "false" -h "if true, exit when the function is not defined"
    arg::add_option_alias -l "EXIT" -o "-e"
    core::arg::parse "$@"

    if declare -F "${ARGS[NAME]}" >/dev/null 2>&1; then
        return 0
    fi

    [[ "${ARGS[ENABLE_ERROR]}" == true ]] && core::log::error "function ${ARGS[NAME]} is not defined"
    [[ "${ARGS[EXIT]}" == "true" ]] && exit 1
    return 1
}

