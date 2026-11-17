# slack/slack.sh

slack ライブラリ

## 概要

Slack を利用するための便利な関数です。

本ライブラリは、以下の環境変数を設定することで動作を変更できます。

* SLACK_POST : false に設定すると、post や upload などの API 呼び出しを行わず、ログの出力のみを行います。デフォルト: ``true``

## 目次

* [slack::ping](#slackping)
* [slack::webhook_post](#slackwebhookpost)
* [slack::post_msg](#slackpostmsg)
* [slack::upload_file](#slackuploadfile)

### slack::ping

Slack ホストに ping を送信します。

#### オプション

* **--host \<value\>**

  (string)(必須): Slack の URL（例: https://localhost:8065）

* **--insecure**

  (任意): 証明書エラーを無視します。

#### 終了コード

* **0**: 成功時
* **1**: 失敗時

#### 標準出力

* なし

#### 標準エラー出力

* エラーおよびデバッグメッセージ

### slack::webhook_post

Incoming Webhook を使用して Slack にメッセージを投稿します。

#### オプション

* **--message**

  / -m <value> (string)(必須): メッセージ

* **--url**

  / -u <value> (string)(必須): Incoming Webhook の URL

* **--type**

  / -t <value> (string)(任意): メッセージタイプ。text または mrkdwn（デフォルト: text）

* **--insecure**

  (任意): 証明書エラーを無視します。

#### 終了コード

* **0**: 成功時
* **1**: 失敗時

#### 標準出力

* API レスポンス (json)

#### 標準エラー出力

* エラーおよびデバッグメッセージ

### slack::post_msg

chat.postMessage API を使用して Slack にメッセージを投稿します。

#### オプション

* **--message \<value\>**

  (string)(必須): メッセージ

* **--type**

  / -t <value> (string)(任意): メッセージタイプ。text または mrkdwn または markdown（デフォルト: mrkdwn）

* **--token \<value\>**

  (string)(必須): Slack ボットトークン

* **--ch \<value\>**

  (string)(必須): チャンネル ID

* **--insecure**

  (任意): 証明書エラーを無視します。

#### 終了コード

* **0**: 成功時
* **1**: 失敗時

#### 標準出力

* API レスポンス (json)

#### 標準エラー出力

* エラーおよびデバッグメッセージ

### slack::upload_file

`files.getUploadURLExternal` と `files.completeUploadExternal` を使用して、Slack にファイルをアップロードします。

#### オプション

* **--file \<value\>**

  (string)(必須): アップロードするファイルのパス

* **--token \<value\>**

  (string)(必須): Slack ボットトークン

* **--ch \<value\>**

  (string)(必須): ファイルをアップロードするチャンネルの ID

* **--title \<value\>**

  (string)(任意): ファイルのタイトル（デフォルト: ファイル名）

* **--message \<value\>**

  (string)(任意): ファイルを紹介するメッセージ本文。Slack の mrkdwn が使用可能です。

* **--thread-ts \<value\>**

  (string)(任意): 返信先の親メッセージの ts

* **--insecure**

  (任意): 証明書エラーを無視します。

#### 終了コード

* **0**: 成功時
* **1**: 失敗時

#### 標準出力

* `files.completeUploadExternal` からの API レスポンス (json)

#### 標準エラー出力

* エラーおよびデバッグメッセージ

