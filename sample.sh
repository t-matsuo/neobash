#!/usr/bin/env bash
# Copyright 2024 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license

source $(cd $(dirname $(readlink -f "${BASH_SOURCE[0]}")) >/dev/null 2>&1 && pwd)/lib/neobash.sh

# set your original library path
# nb::add_lib_path "path/your/dir"

# check command
nb::command_check "column"

# main function
main() {
    # init core/arg.sh lib
    core::arg::init_local
    # define required options "-a" and "--aoption" as string
    core::arg::add_option       -l "ARG_A" -o "-a" -t "string" -r "true"         -h "This is -a string option.\nYou can inseart line break."
    core::arg::add_option_alias -l "ARG_A" -o "--aoption"
    # define optional option "-b" as int as default=0
    core::arg::add_option       -l "ARG_B" -o "-b" -t "int"    -r "false" -d "0" -h "This is -b int option with default."
    # define optional option "-c" as bool
    core::arg::add_option       -l "ARG_C" -o "-c" -t "bool"   -r "false"        -h "This is -c bool option with no default."
    # define flag "-d"
    core::arg::add_option       -l "ARG_D" -o "-d" -s "true"                     -h "Thin is -d flag. ARG_D will be true if it's set."

    # define help message
    core::arg::add_help_header "This is sample.sh for neobash.\n"
    core::arg::add_help_header "You can use it to read 'source lib/neobash.sh' command.\n"
    core::arg::add_help_header "\nUsage:\n"
    # define help message prefix
    core::arg::set_help_prefix "   "
    # define script version
    core::arg::add_version "1.0"
    # parse args
    core::arg::parse "$@"

    echo "#### Demo for arguments parser ####"
    echo "##### Show all options and flags for main()"
    core::arg::get_all_option | column -s, -t
    echo "#### Show all labels and values for main()"
    core::arg::get_all_value

    echo
    echo "#### Demo for logging functions ####"
    core::log::info   "Arg values is -a ${ARGS[ARG_A]}, -b ${ARGS[ARG_B]}, -c ${ARGS[ARG_C]}, -d is ${ARGS[ARG_D]}"
    core::log::notice "This is notice log"
    core::log::warn   "This is warn log"
    core::log::error  "This is error log"
    core::log::debug  "This is debug log"
    # use alias for logging functions
    log::info         "Thins is alias for core::log::info()"

    echo
    # Catch Stderr output automatically and outputs its as log
    echo "#### Demo for executing 'ls /foobar' and catching its outputs and signal 'SIGERR' ####"
    ls /foobar

    echo
    echo "#### Demo for core::log::stack_trace() ####"
    core::log::stack_trace

    echo
    echo "#### Demo for core::log::echo() and core::log::echo_err() ####"
    core::log::echo      "This is stdout message"
    core::log::echo_err  "This is stderr message"

    echo
    echo "#### Demo for nb::get_libs() to show all imported libraries. ####"
    log::info "imported libs: $(nb::get_libs)"

    echo
    echo "#### Demo for checking whether specified library is imported or not ####"
    if nb::has_lib "core/log.sh"; then
        log::info "core/log.sh is imported"
    else
        log::info "core/log.sh is not imported"
    fi

    echo
    echo "#### Demo for importing util/cmd.sh and call util::cmd::exec() ####"
    log::info "importing util/cmd.sh"
    nb::import "util/cmd.sh"
    local STDOUT
    local STDERR
    util::cmd::exec --stdout STDOUT --stderr STDERR -- sub_function
    log::info "sub_function() stdout is \"$STDOUT\""
    log::info "sub_function() stderr is \"$STDERR\""

    echo
    echo "#### Demo for array serialization ####"
    nb::import "util/series.sh"
    local ARRAY_ORG=("a1" "a2" "a3")
    local ARRAY_SERIALIZED
    util::series::serialize --from ARRAY_ORG --to ARRAY_SERIALIZED
    echo -e "ARRAY_ORG=\n${ARRAY_ORG[*]}\n"
    echo -e "ARRAY_SERIALIZED=\n$ARRAY_SERIALIZED\n"
    serialized_array_receiver "$ARRAY_SERIALIZED"

    return 0
}

# function for util/cmd.sh
sub_function() {
    echo "This is stdout in sub()"
    echo "This is stderr in sub()" >&2
}

# function for serialization
serialized_array_receiver() {
    local ARRAY_SERIALIZED="$1"
    local -a ARRAY_DECODED

    # check util/series.sh is imported or not
    nb::require "util/series.sh"

    util::series::deserialize --from ARRAY_SERIALIZED --to ARRAY_DECODED
    echo -e "ARRAY_DECODED=\n${ARRAY_DECODED[*]}"
}

main "$@"
