#!/usr/bin/env bash

set_up() {
  ROOT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"
  source "$ROOT_DIR/../../lib/neobash.sh"
}

test_core::log::stack_trace() {
  $( core::log::stack_trace )
  assert_exit_code "0"

  local OUTPUT=$( core::log::stack_trace {stderr}>&1 )
  assert_matches "^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}\+[0-9]{4} TRACE test_core::log::stack_trace()" "$OUTPUT"
}

test_core::log::crit() {
  $( core::log::crit "crit log" )
  assert_exit_code "1"

  local OUTPUT=$( core::log::crit "crit log" {stderr}>&1 )
  assert_matches "^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}\+[0-9]{4} CRIT crit log" "$OUTPUT"
  assert_matches "[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}\+[0-9]{4} TRACE   test_core::log::crit" "$OUTPUT"
}

test_core::log::error_exit() {
  $( core::log::error_exit "error exit log" )
  assert_exit_code "1"

  local OUTPUT=$( core::log::error_exit "error exit log" {stderr}>&1 )
  assert_matches "^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}\+[0-9]{4} ERROR error exit log" "$OUTPUT"
  assert_matches "[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}\+[0-9]{4} TRACE core::log::error" "$OUTPUT"
}

test_core::log::error() {
  core::log::error "error log"
  assert_exit_code "0"

  local OUTPUT=$( core::log::error "error log" {stderr}>&1 )
  assert_matches "^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}\+[0-9]{4} ERROR error log" "$OUTPUT"
  assert_matches "[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}\+[0-9]{4} TRACE   test_core::log::error" "$OUTPUT"
}

test_core::log::notice() {
  core::log::notice "notice log"
  assert_exit_code "0"

  local OUTPUT=$( core::log::notice "notice log" )
  assert_matches "^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}\+[0-9]{4} NOTICE notice log" "$OUTPUT"
}

test_core::log::info() {
  core::log::info "info log"
  assert_exit_code "0"

  local OUTPUT=$( core::log::info "info log" )
  assert_matches "^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}\+[0-9]{4} INFO info log" "$OUTPUT"
}

test_core::log::debug() {
  core::log::debug "debug log"
  assert_exit_code "0"

  local OUTPUT=$( core::log::debug "debug log" {stderr}>&1 )
  assert_matches "" "$OUTPUT"

  local OUTPUT=$( LOG_DEBUG="true" core::log::debug "debug log" {stderr}>&1 )
  assert_matches "^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}:[0-9]{2}:[0-9]{2}\+[0-9]{4} DEBUG debug log   \[test_core::log::debug()" "$OUTPUT"
}
