#!/usr/bin/env bash

set_up() {
    ROOT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"
    source "$ROOT_DIR/../../lib/neobash.sh"
    nb::import "os/os.sh"
}

# check var

test_os::check_var_ok() {
    local OUTPUT

    __CHECK_ENV_TEST__=""
    OUTPUT=$( os::check_var --name __CHECK_ENV_TEST__ {core_log_saved_stderr}>&1 )
    assert_exit_code "0"
    assert_empty "$OUTPUT"
}

test_os::check_var_ng() {
    local OUTPUT

    OUTPUT=$( core::log::disable_err_trap; os::check_var --name __CHECK_ENV_TEST__ {core_log_saved_stderr}>&1 )
    assert_exit_code "1"
    assert_matches 'variable __CHECK_ENV_TEST__ is not defined' "$OUTPUT"
    core::log::info "$OUTPUT"
}

test_os::check_var_ng_noerror() {
    local OUTPUT

    OUTPUT=$( core::log::disable_err_trap; os::check_var --name __CHECK_ENV_TEST__ -r false {core_log_saved_stderr}>&1 )
    assert_exit_code "1"
    assert_empty "$OUTPUT"
}

# check func

test_os::check_var_ok() {
    local OUTPUT

    __check_func_test__() {
        true
    }
    OUTPUT=$( os::check_func --name __check_func_test__ {core_log_saved_stderr}>&1 )
    assert_exit_code "0"
    assert_empty "$OUTPUT"
}

test_os::check_func_ng() {
    local OUTPUT

    OUTPUT=$( core::log::disable_err_trap; os::check_func --name __check_func_test__ {core_log_saved_stderr}>&1 )
    assert_exit_code "1"
    assert_matches 'function __check_func_test__ is not defined' "$OUTPUT"
    core::log::info "$OUTPUT"
}

test_os::check_func_ng_noerror() {
    local OUTPUT

    OUTPUT=$( core::log::disable_err_trap; os::check_func --name __check_func_test__ -r false {core_log_saved_stderr}>&1 )
    assert_exit_code "1"
    assert_empty "$OUTPUT"
}

test_os::check_exported_var_ok() {
    local OUTPUT

    export __CHECK_ENV_TEST__=""
    OUTPUT=$( os::check_exported_var --name __CHECK_ENV_TEST__ {core_log_saved_stderr}>&1 )
    assert_exit_code "0"
    assert_empty "$OUTPUT"
}

test_os::check_export_var_ng() {
    local OUTPUT

    __CHECK_ENV_TEST__=""
    OUTPUT=$( os::check_exported_var --name __CHECK_ENV_TEST__ {core_log_saved_stderr}>&1 )
    assert_exit_code "1"
    assert_matches 'variable __CHECK_ENV_TEST__ is not exported' "$OUTPUT"
}