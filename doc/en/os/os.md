# os/os.sh

Neobash os/os.sh library

## Overview

* library about os

## Index

* [os::check_var](#oscheckvar)
* [os::check_exported_var](#oscheckexportedvar)
* [os::check_func](#oscheckfunc)

### os::check_var

check if the variable is defined or not

#### Options

* **--name \<string\>**

  Variable name to assign stdout. If it is not specified, messages output to stdout. (required)

* **-n \<string\>**

  Alias for --name

* **--enable-error \<bool\>**

  If true, enable error message when the variable is not defined. (option) DEFAULT:``true``

* **-r \<bool\>**

  Alias for --enable-error

* **--exit \<bool\>**

  If true, exit 1 instead of return 1, when the variable is not defined. (option) DEFAULT:``false``

* **-e \<bool\>**

  Alias for --exit

#### Exit codes

* **0**: The variable is defined.
* **1**: The variable is not defined.

#### Output on stdout

* None.

#### Output on stderr

* Error message if the variable is not define and --enable-error is true.

### os::check_exported_var

check if the variable is exported or not

#### Options

* **--name \<string\>**

  Variable name to assign stdout. If it is not specified, messages output to stdout. (required)

* **-n \<string\>**

  Alias for --name

* **--enable-error \<bool\>**

  If true, enable error message when the variable is not defined. (option) DEFAULT:``true``

* **-r \<bool\>**

  Alias for --enable-error

* **--exit \<bool\>**

  If true, exit 1 instead of return 1, when the variable is not defined. (option) DEFAULT:``false``

* **-e \<bool\>**

  Alias for --exit

#### Exit codes

* **0**: The variable is exported.
* **1**: The variable is not exported.

#### Output on stdout

* None.

#### Output on stderr

* Error message if the variable is not exported and --enable-error is true.

### os::check_func

check if the function is defined or not

#### Options

* **--name \<string\>**

  Function name to check. (required)

* **-n \<string\>**

  Alias for --name

* **--enable-error \<bool\>**

  If true, enable error message when the function is not defined. (option) DEFAULT:``true``

* **-r \<bool\>**

  Alias for --enable-error

* **--exit \<bool\>**

  If true, exit 1 instead of return 1, when the function is not defined. (option) DEFAULT:``false``

* **-e \<bool\>**

  Alias for --exit

#### Exit codes

* **0**: The function is defined.
* **1**: The function is not defined.

#### Output on stdout

* None.

#### Output on stderr

* Error message if the function is not defined and --enable-error is true.

