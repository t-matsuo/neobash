#!/usr/bin/env bash
# Copyright 2025 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license

nb::require "core/log.sh core/arg.sh"

markdown::csv2table() {
    local RES=""
    local HEADER=""
    local BORDER=""
    local DATA=""
    local DATA_TMP=""
    local line

    arg::init_local
    arg::add_option -l "HEADER" -o "--header" -t "string" -r "true" -h "table header csv"
    arg::add_option -l "DATA" -o "--data" -t "string" -r "true" -h "table data csv"
    arg::parse "$@"

    HEADER="${ARGS[HEADER]//,/ | }"
    HEADER="| ${HEADER} |"

    BORDER="${HEADER//[^|]/}"
    BORDER="${BORDER//|/| -- }"
    BORDER="${BORDER% -- }"

    while IFS= read -r line; do
        DATA_TMP="${line//,/ | }"
        DATA_TMP="| ${DATA_TMP} |"
        # add newline with $'\n'
        DATA="${DATA}${DATA_TMP}"$'\n'
    done < <(echo "${ARGS[DATA]}")

    echo "$HEADER"
    echo "$BORDER"
    echo -n "$DATA"
}
