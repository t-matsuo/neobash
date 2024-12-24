# core/arg.sh

Parser for bash script args and bash function args.

## Usage

### Initializing

If you want to parse arguments in a bash script, please initialize it with the following command.

```bash
arg::init_global
```

On the other hand, if you want to parse arguments in a function, please initialize it with the following command inside the function.

```bash
args::init_local
```

### Definition of options

You can define the options with the ``arg::add_option`` command.
This command takes the following options.

* -l: label (required)
  * Argument identifier. You can specify any string without space.
  * ex: ``ARG_PORT``, ``ARG_HOST`` etc.
* -o: option name (required)
  * You can specify option names that start with "-" or "--".
  * ex: ``-p``, ``--port``, ``-h``, ``--host`` etc.
* -t: type (optional)
  * type can be one of: ``string``, ``int``, ``bool``
  * default : ``string``
* -r: required (optional)
  * If true, an error will be occured if this option is not specified in the arguments.
* -h: help (optional)
  * This option's help message.
  * You can show usage with the ``arg::usage``` command.
  * default : ``no help message for this option``
* -s: store (optional)
  * In the case of "none," the argument must be given a value.
  * In the case of "true" or "false," the argument does not take a value.
  * Setting it to true means that the value will be true if the option is specified, and false means the opposite.If you specify true or false, you must set the type to bool.
  * default : "none"
* -d: default value (optional)
  * If the option is not specified, this value will be used as default.
  * If -r value is false and no default value is set, an empty string will be automatically assigned for type string, 0 for type int, and false for type bool.

You can define an option alias in the following way.

```bash
args::add_alias -l "label" -a "alias"
```

For example, you can define an alias for the option ``-p`` as ``--port``.

(ex)
```bash
args::add_option -l "ARG_PORT" -o "-p" -t "int"
args::add_option_alias -l "ARG_PORT" -a "--port"
```

``args::get_all_option`` shows all defined options as csv.

(ex)
```
label,short option,long option,type,required,help message,store,default
ARG_PORT,-p,--port,int,true,"no help message for this option",none,""
ARG_HOST,-n,--name,string,true,"hostname",none,""
```

``args::get_all_value`` shows all labels and values.

(ex)
```
ARG_PORT=80
ARG_HOST=localhost
```

### Parsing arguments

After defining the options, you can parse them using the following command.

```
args::parse "$@"
```

### Extracting a value

You can extract a value using the following command.

```
args::get -l "label"
```

Or use ARGS array.

```
ARGS["label"]
```

### Update a value

You can update a value using the following command.

```
args::set_value -l "label" -v "new value"
```

### Delete a value

You can delete a value using the following command.

```
args::del_value -l "label"
```

If value is deleted, an empty string will be automatically assigned for type string, 0 for type int, and false for type bool.
The label itself cannot be removed.

### Remaining arguments

Any remaining arguments passed that are not options will be assigned to the ARG_OTHERS array.

For example args ``-a 1 -b 2 --c 3 ddd eee fff`` will be assigned to ``ARG_OTHERS=(ddd eee fff)``.

If "--" is passed as an argument, all subsequent arguments will also be assigned to the ARG_OTHERS array.

For example args ``-a 1 -- -b 2 --c 3 ddd eee fff`` will be assigned to ``ARG_OTHERS=(-b 2 --c 3 ddd eee fff)``.

### Reserved options

-h, --help, -v, and --version are reserved. If -h or --help is passed as an argument, it will automatically call show_help() and terminate the program. Similarly, if -v or --version is passed, it will call show_version() and exit. Therefore, it's useful to define both functions in advance before calling args::parse.

### Validation

If a non-integer value is passed to an option of type int, or a value other than true or false is passed to an option of type bool, it will raise an error.Additionally, an error will occur if any options other than those defined are passed.
