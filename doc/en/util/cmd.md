# util/cmd.sh

Neobash util/cmd.sh library

## Overview

* library for executing command or function

## Index

* [util::cmd::exec](#utilcmdexec)

### util::cmd::exec

Wrapper function for executing specified function or command. It can assign stdout/stderr output to separate variables.

#### Options

* **--stdout \<string\>**

  Variable name to assign stdout. If it is not specified, messages output to stdout. (option) DEFAULT: empty

* **-o \<string\>**

  Alias for --stdout

* **--stdout \<string\>**

  Variable name to assign stderr. If it is not specified, messages output to stderr. (option) DEFAULT: empty

* **-e \<string\>**

  Alias for --stderr

* **--catch-sigerr \<true/false\>**

  False means drop SIGERR log (optional) DEFAULT:``$LOG_SIGERR`` (variable of core/log.sh library)

* **-s \<string\>**

  Alias for --catch-sigerr

* **--clear-env \<true/false\>**

  True means clearing all environment varialbes when executing command. you cannot use true when executing function. (optional) DEFAULT:``false``

* **-c \<string\>**

  Alias for --clear-env

* **--timeout \<int\>**

  Timeout(sec). 0 means no timeout. DEFAULT:``600.``

* **-t \<int\>**

  Alias for --timeout

* **--grace-period \<int\>**

  Grace period for timed out (TERM->KILL) (sec). DEFAULT:``1``

* **-g \<int\>**

  Alias for --grace-period

#### Exit codes

* exit code of specified function or command or timedout=124

#### Output on stdout

* None.

#### Output on stderr

* Debug log.

