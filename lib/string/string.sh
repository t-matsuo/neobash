#!/usr/bin/env bash
# Copyright 2025 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license
#
# @file string/string.sh
# @brief Neobash string/string.sh library
# @description
# * library about string

# @description check if the variable is start with specified string or not
#
# @option --string <string> Target string. (required)
# @option -s <string> Alias for --string
# @option --match <string> String to match. (required)
# @option -m <string> Alias for --match
# @stdout None.
# @stderr None.
# @exitcode 0 Matched.
# @exitcode 1 Not matched.
string::start_with() {
    core::arg::init_local
    arg::add_option       -l "STRING" -o "--string" -t "string" -r "true" -h "target string"
    arg::add_option_alias -l "STRING" -o "-s"
    arg::add_option       -l "MATCH"  -o "--match"  -t "string" -r "true" -h "string to match"
    arg::add_option_alias -l "MATCH"  -o "-m"
    core::arg::parse "$@"

    [[ "${ARGS[STRING]}" == "${ARGS[MATCH]}"* ]] && return 0
    return 1
}

# @description check if the variable is end with specified string or not
#
# @option --string <string> Target string. (required)
# @option -s <string> Alias for --string
# @option --match <string> String to match. (required)
# @option -m <string> Alias for --match
# @stdout None.
# @stderr None.
# @exitcode 0 Matched.
# @exitcode 1 Not matched.
string::end_with() {
    core::arg::init_local
    arg::add_option       -l "STRING" -o "--string" -t "string" -r "true" -h "string to check"
    arg::add_option_alias -l "STRING" -o "-s"
    arg::add_option       -l "MATCH"  -o "--match"  -t "string" -r "true" -h "string to match"
    arg::add_option_alias -l "MATCH"  -o "-m"
    core::arg::parse "$@"

    [[ "${ARGS[STRING]}" == *"${ARGS[MATCH]}" ]] && return 0
    return 1
}

# @description check if the variable is include specified string or not
#
# @option --string <string> Target string. (required)
# @option -s <string> Alias for --string
# @option --match <string> String to match. (required)
# @option -m <string> Alias for --match
# @stdout None.
# @stderr None.
# @exitcode 0 Matched.
# @exitcode 1 Not matched.
string::include() {
    core::arg::init_local
    arg::add_option       -l "STRING" -o "--string" -t "string" -r "true" -h "string to check"
    arg::add_option_alias -l "STRING" -o "-s"
    arg::add_option       -l "MATCH"  -o "--match"  -t "string" -r "true" -h "string to match"
    arg::add_option_alias -l "MATCH"  -o "-m"
    core::arg::parse "$@"

    [[ "${ARGS[STRING]}" == *"${ARGS[MATCH]}"* ]] && return 0
    return 1
}