# io/qa.sh

Neobash io/qa.sh library

## Overview

* waiting for user's y(yes) or n(no) input

## Index

* [io::qa](#ioqa)

### io::qa

waiting for y(yes) or n(no) or q(quit). /dev/tty is used to input.

#### Options

* **--message \<string\>**

  message to output to terminal. (option) DEFAULT: empty

* **-m \<string\>**

  Alias for --message

* **--default \<string\>**

  default value if input is empty. y/Y/yes or n/N/no or q/Q/quit are required. (option) DEFAULT: n

* **-d \<string\>**

  Alias for --default

* **--timeout \<int\>**

  timeout(sec). (option) DEFAULT: 120(sec)

* **-t \<int\>**

  Alias for --timeout

#### Exit codes

* **0**: OK
* **1**: Erro
* **125**: Quit
* **142**: Timed out

#### Output on stdout

* y or n or q

#### Output on stderr

* error log.

