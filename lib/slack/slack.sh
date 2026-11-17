#!/usr/bin/env bash
# Copyright 2026 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license

# @file slack/slack.sh
# @brief slack library
# @description
# Useful functions for using slack.
#
# This library can change its behavior by setting the following environment variables.
#
# * SLACK_POST : if false, it outputs logs only instead of calling api such as post, upload and so on. default: ``true``

nb::require "core/log.sh core/arg.sh"
nb::import "curl/curl.sh"
nb::import "util/cmd.sh"
nb::command_check "curl jq"

SLACK_POST="true"

# @internal
# @description check slack hostname and strip last "/"
__slack::check_host__() {
    local HOST=""
    core::arg::init_local
    core::arg::add_option -l "HOST" -o "--host" -r "true" -h "slack host such as https://localhost:8065"
    core::arg::parse "$@"

    HOST="${ARGS[HOST]}"
    if [[ ! "$HOST" =~ ^https?://[.a-zA-Z0-9:-]+/?$ ]]; then
        core::log::error_exit "Invalid slack hostname: $HOST"
    fi
    HOST="${HOST%/}"
    echo "$HOST"
    return 0
}

# @internal
# @description escape message
__slack::escape_message__() {
    local MESSAGE=""
    core::arg::init_local
    core::arg::add_option -l "MESSAGE" -o "--message" -r "true" -h "message"
    core::arg::parse "$@"

    MESSAGE="${ARGS[MESSAGE]}"
    # escape double quote
    MESSAGE="${MESSAGE//\"/\\\"}"
    # replace break
    MESSAGE="${MESSAGE//$'\n'/\\n}"
    # remove control characters
    MESSAGE="${MESSAGE//[]/}"
    echo "$MESSAGE"
    return 0
}

# @description Ping slack host.
# @stdout None
# @stderr Error and debug message.
# @option --host <value> (string)(required): Slack URL such as https://localhost:8065
# @option --insecure (optional): Ignore certificate errors.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
slack::ping() {
    local HOST=""
    local CURL_OPTIONS="-X OPTIONS"
    local curl_rc=""
    local STDOUT=""
    local STDERR=""

    core::arg::init_local
    core::arg::add_option -l "HOST" -o "--host" -r "true" -h "slack host such as https://hooks.slack.com"
    core::arg::add_option -l "INSECURE" -o "--insecure" -r "false" -t "bool" -s "true" -h "ignore certificate errors"
    core::arg::parse "$@"

    core::log::debug "CURL_OPTIONS=$CURL_OPTIONS"

    HOST="$( __slack::check_host__ --host "${ARGS[HOST]}" )" || return 1
    core::log::debug "Slack ping URL: ${HOST}"

    curl::enable_fail
    util::cmd::exec --stdout STDOUT --stderr STDERR --catch-sigerr "false" -- curl::get $CURL_OPTIONS -s "${HOST}"
    curl_rc=$?
    if [[ "$curl_rc" -ne 0 ]]; then
        core::log::error_exit "slack ping failed rc=$curl_rc RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
    fi
    return 0
}

# @description Post a message to slack using incoming webhook.
# @stdout API response (json)
# @stderr Error and debug message.
# @option --message / -m <vahlue> (string)(required): Message.
# @option --url / -u <value> (string)(required): Incoming webhook URL.
# @option --type / -t <value> (string)(option): Message type. text or mrkdwn (default: text)
# @option --insecure (optional): Ignore certificate errors.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
slack::webhook_post() {
    local MESSAGE=""
    local MSG_DATA=""
    local CURL_OPTIONS=""
    local curl_rc=""
    local STDOUT=""
    local STDERR=""

    core::arg::init_local
    core::arg::add_option -l "MESSAGE" -o "--message" -r "true" -h "post message"
    core::arg::add_option_alias -l "MESSAGE" -a "-m"
    core::arg::add_option -l "API_URL" -o "--url" -r "true" -h "webhook api url"
    core::arg::add_option_alias -l "API_URL" -a "-u"
    core::arg::add_option -l "TYPE" -o "--type" -r "false" -d "text" -h "message type (text or mrkdwn)"
    core::arg::add_option_alias -l "TYPE" -a "-t"
    core::arg::add_option -l "INSECURE" -o "--insecure" -r "false" -t "bool" -s "true" -h "ignore certificate errors"
    core::arg::parse "$@"

    [[ "${ARGS[INSECURE]}" == "true" ]] && CURL_OPTIONS="$CURL_OPTIONS --insecure"
    [[ "${ARGS[API_URL]}" == "" ]] && log::error_exit "incoming webhook URL is empty"
    core::log::debug "CURL_OPTIONS=$CURL_OPTIONS"

    slack::ping --host "https://hooks.slack.com" || return 1
    MESSAGE="$( __slack::escape_message__ --message "${ARGS[MESSAGE]}" )"

    if [[ "${ARGS[TYPE]}" == "text" ]]; then
        MSG_DATA='{"text": "'"$MESSAGE"'"}'
    elif [[ "${ARGS[TYPE]}" == "mrkdwn" ]]; then
        MSG_DATA='{"blocks":
            [
                {
                    "type": "section",
                    "text": {
                        "type": "'"${ARGS[TYPE]}"'",
                        "text": "'"$MESSAGE"'"
                    }
                }
            ]
        }'
    else
        core::log::error_exit "invalid type ${ARGS[TYPE]}"
    fi

    curl::enable_fail
    if [[ "${SLACK_POST}" == "true" ]]; then
        util::cmd::exec --stdout STDOUT --stderr STDERR --catch-sigerr "false" -- curl::post_json $CURL_OPTIONS \
            -d "$MSG_DATA" "${ARGS[API_URL]}"
        curl_rc=$?

        if [[ $curl_rc -ne 0 ]]; then
            core::log::error_exit "post message failed rc=$curl_rc msg=\"$MESSAGE\" RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
        fi
        core::log::debug "post message successed: rc=$curl_rc msg=\"$MESSAGE\" RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
        echo "$STDOUT"
    else
        core::log::info "post message skipped: msg=\"$MESSAGE\""
    fi
    return 0
}

# @description Post a message to slack using chat.postMessage API.
# @stdout API response (json)
# @stderr Error and debug message.
# @option --message <value> (string)(required): Message.
# @option --type / -t <value> (string)(option): Message type. text or mrkdwn or markdown (default: mrkdwn)
# @option --token <value> (string)(required): Slack bot token.
# @option --ch <value> (string)(required): Channel id.
# @option --insecure (optional): Ignore certificate errors.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
slack::post_msg() {
    local MESSAGE=""
    local MSG_DATA=""
    local CURL_OPTIONS=""
    local curl_rc=""
    local STDOUT=""
    local STDERR=""
    local MSG_TYPE="mrkdwn"

    core::arg::init_local
    core::arg::add_option -l "MESSAGE" -o "--message" -r "true" -h "post message"
    core::arg::add_option -l "TYPE" -o "--type" -r "false" -d "mrkdwn" -h "message type (text or mrkdwn or markdown) (default: mrkdwn)" 
    core::arg::add_option_alias -l "TYPE" -a "-t"
    core::arg::add_option -l "TOKEN" -o "--token" -r "true" -h "token"
    core::arg::add_option -l "CH" -o "--ch" -r "true" -h "channel id"
    core::arg::add_option -l "INSECURE" -o "--insecure" -r "false" -t "bool" -s "true" -h "ignore certificate errors"
    core::arg::parse "$@"

    [[ "${ARGS[INSECURE]}" == "true" ]] && CURL_OPTIONS="$CURL_OPTIONS --insecure"
    core::log::debug "CURL_OPTIONS=$CURL_OPTIONS"

    [[ "${ARGS[TYPE]}" != "text" ]] && [[ "${ARGS[TYPE]}" != "mrkdwn" ]] && [[ "${ARGS[TYPE]}" != "markdown" ]] && \
        core::log::error_exit "invalid type ${ARGS[TYPE]}"

    MESSAGE="$( __slack::escape_message__ --message "${ARGS[MESSAGE]}" )"

    [[ "${ARGS[TYPE]}" == "text" ]] && MSG_TYPE="plain_text"
    if [[ "${ARGS[TYPE]}" == "markdown" ]]; then
        MSG_DATA='{
            "channel":"'"${ARGS[CH]}"'",
            "markdown_text":"'"$MESSAGE"'"
        }'
    else
        MSG_DATA='{
            "channel":"'"${ARGS[CH]}"'",
            "blocks":
            [
                {
                    "type": "section",
                    "text": {
                        "type": "'"$MSG_TYPE"'",
                        "text": "'"$MESSAGE"'"
                    }
                }
            ]
        }'
    fi

    curl::enable_fail
    if [[ "${SLACK_POST}" == "true" ]]; then
        util::cmd::exec --stdout STDOUT --stderr STDERR --catch-sigerr "false" -- curl::post_json $CURL_OPTIONS \
            --header "Authorization: Bearer ${ARGS[TOKEN]}" \
            -d "$MSG_DATA" \
            "https://slack.com/api/chat.postMessage"
        curl_rc=$?

        if [[ $curl_rc -ne 0 ]]; then
            core::log::error_exit "post markdown message failed rc=$curl_rc ch=\"${ARGS[CH]}\" msg=\"$MESSAGE\" RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
        fi
        core::log::debug "post markdown message successed: rc=$curl_rc ch=\"${ARGS[CH]}\" msg=\"$MESSAGE\" RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
        echo "$STDOUT"
    else
        core::log::info "post markdown message skipped: ch=\"${ARGS[CH]}\" msg=\"$MESSAGE\""
    fi
    return 0
}

# @description Upload a file to slack using files.getUploadURLExternal and files.completeUploadExternal.
# @stdout API response (json) from files.completeUploadExternal
# @stderr Error and debug message.
# @option --file <value> (string)(required): File path to upload.
# @option --token <value> (string)(required): Slack bot token.
# @option --ch <value> (string)(required): The ID of the channel that this file will be uploaded to.
# @option --title <value> (string)(optional): Title of file (default: basename of file).
# @option --message <value> (string)(optional): Message text introducing the file. Slack mrkdwn is available.
# @option --thread-ts <value> (string)(optional): Parent message ts to upload as reply.
# @option --insecure (optional): Ignore certificate errors.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
slack::upload_file() {
    local CURL_OPTIONS=""
    local curl_rc=""
    local STDOUT=""
    local STDERR=""
    local GET_URL_RES=""
    local UPLOAD_URL=""
    local FILE_ID=""
    local FILENAME=""
    local FILE_LENGTH=""
    local TITLE=""
    local MESSAGE=""
    local PAYLOAD=""

    core::arg::init_local
    core::arg::add_option -l "FILE" -o "--file" -r "true" -h "file path to upload"
    core::arg::add_option -l "TOKEN" -o "--token" -r "true" -h "token"
    core::arg::add_option -l "CH" -o "--ch" -r "true" -h "The ID of the channel that this file will be uploaded to"
    core::arg::add_option -l "TITLE" -o "--title" -r "false" -h "title of file (default: basename of file)"
    core::arg::add_option -l "MESSAGE" -o "--message" -r "false" -h "message text introducing the file"
    core::arg::add_option -l "THREAD_TS" -o "--thread-ts" -r "false" -h "parent message ts to upload as reply"
    core::arg::add_option -l "INSECURE" -o "--insecure" -r "false" -t "bool" -s "true" -h "ignore certificate errors"
    core::arg::parse "$@"

    [[ "${ARGS[INSECURE]}" == "true" ]] && CURL_OPTIONS="$CURL_OPTIONS --insecure"
    core::log::debug "CURL_OPTIONS=$CURL_OPTIONS"

    [[ ! -f "${ARGS[FILE]}" ]] && core::log::error_exit "${ARGS[FILE]} file not found"

    FILENAME="$(basename "${ARGS[FILE]}")"
    FILE_LENGTH="$(stat -c %s "${ARGS[FILE]}")"
    TITLE="${ARGS[TITLE]}"
    [[ -z "$TITLE" ]] && TITLE="$FILENAME"
    TITLE="$( __slack::escape_message__ --message "$TITLE" )"

    curl::enable_fail
    if [[ "${SLACK_POST}" == "true" ]]; then
        util::cmd::exec --stdout GET_URL_RES --stderr STDERR --catch-sigerr "false" -- curl::post $CURL_OPTIONS \
            --header "Authorization: Bearer ${ARGS[TOKEN]}" \
            --data-urlencode "filename=${FILENAME}" \
            --data-urlencode "length=${FILE_LENGTH}" \
            "https://slack.com/api/files.getUploadURLExternal"
        curl_rc=$?
        if [[ $curl_rc -ne 0 ]]; then
            core::log::error_exit "get upload url failed rc=$curl_rc file=${ARGS[FILE]} RESPONSE=\"$GET_URL_RES\" CURL_ERROR_LOG=\"$STDERR\""
        fi
        core::log::debug "get upload url succeeded: rc=$curl_rc file=${ARGS[FILE]} RESPONSE=\"$GET_URL_RES\" CURL_ERROR_LOG=\"$STDERR\""

        if [[ "$( echo "$GET_URL_RES" | jq -r '.ok' )" != "true" ]]; then
            core::log::error_exit "get upload url failed: $GET_URL_RES"
        fi
        UPLOAD_URL="$( echo "$GET_URL_RES" | jq -r '.upload_url' )"
        FILE_ID="$( echo "$GET_URL_RES" | jq -r '.file_id' )"

        util::cmd::exec --stdout STDOUT --stderr STDERR --catch-sigerr "false" -- curl::post $CURL_OPTIONS \
            --header "Authorization: Bearer ${ARGS[TOKEN]}" \
            --header "Content-Type: application/octet-stream" \
            --data-binary "@${ARGS[FILE]}" \
            "$UPLOAD_URL"
        curl_rc=$?
        if [[ $curl_rc -ne 0 ]]; then
            core::log::error_exit "file uploading failed rc=$curl_rc file=${ARGS[FILE]} UPLOAD_URL=\"$UPLOAD_URL\" RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
        fi
        core::log::debug "file upload succeeded: rc=$curl_rc file=${ARGS[FILE]} UPLOAD_URL=\"$UPLOAD_URL\" RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""

        MESSAGE="$( __slack::escape_message__ --message "${ARGS[MESSAGE]}" )"
        PAYLOAD=$(jq -n \
            --arg id "$FILE_ID" \
            --arg title "$TITLE" \
            --arg channel_id "${ARGS[CH]}" \
            --arg message "$MESSAGE" \
            --arg thread_ts "${ARGS[THREAD_TS]}" \
            '{files:[{id:$id,title:$title}],channel_id:$channel_id,initial_comment:(if $message=="" then null else $message end),thread_ts:(if $thread_ts=="" then null else $thread_ts end)} | with_entries(select(.value != null))')

        util::cmd::exec --stdout STDOUT --stderr STDERR --catch-sigerr "false" -- curl::post_json $CURL_OPTIONS \
            --header "Authorization: Bearer ${ARGS[TOKEN]}" \
            -d "$PAYLOAD" \
            "https://slack.com/api/files.completeUploadExternal"
        curl_rc=$?
        if [[ $curl_rc -ne 0 ]]; then
            core::log::error_exit "complete upload failed rc=$curl_rc file=${ARGS[FILE]} RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
        fi

        if [[ "$( echo "$STDOUT" | jq -r '.ok' )" != "true" ]]; then
            core::log::error_exit "complete upload failed: $STDOUT"
        fi
        core::log::debug "complete upload succeeded: rc=$curl_rc file=${ARGS[FILE]} RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
        echo "$STDOUT"
    else
        core::log::info "uploading is skipped: file=${ARGS[FILE]} channel_id=${ARGS[CH]}"
    fi
    return 0
}

