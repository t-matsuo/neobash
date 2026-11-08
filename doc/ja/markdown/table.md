# markdown/table.sh

csv から markdown テーブルへの変換

## 概要

csv を markdown テーブルに変換します

## 目次

* [markdown::csv2table](#markdowncsv2table)

### markdown::csv2table

csv を markdown テーブルに変換します

#### オプション

* **--header \<string\>**

  テーブルのヘッダー csv（必須）

* **--data \<string\>**

  テーブルのデータ csv（必須）

* **--line-break \<string\>**

  クォートされた csv フィールド内の改行の置換文字列（デフォルト: <br>）

* **--cell-max-width \<int\>**

  変換後のセルの最大幅。0 は無制限を意味し、0 より大きい場合は 5 以上である必要があります（デフォルト: 0）

* **--table-max-byte \<int\>**

  テーブル出力あたりの最大バイト数。0 は無制限を意味します（デフォルト: 0）

* **--table-max-line \<int\>**

  テーブル出力あたりの最大データ行数。0 は無制限を意味します（デフォルト: 0）

* **--page-break \<string\>**

  ページ区切りの置換文字列（デフォルト: <!-- page %page/%total -->）

#### 終了コード

* 0

#### 標準出力

* テーブル

#### 標準エラー出力

* なし
