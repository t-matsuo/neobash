# util/cmd.sh

Neobash util/cmd.sh ライブラリ

## 概要

* コマンドまたは関数の実行用ライブラリ

## 目次

* [util::cmd::exec](#utilcmdexec)

### util::cmd::exec

指定した関数またはコマンドの実行をラップする関数。標準出力/標準エラー出力を別々の変数に代入できます。

#### オプション

* **--stdout \<string\>**

  標準出力を代入する変数名。指定しない場合、メッセージは標準出力に出力されます。（任意）デフォルト: 空

* **-o \<string\>**

  --stdout のエイリアス

* **--stdout \<string\>**

  標準エラー出力を代入する変数名。指定しない場合、メッセージは標準エラー出力に出力されます。（任意）デフォルト: 空

* **-e \<string\>**

  --stderr のエイリアス

* **--ask-on-fail \<bool\>**

  失敗時に再試行を問い合わせます。（任意）デフォルト: false

* **-a \<string\>**

  --ask-on-fail のエイリアス

* **--catch-sigerr \<true/false\>**

  false の場合、SIGERR ログを破棄します（任意）デフォルト: ``$LOG_SIGERR``（core/log.sh ライブラリの変数）

* **-s \<string\>**

  --catch-sigerr のエイリアス

* **--clear-env \<true/false\>**

  true の場合、コマンド実行時にすべての環境変数をクリアします。関数を実行する場合は true を使用できません。（任意）デフォルト: ``false``

* **-c \<string\>**

  --clear-env のエイリアス

* **--timeout \<int\>**

  タイムアウト（秒）。0 はタイムアウトなしを意味します。デフォルト: ``600``

* **-t \<int\>**

  --timeout のエイリアス

* **--retry \<int\>**

  再試行回数。デフォルト: ``0``

* **-r \<int\>**

  --retry のエイリアス

* **--interval \<int\>**

  再試行の間隔（秒）。デフォルト: ``1``

* **-i \<int\>**

  --interval のエイリアス

* **--grace-period \<int\>**

  タイムアウト時の猶予期間（TERM->KILL）（秒）。デフォルト: ``1``

* **-g \<int\>**

  --grace-period のエイリアス

#### 終了コード

* 指定した関数またはコマンドの終了コード、またはタイムアウト時は 124

#### 標準出力

* なし

#### 標準エラー出力

* デバッグログ
