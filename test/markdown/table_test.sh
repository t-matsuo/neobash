#!/usr/bin/env bash

set_up() {
    ROOT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"
    source "$ROOT_DIR/../../lib/neobash.sh"
    nb::import "markdown/table.sh"
}

test_csv2table::test_1_basic_csv() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'a,b,c' --data '1,2,3')
    assert_exit_code "0"
    assert_equals '| a | b | c |
| -- | -- | -- |
| 1 | 2 | 3 |' "$OUTPUT"
}

test_csv2table::test_2_quoted_comma() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'name,value,note' --data '"foo,bar",10,"hello"')
    assert_exit_code "0"
    assert_equals '| name | value | note |
| -- | -- | -- |
| foo,bar | 10 | hello |' "$OUTPUT"
}

test_csv2table::test_3_escaped_quotes() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'a,b' --data '"say ""hello""",2')
    assert_exit_code "0"
    assert_equals '| a | b |
| -- | -- |
| say "hello" | 2 |' "$OUTPUT"
}

test_csv2table::test_4_newline_in_quotes_default() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'a,b' --data $'"line1\nline2",2')
    assert_exit_code "0"
    assert_equals '| a | b |
| -- | -- |
| line1<br>line2 | 2 |' "$OUTPUT"
}

test_csv2table::test_5_line_break_option() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'a,b' --data $'"line1\nline2",2' --line-break '\n')
    assert_exit_code "0"
    assert_equals '| a | b |
| -- | -- |
| line1\nline2 | 2 |' "$OUTPUT"
}

test_csv2table::test_6_pipe_escape() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'a,b' --data '"a | b",2')
    assert_exit_code "0"
    assert_equals '| a | b |
| -- | -- |
| a \| b | 2 |' "$OUTPUT"
}

test_csv2table::test_7_multi_line_data() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'a,b,c' --data $'1,2,3\n4,5,6')
    assert_exit_code "0"
    assert_equals '| a | b | c |
| -- | -- | -- |
| 1 | 2 | 3 |
| 4 | 5 | 6 |' "$OUTPUT"
}

test_csv2table::test_8_empty_field() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'a,b,c' --data '1,,3')
    assert_exit_code "0"
    assert_equals '| a | b | c |
| -- | -- | -- |
| 1 |  | 3 |' "$OUTPUT"
}

test_csv2table::test_9_header_quoted_comma() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header '"col,1","col 2"' --data 'a,b')
    assert_exit_code "0"
    assert_equals '| col,1 | col 2 |
| -- | -- |
| a | b |' "$OUTPUT"
}

test_csv2table::test_10_mixed_quotes_multi_line() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'name,desc' --data $'"foo,bar","multi\nline"\nsimple,plain')
    assert_exit_code "0"
    assert_equals '| name | desc |
| -- | -- |
| foo,bar | multi<br>line |
| simple | plain |' "$OUTPUT"
}
