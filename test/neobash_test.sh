#!/usr/bin/env bash

function set_up() {
  ROOT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"
  source "$ROOT_DIR/../lib/neobash.sh"
}

function test_nb::import_netbash() {
  assert_same "neobash.sh" "${NB_LIBS[0]}"
}

function test_nb::import_default_loaded_libs() {
  assert_array_contains "core/log.sh" "${NB_LIBS[@]}"
  assert_array_contains "core/arg.sh" "${NB_LIBS[@]}"
}

function test_nb::get_libs() {
  local LIBS=$( nb::get_libs )
  assert_array_contains "neobash.sh"  "${LIBS[@]}"
  assert_array_contains "core/log.sh" "${LIBS[@]}"
  assert_array_contains "core/arg.sh" "${LIBS[@]}"
}

function test_nb::import_series.sh() {
  nb::import "util/*"
  assert_contains "util/series.sh"  "$( nb::get_libs )"
}

function test_nb::has_lib() {
  assert_exit_code "1" $(nb::has_lib "util/series.sh")

  nb::import  "util/series.sh"
  assert_exit_code "0" $(nb::has_lib "util/series.sh")
}

function test_nb::require() {
  assert_exit_code "1" $(nb::require "util/series.sh")
  nb::import  "util/series.sh"
  assert_exit_code "0" $(nb::require "util/series.sh")
}

function test_nb::command_check() {
  assert_exit_code "0" $(nb::command_check "bash")
  assert_exit_code "1" $(nb::command_check "no_exit_command_example")
}

function test_nb::check_bash_min_version() {
  assert_exit_code "0" $(nb::check_bash_min_version "1.0.0")
  assert_exit_code "1" $(nb::check_bash_min_version "100.0.0")
}

function test_nb::check_bash_max_version() {
  assert_exit_code "0" $(nb::check_bash_max_version "100.0.0")
  assert_exit_code "1" $(nb::check_bash_max_version "1.0.0")
}