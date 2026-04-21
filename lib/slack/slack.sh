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
nb::command_check "curl"

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
        core::log::error "Invalid slack hostname: $HOST"
        return 1
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
        core::log::error "slack ping failed rc=$curl_rc RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
        return 1
    fi
    return 0
}

# @description Post a message to slack using incoming webhook.
# @stdout API response (json)
# @stderr Error and debug message.
# @option --message / -m <vahlue> (string)(required): Message.
# @option --url / -u <value> (string)(required): Incoming webhook URL.
# @option --type / -t <value> (string)(option): Message type. text or mrkdwn
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
    [[ "${ARGS[API_URL]}" == "" ]] && log::error "incoming webhook URL is empty" && return 1
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
        core::log::error "invalid type ${ARGS[TYPE]}"
        return 1
    fi

    curl::enable_fail
    if [[ "${SLACK_POST}" == "true" ]]; then
        util::cmd::exec --stdout STDOUT --stderr STDERR --catch-sigerr "false" -- curl::post_json $CURL_OPTIONS \
            -d "$MSG_DATA" "${ARGS[API_URL]}"
        curl_rc=$?

        if [[ $curl_rc -ne 0 ]]; then
            core::log::error "post message failed rc=$curl_rc msg=\"$MESSAGE\" RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
            return 1
        fi
        core::log::debug "post message successed: rc=$curl_rc msg=\"$MESSAGE\" RESPONSE=\"$STDOUT\" CURL_ERROR_LOG=\"$STDERR\""
        echo "$STDOUT"
    else
        core::log::info "post message skipped: msg=\"$MESSAGE\""
    fi
    return 0
}

