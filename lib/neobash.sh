#!/usr/bin/env bash
# shellcheck disable=SC1090

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

# for importing library
nb::import() {
    local i
    local libname

    [[ -z "${1:-}" ]] && core::log::error_exit "library name is empty"
    [[ "${1:-}" =~ " " ]] && core::log::error_exit "library name '$1' contains spaces"
    for i in ${NB_DIR}/$1 ; do
        libname="${i##"${NB_DIR}"/}"
        [[ -f "$i" ]] || core::log::crit "library '$libname' not found"
        if nb::has_lib "$libname"; then
            core::log::debug "library '$libname' already impported" "true"
            continue
        fi
        # cannot use core::log::debug when loading lib/core/log.sh, so skip importing message
        [[ "$i" == "${NB_DIR}/core/log.sh" ]] || core::log::debug "importing library $libname"

        if source "$i" "$@"; then
            #NB_LIBS+=("${i##${NB_DIR}/}")
            NB_LIBS+=("$libname")
        else
            core::log::error_exit "importing library $i failed"
        fi
    done
}

# list loaded libraries
nb::get_libs() {
    echo "${NB_LIBS[@]}"
}

# search loaded libraries
nb::has_lib() {
    [[ -z "${1:-}" ]] && core::log::error_exit "library name is empty"
    if [[ " ${NB_LIBS[*]} " =~ [[:space:]]${1}[[:space:]] ]]; then
        return 0
    fi
    return 1
}

# check depending libraries
nb::require() {
    local lib
    [[ -z "${1:-}" ]] && core::log::error_exit "library name is empty"
    for lib in $1; do
        nb::has_lib "$lib" || core::log::error_exit "library '$lib' is not imported"
    done
    return 0
}

# check depending command
nb::command_check() {
    local cmd
    [[ -z "${1:-}" ]] && core::log::error_exit "cmmand name is empty"
    for cmd in $1; do
        type "$cmd" 2>/dev/null || core::log::error_exit "command '$cmd' not found"
    done
    return 0
}

__nb::init__() {
    if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
         echo "to use netobash, bash version 4 or higher is required"
         exit 1
    fi
    NB_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

    # Loaded Libraries
    NB_LIBS=("neobash.sh")
    # import core libraries
    nb::import 'core/log.sh'
    core::log::debug "library path: $NB_DIR"
    nb::import 'core/*'
}

#### Initiazling ####

# bash settings
shopt -s expand_aliases
set -o pipefail
set -u

__nb::init__
