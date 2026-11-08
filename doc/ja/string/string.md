# string/string.sh

Neobash string/string.sh ライブラリ

## 概要

* 文字列に関するライブラリ

## 目次

* [string::start_with](#stringstartwith)
* [string::end_with](#stringendwith)
* [string::include](#stringinclude)

### string::start_with

変数が指定した文字列で始まっているかどうかを確認します

#### オプション

* **--string \<string\>**

  対象の文字列。（必須）

* **-s \<string\>**

  --string のエイリアス

* **--match \<string\>**

  一致させる文字列。（必須）

* **-m \<string\>**

  --match のエイリアス

#### 終了コード

* **0**: 一致しました
* **1**: 一致しませんでした

#### 標準出力

* なし

#### 標準エラー出力

* なし

### string::end_with

変数が指定した文字列で終わっているかどうかを確認します

#### オプション

* **--string \<string\>**

  対象の文字列。（必須）

* **-s \<string\>**

  --string のエイリアス

* **--match \<string\>**

  一致させる文字列。（必須）

* **-m \<string\>**

  --match のエイリアス

#### 終了コード

* **0**: 一致しました
* **1**: 一致しませんでした

#### 標準出力

* なし

#### 標準エラー出力

* なし

### string::include

変数が指定した文字列を含んでいるかどうかを確認します

#### オプション

* **--string \<string\>**

  対象の文字列。（必須）

* **-s \<string\>**

  --string のエイリアス

* **--match \<string\>**

  一致させる文字列。（必須）

* **-m \<string\>**

  --match のエイリアス

#### 終了コード

* **0**: 一致しました
* **1**: 一致しませんでした

#### 標準出力

* なし

#### 標準エラー出力

* なし
