#!/usr/bin/env bash
# Copyright 2024 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license

source $(cd $(dirname $(readlink -f "${BASH_SOURCE[0]}")) >/dev/null 2>&1 && pwd)/lib/neobash.sh
nb::import "util/*"
nb::require "util/series.sh"

# my main function
myfunc() {
    log::info "MyPID: $$"

    # sample for library manipulation
    log::info "imported libs: $(nb::get_libs)"
    nb::has_lib "core/log.sh"
    [[ $? -eq 0 ]] && log::info "I have core/log.sh library" || log::info "I have no core/log.sh library"

    # sample for handling args in function
    arg::init_local
    arg::add_option -l "ARG_A" -o "-a" -t "string" -r "true"
    arg::add_option_alias -l "ARG_A" -a "--all"
    arg::add_option -l "ARG_B" -o "-b" -t "int" -r "false" -s "none" -h "-b option help"
    arg::add_option -l "ARG_C" -o "-c" -r "false" -s "true"
    arg::add_option -l "ARG_D" -o "-d" -r "false" -t "int" -d 3
    arg::add_option -l "ARG_E" -o "-e" -t "string" -r "false" -d ""
    arg::parse "$@"

    log::info "Options:\n$( arg::get_all_option )"

    log::info "get -a value: $( arg::get_value -l "ARG_A" )"
    log::info "ARGS[ARG_A]:  ${ARGS[ARG_A]}"

    arg::set_value -l "ARG_A" -v "new valueA"
    log::info "get -a value: $( arg::get_value -l "ARG_A" )"
    arg::del_value -l "ARG_A"
    log::info "get -a value: $( arg::get_value -l "ARG_A" )"
    log::info "args all values:\n$( core::arg::get_all_value )"

    log::info "------ show usage -----"
    core::arg::show_usage "help: "
    log::info "-----------------------"

    # check SIGINT (Ctrl-C occurs SIGERR)
    # sleep 2

    # show error message if command is failed
    ls /12345

    ### sample for serialization
    # mystr inclues double quote and linebreak
    local mystr="str123\"
    ::str456\""
    # create ORG as array
    local ORG=("a1\na2" "b1\nb2" "$mystr")
    local ORG[50]="505050"
    # define ENV which receive serialized data
    local ENC
    # serialize ORG to ENC
    util::series::serialize --from ORG --to ENC
    LOG_ESCAPE_LINE_BREAK=false log::info "original array=\n${ORG[*]}\n"
    LOG_ESCAPE_LINE_BREAK=false log::info "serialized array=\n$ENC\n"
    serialized_array_receiver "$ENC"

    return 0
}

serialized_array_receiver() {
    local arg="$1"
    local -a DEC
    util::series::deserialize --from arg --to DEC
    LOG_ESCAPE_LINE_BREAK=false log::info "descerialized array=\n${DEC[*]}"
}

myfunc --all "valueA" -c  -d 5 -e "" -- -b 65535
log::notice "End of myfunc"
