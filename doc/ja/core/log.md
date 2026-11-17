# core/log.sh

Neobash コアロギングライブラリ

## 概要

neobash コアロギングライブラリは、bash スクリプト向けの構造化されたログ出力機能を提供します。
複数の重大度レベル、オプションのスタックトレース、設定可能な出力先、
plain 形式と JSON 形式の両方に対応しています。

機能:
* 複数の種類のログを出力: debug, info, notice, warn, error, crit, stacktrace。
* ログ形式は `plain` または `json` にできます。
* ターミナルへの出力時は、デフォルトでログに色とタイムスタンプが付きます。
* ログメッセージ内の制御文字は削除されます。
* 出力先は標準出力、標準エラー出力、ファイルのいずれか、またはその組み合わせにできます。
* 予期しない SIGINT、SIGTERM、SIGERR シグナルは捕捉され、スタックトレース付きでログに出力されます。

このライブラリの動作は環境変数で制御できます。

## ログレベルスイッチ

各変数は `true` または `false` に設定します。
* `LOG_CRIT`: CRIT ログの出力を有効にします。デフォルト: `true`
* `LOG_ERROR`: ERROR ログの出力を有効にします。デフォルト: `true`
* `LOG_WARN`: WARN ログの出力を有効にします。デフォルト: `true`
* `LOG_NOTICE`: NOTICE ログの出力を有効にします。デフォルト: `true`
* `LOG_INFO`: INFO ログの出力を有効にします。デフォルト: `true`
* `LOG_DEBUG`: DEBUG ログの出力を有効にします。デフォルト: `false`
* `LOG_STDERR`: 標準エラー出力のキャプチャログの出力を有効にします。デフォルト: `true`
* `LOG_SIGERR`: SIGERR ログの出力を有効にします。デフォルト: `true`
* `LOG_SIGTERM`: SIGTERM ログの出力を有効にします。デフォルト: `true`

## ログ形式設定
* `LOG_FORMAT`: ログ形式を `plain` または `json` に設定します。デフォルト: `plain`
* `LOG_STACK_TRACE`: CRIT、DEBUG、ERROR ログのスタックトレースを有効にします。デフォルト: `true`
* `LOG_TIMESTAMP`: すべてのログにタイムスタンプを付与します。デフォルト: `true`
* `LOG_TIMESTAMP_FORMAT`: printf 書式を使ってタイムスタンプ形式を設定します。デフォルト: `%F-%T%z`
* `LOG_ESCAPE_LINE_BREAK`: 改行および `\n` を `\\n` にエスケープします。デフォルト: `true`

## ログ出力先
* `LOG_TERMINAL`: ターミナルへの出力を有効にします。デフォルト: `true`
* `LOG_FILE`: ログファイルのパスを設定します。デフォルト: 空（ファイル出力なし）

## ログプレフィックス
* `LOG_PREFIX_CRIT`: CRIT ログのプレフィックス。デフォルト: `CRIT`
* `LOG_PREFIX_ERROR`: ERROR ログのプレフィックス。デフォルト: `ERROR`
* `LOG_PREFIX_WARN`: WARN ログのプレフィックス。デフォルト: `WARN`
* `LOG_PREFIX_NOTICE`: NOTICE ログのプレフィックス。デフォルト: `NOTICE`
* `LOG_PREFIX_INFO`: INFO ログのプレフィックス。デフォルト: `INFO`
* `LOG_PREFIX_DEBUG`: DEBUG ログのプレフィックス。デフォルト: `DEBUG`
* `LOG_PREFIX_TRACE`: TRACE ログのプレフィックス。デフォルト: `TRACE`
* `LOG_PREFIX_STDERR`: 標準エラー出力キャプチャログのプレフィックス。デフォルト: `STDERR`
* `LOG_PREFIX_SIGNAL`: シグナルログのプレフィックス。デフォルト: `SIGNAL`

## デバッグログフィルタ
* `LOG_DEBUG_FUNC`: 指定した関数名に一致する場合のみデバッグログを出力します。デフォルト: `""`
* `LOG_DEBUG_FILE`: 指定したファイル名またはディレクトリ名に一致する場合のみデバッグログを出力します。デフォルト: `""`
* `LOG_DEBUG_NO_FUNC`: 指定した関数名に一致するデバッグログを抑制します。デフォルト: `""`
* `LOG_DEBUG_NO_FILE`: 指定したファイル名またはディレクトリ名に一致するデバッグログを抑制します。デフォルト: `""`

例: デバッグログを有効にし、スタックトレースを無効にします。
```bash
LOG_DEBUG=true LOG_STACK_TRACE=false ./myscript.sh
```

例: 特定の関数に対してデバッグログを有効にします。
```bash
LOG_DEBUG_FUNC="mylib::get_xxx mylib::set_xxx" ./myscript.sh
```

例: 特定のファイルに対してデバッグログを有効にします。
```bash
LOG_DEBUG_FILE="mylib/myutil.sh" ./myscript.sh
```

## 索引

* [core::log::stack_trace](#corelogstack_trace)
* [core::log::crit](#corelogcrit)
* [core::log::sig_error](#corelogsig_error)
* [core::log::sig_term](#corelogsig_term)
* [core::log::error](#corelogerror)
* [core::log::error_exit](#corelogerror_exit)
* [core::log::echo](#corelogecho)
* [core::log::echo_err](#corelogecho_err)
* [core::log::warn](#corelogwarn)
* [core::log::notice](#corelognotice)
* [core::log::info](#coreloginfo)
* [core::log::debug](#corelogdebug)
* [core::log::is_debug](#corelogis_debug)
* [core::log::enable_err_trap](#corelogenable_err_trap)
* [core::log::disable_err_trap](#corelogdisable_err_trap)
* [core::log::enable_term_trap](#corelogenable_term_trap)
* [core::log::disable_term_trap](#corelogdisable_term_trap)
* [core::log::disable_prefixes](#corelogdisable_prefixes)
* [core::log::disable_decorations](#corelogdisable_decorations)

### core::log::stack_trace

スタックトレースを出力します。
LOG_STACK_TRACE が有効な場合、CRIT、DEBUG、ERROR ログ関数から内部的に使用されます。
JSON モードでは、この関数に渡されたログメッセージにスタックトレースが追加されます。

#### 引数

* **$1** (string): JSON 出力で使用するログレベルのプレフィックス。
* **$2** (string): JSON 出力で使用するログメッセージ。

#### 終了コード

* **0**: 常に。

#### 標準出力

* plain モード時のスタックトレースフレーム。

#### 標準エラー出力

* なし。

### core::log::crit

重大なメッセージをログに出力し、スクリプトを終了します。
エイリアス: `log::crit`。

#### 引数

* **$1** (string): ログメッセージ。

#### 終了コード

* **1**: 常に。

#### 標準エラー出力

* 重大なログメッセージとスタックトレース。

### core::log::sig_error

SIGERR シグナルイベントをログに出力します。
コマンドが予期せず 0 以外の終了コードを返した場合に、ERR トラップから呼び出されます。

#### 引数

* **$1** (string): ログメッセージ。

#### 終了コード

* **0**: 常に。

#### 標準エラー出力

* シグナルログメッセージとスタックトレース。

### core::log::sig_term

SIGTERM シグナルイベントをログに出力します。
この関数は TERM トラップから呼び出されます。

#### 引数

* **$1** (string): ログメッセージ。

#### 終了コード

* **0**: 常に。

#### 標準エラー出力

* シグナルログメッセージとスタックトレース。

### core::log::error

エラーメッセージをログに出力します。
エイリアス: `log::error`。

#### 引数

* **$1** (string): ログメッセージ。

#### 終了コード

* **0**: 常に。

#### 標準エラー出力

* エラーログメッセージとスタックトレース。

### core::log::error_exit

エラーメッセージをログに出力し、スクリプトを終了します。
エイリアス: `log::error_exit`。

#### 引数

* **$1** (string): ログメッセージ。
* **$2** (int): 終了コード。デフォルト: `1`。

#### 終了コード

* $**2**: 指定した終了コード。デフォルトは `1`。

#### 標準エラー出力

* エラーログメッセージとスタックトレース。

#### 関連項目

* [core::log::error](#corelogerror)

### core::log::echo

元の標準出力にメッセージを出力します。
関数内で通常の `echo` の代わりにこれを使うと、ライブラリの標準エラー出力リダイレクトによって出力が奪われるのを防げます。
エイリアス: `log::echo`。

#### 引数

* **...** (string): `echo` に渡す引数。

#### 終了コード

* **0**: 常に。

#### 標準出力

* 指定したメッセージ。

#### 標準エラー出力

* なし。

### core::log::echo_err

元の標準エラー出力にメッセージを出力します。
関数内で通常の `echo >&2` の代わりにこれを使うと、ライブラリの標準エラー出力リダイレクトによって出力が奪われるのを防げます。
エイリアス: `log::echo_err`。

#### 引数

* **...** (string): `echo` に渡す引数。

#### 終了コード

* **0**: 常に。

#### 標準出力

* なし。

#### 標準エラー出力

* 指定したメッセージ。

### core::log::warn

警告メッセージをログに出力します。
エイリアス: `log::warn`。

#### 引数

* **$1** (string): ログメッセージ。

#### 終了コード

* **0**: 常に。

#### 標準出力

* 警告ログ。

#### 標準エラー出力

* なし。

### core::log::notice

通知メッセージをログに出力します。
エイリアス: `log::notice`。

#### 引数

* **$1** (string): ログメッセージ。

#### 終了コード

* **0**: 常に。

#### 標準出力

* NOTICE ログ。

#### 標準エラー出力

* なし。

### core::log::info

情報メッセージをログに出力します。
エイリアス: `log::info`。

#### 引数

* **$1** (string): ログメッセージ。

#### 終了コード

* **0**: 常に。

#### 標準出力

* INFO ログ。

#### 標準エラー出力

* なし。

### core::log::debug

デバッグメッセージをログに出力します。
出力は LOG_DEBUG とデバッグフィルタ（LOG_DEBUG_FUNC、LOG_DEBUG_FILE、LOG_DEBUG_NO_FUNC、LOG_DEBUG_NO_FILE）で制御されます。
エイリアス: `log::debug`。

#### 引数

* **$1** (string): ログメッセージ。
* **$2** (bool): スタックトレースを追加するかどうか。デフォルト: `false`。

#### 終了コード

* **0**: 常に。

#### 標準エラー出力

* デバッグログ。

### core::log::is_debug

呼び出し元に対してデバッグログが有効かどうかを判定します。
LOG_DEBUG が true の場合、または呼び出し元がデバッグフィルタ（LOG_DEBUG_FUNC または LOG_DEBUG_FILE）のいずれかに一致する場合、成功を返します。
エイリアス: `log::is_debug`。

#### 終了コード

* **0**: デバッグログが有効な場合。
* **1**: デバッグログが無効な場合。

#### 標準出力

* なし。

#### 標準エラー出力

* なし。

### core::log::enable_err_trap

ERR トラップを有効にします。
予期しない 0 以外の終了コードは `core::log::sig_error` を介してログに出力されます。
エイリアス: `log::enable_err_trap`。

#### 終了コード

* **0**: 常に。

#### 標準出力

* なし。

#### 標準エラー出力

* なし。

### core::log::disable_err_trap

ERR トラップを無効にします。SIGINT 時の終了動作は保持されます。
エイリアス: `log::disable_err_trap`。

#### 終了コード

* **0**: 常に。

#### 標準出力

* なし。

#### 標準エラー出力

* なし。

### core::log::enable_term_trap

TERM トラップを有効にします。
SIGTERM シグナルを受信すると `core::log::sig_term` を介してログに出力され、スクリプトは終了コード 143 で終了します。
エイリアス: `log::enable_term_trap`。

#### 終了コード

* **0**: 常に。

#### 標準出力

* なし。

#### 標準エラー出力

* なし。

### core::log::disable_term_trap

TERM トラップを無効にします。
エイリアス: `log::disable_term_trap`。

#### 終了コード

* **0**: 常に。

#### 標準出力

* なし。

#### 標準エラー出力

* なし。

### core::log::disable_prefixes

すべてのログプレフィックスを無効にします。
エイリアス: `log::disable_prefixes`。

#### 終了コード

* **0**: 常に。

#### 標準出力

* なし。

#### 標準エラー出力

* なし。

### core::log::disable_decorations

色やタイムスタンプなどのすべての装飾を無効にします。
エイリアス: `log::disable_decorations`。

#### 終了コード

* **0**: 常に。

#### 標準出力

* なし。

#### 標準エラー出力

* なし。
