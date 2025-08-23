# core/log.sh

Neobash ログ管理用コアライブラリ

## Overview

* debug, info, notice, error, crit のログや、必要に応じてスタックトレースも出力できます。
* ログメッセージのフォーマットには、plain または json を指定できます。
* ターミナルへの出力ログにはデフォルトでフォントはカラーになり、タイムスタンプが付与されます。
* ログ出力先は、ターミナル(stdout/stderr)やファイルが選択できます。
* SIGINT, SIGTERM, SIGERR のシグナルを検知し、ログやスタックトレースを自動で出力します。

本ライブラリは、環境変数によって動作を変更できます。

以下はログレベル制御用。true または false を指定してください。
* LOG_CRIT : CRIT ログの出力を切り替えます。 default: ``true``
* LOG_ERROR : ERROR ログの出力を切り替えます。 default: ``true``
* LOG_NOTICE : NOTICE ログの出力を切り替えます。 default: ``true``
* LOG_INFO : INFO ログの出力を切り替えます。 default: ``true``
* LOG_DEBUG : DEBUG ログの出力を切り替えます。 default: ``false``
* LOG_STDERR : 標準エラー出力に出力されたログの出力を切り替えます。 default: ``true``
* LOG_SIGERR : SIGERRのログ出力を切り替えます。 default: ``true``

以下はログのフォーマット制御用。
* LOG_FORMAT : ログのフォーマットとして``plain`` または ``json``を指定できます。 default: ``plain``
* LOG_STACK_TRACE : CRIT または DEBUG ログ出力時にスタックトレースを出力するか切り替えます。default: ``true``
* LOG_TIMESTAMP : ログにタイムスタンプを挿入するか切り替えます。 default: ``true``
* LOG_TIMESTAMP_FORMAT : タイムスタンプ挿入時のフォーマットを指定します。フォーマットは printf の書式を使用してください。default: ``%F-%T%z``

Example: デバッグログを有効にし、スタックトレースを無効にしてスクリプトを実行。
```bash
LOG_DEBUG=true LOG_STACK_TRACE=false ./myscript.sh
````

ログ出力先の指定用。
* LOG_TERMINAL : スクリプト実行したターミナルへ出力するか切り替えます。default: ``true``
* LOG_FILE : ログ出力先のファイルを指定します。default: empty (出力しない)

ログのプレフィックス制御用。
* LOG_PREFIX_CRIT :   CRIT ログのプレフィックスを設定します。default: ``CRIT``
* LOG_PREFIX_ERROR :  ERROR ログのプレフィックスを設定します。default: ``ERROR``
* LOG_PREFIX_NOTICE : NOTICE ログのプレフィックスを設定します。default: ``NOTICE``
* LOG_PREFIX_WARN :   WARN ログのプレフィックスを設定します。default: ``NOTICE``
* LOG_PREFIX_INFO :   INFO ログのプレフィックスを設定します。default: ``INFO``
* LOG_PREFIX_DEBUG :  DEBUG ログのプレフィックスを設定します。default: ``DEBUG``
* LOG_PREFIX_TRACE :  TRACE ログのプレフィックスを設定します。default: ``TRACE``
* LOG_PREFIX_STDERR : 標準出力に出力されたログのプレフィックスを設定します。default: ``STDERR``
* LOG_PREFIX_SIGERR : SIGERRのログのプレフィックスを設定します。 default: ``SIGERR``

デバッグログのフィルタリング用。
* LOG_DEBUG_FUNC : 指定した関数名のログだけ出力します。default: ``''``
* LOG_DEBUG_FILE : 指定したファイル名のログだけ出力します。default: ``''``
* LOG_DEBUG_NO_FUNC : 指定した関数名のログだけ出力を抑止します。default: ``''``
* LOG_DEBUG_NO_FILE : 指定したファイル名のログだけ出力を抑止します。default: ``''``

Example: ``mylib::get_xxx`` という名前の関数内のデバッグログだけ出力します。
```bash
LOG_DEBUG_FUNC="mylib::get_xxx" ./myscript.sh
```

Example: ``mylib/myutil.sh`` という名前のファイル内のデバッグログだけ出力します。
```bash
LOG_DEBUG_FILE="mylib/myutil.sh mylib/string.sh" ./myscript.sh
```

## 関数一覧

* [core::log::stack_trace](#corelogstacktrace)
* [core::log::crit](#corelogcrit)
* [core::log::error](#corelogerror)
* [core::log::error_exit](#corelogerrorexit)
* [core::log::echo](#corelogecho)
* [core::log::echo_err](#corelogechoerr)
* [core::log::warn](#corelogwarn)
* [core::log::notice](#corelognotice)
* [core::log::info](#coreloginfo)
* [core::log::debug](#corelogdebug)

### core::log::stack_trace

実行すると実行箇所のスタックトレースを出力します。

_引数なし_

#### Exit codes

* 0

### core::log::crit

Critical ログを出力します。

関数名のエイリアスとして``log::crit``が定義されています。

#### 引数

* **$1** (string): ログメッセージ。

#### Exit codes

* 1

#### 標準エラー出力

* Critical ログと、有効時はスタックトレースを出力します。

### core::log::error

Error ログを出力します。

関数名のエイリアスとして``log::error``が定義されています。

#### 引数

* **$1** (string): ログメッセージ。

#### Exit codes

* 0

#### 標準エラー出力

* Error ログと、有効時はスタックトレースを出力します。

### core::log::error_exit

Error ログを出力し、exit します。

関数名のエイリアスとして``log::error_exit``が定義されています。

#### 引数

* **$1** (string): ログメッセージ。

#### Exit codes

* 1

#### 標準エラー出力

* Error ログと、有効時はスタックトレースを出力します。

### core::log::echo

関数の出力と混ざらないように、標準出力に文字列をechoで出力します。

Alias is defined as ``log::echo``

#### Exit codes

* 0

#### Output on stdout

* message.

### core::log::echo_err

関数の出力と混ざらないように、標準エラー出力に文字列をechoで出力します。

Alias is defined as ``log::echo_err``

#### Exit codes

* 0

#### Output on stdout

* message.

### core::log::warn

Warn ログを出力します。

関数名のエイリアスとして``log::warn``が定義されています。

#### 引数

* **$1** (string): ログメッセージ。

#### Exit codes

* 0

#### 標準出力

* Warn ログを出力します。

### core::log::info

Info ログを出力します。

関数名のエイリアスとして``log::info``が定義されています。

#### 引数

* **$1** (string): ログメッセージ。

#### Exit codes

* 0

#### 標準出力

* Info ログを出力します。


### core::log::notice

Notice ログを出力します。

関数名のエイリアスとして``log::notice``が定義されています。

#### 引数

* **$1** (string): ログメッセージ。

#### Exit codes

* 0

#### 標準出力

* Notice ログを出力します。

### core::log::info

Info ログを出力します。

関数名のエイリアスとして``log::info``が定義されています。

#### 引数

* **$1** (string): ログメッセージ。

#### Exit codes

* 0

#### 標準出力

* Info ログを出力します。

### core::log::debug

Debug ログを出力します。

関数名のエイリアスとして``log::debug``が定義されています。

#### 引数

* **$1** (string): ログメッセージ。
* **$2** (bool): true を渡すとスタックトレースも出力します。default: ``false``

#### Exit codes

* 0

#### 標準エラー出力

* Debug ログを出力します。
