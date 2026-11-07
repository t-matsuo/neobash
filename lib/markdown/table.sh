#!/usr/bin/env bash
# Copyright 2025 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license

# @file markdown/table.sh
# @brief csv to markdown table
# @description
# convert csv to markdown table

# @internal
# @description Truncate a field string if it exceeds the maximum width.
#              If the field is longer than max, it is truncated and appended with "...".
# @arg $1 string Field value
# @arg $2 int    Maximum width (0 for unlimited)
# @stdout truncated or original field string
__markdown::truncate_field() {
    local field="$1"
    local max="$2"
    if (( max > 0 && ${#field} > max )); then
        printf '%s' "${field:0:max-3}..."
    else
        printf '%s' "$field"
    fi
}

# @internal
# @description Convert a single CSV logical line to a markdown table row.
#              Handles double quotes, escaped quotes (""), line breaks
#              within quoted fields, and cell max width truncation.
# @arg $1 string A single CSV logical line
# @arg $2 string Replacement string for line breaks inside quoted fields
# @arg $3 int    Cell max width (0 for unlimited)
# @stdout markdown table row
__markdown::csv_line_to_markdown() {
    local csv="$1"
    local line_break="$2"
    local cell_max="$3"
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
                    field="$(__markdown::truncate_field "$field" "$cell_max")"
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
    field="$(__markdown::truncate_field "$field" "$cell_max")"
    output+="${field} |"
    printf '%s\n' "$output"
}

# @internal
# @description Count the number of fields in a CSV line.
#              Handles double quotes so commas inside quotes are not counted as delimiters.
# @arg $1 string A single CSV logical line
# @stdout field count as a number
__markdown::field_count() {
    local csv="$1"
    local count=0
    local in_quote=0
    local len=${#csv}
    local i ch
    for ((i = 0; i < len; i++)); do
        ch="${csv:i:1}"
        if (( in_quote == 0 )); then
            if [[ "$ch" == '"' ]]; then
                in_quote=1
            elif [[ "$ch" == ',' ]]; then
                count=$((count + 1))
            fi
        else
            if [[ "$ch" == '"' ]]; then
                if (( i + 1 < len )) && [[ "${csv:i+1:1}" == '"' ]]; then
                    i=$((i + 1))
                else
                    in_quote=0
                fi
            fi
        fi
    done
    printf '%s\n' "$((count + 1))"
}

# @description Convert csv to markdown table
#
# @option --header <string> table header csv (required)
# @option --data <string> table data csv (required)
# @option --line-break <string> replacement string for line breaks in quoted csv fields (default: <br>)
# @option --cell-max-width <int> max cell width after conversion, 0 means unlimited, must be >=5 if >0 (default: 0)
# @option --table-max-byte <int> max byte size per table output, 0 means unlimited (default: 0)
# @option --table-max-line <int> max data lines per table output, 0 means unlimited (default: 0)
# @option --page-break <string> replacement string for page breaks (default: <!-- page %page/%total -->)
# @stdout table
# @stderr None
# @exitcode 0
markdown::csv2table() {
    local LINE_BREAK="<br>"
    local CELL_MAX_WIDTH="0"
    local TABLE_MAX_BYTE="0"
    local TABLE_MAX_LINE="0"

    arg::init_local
    arg::add_option -l "HEADER" -o "--header" -t "string" -r "true" -h "table header csv"
    arg::add_option -l "DATA" -o "--data" -t "string" -r "true" -h "table data csv"
    arg::add_option -l "LINE_BREAK" -o "--line-break" -t "string" -r "false" -d "<br>" -h "replacement string for line breaks in quoted csv fields"
    arg::add_option -l "CELL_MAX_WIDTH" -o "--cell-max-width" -t "int" -r "false" -d "0" -h "max cell width after conversion, 0 means unlimited, must be >=5 if >0"
    arg::add_option -l "TABLE_MAX_BYTE" -o "--table-max-byte" -t "int" -r "false" -d "0" -h "max byte size per table output, 0 means unlimited"
    arg::add_option -l "TABLE_MAX_LINE" -o "--table-max-line" -t "int" -r "false" -d "0" -h "max data lines per table output, 0 means unlimited"
    arg::add_option -l "PAGE_BREAK" -o "--page-break" -t "string" -r "false" -d "<!-- page %page/%total -->" -h "page separator string, %page and %total are replaced"
    arg::parse "$@"

    LINE_BREAK="${ARGS[LINE_BREAK]}"
    CELL_MAX_WIDTH="${ARGS[CELL_MAX_WIDTH]}"
    TABLE_MAX_BYTE="${ARGS[TABLE_MAX_BYTE]}"
    TABLE_MAX_LINE="${ARGS[TABLE_MAX_LINE]}"
    local PAGE_BREAK="${ARGS[PAGE_BREAK]}"

    if (( CELL_MAX_WIDTH > 0 && CELL_MAX_WIDTH < 5 )); then
        log::error_exit "--cell-max-width must be >= 5 or 0"
    fi

    # Split data into logical lines respecting quotes
    local -a DATA_LINES=()
    local raw_csv="${ARGS[DATA]}"
    local current_line=""
    local in_quote=0
    local len=${#raw_csv}
    local i ch

    for ((i = 0; i < len; i++)); do
        ch="${raw_csv:i:1}"
        current_line+="$ch"
        if (( in_quote == 0 )); then
            if [[ "$ch" == '"' ]]; then
                in_quote=1
            elif [[ "$ch" == $'\n' ]]; then
                DATA_LINES+=("${current_line%$'\n'}")
                current_line=""
            fi
        else
            if [[ "$ch" == '"' ]]; then
                if (( i + 1 < len )) && [[ "${raw_csv:i+1:1}" == '"' ]]; then
                    i=$((i + 1))
                    current_line+='"'
                else
                    in_quote=0
                fi
            fi
        fi
    done
    if [[ -n "$current_line" ]]; then
        DATA_LINES+=("${current_line%$'\n'}")
    fi

    # Header and border
    local HEADER_MD
    HEADER_MD=$(__markdown::csv_line_to_markdown "${ARGS[HEADER]}" "$LINE_BREAK" "$CELL_MAX_WIDTH")
    local field_count
    field_count=$(__markdown::field_count "${ARGS[HEADER]}")
    local BORDER="|"
    for ((i = 0; i < field_count; i++)); do
        BORDER+=" -- |"
    done

    local header_block="${HEADER_MD}"$'\n'"${BORDER}"$'\n'
    local header_byte=${#header_block}

    # Fast path: no paging limits and no cell truncation
    if (( CELL_MAX_WIDTH <= 0 && TABLE_MAX_BYTE <= 0 && TABLE_MAX_LINE <= 0 )); then
        printf '%s' "$header_block"
        local raw
        for raw in "${DATA_LINES[@]}"; do
            __markdown::csv_line_to_markdown "$raw" "$LINE_BREAK" "$CELL_MAX_WIDTH"
        done
        return 0
    fi

    # Build pages
    local -a PAGES=()
    local current_page=""
    local current_byte=$header_byte
    local current_line_num=0
    local raw md_line line_byte
    local need_new_page

    for raw in "${DATA_LINES[@]}"; do
        md_line=$(__markdown::csv_line_to_markdown "$raw" "$LINE_BREAK" "$CELL_MAX_WIDTH")
        line_byte=$((${#md_line} + 1))
        need_new_page=0

        if (( TABLE_MAX_BYTE > 0 && current_byte + line_byte > TABLE_MAX_BYTE )); then
            need_new_page=1
        fi
        if (( TABLE_MAX_LINE > 0 && current_line_num >= TABLE_MAX_LINE )); then
            need_new_page=1
        fi

        if (( need_new_page )); then
            PAGES+=("$current_page")
            current_page="${md_line}"$'\n'
            current_byte=$((header_byte + line_byte))
            current_line_num=1
        else
            current_page+="${md_line}"$'\n'
            current_byte=$((current_byte + line_byte))
            current_line_num=$((current_line_num + 1))
        fi
    done

    # Add remaining page
    if [[ -n "$current_page" ]]; then
        PAGES+=("$current_page")
    elif [[ ${#PAGES[@]} -eq 0 ]]; then
        PAGES+=("")
    fi

    local total_pages=${#PAGES[@]}
    local p
    local break_str
    for ((p = 0; p < total_pages; p++)); do
        if (( p > 0 )); then
            break_str="${PAGE_BREAK//%page/$((p + 1))}"
            break_str="${break_str//%total/$total_pages}"
            printf '%s\n' "$break_str"
        fi
        printf '%s' "$header_block"
        printf '%s' "${PAGES[p]}"
    done
}
