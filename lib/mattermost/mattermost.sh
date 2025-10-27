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

# @internal
# @description check mattermost hostname and strip last "/"
__mattermost::check_host__() {
    local HOST=""
    core::arg::init_local
    core::arg::add_option -l "HOST" -o "--host" -r "true" -h "mattermost host such as https://localhost:8065"
    core::arg::parse "$@"

    HOST="${ARGS[HOST]}"
    if [[ ! "$HOST" =~ ^https?://[.a-zA-Z0-9:]+/?$ ]]; then
        core::log::error "Invalid mattermost hostname: $HOST"
        return 1
    fi
    HOST="${HOST%/}"
    echo "$HOST"
    return 0
}

# @internal
# @description escape message
__mattermost::escape_message__() {
    local MESSAGE=""
    core::arg::init_local
    core::arg::add_option -l "MESSAGE" -o "--message" -r "true" -h "message"
    core::arg::parse "$@"

    MESSAGE="${ARGS[MESSAGE]}"
    # escape double quote
    MESSAGE="${MESSAGE//\"/\\\"}"
    # remove control characters
    MESSAGE="${MESSAGE//[]/}"
    echo "$MESSAGE"
    return 0
}

# @description Ping mattermost api using /api/v4/system/ping endpoint.
# @stdout None
# @stderr Error and debug message.
# @option --host <value> (string)(required): Mattermost URL such as https://localhost:8065
# @option --insecure (optional): Ignore certificate errors.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
mattermost::ping() {
    local -r API_PATH="api/v4/system/ping"
    local HOST=""
    local CURL_OPTIONS=""
    local curl_rc=""
    local STDOUT=""
    local STDERR=""

    core::arg::init_local
    core::arg::add_option -l "HOST" -o "--host" -r "true" -h "mattermost host such as https://localhost:8065"
    core::arg::add_option -l "INSECURE" -o "--insecure" -r "false" -t "bool" -s "true" -h "ignore certificate errors"
    core::arg::parse "$@"

    core::log::debug "CURL_OPTIONS=$CURL_OPTIONS"

    HOST="$( __mattermost::check_host__ --host "${ARGS[HOST]}" )" || return 1
    core::log::debug "Mattermost ping URL: ${HOST}/${API_PATH}"

    curl::enable_fail
    util::cmd::exec --stdout STDOUT --stderr STDERR --catch-sigerr "false" -- curl::get $CURL_OPTIONS -s "${HOST}/${API_PATH}"
    curl_rc=$?
    if [[ "$STDOUT" =~ \"status\":\"OK\" ]]; then
        core::log::debug "mattermost ping successed rc=$curl_rc RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
        return 0
    fi
    core::log::error "mattermost ping failed rc=$curl_rc RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
    return 1
}

# @description Post a message to mattermost using incoming webhook.
# @stdout API response (json)
# @stderr Error and debug message.
# @option --message / -m <vahlue> (string)(required): Message.
# @option --url / -u <value> (string)(required): Incoming webhook URL.
# @option --insecure (optional): Ignore certificate errors.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
mattermost::webhook_post() {
    local MESSAGE=""
    local CURL_OPTIONS=""
    local curl_rc=""
    local STDOUT=""
    local STDERR=""

    core::arg::init_local
    core::arg::add_option -l "MESSAGE" -o "--message" -r "true" -h "post message"
    core::arg::add_option_alias -l "MESSAGE" -a "-m"
    core::arg::add_option -l "API_URL" -o "--url" -r "true" -h "webhook api url"
    core::arg::add_option_alias -l "API_URL" -a "-u"
    core::arg::add_option -l "INSECURE" -o "--insecure" -r "false" -t "bool" -s "true" -h "ignore certificate errors"
    core::arg::parse "$@"

    [[ "${ARGS[INSECURE]}" == "true" ]] && CURL_OPTIONS="$CURL_OPTIONS --insecure"
    [[ "${ARGS[API_URL]}" == "" ]] && log::error "incoming webhook URL is empty" && return 1
    core::log::debug "CURL_OPTIONS=$CURL_OPTIONS"

    MESSAGE="$( __mattermost::escape_message__ --message "${ARGS[MESSAGE]}" )"

    curl::enable_fail
    if [[ "${MATTERMOST_POST}" == "true" ]]; then
        util::cmd::exec --stdout STDOUT --stderr STDERR --catch-sigerr "false" -- curl::post_json $CURL_OPTIONS \
            -d '{"text": "'"$MESSAGE"'"}' "${ARGS[API_URL]}"
        curl_rc=$?

        if [[ $curl_rc -ne 0 ]]; then
            core::log::error "post message failed rc=$curl_rc msg=\"$MESSAGE\" RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
            return 1
        fi
        core::log::debug "post message successed: rc=$curl_rc msg=\"$MESSAGE\" RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
        echo "$STDOUT"
    else
        core::log::info "post message skipped: channel_id=${ARGS[CH]} msg=\"$MESSAGE\""
    fi
    return 0
}

# @description post message
# @stdout API response (json)
# @stderr Error and debug message.
# @option --message <vahlue> (string)(required): Message.
# @option --token <token> (string)(required): token.
# @option --host <value> (string)(required): Mattermost URL such as https://localhost:8065
# @option --ch <value> (string)(required): Mattermost channel ID
# @option --insecure (optional): Ignore certificate errors.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
mattermost::post_msg() {
    local -r API_PATH="api/v4/posts"
    local HOST=""
    local CURL_OPTIONS=""
    local curl_rc=""
    local STDOUT=""
    local STDERR=""
    local MESSAGE=""
    local POST_DATA=""
    local POST_DATA_FOR_FILES=""
    local file_ids=""

    core::arg::init_local
    core::arg::add_option -l "MESSAGE" -o "--message" -r "true" -h "post message"
    core::arg::add_option -l "TOKEN" -o "--token" -r "true" -h "token"
    core::arg::add_option -l "HOST" -o "--host" -r "true" -h "mattermost host such as https://localhost:8065"
    core::arg::add_option -l "CH" -o "--ch" -r "true" -h "The ID of the channel that this file will be uploaded to"
    core::arg::add_option -l "FILE_IDS" -o "--files" -r "false" -d "" -h "uploaded file IDs. Separator is space."
    core::arg::add_option -l "INSECURE" -o "--insecure" -r "false" -t "bool" -s "true" -h "ignore certificate errors"
    core::arg::parse "$@"

    MESSAGE="${ARGS[MESSAGE]}"
    [[ "${ARGS[INSECURE]}" == "true" ]] && CURL_OPTIONS="$CURL_OPTIONS --insecure"

    HOST="$( __mattermost::check_host__ --host "${ARGS[HOST]}" )" || return 1
    MESSAGE="$( __mattermost::escape_message__  --message "${ARGS[MESSAGE]}" )" || return 1

    # custructing file_ids array
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
      "message": "'"$MESSAGE"'",
      "file_ids": [
        '"$POST_DATA_FOR_FILES"'
      ]
    }'

    POST_DATA="${POST_DATA//$'\n'/}"

    core::log::debug "CURL_OPTIONS=$CURL_OPTIONS"
    curl::enable_fail
    if [[ "${MATTERMOST_POST}" == "true" ]]; then
        util::cmd::exec --stdout STDOUT --stderr STDERR --catch-sigerr "false" -- curl::post_json $CURL_OPTIONS \
            --header "Accept: application/json" \
            --header "Authorization: Bearer ${ARGS[TOKEN]}" \
            --data "$POST_DATA" \
            ${HOST}/${API_PATH}
        curl_rc=$?
        if [[ $curl_rc -ne 0 ]]; then
            core::log::error "post message failed rc=$curl_rc channel_id=${ARGS[CH]} msg=\"$MESSAGE\" RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
            return 1
        fi
        core::log::debug "post message successed: rc=$curl_rc channel_id=${ARGS[CH]} msg=\"$MESSAGE\" RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
        echo "$STDOUT"
    else
        core::log::info "post message skipped: channel_id=${ARGS[CH]} msg=\"$MESSAGE\""
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
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
mattermost::upload_file() {
    local -r API_PATH="api/v4/files"
    local HOST=""
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
    core::arg::parse "$@"

    [[ "${ARGS[INSECURE]}" == "true" ]] && CURL_OPTIONS="$CURL_OPTIONS --insecure"
    [[ ! -f "${ARGS[FILE]}" ]] && log::error "${ARGS[FILE]} file not found" && return 1

    HOST="$( __mattermost::check_host__ --host "${ARGS[HOST]}" )" || return 1

    core::log::debug "CURL_OPTIONS=$CURL_OPTIONS"
    curl::enable_fail
    if [[ "${MATTERMOST_POST}" == "true" ]]; then
        util::cmd::exec --stdout STDOUT --stderr STDERR --catch-sigerr "false" -- curl::post $CURL_OPTIONS \
            --header "Accept: application/json" \
            --header "Authorization: Bearer ${ARGS[TOKEN]}" \
            --header "Content-Type: multipart/form-data" \
            -F "channel_id=${ARGS[CH]}" \
            -F "files=@${ARGS[FILE]}" \
            ${HOST}/${API_PATH}
        curl_rc=$?
        if [[ $curl_rc -ne 0 ]]; then
            core::log::error "file uploading failed rc=$curl_rc channel_id=${ARGS[CH]} file=${ARGS[FILE]} RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
            return 1
        fi
        core::log::debug "file uploadig successed: rc=$curl_rc channel_id=${ARGS[CH]} file=${ARGS[FILE]} RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
        echo "$STDOUT"
    else
        core::log::info "uploading is skipped: channel_id=${ARGS[CH]} file=${ARGS[FILE]}"
    fi
    return 0
}

# @description upload file and post message with it
# @stdout post message API response (json)
# @stderr Error and debug message.
# @option --message <vahlue> (string)(required): Message.
# @option --file <file> (string)(required): file.
# @option --token <token> (string)(required): token.
# @option --host <value> (string)(required): Mattermost URL such as https://localhost:8065
# @option --ch <value> (string)(required): Mattermost channel ID
# @option --insecure (optional): Ignore certificate errors.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
mattermost::post_msg_with_file() {
    local RES=""
    local FID=""
    local INSECURE_OPTION=""

    core::arg::init_local
    core::arg::add_option -l "MESSAGE" -o "--message" -r "true" -h "post message"
    core::arg::add_option -l "FILE" -o "--file" -r "true" -h "post message"
    core::arg::add_option -l "TOKEN" -o "--token" -r "true" -h "token"
    core::arg::add_option -l "HOST" -o "--host" -r "true" -h "mattermost host such as https://localhost:8065"
    core::arg::add_option -l "CH" -o "--ch" -r "true" -h "The ID of the channel that this file will be uploaded to"
    core::arg::add_option -l "INSECURE" -o "--insecure" -r "false" -t "bool" -s "true" -h "ignore certificate errors"
    core::arg::parse "$@"

    [[ "${ARGS[INSECURE]}" == "true" ]] && INSECURE_OPTION="--insecure"

    RES=$( mattermost::upload_file --file "${ARGS[FILE]}" --host "${ARGS[HOST]}" --token "${ARGS[TOKEN]}" --ch "${ARGS[CH]}" "$INSECURE_OPTION" ) || return 1
    if ! FID=$( echo "$RES" | jq -r '.file_infos[0].id' ); then
        log::error "cannot parse json response"
        return 1
    fi
    if [[ "$FID" == "null" ]]; then
        log::error "cannot extract file ID (ID=null)"
        return 1
    fi
    mattermost::post_msg --message "${ARGS[MESSAGE]}" --host "${ARGS[HOST]}" --token "${ARGS[TOKEN]}" --ch "${ARGS[CH]}" "$INSECURE_OPTION" --files "$FID" || return 1
    return 0
}

