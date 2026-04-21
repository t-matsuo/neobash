# slack/slack.sh

slack library

## Overview

Useful functions for using slack.

This library can change its behavior by setting the following environment variables.

* SLACK_POST : if false, it outputs logs only instead of calling api such as post, upload and so on. default: ``true``

## Index

* [slack::ping](#slackping)
* [slack::webhook_post](#slackwebhookpost)

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

  / -t <value> (string)(option): Message type. text or mrkdwn

* **--insecure**

  (optional): Ignore certificate errors.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* API response (json)

#### Output on stderr

* Error and debug message.

