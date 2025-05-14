#!/usr/bin/env bash

nb::import "curl/*"
nb::require "core/log.sh core/arg.sh curl/curl.sh"

: "${DATADOG_API_HOST:=}"
: "${DATADOG_API_KEY:=}"
: "${DATADOG_APPLICATION_KEY:=}"

DATADOG_API_HEADER=""

datadog::api::ping() {
    curl::ping --url "${DATADOG_API_HOST}" || log::error_exit "Cannot connect Datadog API"
}

datadog::api::get() {
    local RES=""

    arg::init_local
    arg::add_option -l "API" -o "--api" -t "string" -r "true" -h "API path. ex: /api/v2/xxxxx"
    arg::parse "$@"

    RES=$( curl::get_json "${DATADOG_API_HEADER[@]}" "${DATADOG_API_HOST}${ARGS[API]}" ) || log::error_exit "datadog get api failed"
    log::debug "RESPONSE=$RES"
    echo "$RES"
}

datadog::api::post() {
    local RES=""

    arg::init_local
    arg::add_option -l "API" -o "--api" -t "string" -r "true" -h "API path. ex: /api/v2/xxxxx"
    arg::add_option -l "DATA" -o "--data" -t "string" -r "true" -h "Post data(JSON)"
    arg::parse "$@"

    RES=$( curl::post_json "${DATADOG_API_HEADER[@]}" "${DATADOG_API_HOST}${ARGS[API]}" --data-raw "${ARGS[DATA]}" ) || log::error_exit "datadog post api failed"
    log::debug "RESPONSE=$RES"
    echo "$RES"
}

datadog::api::patch() {
    local RES=""

    arg::init_local
    arg::add_option -l "API" -o "--api" -t "string" -r "true" -h "API path. ex: /api/v2/xxxxx"
    arg::add_option -l "DATA" -o "--data" -t "string" -r "true" -h "Patch data(JSON)"
    arg::parse "$@"

    log::debug "API_PATH=${ARGS[API]}"
    RES=$( curl::patch_json "${DATADOG_API_HEADER[@]}" "${DATADOG_API_HOST}${ARGS[API]}" --data-raw "${ARGS[DATA]}" ) || log::error_exit "datadog patch api failed"
    log::debug "RESPONSE=$RES"
    echo "$RES"
}

datadog::api::delete() {
    local RES=""

    arg::init_local
    arg::add_option -l "API" -o "--api" -t "string" -r "true" -h "API path. ex: /api/v2/xxxxx"
    arg::parse "$@"

    log::debug "API_PATH=${ARGS[API]}"

    RES=$( curl::delete_json "${DATADOG_API_HEADER[@]}" "${DATADOG_API_HOST}${ARGS[API]}" ) || log::error_exit "datadog delete api failed"
    log::debug "RESPONSE=$RES"
    echo "$RES"
}

datadog::init() {
    [[ "${DATADOG_API_HOST}" == "" ]] && log::error_exit "DATADOG_API_HOST Env is not set"
    [[ "${DATADOG_API_KEY}" == "" ]] && log::error_exit "DATADOG_API_KEY Env is not set"
    [[ "${DATADOG_APPLICATION_KEY}" == "" ]] && log::error_exit "DATADOG_APPLICATION_KEY Env is not set"
    DATADOG_API_HEADER=("--header" "DD-API-KEY: ${DATADOG_API_KEY}"
                        "--header" "DD-APPLICATION-KEY: ${DATADOG_APPLICATION_KEY}")
    return 0
}

datadog::init
