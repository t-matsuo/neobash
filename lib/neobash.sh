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
    local file
    local libname
    local path
    local import_ok=false

    [[ -z "${1:-}" ]] && core::log::error_exit "library name is empty"
    [[ "${1:-}" =~ " " ]] && core::log::error_exit "library name '$1' contains spaces"
    for path in ${NB_LIB_PATH[@]}; do
        for file in ${path}/$1 ; do
            [[ "$file" == "${NB_DIR}/core/log.sh" ]] || core::log::debug "searching library '$1' in $path"
            libname="${file##"${path}"/}"
            if [[ ! -f "$file" ]]; then
                core::log::debug "library '$libname' not found in $path"
                continue
            fi
            if nb::has_lib "$libname"; then
                core::log::debug "library '$libname' already impported" "true"
                import_ok=true
                continue
            fi
            # cannot use core::log::debug when loading lib/core/log.sh, so skip importing message
            if [[ "$file" == "${NB_DIR}/core/log.sh" ]]; then
                [[ "${LOG_DEBUG:-}" == "true" ]] && printf "%(%F-%T%z)T " && echo "DEBUG importing library $file" >&2
            else
                core::log::debug "importing library $libname in $path"
            fi

            if source "$file" "$@"; then
                #NB_LIBS+=("${i##${NB_DIR}/}")
                NB_LIBS+=("$libname")
                import_ok=true
            else
                core::log::error_exit "importing library $file failed"
            fi
        done
        [[ "$import_ok" == "true" ]] && break
    done

    if [[ "$import_ok" == "false" ]]; then
        core::log::error_exit "importing library '$1' failed"
    fi
}

# add library path to import
nb::add_lib_path() {
    [[ -z "${1:-}" ]] && core::log::crit "library path is empty"
    [[ ! -d "$1" ]] && core::log::crit "library path '$1' not found"
    NB_LIB_PATH=("$1" "${NB_LIB_PATH[@]}")
}

# get library path
nb::get_lib_path() {
    echo "${NB_LIB_PATH[@]}"
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
        type "$cmd" >/dev/null 2>/dev/null || core::log::error_exit "command '$cmd' not found"
    done
    return 0
}

# check bash minimum version
# arg1: minimum version
nb::check_bash_min_version() {
    local version=$1
    local major
    local minor
    local patch

    if [[ ${version} =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        major=${BASH_REMATCH[1]}
        minor=${BASH_REMATCH[2]}
        patch=${BASH_REMATCH[3]}
    else
        echo "ERROR invalid bash version format ${BASH_SOURCE[0]}:${BASH_LINENO[0]}"
        exit 1
    fi
    [[ ${BASH_VERSINFO[0]} -lt $major ]] && return 1
    [[ ${BASH_VERSINFO[0]} -eq $major ]] && [[ ${BASH_VERSINFO[1]} -lt $minor ]] && return 1
    [[ ${BASH_VERSINFO[0]} -eq $major ]] && [[ ${BASH_VERSINFO[1]} -eq $minor ]] \
        && [[ ${BASH_VERSINFO[2]} -lt $patch ]] && return 1
    return 0
}

# check bash maximum version
# arg1: maximum version
nb::check_bash_max_version() {
    local version=$1
    local major
    local minor
    local patch

    if [[ ${version} =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        major=${BASH_REMATCH[1]}
        minor=${BASH_REMATCH[2]}
        patch=${BASH_REMATCH[3]}
    else
        echo "ERROR invalid bash version format ${BASH_SOURCE[0]}:${BASH_LINENO[0]}"
        exit 1
    fi
    [[ ${BASH_VERSINFO[0]} -gt $major ]] && return 1
    [[ ${BASH_VERSINFO[0]} -eq $major ]] && [[ ${BASH_VERSINFO[1]} -gt $minor ]] && return 1
    [[ ${BASH_VERSINFO[0]} -eq $major ]] && [[ ${BASH_VERSINFO[1]} -eq $minor ]] \
        && [[ ${BASH_VERSINFO[2]} -gt $patch ]] && return 1
    return 0
}

__nb::init__() {
    local required_bash_verion="4.2.0"
    if ! nb::check_bash_min_version $required_bash_verion; then
         echo "ERROR netobash requires bash version $required_bash_verion or higher"
         exit 1
    fi
    NB_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"
    # add library path
    NB_LIB_PATH+=("$NB_DIR")

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
