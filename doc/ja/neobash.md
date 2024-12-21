# neobash.sh

Neobashブートストラップファイル。

## 使用方法

### Neobashの読み込み

本ファイルをsourceコマンドで読み込む必要があります。

```bash
source /path/to/lib/neobash.sh
```

本ファイルを読むこむと、自動で全``core``ライブラリがimportされます。

### ライブラリの読み込み

``nb::import``コマンドでライブラリを読み込みます。

(例)
```bash
nb::import 'util/mylib.sh'
```

### ライブラリ読み込み後のbashの挙動

bashの以下の設定が有効になります。

* ``shopt -s expand_aliases``
  * bashのエイリアスが使用可能になります
* ``set -o pipefail``
  * パイプ使用時に、パイプの途中でエラーが発生した場合、最後に失敗したコマンドの戻り値が返ります
* ``set -u``
  * 未定義の変数を使用しようとした場合、エラーメッセージが出力されます
* ``NB_DIR``変数に、neobash.shが置かれているディレクトリの絶対パスが格納されます

## 関数

#### nb::import()

* 概要: ライブラリの読み込みます
* 引数
  * arg1: ライブラリのパス(文字列)
    * libより下のパスを指定します。
    * (例) lib/core/log.sh を読み込みたい場合は、``core/log.sh``を指定します
* 戻り値
  * 0: 成功
* エラー時
  * ライブラリの読み込みに失敗した場合、エラーメッセージを出力しスクリプトを強制終了します
* その他
  * neobash.shが置かれているディレクトリのlibディレクトリに配置されているライブラリを読み込みます。
  * coreディレクトリ配下の全ライブラリはneobash.sh読み込み時に自動で読み込まれるため、個別にimportする必要はありません。
  * ``*``で指定したディレクトリの全ライブラリをimport可能です。
    * (例) ``nb::import 'util/*'``
  * nb::importされたライブラリは``nb::has_lib()``で調べることが可能です。
  * nb::importされた全ライブラリは``nb::get_libs()``で取得可能です。

#### nb::has_lib()

* 概要: 指定されたライブラリがimportされているか調べます。
* 引数
  * arg1: ライブラリのパス(文字列)
* 戻り値
  * 0: importされています
  * 1: importされていません
* エラー時
  * 引数が未指定の場合、エラーメッセージを出力しスクリプトを強制終了します
* その他
  * なし

#### nb::require()

* 概要: 依存するライブラリを指定します。
* 引数
  * arg1: ライブラリのパス(文字列)
* 戻り値
  * 0: 依存ライブラリはすべてimportされています
* エラー時
  * 依存ライブラリがimportされていない場合、エラーメッセージを出力しスクリプトを強制終了します
* その他
  * なし

#### nb::command_check()

* 概要: 依存するコマンドが使用できるかを調べます。
* 引数
  * arg1: 以前するコマンド名
    * スペース区切りで複数のコマンドを指定できます。
* 戻り値
  * 0: 依存コマンドはすべて使用できます
* エラー時
  * 依存コマンドが使用できない場合、エラーメッセージを出力しスクリプトを強制終了します
* その他
  * なし