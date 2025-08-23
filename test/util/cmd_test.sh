#!/usr/bin/env bash

set_up() {
    ROOT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"
    source "$ROOT_DIR/../../lib/neobash.sh"
    nb::import "util/cmd.sh"
}

# executing command test

test_util::cmd_cmd_normal_ok() {
    local OUTPUT
    local ERROR

    util::cmd::exec --stdout OUTPUT --stderr ERROR -- echo "myout"
    assert_exit_code "0"
    assert_matches "^myout$" "$OUTPUT"
    assert_empty "$ERROR"
}

test_util::cmd_cmd_normal_error() {
    local OUTPUT
    local ERROR

    util::cmd::exec --stdout OUTPUT --stderr ERROR -- /usr/bin/bash -c "echo myout; echo myerror >&2; exit 1"
    assert_exit_code "1"
    assert_matches "^myout$" "$OUTPUT"
    assert_matches "^myerror$" "$ERROR"
}

test_util::cmd_cmd_normal_error_no_stdout_variable() {
    local OUTPUT

    OUTPUT=$( util::cmd::exec -- /usr/bin/bash -c "echo myout; exit 1" )
    assert_exit_code "1"
    assert_matches "^myout$" "$OUTPUT"
}

test_util::cmd_cmd_normal_error_no_stderr_variable() {
    local OUTPUT

    OUTPUT=$( util::cmd::exec -- /usr/bin/bash -c "echo myout; echo myerror >&2; exit 1" 2>&1 >/dev/null )
    assert_exit_code "1"
    assert_matches "^myerror$" "$OUTPUT"
}

test_util::cmd_cmd_retry_errror() {
    local OUTPUT
    local ERROR

    util::cmd::exec --stdout OUTPUT --stderr ERROR --retry 1 -- /usr/bin/bash -c "echo myout; echo myerror >&2; exit 1"
    assert_exit_code "1"
    assert_matches "^myout$" "$OUTPUT"
    assert_matches "^myerror$" "$ERROR"
}

test_util::cmd_cmd_timeout_SIGTERM() {
    local OUTPUT
    local ERROR

    util::cmd::exec --stdout OUTPUT --stderr ERROR --timeout 1 --grace-period 1 -- sleep 5
    assert_exit_code "124"
    assert_empty "$OUTPUT"
    assert_empty "$ERROR"
}

test_util::cmd_cmd_timeout_SIGKILL() {
    local OUTPUT
    local ERROR

    util::cmd::exec --stdout OUTPUT --stderr ERROR --timeout 1 --grace-period 10 -- sleep 2
    assert_exit_code "124"
    assert_empty "$OUTPUT"
    assert_empty "$ERROR"
}

test_util::cmd_cmd_timeout_SIGKILL_grace_0() {
    local OUTPUT
    local ERROR

    util::cmd::exec --stdout OUTPUT --stderr ERROR --timeout 1 --grace-period 0 -- sleep 2
    assert_exit_code "124"
    assert_empty "$OUTPUT"
    assert_empty "$ERROR"
}

test_util::cmd_cmd_env_noclear() {
    local OUTPUT
    local ERROR

    export MYENV="myenv"
    util::cmd::exec --stdout OUTPUT --stderr ERROR -- /usr/bin/bash -c "export | grep MYENV"
    assert_exit_code "0"
    assert_matches '^declare -x MYENV="myenv"$' "$OUTPUT"
    assert_empty "$ERROR"
}

test_util::cmd_cmd_env_clear() {
    local OUTPUT
    local ERROR

    export MYENV="myenv"
    util::cmd::exec --stdout OUTPUT --stderr ERROR --clear-env true -- /usr/bin/bash -c "export | grep MYENV"
    assert_exit_code "1"
    assert_empty "$OUTPUT"
    assert_empty "$ERROR"
}


# executing function test

test_util::cmd_func_normal_ok() {
    local OUTPUT
    local ERROR

    internal() {
        echo myout
        return 0
    }

    util::cmd::exec --stdout OUTPUT --stderr ERROR -- internal
    assert_exit_code "0"
    assert_matches "^myout$" "$OUTPUT"
    assert_empty "$ERROR"
}

test_util::cmd_func_normal_error() {
    local OUTPUT
    local ERROR

    internal() {
        echo myout
        echo myerror >&2
        return 3
    }

    util::cmd::exec --stdout OUTPUT --stderr ERROR -- internal
    assert_exit_code "3"
    assert_matches "^myout$" "$OUTPUT"
    assert_matches "^myerror$" "$ERROR"
}

test_util::cmd_func_normal_error_no_stdout_variable() {
    local OUTPUT

    internal() {
        echo myout
        return 3
    }

    OUTPUT=$( util::cmd::exec -- internal )
    assert_exit_code "3"
    assert_matches "^myout$" "$OUTPUT"
}

test_util::cmd_func_normal_error_no_stderr_variable() {
    local OUTPUT

    internal() {
        echo myout
        echo myerror >&2
        return 3
    }

    OUTPUT=$( util::cmd::exec -- internal 2>&1 >/dev/null )
    assert_exit_code "3"
    assert_matches "^myerror$" "$OUTPUT"
}

test_util::cmd_func_retry_errror() {
    local OUTPUT
    local ERROR

    internal() {
        echo myout
        echo myerror >&2
        return 1
    }

    util::cmd::exec --stdout OUTPUT --stderr ERROR --retry 1 -- internal
    assert_exit_code "1"
    assert_matches "^myout$" "$OUTPUT"
    assert_matches "^myerror$" "$ERROR"
}

test_util::cmd_func_timeout_SIGTERM() {
    local OUTPUT
    local ERROR

    internal() {
        sleep 5
    }

    util::cmd::exec --stdout OUTPUT --stderr ERROR --timeout 1 --grace-period 1 -- internal
    assert_exit_code "124"
    assert_empty "$OUTPUT"
    assert_empty "$ERROR"
}

test_util::cmd_func_timeout_SIGKILL() {
    local OUTPUT
    local ERROR

    internal() {
        sleep 2
    }

    util::cmd::exec --stdout OUTPUT --stderr ERROR --timeout 1 --grace-period 10 -- internal
    assert_exit_code "124"
    assert_empty "$OUTPUT"
    assert_empty "$ERROR"
}

test_util::cmd_func_timeout_SIGKILL_grace_0() {
    local OUTPUT
    local ERROR

    internal() {
        sleep 2
    }

    util::cmd::exec --stdout OUTPUT --stderr ERROR --timeout 1 --grace-period 0 -- internal
    assert_exit_code "124"
    assert_empty "$OUTPUT"
    assert_empty "$ERROR"
}

test_util::cmd_func_env_noclear() {
    local OUTPUT
    local ERROR

    internal() {
        export | grep MYENV
    }

    export MYENV="myenv"
    util::cmd::exec --stdout OUTPUT --stderr ERROR -- internal
    assert_exit_code "0"
    assert_matches '^declare -x MYENV="myenv"$' "$OUTPUT"
    assert_empty "$ERROR"
}

test_util::cmd_func_env_clear() {
    local OUTPUT
    local ERROR

    internal() {
        export | grep MYENV
    }

    export MYENV="myenv"
    util::cmd::exec --stdout OUTPUT --stderr ERROR --clear-env true -- internal
    assert_exit_code "127"
    assert_empty "$OUTPUT"
    assert_matches "No such file or directory$" "$ERROR"
}

