#!/usr/bin/env bash
# Copyright 2024 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license
# shellcheck disable=SC1090

# @file neobash.sh
# @brief Neobash bootstrap library
# @description
# * Provide library management functions.
# * Load core library such as ``core/log.sh`` and ``core/arg.sh`` to manage logging and parsing arguments.
# ### Bootstrap
# ```bash
# source /path/to/lib/neobash.sh
# ```
#
# If source it, neobash defines global variables.
# * NB_DIR : neobash.sh directory
# * NB_LIB_PATH : Library path. default is ``${NB_DIR}/lib``
# * NB_LIBS : Loaded libraries.
#
# And chnage bash configuration.
# * shopt -s expand_aliases
# * set -o pipefail
# * set -u

# @description Import library.
# * If library is already loaded, do nothing.
# * If path is invalid, script is forcedly exited.
# @arg $1 string Library name such as ``core/log.sh``. Name path is relative to ``NB_LIB_PATH``.
# @stdout None.
# @stderr Error and debug message.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
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

# @description Add library path.
# * If path is invalid, script is forcedly exited.
# @arg $1 Library path.
# @stdout None.
# @stderr Error and debug message.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
nb::add_lib_path() {
    [[ -z "${1:-}" ]] && core::log::crit "library path is empty"
    [[ ! -d "$1" ]] && core::log::crit "library path '$1' not found"
    NB_LIB_PATH=("$1" "${NB_LIB_PATH[@]}")
}

# @description Show all library paths.
# @stdout Library paths added by ``nb::add_lib_path``.
# @stderr None.
# @exitcode 0
nb::get_lib_path() {
    echo "${NB_LIB_PATH[@]}"
}

# @description Show all loaded library.
# @stdout Loaded libraries.
# @stderr None.
# @exitcode 0
nb::get_libs() {
    echo "${NB_LIBS[@]}"
}

# @description Check if library is loaded.
# @arg $1 Library name.
# @stdout None.
# @stderr Error and debug message.
# @exitcode 0 If loaded.
# @exitcode 1 If not loaded or error occured.
nb::has_lib() {
    [[ -z "${1:-}" ]] && core::log::error_exit "library name is empty"
    if [[ " ${NB_LIBS[*]} " =~ [[:space:]]${1}[[:space:]] ]]; then
        return 0
    fi
    return 1
}

# check depending libraries

# @description Define required libraries in each library.
# * If library is not loaded or argument is invalid, script is forcedly exited.
# @arg $1 Library name.
# @stdout None.
# @stderr Error and debug message.
# @exitcode 0 If loaded.
# @exitcode 1 If not loaded or error occured.
nb::require() {
    local lib
    [[ -z "${1:-}" ]] && core::log::error_exit "library name is empty"
    for lib in $1; do
        nb::has_lib "$lib" || core::log::error_exit "library '$lib' is not imported"
    done
    return 0
}

# @description Check depending command.
# * If command is not found or argument is invalid, script is forcedly exited.
# @arg $1 Command name.
# @stdout None.
# @stderr Error and debug message.
# @exitcode 0 If exists.
# @exitcode 1 Error occured.
nb::command_check() {
    local cmd
    [[ -z "${1:-}" ]] && core::log::error_exit "cmmand name is empty"
    for cmd in $1; do
        type "$cmd" >/dev/null 2>/dev/null || core::log::error_exit "command '$cmd' not found"
    done
    return 0
}

# @description Check bash minimum version.
# * If the version does not meet the requirements or argument is invalid, script is forcedly exited.
# * Version format is ``MAJOR.MINOR.PATCH``.
# @arg $1 Version number.
# @stdout None.
# @stderr Error and debug message.
# @exitcode 0 If the version meets the requirements.
# @exitcode 1 Error occured.
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
        core::log::error_exit "ERROR invalid bash version format ${BASH_SOURCE[0]}:${BASH_LINENO[0]}"
    fi
    core::log::debug "checking bash minimum version ( $major.$minor.$patch <= ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}.${BASH_VERSINFO[2]} )"
    [[ ${BASH_VERSINFO[0]} -lt $major ]] && return 1
    [[ ${BASH_VERSINFO[0]} -eq $major ]] && [[ ${BASH_VERSINFO[1]} -lt $minor ]] && return 1
    [[ ${BASH_VERSINFO[0]} -eq $major ]] && [[ ${BASH_VERSINFO[1]} -eq $minor ]] \
        && [[ ${BASH_VERSINFO[2]} -lt $patch ]] && return 1
    return 0
}

# @description Check bash maximum version.
# * If the version does not meet the requirements or argument is invalid, script is forcedly exited.
# * Version format is ``MAJOR.MINOR.PATCH``.
# @arg $1 Version number.
# @stdout None.
# @stderr Error and debug message.
# @exitcode 0 If the version meets the requirements.
# @exitcode 1 Error occured.
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
        core::log::error_exit "ERROR invalid bash version format ${BASH_SOURCE[0]}:${BASH_LINENO[0]}"
        exit 1
    fi
    core::log::debug "checking bash maximum version ( $major.$minor.$patch >= ${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}.${BASH_VERSINFO[2]} )"
    [[ ${BASH_VERSINFO[0]} -gt $major ]] && return 1
    [[ ${BASH_VERSINFO[0]} -eq $major ]] && [[ ${BASH_VERSINFO[1]} -gt $minor ]] && return 1
    [[ ${BASH_VERSINFO[0]} -eq $major ]] && [[ ${BASH_VERSINFO[1]} -eq $minor ]] \
        && [[ ${BASH_VERSINFO[2]} -gt $patch ]] && return 1
    return 0
}

# @internal
# @description Initialize neobash.
# * If environment is invalid, script is forcedly exited.
# @stdout None.
# @stderr Error and debug message.
# @exitcode 0 If the version meets the requirements.
# @exitcode 1 Error occured.
__nb::init__() {
    local required_bash_verion="4.2.0"
    NB_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"
    # add library path
    NB_LIB_PATH+=("$NB_DIR")

    # Loaded Libraries
    NB_LIBS=("neobash.sh")
    # import core libraries
    nb::import 'core/log.sh'
    core::log::debug "library path: $NB_DIR"
    nb::import 'core/*'

    if ! nb::check_bash_min_version $required_bash_verion; then
         echo "ERROR netobash requires bash version $required_bash_verion or higher"
         exit 1
    fi
}

#### Initiazling ####

# bash settings
shopt -s expand_aliases
set -o pipefail
set -u

__nb::init__
