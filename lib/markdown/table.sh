#!/usr/bin/env bash
# Copyright 2025 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license

# @internal
# @description Convert a single CSV logical line to a markdown table row.
#              Handles double quotes, escaped quotes (""), and line breaks
#              within quoted fields.
# @arg $1 string A single CSV logical line
# @arg $2 string Replacement string for line breaks inside quoted fields
# @stdout markdown table row
__markdown::csv_line_to_markdown() {
    local csv="$1"
    local line_break="$2"
    local output="| "
    local field=""
    local in_quote=0
    local len=${#csv}
    local i ch

    for ((i = 0; i < len; i++)); do
        ch="${csv:i:1}"
        if (( in_quote == 0 )); then
            case "$ch" in
                '"')
                    in_quote=1
                    ;;
                ',')
                    field="${field//|/\\|}"
                    output+="${field} | "
                    field=""
                    ;;
                *)
                    field+="$ch"
                    ;;
            esac
        else
            case "$ch" in
                '"')
                    if (( i + 1 < len )) && [[ "${csv:i+1:1}" == '"' ]]; then
                        field+='"'
                        i=$((i + 1))
                    else
                        in_quote=0
                    fi
                    ;;
                $'\n')
                    field+="$line_break"
                    ;;
                *)
                    field+="$ch"
                    ;;
            esac
        fi
    done

    field="${field//|/\\|}"
    output+="${field} |"
    printf '%s\n' "$output"
}

# @description Convert csv to markdown table
#
# @option --header <string> table header csv (required)
# @option --data <string> table data csv (required)
# @option --line-break <string> replacement string for line breaks in quoted csv fields (default: <br>)
# @stdout table
# @stderr None
# @exitcode 0
markdown::csv2table() {
    local HEADER_MD=""
    local BORDER=""
    local DATA_MD=""
    local LINE_BREAK="<br>"
    local line
    local current_line=""
    local in_quote=0
    local len i ch

    arg::init_local
    arg::add_option -l "HEADER" -o "--header" -t "string" -r "true" -h "table header csv"
    arg::add_option -l "DATA" -o "--data" -t "string" -r "true" -h "table data csv"
    arg::add_option -l "LINE_BREAK" -o "--line-break" -t "string" -r "false" -d "<br>" -h "replacement string for line breaks in quoted csv fields"
    arg::parse "$@"

    LINE_BREAK="${ARGS[LINE_BREAK]}"

    # Process header (single logical line)
    HEADER_MD="$(__markdown::csv_line_to_markdown "${ARGS[HEADER]}" "$LINE_BREAK")"

    # Build border from header field count
    local field_count=0
    local header_csv="${ARGS[HEADER]}"
    local h_in_quote=0
    len=${#header_csv}
    for ((i = 0; i < len; i++)); do
        ch="${header_csv:i:1}"
        if (( h_in_quote == 0 )); then
            if [[ "$ch" == '"' ]]; then
                h_in_quote=1
            elif [[ "$ch" == ',' ]]; then
                field_count=$((field_count + 1))
            fi
        else
            if [[ "$ch" == '"' ]]; then
                if (( i + 1 < len )) && [[ "${header_csv:i+1:1}" == '"' ]]; then
                    i=$((i + 1))
                else
                    h_in_quote=0
                fi
            fi
        fi
    done
    field_count=$((field_count + 1))

    BORDER="|"
    for ((i = 0; i < field_count; i++)); do
        BORDER+=" -- |"
    done

    # Process data: split into logical lines respecting quotes, then convert each
    local data_csv="${ARGS[DATA]}"
    len=${#data_csv}
    for ((i = 0; i < len; i++)); do
        ch="${data_csv:i:1}"
        current_line+="$ch"
        if (( in_quote == 0 )); then
            if [[ "$ch" == '"' ]]; then
                in_quote=1
            elif [[ "$ch" == $'\n' ]]; then
                # Remove trailing newline before conversion
                line="${current_line%$'\n'}"
                DATA_MD+="$(__markdown::csv_line_to_markdown "$line" "$LINE_BREAK")"$'\n'
                current_line=""
            fi
        else
            if [[ "$ch" == '"' ]]; then
                if (( i + 1 < len )) && [[ "${data_csv:i+1:1}" == '"' ]]; then
                    i=$((i + 1))
                    current_line+='"'
                else
                    in_quote=0
                fi
            fi
        fi
    done

    # Handle last line (with or without trailing newline)
    if [[ -n "$current_line" ]]; then
        line="${current_line%$'\n'}"
        DATA_MD+="$(__markdown::csv_line_to_markdown "$line" "$LINE_BREAK")"$'\n'
    fi

    printf '%s\n' "$HEADER_MD"
    printf '%s\n' "$BORDER"
    printf '%s' "$DATA_MD"
}
