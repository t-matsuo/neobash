#!/usr/bin/env bash

# Copyright 2024 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"/lib/neobash.sh
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
    arg::parse "$@"
    log::info "Options:\n$( arg::get_all_option )"

    log::info "get -a value: $( arg::get_value -l "ARG_A" )"
    arg::set_value -l "ARG_A" -v "new valueA"
    log::info "get -a value: $( arg::get_value -l "ARG_A" )"
    arg::del_value -l "ARG_A"
    log::info "get -a value: $( arg::get_value -l "ARG_A" )"
    log::info "args all values:\n$( core::arg::get_all_value )"

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
    log::info "original array=\n${ORG[*]}\n"
    log::info "serialized array=\n$ENC\n"
    serialized_array_receiver "$ENC"

    return 0
}

serialized_array_receiver() {
    local arg="$1"
    local -a DEC
    util::series::deserialize --from arg --to DEC
    log::info "descerialized array=\n${DEC[*]}"
}

myfunc --all "valueA" -c -- -b 65535
log::notice "End of myfunc"
