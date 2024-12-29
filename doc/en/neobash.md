# neobash.sh

Neobash bootstrap library

## Overview

* Provide library management functions.
* Load core library such as ``core/log.sh`` and ``core/arg.sh`` to manage logging and parsing arguments.
### Bootstrap
```bash
source /path/to/lib/neobash.sh
```

If source it, neobash defines global variables.
* NB_DIR : neobash.sh directory
* NB_LIB_PATH : Library path. default is ``${NB_DIR}/lib``
* NB_LIBS : Loaded libraries.

And chnage bash configuration.
* shopt -s expand_aliases
* set -o pipefail
* set -u

## Index

* [nb::import](#nbimport)
* [nb::add_lib_path](#nbaddlibpath)
* [nb::get_lib_path](#nbgetlibpath)
* [nb::get_libs](#nbgetlibs)
* [nb::has_lib](#nbhaslib)
* [nb::require](#nbrequire)
* [nb::command_check](#nbcommandcheck)
* [nb::check_bash_min_version](#nbcheckbashminversion)
* [nb::check_bash_max_version](#nbcheckbashmaxversion)

### nb::import

Import library.
* If library is already loaded, do nothing.
* If path is invalid, script is forcedly exited.

#### Arguments

* **$1** (string): Library name such as ``core/log.sh``. Name path is relative to ``NB_LIB_PATH``.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* None.

#### Output on stderr

* Error and debug message.

### nb::add_lib_path

Add library path.
* If path is invalid, script is forcedly exited.

#### Arguments

* **$1** (Library): path.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* None.

#### Output on stderr

* Error and debug message.

### nb::get_lib_path

Show all library paths.

#### Exit codes

* 0

#### Output on stdout

* Library paths added by ``nb::add_lib_path``.

#### Output on stderr

* None.

### nb::get_libs

Show all loaded library.

#### Exit codes

* 0

#### Output on stdout

* Loaded libraries.

#### Output on stderr

* None.

### nb::has_lib

Check if library is loaded.

#### Arguments

* **$1** (Library): name.

#### Exit codes

* **0**: If loaded.
* **1**: If not loaded or error occured.

#### Output on stdout

* None.

#### Output on stderr

* Error and debug message.

### nb::require

Define required libraries in each library.
* If library is not loaded or argument is invalid, script is forcedly exited.

#### Arguments

* **$1** (Library): name.

#### Exit codes

* **0**: If loaded.
* **1**: If not loaded or error occured.

#### Output on stdout

* None.

#### Output on stderr

* Error and debug message.

### nb::command_check

Check depending command.
* If command is not found or argument is invalid, script is forcedly exited.

#### Arguments

* **$1** (Command): name.

#### Exit codes

* **0**: If exists.
* **1**: Error occured.

#### Output on stdout

* None.

#### Output on stderr

* Error and debug message.

### nb::check_bash_min_version

Check bash minimum version.
* If the version does not meet the requirements or argument is invalid, script is forcedly exited.
* Version format is ``MAJOR.MINOR.PATCH``.

#### Arguments

* **$1** (Version): number.

#### Exit codes

* **0**: If the version meets the requirements.
* **1**: Error occured.

#### Output on stdout

* None.

#### Output on stderr

* Error and debug message.

### nb::check_bash_max_version

Check bash maximum version.
* If the version does not meet the requirements or argument is invalid, script is forcedly exited.
* Version format is ``MAJOR.MINOR.PATCH``.

#### Arguments

* **$1** (Version): number.

#### Exit codes

* **0**: If the version meets the requirements.
* **1**: Error occured.

#### Output on stdout

* None.

#### Output on stderr

* Error and debug message.

