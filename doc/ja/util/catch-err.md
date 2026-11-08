# util/catch-err.sh

Neobash util/catch-err.sh ライブラリ

## 概要

* 関数やコマンドの実行をラップする ``util::catch_output`` ラッパー関数を提供します。
* 関数実行中の標準出力と標準エラー出力を別々の変数に代入できます。

## 目次

* [util::catch_output](#utilcatchoutput)

### util::catch_output

指定した関数またはコマンドの実行をラップする関数

#### オプション

* **--stdout \<string\>**

  標準出力を代入する変数名。（必須）

* **--stdout \<string\>**

  標準エラー出力を代入する変数名。（必須）

* **--catch-sigerr \<true/false\>**

  false の場合、SIGERR ログを破棄します（任意）デフォルト: ``true``

* **--clear-env \<true/false\>**

  true の場合、コマンド実行時にすべての環境変数をクリアします。関数を実行する場合は true を使用できません。（任意）デフォルト: ``false``

#### 終了コード

* 指定した関数またはコマンドの終了コード

#### 標準出力

* なし

#### 標準エラー出力

* デバッグログ
