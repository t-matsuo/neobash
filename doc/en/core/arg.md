# core/arg.sh

Neobash core library for parsing arguments.

## Overview

This library allows you to define and parse command-line options for bash scripts or functions.
It supports required and optional options, option aliases, default values, and type checking.
It can also generate option usage text automatically.

When ``-h`` or ``--help`` is passed, the user-defined ``show_help`` function is executed
(or ``core::arg::show_usage`` if ``show_help`` is not defined).
When ``-v`` or ``--version`` is passed, the user-defined ``show_version`` function is executed.

Supported argument types are ``string``, ``int``, and ``bool``. Values are validated during parsing.

### Initializing

To parse arguments in a script, initialize the library with:

```bash
arg::init_global
```

To parse arguments inside a function, initialize the library with:

```bash
arg::init_local
```

## Index

* [core::arg::add_option](#coreargadd_option)
* [core::arg::add_option_alias](#coreargadd_option_alias)
* [core::arg::parse](#coreargparse)
* [core::arg::get_value](#coreargget_value)
* [core::arg::set_value](#coreargset_value)
* [core::arg::get_all_value](#coreargget_all_value)
* [core::arg::get_all_option](#coreargget_all_option)
* [core::arg::show_usage](#coreargshow_usage)
* [core::arg::set_help_prefix](#coreargset_help_prefix)
* [core::arg::add_help_header](#coreargadd_help_header)
* [core::arg::add_version](#coreargadd_version)

### core::arg::add_option

Defines an option specification.
* Alias is defined as ``arg::add_option``.
* Variables must be initialized first with ``core::arg::init_global`` or ``core::arg::init_local``.
* ``-h``, ``--help``, ``-v``, and ``--version`` are reserved and cannot be used as option names.

#### Options

* **-l \<value\>**

  (string)(required): Label name used to identify the option.

* **-o \<value\>**

  (string)(required): Option name such as ``-m`` or ``--myarg``.

* **-t \<value\>**

  (string)(optional): Option type. Must be one of: ``string``, ``int``, ``bool``. default: ``string``.

* **-r \<value\>**

  (bool)(optional): Whether the option is required. Must be one of: ``true``, ``false``. default: ``false``.

* **-d \<value\>**

  (string)(optional): Default value used when the option is not specified. default: ``""`` for ``string``, ``0`` for ``int``, ``false`` for ``bool``.

* **-s \<value\>**

  (string)(optional): Storage mode. Must be one of: ``none``, ``true``, ``false``. With ``none`` the option requires a value; with ``true`` or ``false`` it acts as a flag. default: ``none``.

* **-h \<value\>**

  (string)(optional): Help message for the option. default: ``no help message for this option``.

#### Exit codes

* **0**: If successful.
* **1**: If failed.

#### Output on stdout

* None.

#### Output on stderr

* Error and debug messages.

### core::arg::add_option_alias

Defines an option alias.
* Alias is defined as ``arg::add_option_alias``.
* The option must be defined first with ``core::arg::add_option``.
* ``-h``, ``--help``, ``-v``, and ``--version`` are reserved and cannot be used as aliases.
* Only one alias can be defined per label.

#### Options

* **-l \<value\>**

  (string)(required): Label defined by ``arg::add_option``.

* **-o \<value\>**

  (string)(required): Option alias name such as ``-m`` for ``--myarg``.

* **-a \<value\>**

  (string)(deprecated): Deprecated alias for ``-o``. Use ``-o`` instead.

#### Exit codes

* **0**: If successful.
* **1**: If failed.

#### Output on stdout

* None.

#### Output on stderr

* Error and debug messages.

### core::arg::parse

Parses arguments.
* Alias is defined as ``arg::parse``.
#### Reserved Options
* ``-h`` or ``--help``: Executes the user-defined ``show_help`` function (or ``core::arg::show_usage`` if ``show_help`` is not defined).
* ``-v`` or ``--version``: Executes the user-defined ``show_version`` function.
#### Validation
Passing a non-integer value to an ``int`` option, or a value other than ``true``/``false`` to a ``bool`` option,
will cause an error. Passing an undefined option will also cause an error.
#### Remaining Arguments
If the argument ``--`` is passed, all subsequent arguments are stored in the ``ARG_OTHERS`` array.
##### Examples
* With arguments ``-a 1 -b 2 --c 3 ddd eee fff``, ``ARG_OTHERS=(ddd eee fff)`` is set.
* With arguments ``-a 1 -- -b 2 --c 3 ddd eee fff``, ``ARG_OTHERS=(-b 2 --c 3 ddd eee fff)`` is set.

#### Arguments

* **...** (string): All arguments. Pass them as ``"$@"``.

#### Exit codes

* **0**: If successful.
* **1**: If failed.

#### Output on stdout

* Help text when ``-h`` or ``--help`` is specified; version information when ``-v`` or ``--version`` is specified.

#### Output on stderr

* Error and debug messages.

### core::arg::get_value

Gets a value.
* Alias is defined as ``arg::get_value``.

#### Options

* **-l \<value\>**

  (string)(required): Label defined by ``arg::add_option``.

#### Exit codes

* **0**: If successful.
* **1**: If failed.

#### Output on stdout

* The option value.

#### Output on stderr

* Error and debug messages.

### core::arg::set_value

Updates a value.
* Alias is defined as ``arg::set_value``.

#### Options

* **-l \<value\>**

  (string)(required): Label defined by ``arg::add_option``.

* **-v \<value\>**

  (string)(required): New value.

#### Exit codes

* **0**: If successful.
* **1**: If failed.

#### Output on stdout

* None.

#### Output on stderr

* Error and debug messages.

### core::arg::get_all_value

Shows all values after ``core::arg::parse`` is called.
* Alias is defined as ``arg::get_all_value``.

#### Exit codes

* **0**: If successful.
* **1**: If failed.

#### Output on stdout

* All labels and their values.

#### Output on stderr

* Error and debug messages.

### core::arg::get_all_option

Shows all options defined by ``arg::add_option``.
* Alias is defined as ``arg::get_all_option``.

#### Exit codes

* **0**: If successful.
* **1**: If failed.

#### Output on stdout

* All options in CSV format.

#### Output on stderr

* Error and debug messages.

### core::arg::show_usage

Shows option usage for the script help text.
* Alias is defined as ``arg::show_usage``.
* This function is designed to embed the usage of options in the script's help message.

#### Arguments

* **$1** ((string)(optional):): Line prefix used to indent the usage output. You can also set it with ``core::arg::set_help_prefix()``. default: ``""``.

#### Exit codes

* **0**: If successful.
* **1**: If failed.

#### Output on stdout

* The usage message for options.

#### Output on stderr

* Error and debug messages.

### core::arg::set_help_prefix

Sets the option help text prefix.
* Alias is defined as ``arg::set_help_prefix``.

#### Arguments

* **$1** ((string):): Prefix string.

#### Exit codes

* **0**: If successful.
* **1**: If failed.

#### Output on stdout

* None.

#### Output on stderr

* None.

### core::arg::add_help_header

Adds a help header.
* Alias is defined as ``arg::add_help_header``.

#### Arguments

* **$1** ((string):): Header string.

#### Exit codes

* **0**: If successful.
* **1**: If failed.

#### Output on stdout

* None.

#### Output on stderr

* None.

### core::arg::add_version

Adds a version string.
* Alias is defined as ``arg::add_version``.

#### Arguments

* **$1** ((string):): Version string.

#### Exit codes

* **0**: If successful.
* **1**: If failed.

#### Output on stdout

* None.

#### Output on stderr

* None.

