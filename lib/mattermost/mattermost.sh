#!/usr/bin/env bash
# Copyright 2025 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license

# @file mattermost/mattermost.sh
# @brief mattermost library
# @description
# Useful functions for using mattermost.
#
# This library can change its behavior by setting the following environment variables.
#
# * MATTERMOST_POST : if false, it outputs logs only instead of calling api such as post, upload and so on. default: ``true``

nb::require "core/log.sh core/arg.sh"
nb::import "curl/curl.sh"
nb::import "util/cmd.sh"
nb::command_check "curl"

MATTERMOST_POST="true"

# @description Ping mattermost api using /api/v4/system/ping endpoint.
# @stdout None
# @stderr Error and debug message.
# @option --host <value> (string)(required): Mattermost URL such as https://localhost:8065
# @option --insecure (optional): Ignore certificate errors.
# @option --verbose (optional): Verbose log.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
mattermost::ping() {
    local -r PING_PATH="api/v4/system/ping"
    local HOST
    local URL
    local CURL_OPTIONS=""
    local CURL_LOG
    local curl_rc

    core::arg::init_local
    core::arg::add_option -l "HOST" -o "--host" -r "true" -h "mattermost host such as https://localhost:8065"
    core::arg::add_option -l "INSECURE" -o "--insecure" -r "false" -t "bool" -s "true" -h "ignore certificate errors"
    core::arg::add_option -l "VERBOSE" -o "--verbose" -r "false" -t "bool" -s "true" -h "verbose curl log"
    core::arg::parse "$@"

    core::log::debug "CURL_OPTIONS=$CURL_OPTIONS"

    HOST="${ARGS[HOST]}"
    if [[ ! "$HOST" =~ ^https?://[.a-zA-Z0-9:]+/?$ ]]; then
        core::log::error "Invalid mattermost hostname: $HOST"
        return 1
    fi
    HOST="${HOST%/}"
    URL="${HOST}/${PING_PATH}"
    core::log::debug "Mattermost ping URL: ${URL}"

    curl::enable_fail
    CURL_LOG=$( curl::get $CURL_OPTIONS -s "${URL}" 2>&1)
    curl_rc=$?
    if [[ $curl_rc -ne 0 ]]; then
        core::log::error "mattermost ping failed rc=$curl_rc CURL_LOG=\"$CURL_LOG\""
        return 1
    fi
    if [[ "$CURL_LOG" =~ \"status\":\"OK\" ]]; then
        core::log::debug "mattermost ping succeeded. CURL_LOG=\"$CURL_LOG\""
        return 0
    fi
    core::log::error "mattermost ping failed rc=$curl_rc CURL_LOG=\"$CURL_LOG\""
    return 1
}

# @description Post a message to mattermost using incoming webhook.
# @stdout Show a post message if MATTERMOST_POST=false.
# @stderr Error and debug message.
# @option --message / -m <vahlue> (string)(required): Message.
# @option --url / -u <value> (string)(required): Incoming webhook URL.
# @option --insecure (optional): Ignore certificate errors.
# @option --verbose (optional): Verbose log.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
mattermost::webhook_post() {
    local MESSAGE
    local ESCAPED_MESSAGE
    local API_URL
    local CURL_OPTIONS=""
    local CURL_LOG
    local curl_rc

    core::arg::init_local
    core::arg::add_option -l "MESSAGE" -o "--message" -r "true" -h "post message"
    core::arg::add_option_alias -l "MESSAGE" -a "-m"
    core::arg::add_option -l "API_URL" -o "--url" -r "true" -h "webhook api url"
    core::arg::add_option_alias -l "API_URL" -a "-u"
    core::arg::add_option -l "INSECURE" -o "--insecure" -r "false" -t "bool" -s "true" -h "ignore certificate errors"
    core::arg::add_option -l "VERBOSE" -o "--verbose" -r "false" -t "bool" -s "true" -h "verbose curl log"
    core::arg::parse "$@"
    MESSAGE=$( core::arg::get_value -l "MESSAGE" )
    API_URL=$( core::arg::get_value -l "API_URL" )

    [[ "$MESSAGE" == "" ]] && log::error "post message is empty" && return 1
    [[ "$API_URL" == "" ]] && log::error "incoming webhook URL is empty" && return 1
    [[ "${ARGS[INSECURE]}" == "true" ]] && CURL_OPTIONS="$CURL_OPTIONS --insecure"
    [[ "${ARGS[VERBOSE]}" == "true" ]] && CURL_OPTIONS="$CURL_OPTIONS --verbose"
    core::log::debug "CURL_OPTIONS=$CURL_OPTIONS"

    # escape double quote
    ESCAPED_MESSAGE="${MESSAGE//\"/\\\"}"

    # remove control characters
    ESCAPED_MESSAGE="${ESCAPED_MESSAGE//[]/}"

    curl::enable_fail
    if [[ "${MATTERMOST_POST}" == "true" ]]; then
        CURL_LOG=$( curl::post_json $CURL_OPTIONS -s \
                        -d '{"text": "'"$ESCAPED_MESSAGE"'"}' "${API_URL}" 2>&1)
        curl_rc=$?
        if [[ $curl_rc -ne 0 ]]; then
            core::log::error "mattermost post failed rc=$curl_rc POST_MESSAGE=\"$ESCAPED_MESSAGE\" CURL_LOG=\"$CURL_LOG\""
            return 1
        fi
        core::log::debug "mattermost post successed: rc=$curl_rc POST_MESSAGE=\"$ESCAPED_MESSAGE\" CURL_LOG=\"$CURL_LOG\""
    else
        core::log::info "mattermost post skipped: POST_MESSAGE=\"$ESCAPED_MESSAGE\""
    fi
}

# @description post message
# @stdout API response (json)
# @stderr Error and debug message.
# @option --message <vahlue> (string)(required): Message.
# @option --token <token> (string)(required): token.
# @option --host <value> (string)(required): Mattermost URL such as https://localhost:8065
# @option --ch <value> (string)(required): Mattermost channel ID
# @option --insecure (optional): Ignore certificate errors.
# @option --verbose (optional): Verbose log.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
mattermost::post_msg() {
    local MESSAGE=""
    local ESCAPED_MESSAGE=""
    local -r API_PATH="api/v4/posts"
    local CURL_OPTIONS=""
    local curl_rc=""
    local STDOUT=""
    local STDERR=""
    local POST_DATA=""
    local POST_DATA_FOR_FILES=""
    local file_id=""

    core::arg::init_local
    core::arg::add_option -l "MESSAGE" -o "--message" -r "true" -h "post message"
    core::arg::add_option -l "TOKEN" -o "--token" -r "true" -h "token"
    core::arg::add_option -l "HOST" -o "--host" -r "true" -h "mattermost host such as https://localhost:8065"
    core::arg::add_option -l "CH" -o "--ch" -r "true" -h "The ID of the channel that this file will be uploaded to"
    core::arg::add_option -l "FILE_IDS" -o "--files" -r "false" -d "" -h "uploaded file IDs. Separator is space."
    core::arg::add_option -l "INSECURE" -o "--insecure" -r "false" -t "bool" -s "true" -h "ignore certificate errors"
    core::arg::add_option -l "VERBOSE" -o "--verbose" -r "false" -t "bool" -s "true" -h "verbose curl log"
    core::arg::parse "$@"

    MESSAGE="${ARGS[MESSAGE]}"
    [[ "${ARGS[INSECURE]}" == "true" ]] && CURL_OPTIONS="$CURL_OPTIONS --insecure"
    [[ "${ARGS[VERBOSE]}" == "true" ]] && CURL_OPTIONS="$CURL_OPTIONS --verbose"

    # escape double quote
    ESCAPED_MESSAGE="${MESSAGE//\"/\\\"}"

    # remove control characters
    ESCAPED_MESSAGE="${ESCAPED_MESSAGE//[]/}"

    # custructing file_ids value
    if [[ -z "${ARGS[FILE_IDS]}" ]]; then
        POST_DATA_FOR_FILES="\"\""
    else
        POST_DATA_FOR_FILES="\""
        for file_ids in ${ARGS[FILE_IDS]}; do
            POST_DATA_FOR_FILES="$POST_DATA_FOR_FILES\", \"$file_ids"
        done
        POST_DATA_FOR_FILES="$POST_DATA_FOR_FILES\""
    fi

    POST_DATA='{
      "channel_id": "'"${ARGS[CH]}"'",
      "message": "'"$ESCAPED_MESSAGE"'",
      "file_ids": [
        '"$POST_DATA_FOR_FILES"'
      ]
    }'

    POST_DATA="${POST_DATA//$'\n'/}"

    core::log::debug "CURL_OPTIONS=$CURL_OPTIONS"
    curl::enable_fail
    if [[ "${MATTERMOST_POST}" == "true" ]]; then
        util::cmd::exec --stdout STDOUT --stderr STDERR -- curl::post_json $CURL_OPTIONS \
            --header "Accept: application/json" \
            --header "Authorization: Bearer ${ARGS[TOKEN]}" \
            --data "$POST_DATA" \
            ${ARGS[HOST]}/${API_PATH}
        curl_rc=$?
        if [[ $curl_rc -ne 0 ]]; then
            core::log::error "post message failed rc=$curl_rc channel_id=${ARGS[CH]} msg=\"$ESCAPED_MESSAGE\" CURL_ERROR_LOG=\"$STDERR\""
            return 1
        fi
        core::log::debug "post message successed: rc=$curl_rc channel_id=${ARGS[CH]} msg=\"$ESCAPED_MESSAGE\" CURL_ERROR_LOG=\"$STDERR\""
        echo "$STDOUT"
    else
        core::log::info "post message skipped: channel_id=${ARGS[CH]} msg=\"$ESCAPED_MESSAGE\""
    fi
    return 0
}

# @description Upload a file to mattermost using token. NOTE: Incoming webhook does not support uploading.
# @stdout API response (json)
# @stderr Error and debug message.
# @option --file <file> (string)(required): file.
# @option --token <token> (string)(required): token.
# @option --host <value> (string)(required): Mattermost URL such as https://localhost:8065
# @option --ch <value> (string)(required): Mattermost channel ID
# @option --insecure (optional): Ignore certificate errors.
# @option --verbose (optional): Verbose log.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
mattermost::upload_file() {
    local FILE
    local -r API_PATH="api/v4/files"
    local CURL_OPTIONS=""
    local curl_rc=""
    local STDOUT=""
    local STDERR=""

    core::arg::init_local
    core::arg::add_option -l "FILE" -o "--file" -r "true" -h "post message"
    core::arg::add_option -l "TOKEN" -o "--token" -r "true" -h "token"
    core::arg::add_option -l "HOST" -o "--host" -r "true" -h "mattermost host such as https://localhost:8065"
    core::arg::add_option -l "CH" -o "--ch" -r "true" -h "The ID of the channel that this file will be uploaded to"
    core::arg::add_option -l "INSECURE" -o "--insecure" -r "false" -t "bool" -s "true" -h "ignore certificate errors"
    core::arg::add_option -l "VERBOSE" -o "--verbose" -r "false" -t "bool" -s "true" -h "verbose curl log"
    core::arg::parse "$@"

    FILE="${ARGS[FILE]}"
    [[ "${ARGS[INSECURE]}" == "true" ]] && CURL_OPTIONS="$CURL_OPTIONS --insecure"
    [[ "${ARGS[VERBOSE]}" == "true" ]] && CURL_OPTIONS="$CURL_OPTIONS --verbose"

    core::log::debug "CURL_OPTIONS=$CURL_OPTIONS"
    curl::enable_fail
    if [[ "${MATTERMOST_POST}" == "true" ]]; then
        util::cmd::exec --stdout STDOUT --stderr STDERR -- curl::post $CURL_OPTIONS \
            --header "Accept: application/json" \
            --header "Authorization: Bearer ${ARGS[TOKEN]}" \
            --header "Content-Type: multipart/form-data" \
            -F "channel_id=${ARGS[CH]}" \
            -F "files=@${ARGS[FILE]}" \
            ${ARGS[HOST]}/${API_PATH}
        curl_rc=$?
        if [[ $curl_rc -ne 0 ]]; then
            core::log::error "file uploading failed rc=$curl_rc channel_id=${ARGS[CH]} file=${ARGS[FILE]} CURL_ERROR_LOG=\"$STDERR\""
            return 1
        fi
        core::log::debug "file uploadig successed: rc=$curl_rc channel_id=${ARGS[CH]} file=${ARGS[FILE]} CURL_ERROR_LOG=\"$STDERR\""
        echo "$STDOUT"
    else
        core::log::info "uploading is skipped: channel_id=${ARGS[CH]} file=${ARGS[FILE]}"
    fi
    return 0
}
