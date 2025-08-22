#!/usr/bin/env bash
# Copyright 2025 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license
#
# @file util/cmd.sh
# @brief Neobash util/cmd.sh library
# @description
# * library for executing command or function

nb::require "core/log.sh core/arg.sh"
nb::command_check "sleep kill"
nb::check_bash_min_version "4.3.0" \
    || core::log::error_exit "bash version 4.3.0 or higher is required for using util/cmd.sh library to use nameref"

# @description Wrapper function for executing specified function or command. It can assign stdout/stderr output to separate variables.
#
# @option --stdout <string> Variable name to assign stdout. (required)
# @option -o <string> Alias for --stdout
# @option --stdout <string> Variable name to assign stderr. (required)
# @option -e <string> Alias for --stderr
# @option --catch-sigerr <true/false> False means drop SIGERR log (optional) DEFAULT:``$LOG_SIGERR`` (variable of core/log.sh library)
# @option -s <string> Alias for --catch-sigerr
# @option --clear-env <true/false> True means clearing all environment varialbes when executing command. you cannot use true when executing function. (optional) DEFAULT:``false``
# @option -c <string> Alias for --clear-env
# @option --timeout <int> Timeout(sec). 0 means no timeout. DEFAULT:``600.``
# @option -t <int> Alias for --timeout
# @option --grace-period <int> Grace period for timed out (TERM->KILL) (sec). DEFAULT:``1``
# @option -g <int> Alias for --grace-period
# @stdout None.
# @stderr Debug log.
# @exitcode exit code of specified function or command or timedout=124
util::cmd::exec() {
    local __UTIL_CMD_EXEC_STDOUT_MSG__=""
    local __UTIL_CMD_EXEC_ERR_MSG__=""
    local __UTIL_CMD_EXEC_RETURN_CODE__=1
    local __UTIL_CMD_EXEC_LOG_SIGERR_ORG__="$LOG_SIGERR"
    local __UTIL_CMD_EXEC_CLEAR_ALL_ENV__=""
    local __UTIL_CMD_EXEC_RETRY_COUNT__=0
    local __UTIL_CMD_EXEC_STDOUT_FD__=""
    local __UTIL_CMD_EXEC_STDERR_FD__=""
    local __UTIL_CMD_EXEC_CHILD_PID__=""
    local __UTIL_CMD_EXEC_CHILD_PGID__=""
    local __UTIL_CMD_EXEC_TIMEDOUT_COUNTER__=0
    local __UTIL_CMD_EXEC_GRACE_COUNTER__=0
    local __UTIL_CMD_EXEC_ISSUED_SIGNAL__=""

    core::arg::init_local
    arg::add_option       -l "STDOUT" -o "--stdout" -t "string" -r "true" -h "Stdout Variable"
    arg::add_option_alias -l "STDOUT" -o "-o"
    arg::add_option       -l "STDERR" -o "--stderr" -t "string" -r "true" -h "Stderr Variable"
    arg::add_option_alias -l "STDERR" -o "-e"
    arg::add_option       -l "CATCH_SIGERR"   -o "--catch-sigerr" -t "bool" -r "false" -d "$LOG_SIGERR" -h "Catch SIGERR and output it"
    arg::add_option_alias -l "CATCH_SIGERR"   -o "-s"
    arg::add_option       -l "CLEAR_ENV"      -o "--clear-env"    -t "bool" -r "false" -d "false" -h "Clear all environment variables using env -i"
    arg::add_option_alias -l "CLEAR_ENV"      -o "-c"
    arg::add_option       -l "TIMEOUT"        -o "--timeout"      -t "int"  -r "false" -d "600"   -h "command timeout (sec)"
    arg::add_option_alias -l "TIMEOUT"        -o "-t"
    arg::add_option       -l "RETRY_COUNT"    -o "--retry"        -t "int"  -r "false" -d "0"     -h "Retry count. "
    arg::add_option_alias -l "RETRY_COUNT"    -o "-r"
    arg::add_option       -l "RETRY_INTERVAL" -o "--interval"     -t "int"  -r "false" -d "1"     -h "Retry interval time (sec)"
    arg::add_option_alias -l "RETRY_INTERVAL" -o "-i"
    arg::add_option       -l "GRACE_PERIOD"   -o "--grace-period" -t "int"  -r "false" -d "1"     -h "Grace period for timed out (TERM->KILL) (sec)"
    arg::add_option_alias -l "GRACE_PERIOD"   -o "-g"
    core::arg::parse "$@"

    core::log::debug "stdout val=${ARGS[STDOUT]}"
    core::log::debug "stderr val=${ARGS[STDERR]}"

    local -n __UTIL_CMD_STDOUT_RESULT__="${ARGS[STDOUT]}"
    local -n __UTIL_CMD_STDERR_RESULT__="${ARGS[STDERR]}"

    [[ "${ARGS[CLEAR_ENV]}" == "true" ]] && __UTIL_CMD_EXEC_CLEAR_ALL_ENV__="env -i"

    # loop for retry
    while true; do
        LOG_SIGERR="${ARGS[CATCH_SIGERR]}"
        eval "$(
            (
                # create file descriptor for stdout/stderr
                exec {__UTIL_CMD_EXEC_STDOUT_FD__}> >(
                    __UTIL_CMD_EXEC_STDOUT_MSG__=$(cat)
                    typeset -p __UTIL_CMD_EXEC_STDOUT_MSG__
                )
                exec {__UTIL_CMD_EXEC_STDERR_FD__}> >(
                    __UTIL_CMD_EXEC_ERR_MSG__=$(cat)
                    typeset -p __UTIL_CMD_EXEC_ERR_MSG__
                )

                # controlling job for child process to use Process Group
                set -m

                # execute command or function in the background
                (
                    $__UTIL_CMD_EXEC_CLEAR_ALL_ENV__ "${ARG_OTHERS[@]}"
                ) 1>&${__UTIL_CMD_EXEC_STDOUT_FD__} 2>&${__UTIL_CMD_EXEC_STDERR_FD__} &
                # get child process id
                __UTIL_CMD_EXEC_CHILD_PID__=$!

                # execute set -m to prevent child process SIGTERM exit message
                set +m

                # get process group id
                __UTIL_CMD_EXEC_CHILD_PGID__=$( ps -o pgid= -p "$__UTIL_CMD_EXEC_CHILD_PID__" 2>/dev/null ) || true

                # remove spaces
                __UTIL_CMD_EXEC_CHILD_PGID__=${__UTIL_CMD_EXEC_CHILD_PGID__#"${__UTIL_CMD_EXEC_CHILD_PGID__%%[![:space:]]*}"}
                __UTIL_CMD_EXEC_CHILD_PGID__=${__UTIL_CMD_EXEC_CHILD_PGID__%"${__UTIL_CMD_EXEC_CHILD_PGID__##*[![:space:]]}"}
                log::debug "child process PID=$__UTIL_CMD_EXEC_CHILD_PID__ PGID=$__UTIL_CMD_EXEC_CHILD_PGID__ $__UTIL_CMD_EXEC_TIMEDOUT_COUNTER__/${ARGS[TIMEOUT]}"

                # close file descriptor
                exec {__UTIL_CMD_EXEC_STDOUT_FD__}>&-
                exec {__UTIL_CMD_EXEC_STDERR_FD__}>&-

                if [[ ${ARGS[TIMEOUT]} -ne 0 ]]; then
                    # loop for monitoring child process for timed out
                    while kill -0 "$__UTIL_CMD_EXEC_CHILD_PID__" 2>/dev/null; do
                        log::debug "waiting timed out ${__UTIL_CMD_EXEC_TIMEDOUT_COUNTER__}/${ARGS[TIMEOUT]} sec PID=$__UTIL_CMD_EXEC_CHILD_PID__ PGID=$__UTIL_CMD_EXEC_CHILD_PGID__"
                        if [[ __UTIL_CMD_EXEC_TIMEDOUT_COUNTER__ -ge ${ARGS[TIMEOUT]} ]]; then

                            # if grace period is 0, use SIGKILL immediately and break
                            if [[ ${ARGS[GRACE_PERIOD]} -le 0 ]]; then
                                log::debug "grace period is ${ARGS[GRACE_PERIOD]}s so killing child process (SIGKILL) PID=$__UTIL_CMD_EXEC_CHILD_PID__ PGID=$__UTIL_CMD_EXEC_CHILD_PGID__"
                                __UTIL_CMD_EXEC_ISSUED_SIGNAL__="SIGKILL"
                                kill -KILL -"${__UTIL_CMD_EXEC_CHILD_PGID__}" 2>/dev/null
                                break
                            fi

                            log::debug "killing child process (SIGTERM) PID=$__UTIL_CMD_EXEC_CHILD_PID__ PGID=$__UTIL_CMD_EXEC_CHILD_PGID__"
                            if [[ -n $__UTIL_CMD_EXEC_CHILD_PGID__ ]]; then
                                __UTIL_CMD_EXEC_ISSUED_SIGNAL__=SIGTERM
                                kill -TERM -"${__UTIL_CMD_EXEC_CHILD_PGID__}" 2>/dev/null
                                log::debug "waiting grace period 0/${ARGS[GRACE_PERIOD]} sec PID=$__UTIL_CMD_EXEC_CHILD_PID__ PGID=$__UTIL_CMD_EXEC_CHILD_PGID__"

                                # sleep 0.2 sec because child process may not be terminated immediately
                                sleep .2

                                # recheck child process and wait grace period
                                if kill -0 "$__UTIL_CMD_EXEC_CHILD_PID__" 2>/dev/null; then
                                    sleep .8
                                    __UTIL_CMD_EXEC_GRACE_COUNTER__=$(( __UTIL_CMD_EXEC_GRACE_COUNTER__ + 1 ))

                                    # check if child process terminated
                                    while kill -0 "$__UTIL_CMD_EXEC_CHILD_PID__" 2>/dev/null; do
                                        log::debug "waiting grace period ${__UTIL_CMD_EXEC_GRACE_COUNTER__}/${ARGS[GRACE_PERIOD]} sec PID=$__UTIL_CMD_EXEC_CHILD_PID__ PGID=$__UTIL_CMD_EXEC_CHILD_PGID__"
                                        if [[ __UTIL_CMD_EXEC_GRACE_COUNTER__ -ge ${ARGS[GRACE_PERIOD]} ]]; then
                                            log::debug "killing child process (SIGKILL) PID=$__UTIL_CMD_EXEC_CHILD_PID__ PGID=$__UTIL_CMD_EXEC_CHILD_PGID__"
                                            __UTIL_CMD_EXEC_ISSUED_SIGNAL__=SIGKILL
                                            kill -KILL -"${__UTIL_CMD_EXEC_CHILD_PGID__}" 2>/dev/null
                                            break
                                        fi
                                        sleep 1
                                        __UTIL_CMD_EXEC_GRACE_COUNTER__=$(( __UTIL_CMD_EXEC_GRACE_COUNTER__ + 1 ))
                                    done
                                fi
                            fi
                            break
                        fi
                        sleep 1
                        __UTIL_CMD_EXEC_TIMEDOUT_COUNTER__=$(( __UTIL_CMD_EXEC_TIMEDOUT_COUNTER__ + 1 ))
                    done
                    # end of loop for timeout
                else
                    log::debug "timeout is disabled"
                fi

                wait "$__UTIL_CMD_EXEC_CHILD_PID__"
                __UTIL_CMD_EXEC_RETURN_CODE__=$?

                # if SIGTERM or SIGKILL were issued by timed out, return 124 (timed out) regardless of the return code of the child process
                if [[ -n "$__UTIL_CMD_EXEC_ISSUED_SIGNAL__" ]]; then
                    core::log::error "Timed out and $__UTIL_CMD_EXEC_ISSUED_SIGNAL__ was issued, so return 124. Child process rc=$__UTIL_CMD_EXEC_RETURN_CODE__."
                    __UTIL_CMD_EXEC_RETURN_CODE__=124
                fi
                typeset -p __UTIL_CMD_EXEC_RETURN_CODE__

            # If SIGKILL is issued, bash output message to stderr 'Killed', so prevent it.
            # If you want to debug in ( ), please comment out '2>/dev/null'
            ) 2>/dev/null
        )"
        LOG_SIGERR="$__UTIL_CMD_EXEC_LOG_SIGERR_ORG__"

        # break if command/function return 0
        [[ $__UTIL_CMD_EXEC_RETURN_CODE__ -eq 0 ]] && break
        # break when reaching max retry count
        [[ $__UTIL_CMD_EXEC_RETRY_COUNT__ -ge ${ARGS[RETRY_COUNT]} ]] && break

        __UTIL_CMD_EXEC_RETRY_COUNT__=$(( __UTIL_CMD_EXEC_RETRY_COUNT__ + 1 ))
        core::log::warn  "Command failed with rc=$__UTIL_CMD_EXEC_RETURN_CODE__. retrying [$__UTIL_CMD_EXEC_RETRY_COUNT__/${ARGS[RETRY_COUNT]}]..."
        core::log::debug "Dropped stdout=\"${__UTIL_CMD_EXEC_STDOUT_MSG__:-}\" / stderr=\"${__UTIL_CMD_EXEC_ERR_MSG__:-}\""
        sleep ${ARGS[RETRY_INTERVAL]}
    done

    core::log::debug "stderr=$__UTIL_CMD_EXEC_ERR_MSG__"
    core::log::debug "stdout=$__UTIL_CMD_EXEC_STDOUT_MSG__"
    core::log::debug "rc=$__UTIL_CMD_EXEC_RETURN_CODE__"

    __UTIL_CMD_STDERR_RESULT__="$__UTIL_CMD_EXEC_ERR_MSG__"
    __UTIL_CMD_STDOUT_RESULT__="$__UTIL_CMD_EXEC_STDOUT_MSG__"
    return $__UTIL_CMD_EXEC_RETURN_CODE__
}

