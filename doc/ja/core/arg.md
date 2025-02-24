# core/arg.sh

bashスクリプトおよびbashの関数の引数のパーサー

## 使用方法

### 初期化

bashスクリプト自体の引数をパースしたい場合、以下のコマンドで初期化してください。

```bash
arg::init_global
```

一方、bash関数の引数をパースしたい場合は、以下のコマンドで初期化してください。

```bash
arg::init_local
```

### オプションの定義方法

``arg::add_option``コマンドを使ってオプションを定義します。
このコマンドには以下のオプションを与えることができます。

* -l: ラベル (必須)
  * 本オプションのラベル。ここで指定しラベル名の変数にオプションの値が代入されます。識別子にスペースを含めることはできません。
  * 例: ``ARG_PORT``, ``ARG_HOST`` 等
* -o: オプション名 (必須)
  * "-" または "--" で始まるオプション名を指定します。
  * 例: ``-p``, ``--port``, ``-h``, ``--host`` etc.
* -t: タイプ (任意)
  * 右記からオプションのタイプ(変数の型)を指定します: ``string``, ``int``, ``bool``
  * デフォルト: ``string``
* -r: 必須オプション (任意)
  * このオプションが引数として必須かどうかを指定します: ``true`` or ``false``
  * デフォルト: ``false``
* -h: ヘルプ (任意)
  * このオプションのヘルプメッセージを指定します。
  * ``arg::usage``` コマンドを実行することで、指定したヘルプメッセージを表示します。
  * デフォルト: ``no help message for this option``
* -s: ストア (任意)
  * "none"を指定する場合、オプションには値を与える必要があります。
  * "true" または "false," を指定する場合、このオプションは値を採りません。
  * "true"を設定すると、オプションが指定された場合、値はtrueになります。"false"を設定すると、逆になります。trueまたはfalseを指定する場合、タイプにはboolを設定する必要があります。
  * デフォルト: ``none``
* -d: デフォルト値 (任意)
  * 本オプションのデフォルト値を指定します。
  * デフォルト: -r(必須)オプションが"false"、かつデフォルト値が設定指定されていない場合、stringタイプでは空文字が、intの場合は0が、boolの場合はfalseがデフォルトで設定されます。

以下のように、オプションのエイリアスを定義できます。

```bash
arg::add_alias -l "label" -a "alias"
```

例えば、以下のように``-p``オプションのエイリアスとして``--port``オプションを定義できます。

(例)
```bash
arg::add_option -l "ARG_PORT" -o "-p" -t "int"
arg::add_option_alias -l "ARG_PORT" -a "--port"
```

``arg::get_all_option`` コマンドで定義されている全てのオプションをcsvフォーマットで表示できます。

(例)
```
label,short option,long option,type,required,help message,store,default
ARG_PORT,-p,--port,int,true,"no help message for this option",none,""
ARG_HOST,-n,--name,string,true,"hostname",none,""
```

``arg::get_all_value`` コマンドは、引数パース後に実行すると全てのラベルと値を表示します。

(例)
```
ARG_PORT=80
ARG_HOST=localhost
```

### 引数のパース

オプションを定義した後、以下のコマンドでパースできます。

```
arg::parse "$@"
```

### 値の取得

以下のコマンドでパースした値を取得できます。

```
arg::get -l "label"
```

もしくはARGS配列から取得できます。

```
ARGS["label"]
```

### 値の更新

以下のコマンドでパースした値を更新できます。

```
arg::set_value -l "label" -v "new value"
```

### 値の削除

以下のコマンドでパースした値を削除できます。

```
arg::del_value -l "label"
```

値を削除した場合、デフォルト値が設定されていないstringタイプには空文字が、intタイプには0が、boolタイプにはfalseが自動的に割り当てられます。デフォルト値が設定されている場合はデフォルト値になります。ラベル自体は削除されません。

### 残りの引数

オプションで定義されなかった引数は、ARG_OTHERSに格納されます。

例えば ``-a 1 -b 2 --c 3 ddd eee fff`` を引数として渡すと``ARG_OTHERS=(ddd eee fff)``となります。

もし引数に "--" が渡された場合, その後ろの全引数がARG_OTHERSに格納されます。

例えば、 ``-a 1 -- -b 2 --c 3 ddd eee fff`` を引数として渡すと``ARG_OTHERS=(-b 2 --c 3 ddd eee fff)``となります。

### 予約済みオプション

-h, --help, -v, --version オプションは予約されています. 引数として、-h または --help が渡されると、自動でshow_help()関数が実行されプログラムは終了します。同様に-v または --version が渡されると、 show_version()関数が実行されプログラムは終了します. そのため、これらの関数はarg::parseを呼び出す前に定義してあげると便利です。

### バリデーション

intタイプに整数以外の値が渡されたり、boolタイプにtrueまたはfalse以外の値が渡された場合、エラーが発生します。さらに、定義されていないオプションが渡された場合もエラーが発生します。
