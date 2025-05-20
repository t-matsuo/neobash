#!/usr/bin/env bash
# Copyright 2025 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license

nb::require "core/log.sh core/arg.sh"
nb::command_check "curl"

readonly __CURL_HEADER_JSON__='Content-Type: application/json'

__CURL_DEFAULT_OPTIONS__=""
__CURL_COMMON_OPTIONS__="-sSL"
__CURL_DEFAULT_CONNECT_TIMEOUT__="3"
__CURL_DEFAULT_RETRY__="3"
__CURL_DEFAULT_RETRY_DELAY__="3"
__CURL_FAILCHECK_OPTION__="--fail-with-body"

__curl::init__() {
    local CURL_HELP
    CURL_HELP=$( curl --help all )
    if [[ ${CURL_HELP} =~ " --fail-with-body " ]]; then
        core::log::debug "curl --fail-with-body is available"
    else
        core::log::debug "curl --fail-with-body is not available. use --fail instead"
        __CURL_FAILCHECK_OPTION__="--fail"
    fi
    __curl::set_default_options__
}

__curl::set_default_options__() {
    __CURL_DEFAULT_OPTIONS__="${__CURL_COMMON_OPTIONS__} ${__CURL_FAILCHECK_OPTION__} --connect-timeout $__CURL_DEFAULT_CONNECT_TIMEOUT__ --retry ${__CURL_DEFAULT_RETRY__} --retry-delay $__CURL_DEFAULT_RETRY_DELAY__"
    core::log::debug "default curl options: $__CURL_COMMON_OPTIONS__"
}

curl::set_connect_timeout() {
    arg::init_local
    arg::add_option -l "TIMEOUT" -o "--value" -t "int" -r "true"  -h "Set default connect timeout. Default 3 (sec)"
    arg::parse "$@"

    __CURL_DEFAULT_CONNECT_TIMEOUT__=${ARGS[TIMEOUT]}
    __curl::set_default_options__
}

curl::set_retry() {
    arg::init_local
    arg::add_option -l "RETRY" -o "--value" -t "int" -r "true"  -h "Set default retry num. Default 3 (sec)"
    arg::parse "$@"

    __CURL_DEFAULT_RETRY__=${ARGS[RETRY]}
    __curl::set_default_options__
}

curl::set_retry_delay() {
    arg::init_local
    arg::add_option -l "DELAY" -o "--value" -t "int" -r "true"  -h "Set default retry delay. Default 3 (sec)"
    arg::parse "$@"

    __CURL_DEFAULT_RETRY_DELAY__=${ARGS[DELAY]}
    __curl::set_default_options__
}

__curl::exec__() {
    local i
    log::debug "Exec: curl $( for i in ${__CURL_DEFAULT_OPTIONS__}; do echo -n "'$i' "; done ) $( while (( $# > 0 )); do echo -n "'$1' "; shift; done )"
    curl ${__CURL_DEFAULT_OPTIONS__} "$@"
}

curl::ping() {
    arg::init_local
    arg::add_option -l "URL" -o "--url"  -t "string" -r "true" -h "URL"
    arg::parse "$@"
    core::log::debug "ping with curl: ${ARGS[URL]}"

    if ! __curl::exec__ -X GET "${ARGS[URL]}" > /dev/null; then
        log::error_exit "connecting ${ARGS[URL]} is failed"
    fi
    log::debug "connecting ${ARGS[URL]} is succeeded"
    return 0
}

curl::get() {
    __curl::exec__ --get "$@"
}

curl::patch() {
    __curl::exec__ -X PATCH "$@"
}

curl::post() {
    __curl::exec__ -X POST "$@"
}

curl::put() {
    __curl::exec__ -X PUT "$@"
}

curl::delete() {
    __curl::exec__ -X DELETE "$@"
}

# for json header

curl::get_json() {
    curl::get --header "${__CURL_HEADER_JSON__}" "$@"
}

curl::patch_json() {
    curl::patch --header "${__CURL_HEADER_JSON__}" "$@"
}

curl::post_json() {
    curl::post --header "${__CURL_HEADER_JSON__}" "$@"
}

curl::put_json() {
    curl::put --header "${__CURL_HEADER_JSON__}" "$@"
}

curl::delete_json() {
    curl::delete --header "${__CURL_HEADER_JSON__}" "$@"
}

__curl::init__
