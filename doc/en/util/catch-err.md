# util/catch-err.sh

Neobash util/catch-err.sh library

## Overview

* Provides a wrapper function "util::catch_output" for executing functions and commands.
* You can assign the stdout and stderr output during function execution to separate variables.

## Index

* [util::catch_output](#utilcatchoutput)

### util::catch_output

wrapper function for executing specified function or command

#### Options

* **--stdout \<string\>**

  Variable name to assign stdout. (required)

* **--stdout \<string\>**

  Variable name to assign stderr. (required)

* **--catch-sigerr \<true/false\>**

  False means drop SIGERR log (optional) DEFAULT:``true``

* **--clear-env \<true/false\>**

  True means clearing all environment varialbes when executing command. you cannot use true when executing function. (optional) DEFAULT:``false``

#### Exit codes

* exit code of specified function or command

#### Output on stdout

* None.

#### Output on stderr

* Debug log.

