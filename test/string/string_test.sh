#!/usr/bin/env bash

set_up() {
    ROOT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"
    source "$ROOT_DIR/../../lib/neobash.sh"
    nb::import "string/string.sh"
}

test_string::start_with_ok() {
    string::start_with --string 'abcdefghijklmn' --match 'abcd'
    assert_exit_code "0"
}

test_string::start_with_ng() {
    string::start_with --string 'abcdefghijklmn' --match 'klmn'
    assert_exit_code "1"
}

test_string::end_with_ok() {
    string::end_with --string 'abcdefghijklmn' --match 'klmn'
    assert_exit_code "0"
}

test_string::end_with_ng() {
    string::end_with --string 'abcdefghijklmn' --match 'abcd'
    assert_exit_code "1"
}

test_string::include_ok() {
    string::include --string 'abcdefghijklmn' --match 'fghi'
    assert_exit_code "0"
}

test_string::include_ng() {
    string::include --string 'abcdefghijklmn' --match 'abmn'
    assert_exit_code "1"
}
