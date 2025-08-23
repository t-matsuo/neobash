# core/log.sh

Neobash core logging library

## Overview

* Output logs of various types, such as debug, info, notice, error, crit, and stacktrace.
* Log message format is plain or json.
* Log message is formatted with color and timestamp by default.
* Control characters in log message are removed.
* Can select output destination of log to stdout/stderr or file.
* Catch unexpected SIGINT, SIGTERM, and SIGERR, and output the stacktrace.

This library can change its behavior by setting the following environment variables.

Controlling log level. Set true or false.
* LOG_CRIT : Switch the output of the CRIT log. default: ``true``
* LOG_ERROR : Switch the output of the ERROR log. default: ``true``
* LOG_NOTICE : Switch the output of the NOTICE log. default: ``true``
* LOG_INFO : Switch the output of the INFO log. default: ``true``
* LOG_DEBUG : Switch the output of the DEBUG log. default: ``false``
* LOG_STDERR : Switch the output of the standard error log. default: ``true``
* LOG_SIGERR : Switch the output of the SIGERROR log. default: ``true``

Controlling log format.
* LOG_FORMAT : Set the log format ``plain`` or ``json``. default: ``plain``
* LOG_STACK_TRACE : Switch the output of the stack trace for CRIT, DEBUG, and ERROR logs. default: ``true``
* LOG_TIMESTAMP : Switch the output of the timestamp to the all logs. default: ``true``
* LOG_TIMESTAMP_FORMAT : Set the timestamp format. please specify the format using printf formatting. default: ``%F-%T%z``
* LOG_ESCAPE_LINE_BREAK: switch escaping of line breaks and \n to \\n. default: ``true`` (escape line breaks and \n to \\n)

Example: enable debug log and disable stack trace.
```bash
LOG_DEBUG=true LOG_STACK_TRACE=false ./myscript.sh
````

Controlling log output destination.
* LOG_TERMINAL : switch the output of the log to the terminal. default: ``true``
* LOG_FILE : Set the log file name. default: ``/dev/null`` (no output to file)

Controlling log prefix.
* LOG_PREFIX_CRIT : Set the log prefix for CRIT log. default: ``CRIT``
* LOG_PREFIX_ERROR : Set the log prefix for ERROR log. default: ``ERROR``
* LOG_PREFIX_WARN : Set the log prefix for ERROR log. default: ``WARN``
* LOG_PREFIX_NOTICE : set the log prefix for NOTICE log. default: ``NOTICE``
* LOG_PREFIX_INFO : set the log prefix for INFO log. default: ``INFO``
* LOG_PREFIX_DEBUG : set the log prefix for DEBUG log. default: ``DEBUG``
* LOG_PREFIX_TRACE : set the log prefix for TRACE log. default: ``TRACE``
* LOG_PREFIX_STDERR : set the log prefix for stderr log default: ``STDERR``
* LOG_PREFIX_SIGERR : set the log prefix for SIGERROR log default: ``SIGERR``

Controlling debug log filter.
* LOG_DEBUG_FUNC : select the debug log by function name. default: ``''``
* LOG_DEBUG_FILE : select the debug log by file name. default: ``''``
* LOG_DEBUG_NO_FUNC : drop the debug log by function name. default: ``''``
* LOG_DEBUG_NO_FILE : drop the debug log by file name. default: ``''``

Example: enable debug log for ``mylib::get_xxx`` function only.
```bash
LOG_DEBUG_FUNC="mylib::get_xxx mylib:set_xxx" ./myscript.sh
```

Example: enable debug log for ``mylib/myutil.sh`` file only.
```bash
LOG_DEBUG_FILE="mylib/myutil.sh" ./myscript.sh
```

## Index

* [core::log::stack_trace](#corelogstacktrace)
* [core::log::crit](#corelogcrit)
* [core::log::sig_error](#corelogsigerror)
* [core::log::error](#corelogerror)
* [core::log::error_exit](#corelogerrorexit)
* [core::log::echo](#corelogecho)
* [core::log::echo_err](#corelogechoerr)
* [core::log::warn](#corelogwarn)
* [core::log::notice](#corelognotice)
* [core::log::info](#coreloginfo)
* [core::log::debug](#corelogdebug)
* [core::log::is_debug](#corelogisdebug)
* [core::log::enable_err_trap](#corelogenableerrtrap)
* [core::log::disable_err_trap](#corelogdisableerrtrap)

### core::log::stack_trace

Logger for stack trace.

#### Arguments

* **$1** (log): level for json
* **$2** (stack): trace message for json

#### Exit codes

* 0

### core::log::crit

Logger for crit.

Alias is defined as ``log::crit``

#### Arguments

* **$1** (string): log message.

#### Exit codes

* 1

#### Output on stderr

* output critical log message and stack trace.

### core::log::sig_error

Logger for SIGERR.

#### Arguments

* **$1** (string): log message.

#### Exit codes

* 0

#### Output on stderr

* output error log message and stack trace.

### core::log::error

Logger for error.

Alias is defined as ``log::error``

#### Arguments

* **$1** (string): log message.

#### Exit codes

* 0

#### Output on stderr

* output error log message and stack trace.

### core::log::error_exit

Logger for error and exit script.

Alias is defined as ``log::error_exit``

#### Arguments

* **$1** (string): log message.

#### Exit codes

* 1

#### Output on stderr

* output error log message and stack trace.

### core::log::echo

print message to stdout to prevent mixing of function output.

Alias is defined as ``log::echo``

#### Exit codes

* 0

#### Output on stdout

* message.

### core::log::echo_err

print message to stderr to prevent mixing of function output.

Alias is defined as ``log::echo_err``

#### Exit codes

* 0

#### Output on stdout

* message.

### core::log::warn

Logger for warn.

Alias is defined as ``log::warn``

#### Arguments

* **$1** (string): log message.

#### Exit codes

* 0

#### Output on stdout

* Warn log.

### core::log::notice

Logger for notice.

Alias is defined as ``log::notice``

#### Arguments

* **$1** (string): log message.

#### Exit codes

* 0

#### Output on stdout

* Notice log.

### core::log::info

Logger for info.

Alias is defined as ``log::info``

#### Arguments

* **$1** (string): log message.

#### Exit codes

* 0

#### Output on stdout

* Info log.

### core::log::debug

Logger for debug.

Alias is defined as ``log::debug``

#### Arguments

* **$1** (string): log message.
* **$2** (bool): if true, show stackstrace. default: ``false``

#### Exit codes

* 0

#### Output on stderr

* Debug log.

### core::log::is_debug

determine whether debug mode is enabled.

Alias is defined as ``log::is_debug``

#### Exit codes

* **0**: if it debug mode is enabled
* **1**: if it debug mode is disabled

### core::log::enable_err_trap

Enable error trap

Alias is defined as ``log::enable_err_trap``

#### Options

* none

#### Exit codes

* 0

#### Output on stderr

* none

### core::log::disable_err_trap

Disable error trap

Alias is defined as ``log::disable_err_trap``

#### Options

* none

#### Exit codes

* 0

#### Output on stderr

* none

