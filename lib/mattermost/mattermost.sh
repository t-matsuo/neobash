#!/usr/bin/env bash
# Copyright 2025 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license

nb::require "core/log.sh core/arg.sh"
nb::command_check "curl"

MATTERMOST_POST="true"

# @description Post a message to mattermost using incoming webhook.
# @stdout Show a post message if MATTERMOST_POST=true.
# @stderr Error and debug message.
# @option --message / -m <vahlue> (string)(required): Message.
# @option --url / -u <value> (string)(required): Incoming webhook URL.
# @option --insecure (optional): Ignore certificate errors.
# @option --verbose (optional): Verbose log.
# @exitcode 0 If successfull.
# @exitcode 1 If failed.
mattermost::post() {
    local MESSAGE
    local ESCAPED_MESSAGE
    local API_URL
    local CURL_OPTIONS=""
    local CURL_LOG
    local curl_rc

    core::arg::init_local
    core::arg::add_option -l "MESSAGE" -o "--message" -r "true" -h "post message"
    core::arg::add_option_alias -l "MESSAGE" -a "-m"
    core::arg::add_option -l "API_URL" -o "--url" -r "true" -h "mattermost api url"
    core::arg::add_option_alias -l "API_URL" -a "-u"
    core::arg::add_option -l "INSECURE" -o "--insecure" -r "false" -t "bool" -s "true" -h "ignore certificate errors"
    core::arg::add_option -l "VERBOSE" -o "--verbose" -r "false" -t "bool" -s "true" -h "verbose curl log"
    core::arg::add_option_alias -l "VERBOSE" -a "-v"
    core::arg::parse "$@"
    MESSAGE=$( core::arg::get_value -l "MESSAGE" )
    API_URL=$( core::arg::get_value -l "API_URL" )

    [[ "$MESSAGE" == "" ]] && log::error "post message is empty" && return 1
    [[ "$API_URL" == "" ]] && log::error "incoming webhook URL is empty" && return 1
    [[ "${CORE_ARG_VALUE[INSECURE]}" == "true" ]] && CURL_OPTIONS="$CURL_OPTIONS --insecure"
    [[ "${CORE_ARG_VALUE[VERBOSE]}" == "true" ]] && CURL_OPTIONS="$CURL_OPTIONS --verbose"
    core::log::debug "CURL_OPTIONS=$CURL_OPTIONS"

    # escape double quote
    ESCAPED_MESSAGE="${MESSAGE//\"/\\\"}"

    # remove control characters
    ESCAPED_MESSAGE="${ESCAPED_MESSAGE//[]/}"

    if [[ "${MATTERMOST_POST}" == "true" ]]; then
        CURL_LOG=$( curl $CURL_OPTIONS -s --fail-with-body -XPOST -H 'Content-Type: application/json' \
                        -d '{"text": "'"$ESCAPED_MESSAGE"'"}' "${API_URL}" 2>&1)
        curl_rc=$?
        if [[ $curl_rc -ne 0 ]]; then
            core::log::error "mattermost post failed: CURL_EXIT_CODE=$curl_rc CURL_LOG=\"$CURL_LOG\" POST_MESSAGE=\"$ESCAPED_MESSAGE\""
            return 1
        fi
        core::log::debug "mattermost post successed: CURL_EXIT_CODE=$curl_rc CURL_LOG=\"$CURL_LOG\" POST_MESSAGE=\"$ESCAPED_MESSAGE\""
    else
        core::log::info "mattermost post skipped: POST_MESSAGE=\"$ESCAPED_MESSAGE\""
    fi
}
