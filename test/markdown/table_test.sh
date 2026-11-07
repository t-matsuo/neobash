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

test_csv2table::test_11_cell_max_width_truncate() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'a,b' --data '"verylongstring",2' --cell-max-width '8')
    assert_exit_code "0"
    assert_equals '| a | b |
| -- | -- |
| veryl... | 2 |' "$OUTPUT"
}

test_csv2table::test_12_cell_max_width_invalid() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'a,b' --data '1,2' --cell-max-width '3' 2>/dev/null)
    assert_exit_code "1"
}

test_csv2table::test_13_max_table_byte_split() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'a,b' --data $'11111,22222\n33333,44444' --table-max-byte '55')
    assert_exit_code "0"
    assert_equals '| a | b |
| -- | -- |
| 11111 | 22222 |
<!-- page 2/2 -->
| a | b |
| -- | -- |
| 33333 | 44444 |' "$OUTPUT"
}

test_csv2table::test_14_max_table_line_split() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'a,b' --data $'1,2\n3,4\n5,6\n7,8' --table-max-line '2')
    assert_exit_code "0"
    assert_equals '| a | b |
| -- | -- |
| 1 | 2 |
| 3 | 4 |
<!-- page 2/2 -->
| a | b |
| -- | -- |
| 5 | 6 |
| 7 | 8 |' "$OUTPUT"
}

test_csv2table::test_15_combined_cell_max_and_line() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'a,b' --data $'1111111,2222222\n3333333,4444444\n5555555,6666666' --cell-max-width '6' --table-max-line '1')
    assert_exit_code "0"
    assert_equals '| a | b |
| -- | -- |
| 111... | 222... |
<!-- page 2/3 -->
| a | b |
| -- | -- |
| 333... | 444... |
<!-- page 3/3 -->
| a | b |
| -- | -- |
| 555... | 666... |' "$OUTPUT"
}

test_csv2table::test_16_both_byte_and_line_limits() {
    local OUTPUT

    # table-max-line=1 triggers split first; table-max-byte=200 is large enough not to trigger
    OUTPUT=$(markdown::csv2table --header 'a,b' --data $'1,2\n3,4\n5,6\n7,8' --table-max-line '1' --table-max-byte '200')
    assert_exit_code "0"
    assert_equals '| a | b |
| -- | -- |
| 1 | 2 |
<!-- page 2/4 -->
| a | b |
| -- | -- |
| 3 | 4 |
<!-- page 3/4 -->
| a | b |
| -- | -- |
| 5 | 6 |
<!-- page 4/4 -->
| a | b |
| -- | -- |
| 7 | 8 |' "$OUTPUT"
}

test_csv2table::test_18_custom_page_break() {
    local OUTPUT

    OUTPUT=$(markdown::csv2table --header 'a,b' --data $'1,2\n3,4' --table-max-line '1' --page-break '--- %page / %total ---')
    assert_exit_code "0"
    assert_equals '| a | b |
| -- | -- |
| 1 | 2 |
--- 2 / 2 ---
| a | b |
| -- | -- |
| 3 | 4 |' "$OUTPUT"
}

test_csv2table::test_17_cell_max_width_exact() {
    local OUTPUT

    # Exactly max width should NOT be truncated
    OUTPUT=$(markdown::csv2table --header 'a,b' --data '"abcdef",2' --cell-max-width '6')
    assert_exit_code "0"
    assert_equals '| a | b |
| -- | -- |
| abcdef | 2 |' "$OUTPUT"
}
