# core/arg.sh

Neobash core library for parsing arguments.

## Overview

* Can define bash script or function options and parse them.
* Can define required options or optional options.
* Can define an option name alias.
* Can define a default value.
* Can Generate option usage.
* Execute show_help function you define, if ``-h`` or ``--help`` option is passed.
* Execute show_version function you define, if ``-v`` or ``--version`` option is passed.
* Arguments type can be one of: string, int, bool, and can check value while parsing arguments.

### Initializing

If you want to parse arguments in a bash script, please initialize it with the following command.

```bash
arg::init_global
```

On the other hand, if you want to parse arguments in a function, please initialize it with the following command inside the function.

```bash
args::init_local
```

## Index

* [core::arg::add_option](#coreargaddoption)
* [core::arg::add_option_alias](#coreargaddoptionalias)
* [core::arg::parse](#coreargparse)
* [core::arg::get_value](#corearggetvalue)
* [core::arg::set_value](#coreargsetvalue)
* [core::arg::del_value](#coreargdelvalue)
* [core::arg::get_all_value](#corearggetallvalue)
* [core::arg::get_all_option](#corearggetalloption)
* [core::arg::show_usage](#coreargshowusage)
* [core::arg::set_help_prefix](#coreargsethelpprefix)
* [core::arg::add_help_header](#coreargaddhelpheader)

### core::arg::add_option

Define an option specifications
* Alias is defined as ``arg::add_option``
* Need to initialize variables first with ``core::arg::init_global`` or ``core::arg::init_local``.
* ``-h `` ``--help`` ``l-v`` ``--version`` are defined by default so you cannot use them as option name.

#### Options

* **-l \<value\>**

  (string)(required): Label name to identify.

* **-o \<value\>**

  (string)(required): Option name such as ``-m`` or ``--myarg``.

* **-t \<value\>**

  (string)(optional): Option type. type can be one of: string, int, bool. default: ``string``

* **-r \<value\>**

  (bool)(optional): Define if the ophtion is required. It can be one of: true, false. default: ``false``

* **-d \<value\>**

  (string)(optional): Default value if the option is not specified. default: if type is  string then ``""``, if type is int then ``0``, if type is bool then ``false``

* **-s \<value\>**

  (string)(optional): Store option value. It can be one of: none, true, false. If none, the option require value otherwise not. If true and the option is specified, the value is true, otherwise false. default: ``none``

* **-h \<value\>**

  (string)(optional): Help message. default: ``no help message for this option``

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* None.

#### Output on stderr

* Error and debug message.

### core::arg::add_option_alias

Define an option alias name.
* Alias is defined as ``arg::add_option_alias``
* You need to define option first with ``core::arg::add_option``.
* ``-h `` ``--help`` ``-v`` ``--version`` are defined by default so you cannot use them as option.
* You can define only one alias per label.

#### Options

* **-l \<value\>**

  (string)(required): Label defined by ``arg::add_option``

* **-a \<value\>**

  (string)(optional): Option alias name such as ``--m`` for ``--myarg``.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* None.

#### Output on stderr

* Error and debug message.

### core::arg::parse

Parse arguments.
* Alias is defined as ``arg::parse``
#### Reserved Options
* ``-h`` or ``--help`` : ``show_help`` function you defined is executed.
* ``-v``" or ``--version`` : ``show_version`` function you defined is executed.
#### Validation
An error occurs if a value other than an integer is passed to the int type,
or if a value other than true or false is passed to the bool type. Additionally,
an error will occur if an undefined option is passed.
#### Remaining arguments
If the argument '--' is passed, all subsequent arguments will be stored in ARG_OTHERS variable.
##### For example
* If you pass the arguments ``-a 1 -b 2 --c 3 ddd eee fff``, then ``ARG_OTHERS=(ddd eee fff)`` will be set.
* If you pass the arguments ``-a 1 -- -b 2 --c 3 ddd eee fff``, then ARG_OTHERS=(-b 2 --c 3 ddd eee fff) will be set.

#### Arguments

* **...** (string): please specify all arguments as ``"$@"``

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* Help text if ``-h`` or ``--help`` is specified. Version information if ``-v`` or ``--version`` is specified.

#### Output on stderr

* Error and debug message.

### core::arg::get_value

Get a value.
* Alias is defined as ``arg::get_value``

#### Options

* **-l \<value\>**

  (string)(required): Label defined by ``arg::add_option``

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* Show value.

#### Output on stderr

* Error and debug message.

### core::arg::set_value

Update a value.
* Alias is defined as ``arg::set_value``

#### Options

* **-l \<value\>**

  (string)(required): Label defined by ``arg::add_option``

* **-v \<value\>**

  (string)(optional): New value.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* None.

#### Output on stderr

* Error and debug message.

### core::arg::del_value

Delete a value and set default.
* Alias is defined as ``arg::del_value``
* If option type is string, value set empty string if default value is not set.
* If option type is int, value set 0 if default value is not set.
* If option type is bool, value set false if default value is not set.

#### Options

* **-l \<value\>**

  (string)(required): Label defined by ``arg::add_option``

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* None.

#### Output on stderr

* Error and debug message.

### core::arg::get_all_value

Show all values after ``core::arg::parse`` is called.
* Alias is defined as ``arg::get_all_value``

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* All labels and their values.

#### Output on stderr

* Error and debug message.

### core::arg::get_all_option

Show all options defined by ``arg::add_option``.
* Alias is defined as ``arg::get_all_option``

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* All options. Format is csv.

#### Output on stderr

* Error and debug message.

### core::arg::show_usage

Show option usages for your script help text.
* Alias is defined as ``arg::show_usage``
* This function is designed to embed the usage of options in the script's help message.

#### Arguments

* **$1** ((string)): (optional): Line prefix. This prefix is intended to be used when you want to decrease the indentation at the beginning of the usage of options. You can also specify core::arg::set_help_prefix(). default: ``""``

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* Show usage message for option.

#### Output on stderr

* Error and debug message.

### core::arg::set_help_prefix

Set option help text prefix.
* Alias is defined as ``arg::set_help_prefix``

#### Arguments

* **$1** ((string):): prefix string

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* None

#### Output on stderr

* None

### core::arg::add_help_header

Add help header
* Alias is defined as ``arg::add_help_prefix``

#### Arguments

* **$1** ((string):): header string

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* None

#### Output on stderr

* None

