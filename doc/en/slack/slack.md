# slack/slack.sh

slack library

## Overview

Useful functions for using slack.

This library can change its behavior by setting the following environment variables.

* SLACK_POST : if false, it outputs logs only instead of calling api such as post, upload and so on. default: ``true``

## Index

* [slack::ping](#slackping)
* [slack::webhook_post](#slackwebhook_post)
* [slack::post_msg](#slackpost_msg)
* [slack::upload_file](#slackupload_file)

### slack::ping

Ping slack host.

#### Options

* **--host \<value\>**

  (string)(required): Slack URL such as https://localhost:8065

* **--insecure**

  (optional): Ignore certificate errors.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* None

#### Output on stderr

* Error and debug message.

### slack::webhook_post

Post a message to slack using incoming webhook.

#### Options

* **--message**

  / -m <vahlue> (string)(required): Message.

* **--url**

  / -u <value> (string)(required): Incoming webhook URL.

* **--type**

  / -t <value> (string)(option): Message type. text or mrkdwn (default: text)

* **--insecure**

  (optional): Ignore certificate errors.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* API response (json)

#### Output on stderr

* Error and debug message.

### slack::post_msg

Post a message to slack using chat.postMessage API.

#### Options

* **--message \<value\>**

  (string)(required): Message.

* **--type**

  / -t <value> (string)(option): Message type. text or mrkdwn or markdown (default: mrkdwn)

* **--token \<value\>**

  (string)(required): Slack bot token.

* **--ch \<value\>**

  (string)(required): Channel id.

* **--insecure**

  (optional): Ignore certificate errors.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* API response (json)

#### Output on stderr

* Error and debug message.

### slack::upload_file

Upload a file to slack using files.getUploadURLExternal and files.completeUploadExternal.

#### Options

* **--file \<value\>**

  (string)(required): File path to upload.

* **--token \<value\>**

  (string)(required): Slack bot token.

* **--ch \<value\>**

  (string)(required): The ID of the channel that this file will be uploaded to.

* **--title \<value\>**

  (string)(optional): Title of file (default: basename of file).

* **--message \<value\>**

  (string)(optional): Message text introducing the file. Slack mrkdwn is available.

* **--thread-ts \<value\>**

  (string)(optional): Parent message ts to upload as reply.

* **--insecure**

  (optional): Ignore certificate errors.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* API response (json) from files.completeUploadExternal

#### Output on stderr

* Error and debug message.

