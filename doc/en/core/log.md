# core/log.sh

Neobash core logging library

## Overview

The neobash core logging library provides structured log output for bash scripts.
It supports multiple severity levels, optional stack traces, configurable output
destinations, and both plain and JSON formatting.

Features:
* Output logs of various types: debug, info, notice, warn, error, crit, and stacktrace.
* Log format can be `plain` or `json`.
* Log messages are colored and timestamped by default when writing to a terminal.
* Control characters in log messages are removed.
* Output destination can be stdout, stderr, and/or a file.
* Unexpected SIGINT, SIGTERM, and SIGERR signals are caught and logged with a stack trace.

The behavior of this library is controlled by environment variables.

## Log level switches
Set each variable to `true` or `false`.
* `LOG_CRIT`: Enable CRIT log output. default: `true`
* `LOG_ERROR`: Enable ERROR log output. default: `true`
* `LOG_WARN`: Enable WARN log output. default: `true`
* `LOG_NOTICE`: Enable NOTICE log output. default: `true`
* `LOG_INFO`: Enable INFO log output. default: `true`
* `LOG_DEBUG`: Enable DEBUG log output. default: `false`
* `LOG_STDERR`: Enable stderr capture log output. default: `true`
* `LOG_SIGERR`: Enable SIGERR log output. default: `true`
* `LOG_SIGTERM`: Enable SIGTERM log output. default: `true`

## Log format settings
* `LOG_FORMAT`: Set the log format to `plain` or `json`. default: `plain`
* `LOG_STACK_TRACE`: Enable stack traces for CRIT, DEBUG, and ERROR logs. default: `true`
* `LOG_TIMESTAMP`: Enable timestamps on all logs. default: `true`
* `LOG_TIMESTAMP_FORMAT`: Set the timestamp format using printf formatting. default: `%F-%T%z`
* `LOG_ESCAPE_LINE_BREAK`: Escape line breaks and `\n` to `\\n`. default: `true`

## Log output destinations
* `LOG_TERMINAL`: Enable output to the terminal. default: `true`
* `LOG_FILE`: Set the log file path. default: empty (no file output)

## Log prefixes
* `LOG_PREFIX_CRIT`: Prefix for CRIT logs. default: `CRIT`
* `LOG_PREFIX_ERROR`: Prefix for ERROR logs. default: `ERROR`
* `LOG_PREFIX_WARN`: Prefix for WARN logs. default: `WARN`
* `LOG_PREFIX_NOTICE`: Prefix for NOTICE logs. default: `NOTICE`
* `LOG_PREFIX_INFO`: Prefix for INFO logs. default: `INFO`
* `LOG_PREFIX_DEBUG`: Prefix for DEBUG logs. default: `DEBUG`
* `LOG_PREFIX_TRACE`: Prefix for TRACE logs. default: `TRACE`
* `LOG_PREFIX_STDERR`: Prefix for stderr capture logs. default: `STDERR`
* `LOG_PREFIX_SIGNAL`: Prefix for signal logs. default: `SIGNAL`

## Debug log filters
* `LOG_DEBUG_FUNC`: Output debug logs only from matching function names. default: `""`
* `LOG_DEBUG_FILE`: Output debug logs only from matching file or directory names. default: `""`
* `LOG_DEBUG_NO_FUNC`: Suppress debug logs from matching function names. default: `""`
* `LOG_DEBUG_NO_FILE`: Suppress debug logs from matching file or directory names. default: `""`

Example: enable debug log and disable stack trace.
```bash
LOG_DEBUG=true LOG_STACK_TRACE=false ./myscript.sh
```

Example: enable debug log for specific functions.
```bash
LOG_DEBUG_FUNC="mylib::get_xxx mylib::set_xxx" ./myscript.sh
```

Example: enable debug log for a specific file.
```bash
LOG_DEBUG_FILE="mylib/myutil.sh" ./myscript.sh
```

## Index

* [core::log::stack_trace](#corelogstack_trace)
* [core::log::crit](#corelogcrit)
* [core::log::sig_error](#corelogsig_error)
* [core::log::sig_term](#corelogsig_term)
* [core::log::error](#corelogerror)
* [core::log::error_exit](#corelogerror_exit)
* [core::log::echo](#corelogecho)
* [core::log::echo_err](#corelogecho_err)
* [core::log::warn](#corelogwarn)
* [core::log::notice](#corelognotice)
* [core::log::info](#coreloginfo)
* [core::log::debug](#corelogdebug)
* [core::log::is_debug](#corelogis_debug)
* [core::log::enable_err_trap](#corelogenable_err_trap)
* [core::log::disable_err_trap](#corelogdisable_err_trap)
* [core::log::enable_term_trap](#corelogenable_term_trap)
* [core::log::disable_term_trap](#corelogdisable_term_trap)
* [core::log::disable_prefixes](#corelogdisable_prefixes)
* [core::log::disable_decorations](#corelogdisable_decorations)

### core::log::stack_trace

Print a stack trace.
Used internally by CRIT, DEBUG, and ERROR log functions when LOG_STACK_TRACE is enabled.
In JSON mode, the trace is appended to the log message passed to this function.

#### Arguments

* **$1** (string): Log level prefix used in JSON output.
* **$2** (string): Log message used in JSON output.

#### Exit codes

* **0**: Always.

#### Output on stdout

* Stack trace frames in plain mode.

#### Output on stderr

* none.

### core::log::crit

Log a critical message and exit the script.
Alias: `log::crit`.

#### Arguments

* **$1** (string): Log message.

#### Exit codes

* **1**: Always.

#### Output on stderr

* Critical log message and stack trace.

### core::log::sig_error

Log a SIGERR signal event.
This function is invoked by the ERR trap when a command returns a non-zero exit code unexpectedly.

#### Arguments

* **$1** (string): Log message.

#### Exit codes

* **0**: Always.

#### Output on stderr

* Signal log message and stack trace.

### core::log::sig_term

Log a SIGTERM signal event.
This function is invoked by the TERM trap.

#### Arguments

* **$1** (string): Log message.

#### Exit codes

* **0**: Always.

#### Output on stderr

* Signal log message and stack trace.

### core::log::error

Log an error message.
Alias: `log::error`.

#### Arguments

* **$1** (string): Log message.

#### Exit codes

* **0**: Always.

#### Output on stderr

* Error log message and stack trace.

### core::log::error_exit

Log an error message and exit the script.
Alias: `log::error_exit`.

#### Arguments

* **$1** (string): Log message.
* **$2** (int): Exit code. default: `1`.

#### Exit codes

* $**2**: The supplied exit code, or `1` by default.

#### Output on stderr

* Error log message and stack trace.

#### See also

* [core::log::error](#corelogerror)

### core::log::echo

Print a message to the original stdout.
Use this instead of plain `echo` inside functions to avoid having the output
captured by the library's stderr redirection.
Alias: `log::echo`.

#### Arguments

* **...** (string): Arguments forwarded to `echo`.

#### Exit codes

* **0**: Always.

#### Output on stdout

* The supplied message.

#### Output on stderr

* none.

### core::log::echo_err

Print a message to the original stderr.
Use this instead of plain `echo >&2` inside functions to avoid having the output
captured by the library's stderr redirection.
Alias: `log::echo_err`.

#### Arguments

* **...** (string): Arguments forwarded to `echo`.

#### Exit codes

* **0**: Always.

#### Output on stdout

* none.

#### Output on stderr

* The supplied message.

### core::log::warn

Log a warning message.
Alias: `log::warn`.

#### Arguments

* **$1** (string): Log message.

#### Exit codes

* **0**: Always.

#### Output on stdout

* Warning log.

#### Output on stderr

* none.

### core::log::notice

Log a notice message.
Alias: `log::notice`.

#### Arguments

* **$1** (string): Log message.

#### Exit codes

* **0**: Always.

#### Output on stdout

* Notice log.

#### Output on stderr

* none.

### core::log::info

Log an informational message.
Alias: `log::info`.

#### Arguments

* **$1** (string): Log message.

#### Exit codes

* **0**: Always.

#### Output on stdout

* Info log.

#### Output on stderr

* none.

### core::log::debug

Log a debug message.
Output is controlled by LOG_DEBUG and the debug filters (LOG_DEBUG_FUNC,
LOG_DEBUG_FILE, LOG_DEBUG_NO_FUNC, LOG_DEBUG_NO_FILE).
Alias: `log::debug`.

#### Arguments

* **$1** (string): Log message.
* **$2** (bool): Whether to append a stack trace. default: `false`.

#### Exit codes

* **0**: Always.

#### Output on stderr

* Debug log.

### core::log::is_debug

Determine whether debug logging is enabled for the caller.
Returns success when LOG_DEBUG is true, or when the caller matches one of the
debug filters (LOG_DEBUG_FUNC or LOG_DEBUG_FILE).
Alias: `log::is_debug`.

#### Exit codes

* **0**: If debug logging is enabled.
* **1**: If debug logging is disabled.

#### Output on stdout

* none.

#### Output on stderr

* none.

### core::log::enable_err_trap

Enable the ERR trap.
Unexpected non-zero return codes will be logged via `core::log::sig_error`.
Alias: `log::enable_err_trap`.

#### Exit codes

* **0**: Always.

#### Output on stdout

* none.

#### Output on stderr

* none.

### core::log::disable_err_trap

Disable the ERR trap while preserving the SIGINT exit behavior.
Alias: `log::disable_err_trap`.

#### Exit codes

* **0**: Always.

#### Output on stdout

* none.

#### Output on stderr

* none.

### core::log::enable_term_trap

Enable the TERM trap.
Received SIGTERM signals will be logged via `core::log::sig_term` and the
script will exit with code 143.
Alias: `log::enable_term_trap`.

#### Exit codes

* **0**: Always.

#### Output on stdout

* none.

#### Output on stderr

* none.

### core::log::disable_term_trap

Disable the TERM trap.
Alias: `log::disable_term_trap`.

#### Exit codes

* **0**: Always.

#### Output on stdout

* none.

#### Output on stderr

* none.

### core::log::disable_prefixes

Disable all log prefixes.
Alias: `log::disable_prefixes`.

#### Exit codes

* **0**: Always.

#### Output on stdout

* none.

#### Output on stderr

* none.

### core::log::disable_decorations

Disable all decorations such as color and timestamp.
Alias: `log::disable_decorations`.

#### Exit codes

* **0**: Always.

#### Output on stdout

* none.

#### Output on stderr

* none.

