# mattermost/mattermost.sh

mattermost library

## Overview

Useful functions for using mattermost.

This library can change its behavior by setting the following environment variables.

* MATTERMOST_POST : if false, it outputs logs only instead of calling api such as post, upload and so on. default: ``true``

## Index

* [__mattermost::check_host__](#mattermostcheckhost)
* [__mattermost::escape_message__](#mattermostescapemessage)
* [mattermost::ping](#mattermostping)
* [mattermost::webhook_post](#mattermostwebhookpost)
* [mattermost::post_msg](#mattermostpostmsg)
* [mattermost::upload_file](#mattermostuploadfile)
* [mattermost::post_msg_with_file](#mattermostpostmsgwithfile)

### __mattermost::check_host__

check mattermost hostname and strip last "/"

### __mattermost::escape_message__

escape message

### mattermost::ping

Ping mattermost api using /api/v4/system/ping endpoint.

#### Options

* **--host \<value\>**

  (string)(required): Mattermost URL such as https://localhost:8065

* **--insecure**

  (optional): Ignore certificate errors.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* None

#### Output on stderr

* Error and debug message.

### mattermost::webhook_post

Post a message to mattermost using incoming webhook.

#### Options

* **--message**

  / -m <vahlue> (string)(required): Message.

* **--url**

  / -u <value> (string)(required): Incoming webhook URL.

* **--insecure**

  (optional): Ignore certificate errors.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* API response (json)

#### Output on stderr

* Error and debug message.

### mattermost::post_msg

post message

#### Options

* **--message \<vahlue\>**

  (string)(required): Message.

* **--token \<token\>**

  (string)(required): token.

* **--host \<value\>**

  (string)(required): Mattermost URL such as https://localhost:8065

* **--ch \<value\>**

  (string)(required): Mattermost channel ID

* **--insecure**

  (optional): Ignore certificate errors.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* API response (json)

#### Output on stderr

* Error and debug message.

### mattermost::upload_file

Upload a file to mattermost using token. NOTE: Incoming webhook does not support uploading.

#### Options

* **--file \<file\>**

  (string)(required): file.

* **--token \<token\>**

  (string)(required): token.

* **--host \<value\>**

  (string)(required): Mattermost URL such as https://localhost:8065

* **--ch \<value\>**

  (string)(required): Mattermost channel ID

* **--insecure**

  (optional): Ignore certificate errors.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* API response (json)

#### Output on stderr

* Error and debug message.

### mattermost::post_msg_with_file

upload file and post message with it

#### Options

* **--message \<vahlue\>**

  (string)(required): Message.

* **--file \<file\>**

  (string)(required): file.

* **--token \<token\>**

  (string)(required): token.

* **--host \<value\>**

  (string)(required): Mattermost URL such as https://localhost:8065

* **--ch \<value\>**

  (string)(required): Mattermost channel ID

* **--insecure**

  (optional): Ignore certificate errors.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* post message API response (json)

#### Output on stderr

* Error and debug message.

