# mattermost/mattermost.sh

mattermost library

## Overview

Useful functions for using mattermost.

This library can change its behavior by setting the following environment variables.

* MATTERMOST_POST : if false, log message instead of post in mattermost::post(). default: ``true``

## Index

* [mattermost::ping](#mattermostping)
* [mattermost::post](#mattermostpost)

### mattermost::ping

Ping mattermost api using /api/v4/system/ping endpoint.

#### Options

* **--host \<value\>**

  (string)(required): Mattermost URL such as https://localhost:8065

* **--insecure**

  (optional): Ignore certificate errors.

* **--verbose**

  (optional): Verbose log.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* None

#### Output on stderr

* Error and debug message.

### mattermost::post

Post a message to mattermost using incoming webhook.

#### Options

* **--message**

  / -m <vahlue> (string)(required): Message.

* **--url**

  / -u <value> (string)(required): Incoming webhook URL.

* **--insecure**

  (optional): Ignore certificate errors.

* **--verbose**

  (optional): Verbose log.

#### Exit codes

* **0**: If successfull.
* **1**: If failed.

#### Output on stdout

* Show a post message if MATTERMOST_POST=false.

#### Output on stderr

* Error and debug message.

