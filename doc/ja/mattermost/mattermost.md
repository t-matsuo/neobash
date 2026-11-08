# mattermost/mattermost.sh

mattermost ライブラリ

## 概要

Mattermost を利用するための便利な関数です。

本ライブラリは、以下の環境変数を設定することで動作を変更できます。

* MATTERMOST_POST : false に設定すると、post や upload などの API 呼び出しを行わず、ログの出力のみを行います。デフォルト: ``true``

## 目次

* [mattermost::ping](#mattermostping)
* [mattermost::webhook_post](#mattermostwebhookpost)
* [mattermost::post_msg](#mattermostpostmsg)
* [mattermost::upload_file](#mattermostuploadfile)
* [mattermost::post_msg_with_file](#mattermostpostmsgwithfile)

### mattermost::ping

/api/v4/system/ping エンドポイントを使用して Mattermost API に ping を送信します。

#### オプション

* **--host \<value\>**

  (string)(必須): Mattermost の URL（例: https://localhost:8065）

* **--insecure**

  (任意): 証明書エラーを無視します。

#### 終了コード

* **0**: 成功時
* **1**: 失敗時

#### 標準出力

* なし

#### 標準エラー出力

* エラーおよびデバッグメッセージ

### mattermost::webhook_post

Incoming Webhook を使用して Mattermost にメッセージを投稿します。

#### オプション

* **--message**

  / -m <value> (string)(必須): メッセージ

* **--url**

  / -u <value> (string)(必須): Incoming Webhook の URL

* **--insecure**

  (任意): 証明書エラーを無視します。

#### 終了コード

* **0**: 成功時
* **1**: 失敗時

#### 標準出力

* API レスポンス (json)

#### 標準エラー出力

* エラーおよびデバッグメッセージ

### mattermost::post_msg

メッセージを投稿します

#### オプション

* **--message \<value\>**

  (string)(必須): メッセージ

* **--token \<token\>**

  (string)(必須): トークン

* **--host \<value\>**

  (string)(必須): Mattermost の URL（例: https://localhost:8065）

* **--ch \<value\>**

  (string)(必須): Mattermost のチャンネル ID

* **--insecure**

  (任意): 証明書エラーを無視します。

#### 終了コード

* **0**: 成功時
* **1**: 失敗時

#### 標準出力

* API レスポンス (json)

#### 標準エラー出力

* エラーおよびデバッグメッセージ

### mattermost::upload_file

トークンを使用して Mattermost にファイルをアップロードします。注: Incoming Webhook ではアップロードはサポートされていません。

#### オプション

* **--file \<file\>**

  (string)(必須): ファイル

* **--token \<token\>**

  (string)(必須): トークン

* **--host \<value\>**

  (string)(必須): Mattermost の URL（例: https://localhost:8065）

* **--ch \<value\>**

  (string)(必須): Mattermost のチャンネル ID

* **--insecure**

  (任意): 証明書エラーを無視します。

#### 終了コード

* **0**: 成功時
* **1**: 失敗時

#### 標準出力

* API レスポンス (json)

#### 標準エラー出力

* エラーおよびデバッグメッセージ

### mattermost::post_msg_with_file

ファイルをアップロードし、それを添付してメッセージを投稿します

#### オプション

* **--message \<value\>**

  (string)(必須): メッセージ

* **--file \<file\>**

  (string)(必須): ファイル

* **--token \<token\>**

  (string)(必須): トークン

* **--host \<value\>**

  (string)(必須): Mattermost の URL（例: https://localhost:8065）

* **--ch \<value\>**

  (string)(必須): Mattermost のチャンネル ID

* **--insecure**

  (任意): 証明書エラーを無視します。

#### 終了コード

* **0**: 成功時
* **1**: 失敗時

#### 標準出力

* メッセージ投稿 API のレスポンス (json)

#### 標準エラー出力

* エラーおよびデバッグメッセージ
