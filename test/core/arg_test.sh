#!/usr/bin/env bash

set_up() {
  ROOT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"
  source "$ROOT_DIR/../../lib/neobash.sh"
}

test_core::arg::add_option_normal() {
  local TMP_ARG='-x "valueX" --argy 456'

  core::arg::add_option_normal_func() {
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

    core::arg::add_option -l "ARG_A" -o "-a" -t "string" -r "true"
    core::arg::add_option -l "ARG_B" -o "--argb" -t "int" -r "false" -d "123" -h "-b option help"
    core::arg::add_option_alias -l "ARG_B" -a "-b"
    core::arg::add_option -l "ARG_C" -o "-c" -t "bool" -r "false" -h "-c option help" -s "true"
    core::arg::add_option -l "ARG_D" -o "-d" -t "bool" -r "false" -s "false"
    core::arg::add_option -l "ARG_E" -o "-e" -t "int" -r "false" -d "567"
    core::arg::add_option -l "ARG_F" -o "-f" -t "string" -r "false" -d "eeee"

    assert_matches "ARG_A"  "${CORE_ARG_OPTION_LABEL["-a"]}"
    assert_matches "ARG_B"  "${CORE_ARG_OPTION_LABEL["--argb"]}"
    assert_matches "-a"     "${CORE_ARG_OPTION_SHORT["ARG_A"]}"
    assert_matches "--argb" "${CORE_ARG_OPTION_LONG["ARG_B"]}"
    assert_matches "-b"     "${CORE_ARG_OPTION_SHORT["ARG_B"]}"
    assert_matches "string" "${CORE_ARG_TYPE["ARG_A"]}"
    assert_matches "int"    "${CORE_ARG_TYPE["ARG_B"]}"
    assert_matches "true"   "${CORE_ARG_REQUIRED["ARG_A"]}"
    assert_matches "false"  "${CORE_ARG_REQUIRED["ARG_B"]}"
    assert_matches "-b option help" "${CORE_ARG_HELP["ARG_B"]}"

    core::arg::parse "$@"

    assert_matches "true"  "${CORE_ARG_STORE["ARG_C"]}"
    assert_matches "false" "${CORE_ARG_STORE["ARG_D"]}"

    assert_matches ""      "${CORE_ARG_DEFAULT["ARG_A"]}"
    assert_matches "123"   "${CORE_ARG_DEFAULT["ARG_B"]}"
    assert_matches "false" "${CORE_ARG_DEFAULT["ARG_C"]}"
    assert_matches "true"  "${CORE_ARG_DEFAULT["ARG_D"]}"
    assert_matches "567"   "${CORE_ARG_DEFAULT["ARG_E"]}"
    assert_matches "eeee"  "${CORE_ARG_DEFAULT["ARG_F"]}"

    assert_matches "aaaa"  "${ARGS["ARG_A"]}"
    assert_matches "3"     "${ARGS["ARG_B"]}"
    assert_matches "true"  "${ARGS["ARG_C"]}"
    assert_matches "true"  "${ARGS["ARG_D"]}"
    assert_matches "567"   "${ARGS["ARG_E"]}"
    assert_matches "eeee"  "${ARGS["ARG_F"]}"

    assert_same    "aaaa"  "$(core::arg::get_value -l 'ARG_A')"
    assert_same    "3"     "$(core::arg::get_value -l 'ARG_B')"
    assert_same    "true"  "$(core::arg::get_value -l 'ARG_C')"
    assert_same    "true"  "$(core::arg::get_value -l 'ARG_D')"
    assert_same    "567"   "$(core::arg::get_value -l 'ARG_E')"
    assert_same    "eeee"  "$(core::arg::get_value -l 'ARG_F')"

    core::arg::set_value -l "ARG_A" -v "AAAA"
    core::arg::set_value -l "ARG_B" -v "4"
    core::arg::set_value -l "ARG_C" -v "false"
    core::arg::set_value -l "ARG_D" -v "false"
    core::arg::set_value -l "ARG_E" -v "890"
    core::arg::set_value -l "ARG_F" -v "EEEE"
    assert_same    "AAAA"  "$(core::arg::get_value -l 'ARG_A')"
    assert_same    "4"     "$(core::arg::get_value -l 'ARG_B')"
    assert_same    "false" "$(core::arg::get_value -l 'ARG_C')"
    assert_same    "false" "$(core::arg::get_value -l 'ARG_D')"
    assert_same    "890"   "$(core::arg::get_value -l 'ARG_E')"
    assert_same    "EEEE"  "$(core::arg::get_value -l 'ARG_F')"
    core::arg::set_value -l "ARG_A" -v "AAAA"
    core::arg::set_value -l "ARG_B" -v "4"
    core::arg::set_value -l "ARG_C" -v "false"
    core::arg::set_value -l "ARG_D" -v "false"
    core::arg::set_value -l "ARG_E" -v "890"
    core::arg::set_value -l "ARG_F" -v "EEEE"

    core::arg::del_value -l 'ARG_A'
    core::arg::del_value -l 'ARG_B'
    core::arg::del_value -l 'ARG_C'
    core::arg::del_value -l 'ARG_D'
    core::arg::del_value -l 'ARG_E'
    core::arg::del_value -l 'ARG_F'
    assert_same    ""      "$(core::arg::get_value -l 'ARG_A')"
    assert_same    "123"   "$(core::arg::get_value -l 'ARG_B')"
    assert_same    "false" "$(core::arg::get_value -l 'ARG_C')"
    assert_same    "true"  "$(core::arg::get_value -l 'ARG_D')"
    assert_same    "567"   "$(core::arg::get_value -l 'ARG_E')"
    assert_same    "eeee"  "$(core::arg::get_value -l 'ARG_F')"

    assert_matches "$TMP_ARG" "${ARG_OTHERS[*]}"

    assert_exit_code 0 $(__core::arg::is_option__ "-t")
    assert_exit_code 0 $(__core::arg::is_option__ "--time")
    assert_exit_code 1 $(__core::arg::is_option__ "hoge")
  }

  core::arg::add_option_normal_func -a "aaaa" --argb 3 -c -- $TMP_ARG
}
