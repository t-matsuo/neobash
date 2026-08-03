#!/usr/bin/env bash

set_up() {
  ROOT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"
  source "$ROOT_DIR/../../lib/neobash.sh"
}

test_core::arg::add_option_normal() {
  local TMP_ARG='-x "valueX" --argy 456'
  local TMP_VERSION='1.0.0'

  core::arg::add_option_normal_func() {
    # Cannot use alias core::arg::init_local here, so define manually.
    local CORE_ARG_LABEL=""
    local CORE_ARG_HELP_HEADER=""
    local CORE_ARG_HELP_PREFIX=""
    local CORE_ARG_VERSION=""
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

    # required is true
    core::arg::add_option -l "STR_REQ"  -o "--str-req"  -t "string" -r "true"
    core::arg::add_option -l "INT_REQ"  -o "--int-req"  -t "int"    -r "true"
    core::arg::add_option -l "BOOL_REQ" -o "--bool-req" -t "bool"   -r "true"
    assert_exit_code 0 $?

    # alias for above
    core::arg::add_option_alias  -l "STR_REQ"  -o "-s"
    core::arg::add_option_alias  -l "INT_REQ"  -o "-i"
    core::arg::add_option_alias  -l "BOOL_REQ" -o "-b"
    assert_exit_code 0 $?

    # required is false and default is empty
    core::arg::add_option -l "STR_NO_DEF"  -o "--str-no-def"  -t "string" -r "false"
    core::arg::add_option -l "INT_NO_DEF"  -o "--int-no-def"  -t "int"    -r "false"
    core::arg::add_option -l "BOOL_NO_DEF" -o "--bool-no-def" -t "bool"   -r "false"
    assert_exit_code 0 $?

    # required is false and default is not empty
    core::arg::add_option -l "STR_DEF"     -o "--str-def"     -t "string" -r "false" -d "default value"
    core::arg::add_option -l "INT_DEF"     -o "--int-def"     -t "int"    -r "false" -d "99"
    core::arg::add_option -l "BOOL_DEF"    -o "--bool-def"    -t "bool"   -r "false" -d "true"
    assert_exit_code 0 $?

    # store
    core::arg::add_option -l "STORE_TRUE"  -o "--store-true"  -s "true"
    core::arg::add_option -l "STORE_FALSE" -o "--store-false" -s "false"
    assert_exit_code 0 $?

    # with help
    core::arg::add_option -l "WITH_HELP"   -o "--with-help"   -t "int"    -r "false"  -h "--with-help help message"
    assert_exit_code 0 $?

    #### check added options ####
    # check label
    assert_matches "STR_REQ"  "${CORE_ARG_OPTION_LABEL["--str-req"]}"
    assert_matches "INT_REQ"  "${CORE_ARG_OPTION_LABEL["--int-req"]}"
    assert_matches "BOOL_REQ" "${CORE_ARG_OPTION_LABEL["--bool-req"]}"
    assert_matches "STR_REQ"  "${CORE_ARG_OPTION_LABEL["-s"]}"
    assert_matches "INT_REQ"  "${CORE_ARG_OPTION_LABEL["-i"]}"
    assert_matches "BOOL_REQ" "${CORE_ARG_OPTION_LABEL["-b"]}"

    # check short option
    assert_matches "-s"       "${CORE_ARG_OPTION_SHORT["STR_REQ"]}"
    assert_matches "-i"       "${CORE_ARG_OPTION_SHORT["INT_REQ"]}"
    assert_matches "-b"       "${CORE_ARG_OPTION_SHORT["BOOL_REQ"]}"

    # check long option
    assert_matches "--str-req"  "${CORE_ARG_OPTION_LONG["STR_REQ"]}"
    assert_matches "--int-req"  "${CORE_ARG_OPTION_LONG["INT_REQ"]}"
    assert_matches "--bool-req" "${CORE_ARG_OPTION_LONG["BOOL_REQ"]}"

    # check type
    assert_matches "string" "${CORE_ARG_TYPE["STR_REQ"]}"
    assert_matches "int"    "${CORE_ARG_TYPE["INT_REQ"]}"
    assert_matches "bool"   "${CORE_ARG_TYPE["BOOL_REQ"]}"
    assert_matches "bool"   "${CORE_ARG_TYPE["STORE_TRUE"]}"
    assert_matches "bool"   "${CORE_ARG_TYPE["STORE_FALSE"]}"

    # check required
    assert_matches "true"   "${CORE_ARG_REQUIRED["STR_REQ"]}"
    assert_matches "false"  "${CORE_ARG_REQUIRED["STR_NO_DEF"]}"
    assert_matches "false"  "${CORE_ARG_REQUIRED["STORE_TRUE"]}"
    assert_matches "false"  "${CORE_ARG_REQUIRED["STORE_FALSE"]}"

    # check default
    assert_matches ""              "${CORE_ARG_DEFAULT["STR_REQ"]}"
    assert_matches "0"             "${CORE_ARG_DEFAULT["INT_REQ"]}"
    assert_matches "false"         "${CORE_ARG_DEFAULT["BOOL_REQ"]}"
    assert_matches ""              "${CORE_ARG_DEFAULT["STR_NO_DEF"]}"
    assert_matches "0"             "${CORE_ARG_DEFAULT["INT_NO_DEF"]}"
    assert_matches "false"         "${CORE_ARG_DEFAULT["BOOL_NO_DEF"]}"
    assert_matches "default value" "${CORE_ARG_DEFAULT["STR_DEF"]}"
    assert_matches "99"            "${CORE_ARG_DEFAULT["INT_DEF"]}"
    assert_matches "true"          "${CORE_ARG_DEFAULT["BOOL_DEF"]}"
    assert_matches "false"         "${CORE_ARG_DEFAULT["STORE_TRUE"]}"
    assert_matches "true"          "${CORE_ARG_DEFAULT["STORE_FALSE"]}"

    # check help
    assert_matches "--with-help help message" "${CORE_ARG_HELP["WITH_HELP"]}"

    # add help header and prefix
    core::arg::add_help_header "foobar"
    assert_exit_code 0 $?
    assert_matches "foobar"    "${CORE_ARG_HELP_HEADER}"

    core::arg::set_help_prefix "prefix: "
    assert_exit_code 0 $?
    assert_matches "prefix: "  "${CORE_ARG_HELP_PREFIX}"

    # add version
    core::arg::add_version "$TMP_VERSION"
    assert_matches "$TMP_VERSION"  "${CORE_ARG_VERSION}"

    # parsing #######################
    core::arg::parse "$@"
    #################################

    # check stored value
    assert_matches "true"  "${CORE_ARG_STORE["STORE_TRUE"]}"
    assert_matches "false" "${CORE_ARG_STORE["STORE_FALSE"]}"

    # check value
    assert_matches "aaaa"  "${ARGS["STR_REQ"]}"
    assert_matches "3"     "${ARGS["INT_REQ"]}"
    assert_matches "true"  "${ARGS["BOOL_REQ"]}"
    assert_matches ""      "${ARGS["STR_NO_DEF"]}"
    assert_matches "0"     "${ARGS["INT_NO_DEF"]}"
    assert_matches "false" "${ARGS["BOOL_NO_DEF"]}"
    # check other args
    assert_matches "$TMP_ARG" "${ARG_OTHERS[*]}"

    # get_value()
    assert_same    "aaaa"  "$(core::arg::get_value -l 'STR_REQ')"

    # set_value()
    core::arg::set_value -l "STR_REQ"  -v "AAAA"
    core::arg::set_value -l "INT_REQ"  -v "2345"
    core::arg::set_value -l "BOOL_REQ" -v "false"
    assert_same    "AAAA"    "$(core::arg::get_value -l 'STR_REQ')"
    assert_same    "2345"    "$(core::arg::get_value -l 'INT_REQ')"
    assert_same    "false"   "$(core::arg::get_value -l 'BOOL_REQ')"

    # internal fnction
    assert_exit_code 0 $(__core::arg::has_label__ "STR_REQ")
    assert_exit_code 1 $(__core::arg::has_label__ "STR_REQ_DUMMY")
    assert_exit_code 1 $(__core::arg::has_label__ "DUMMY_LABEL")

    assert_exit_code 0 $(__core::arg::has_option__ "--str-req")
    assert_exit_code 1 $(__core::arg::has_option__ "--dummy")
    assert_exit_code 1 $(__core::arg::has_option__ "-z")
  }

  core::arg::add_option_normal_func --str-req "aaaa" --int-req 3 --bool-req true -- $TMP_ARG
  assert_matches "$TMP_VERSION" $( core::arg::add_option_normal_func -v )
  assert_matches "$TMP_VERSION" $( core::arg::add_option_normal_func --version )
  assert_exit_code 0 $( core::arg::add_option_normal_func --str-req "aaaa" --int-req 3 --bool-req true -- $TMP_ARG )
  assert_exit_code 0 $( core::arg::add_option_normal_func -s "aaaa" -i 3 -b true -- $TMP_ARG )
  assert_exit_code 0 $( core::arg::add_option_normal_func --str-req "aaaa" --int-req 3 --bool-req true --store-true -- $TMP_ARG )
  assert_exit_code 0 $( core::arg::add_option_normal_func --str-req "aaaa" --int-req 3 --bool-req true --store-false -- $TMP_ARG )

  assert_exit_code 1 $( core::arg::add_option_normal_func )
  assert_exit_code 1 $( core::arg::add_option_normal_func --str-req "aaaa" --int-req foo --bool-req true -- $TMP_ARG )
  assert_exit_code 1 $( core::arg::add_option_normal_func --str-req "aaaa" --int-req 3 --bool-req foo -- $TMP_ARG )
  assert_exit_code 1 $( core::arg::add_option_normal_func --str-req --int-req 3 --bool-req true -- $TMP_ARG )
  assert_exit_code 1 $( core::arg::add_option_normal_func --str-req "aaaa" --int-req 3 --bool-req -- $TMP_ARG )
  assert_exit_code 1 $( core::arg::add_option_normal_func --store-true -- $TMP_ARG )
  assert_exit_code 1 $( core::arg::add_option_normal_func --store-false -- $TMP_ARG )
}

test_core::arg::is_option() {
    assert_exit_code 0 $(__core::arg::is_option__ "-t")
    assert_exit_code 0 $(__core::arg::is_option__ "--long-option-name")
    assert_exit_code 1 $(__core::arg::is_option__ "foo")
    assert_exit_code 1 $(__core::arg::is_option__ "")
    assert_exit_code 1 $(__core::arg::is_option__ "-")
    assert_exit_code 1 $(__core::arg::is_option__ "--")
    assert_exit_code 1 $(__core::arg::is_option__ "---")
}

test_core::arg::check_value_type__() {
    assert_exit_code 0 $(__core::arg::check_value_type__ "string" "foo" )
    assert_exit_code 0 $(__core::arg::check_value_type__ "int"    "0" )
    assert_exit_code 0 $(__core::arg::check_value_type__ "int"    "99" )
    assert_exit_code 1 $(__core::arg::check_value_type__ "int"    "-1" )
    assert_exit_code 1 $(__core::arg::check_value_type__ "int"    "11.11" )
    assert_exit_code 0 $(__core::arg::check_value_type__ "bool"   "true" )
    assert_exit_code 0 $(__core::arg::check_value_type__ "bool"   "false" )
    assert_exit_code 1 $(__core::arg::check_value_type__ "bool"   "1" )
    assert_exit_code 1 $(__core::arg::check_value_type__ "bool"   "foo" )
}

