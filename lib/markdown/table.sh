#!/usr/bin/env bash
# Copyright 2025 MATSUO Takatoshi (matsuo.tak@gmail.com)
# Released under the MIT licence: http://opensource.org/licenses/mit-license

nb::require "core/log.sh core/arg.sh"

# Global work arrays used to pass data without nameref (bash 4.2 compatible)
__MARKDOWN_CELLS=()
__MARKDOWN_COL_WIDTHS=()

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
# @description Parse a single CSV logical line into the global __MARKDOWN_CELLS array.
#              Handles double quotes, escaped quotes (""), and line breaks.
# @arg $1 string A single CSV logical line
# @arg $2 string Replacement string for line breaks inside quoted fields
# @arg $3 int    If non-zero, keep line breaks as-is instead of replacing them
__markdown::parse_csv_to_cells() {
    local csv="$1"
    local line_break="$2"
    local no_line_break="$3"
    __MARKDOWN_CELLS=()
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
                    __MARKDOWN_CELLS+=("$field")
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
                    if (( no_line_break )); then
                        field+="$ch"
                    else
                        field+="$line_break"
                    fi
                    ;;
                *)
                    field+="$ch"
                    ;;
            esac
        fi
    done
    __MARKDOWN_CELLS+=("$field")
}

# @internal
# @description Build a single markdown row from cells.
#              Cells are passed as individual arguments after cell_max and align flags ($3 and onwards).
# @arg $1 int    Cell max width (0 for unlimited)
# @arg $2 int    If non-zero, pad cells using __MARKDOWN_COL_WIDTHS
# @arg $3 string Cell value (additional cell values follow as further arguments)
# @stdout markdown table row
__markdown::build_md_row() {
    local cell_max="$1"
    local align="$2"
    shift 2
    local output="| "
    local cell
    local i=0
    for cell in "$@"; do
        cell="${cell//|/\\|}"
        cell="$(__markdown::truncate_field "$cell" "$cell_max")"
        if (( align )); then
            local width=${__MARKDOWN_COL_WIDTHS[$i]}
            cell=$(printf '%-*s' "$width" "$cell")
        fi
        output+="${cell} | "
        i=$((i + 1))
    done
    output="${output% }"
    printf '%s\n' "$output"
}

# @internal
# @description Render a single CSV logical row as one or more markdown rows.
#              When a field contains newlines, it is expanded so that continuation
#              parts appear in the same column on subsequent markdown rows, while
#              other columns are left empty.
# @arg $1 int    Cell max width (0 for unlimited)
# @arg $2 int    If non-zero, pad cells using __MARKDOWN_COL_WIDTHS
# @arg $3 string First cell value (additional cells follow as further arguments)
# @stdout one or more markdown rows separated by newlines
__markdown::render_logical_row() {
    local cell_max="$1"
    local align="$2"
    shift 2
    local -a cells=("$@")
    local col_count=${#cells[@]}

    if (( col_count == 0 )); then
        return 0
    fi

    # Split each field by newline and store parts in flat arrays with offsets.
    # Using eval with newline-bearing data can corrupt values, so we keep a
    # single flat list plus per-column start/count metadata.
    local -a parts_flat=()
    local -a parts_start=()
    local -a parts_count=()
    local max_subrows=0
    local i j

    for ((i = 0; i < col_count; i++)); do
        local cell="${cells[i]}"
        local current=""
        local start=${#parts_flat[@]}
        local count=0
        local len=${#cell}
        for ((j = 0; j < len; j++)); do
            local ch="${cell:j:1}"
            if [[ "$ch" == $'\n' ]]; then
                parts_flat+=("$current")
                current=""
                count=$((count + 1))
            else
                current+="$ch"
            fi
        done
        parts_flat+=("$current")
        count=$((count + 1))
        parts_start+=($start)
        parts_count+=($count)
        if (( count > max_subrows )); then
            max_subrows=$count
        fi
    done

    # Build output rows
    local output=""
    for ((j = 0; j < max_subrows; j++)); do
        local -a row_cells=()
        for ((i = 0; i < col_count; i++)); do
            local start=${parts_start[$i]}
            local count=${parts_count[$i]}
            if (( j < count )); then
                row_cells+=("${parts_flat[$((start + j))]}")
            else
                row_cells+=("")
            fi
        done
        output+="$(__markdown::build_md_row "$cell_max" "$align" "${row_cells[@]}")"$'\n'
    done

    output="${output%$'\n'}"
    printf '%s' "$output"
}

# @internal
# @description Update __MARKDOWN_COL_WIDTHS from a single row of cells.
#              Each cell may contain newlines; each part is considered separately.
# @arg $1 string First cell value (additional cells follow as further arguments)
__markdown::update_col_widths() {
    local i=0
    local cell part current ch
    for cell in "$@"; do
        current=""
        local len=${#cell}
        local j
        for ((j = 0; j < len; j++)); do
            ch="${cell:j:1}"
            if [[ "$ch" == $'\n' ]]; then
                part="$current"
                current=""
            else
                current+="$ch"
                continue
            fi
            if (( i < ${#__MARKDOWN_COL_WIDTHS[@]} )); then
                if (( ${#part} > __MARKDOWN_COL_WIDTHS[i] )); then
                    __MARKDOWN_COL_WIDTHS[i]=${#part}
                fi
            else
                __MARKDOWN_COL_WIDTHS+=(${#part})
            fi
        done
        part="$current"
        if (( i < ${#__MARKDOWN_COL_WIDTHS[@]} )); then
            if (( ${#part} > __MARKDOWN_COL_WIDTHS[i] )); then
                __MARKDOWN_COL_WIDTHS[i]=${#part}
            fi
        else
            __MARKDOWN_COL_WIDTHS+=(${#part})
        fi
        i=$((i + 1))
    done
}

# @internal
# @description Count physical lines in a string.
# @arg $1 string Input string
# @stdout number of physical lines
__markdown::count_physical_lines() {
    local str="$1"
    local len=${#str}
    if (( len == 0 )); then
        printf '0\n'
        return 0
    fi
    local count=1
    local i
    for ((i = 0; i < len; i++)); do
        if [[ "${str:i:1}" == $'\n' ]]; then
            count=$((count + 1))
        fi
    done
    printf '%s\n' "$count"
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
# @option --table-max-lines <int> max table lines per page (header and separator line included), 0 means unlimited (default: 0)
# @option --page-break <string> page separator string, %page and %total are replaced (default: <!-- page %page/%total -->)
# @option --align <bool> if true, align columns by padding cells with spaces (default: false)
# @option --no-line-break <bool> if true, preserve line breaks inside quoted fields as physical rows instead of replacing them (default: false)
# @stdout table
# @stderr None
# @exitcode 0
markdown::csv2table() {
    local LINE_BREAK="<br>"
    local CELL_MAX_WIDTH="0"
    local TABLE_MAX_BYTE="0"
    local TABLE_MAX_LINES="0"
    local PAGE_BREAK="<!-- page %page/%total -->"
    local ALIGN="false"
    local NO_LINE_BREAK="false"

    arg::init_local
    arg::add_option -l "HEADER" -o "--header" -t "string" -r "true" -h "table header csv"
    arg::add_option -l "DATA" -o "--data" -t "string" -r "true" -h "table data csv"
    arg::add_option -l "LINE_BREAK" -o "--line-break" -t "string" -r "false" -d "<br>" -h "replacement string for line breaks in quoted csv fields"
    arg::add_option -l "CELL_MAX_WIDTH" -o "--cell-max-width" -t "int" -r "false" -d "0" -h "max cell width after conversion, 0 means unlimited, must be >=5 if >0"
    arg::add_option -l "TABLE_MAX_BYTE" -o "--table-max-byte" -t "int" -r "false" -d "0" -h "max byte size per table output, 0 means unlimited"
    arg::add_option -l "TABLE_MAX_LINES" -o "--table-max-lines" -t "int" -r "false" -d "0" -h "max table lines per page (header and separator line included), 0 means unlimited"
    arg::add_option -l "PAGE_BREAK" -o "--page-break" -t "string" -r "false" -d "<!-- page %page/%total -->" -h "page separator string, %page and %total are replaced"
    arg::add_option -l "ALIGN" -o "--align" -t "bool" -r "false" -d "false" -h "if true, align columns by padding cells with spaces"
    arg::add_option -l "NO_LINE_BREAK" -o "--no-line-break" -t "bool" -r "false" -d "false" -h "if true, preserve line breaks inside quoted fields as physical rows instead of replacing them"
    arg::parse "$@"

    LINE_BREAK="${ARGS[LINE_BREAK]}"
    CELL_MAX_WIDTH="${ARGS[CELL_MAX_WIDTH]}"
    TABLE_MAX_BYTE="${ARGS[TABLE_MAX_BYTE]}"
    TABLE_MAX_LINES="${ARGS[TABLE_MAX_LINES]}"
    PAGE_BREAK="${ARGS[PAGE_BREAK]}"
    ALIGN="${ARGS[ALIGN]}"
    NO_LINE_BREAK="${ARGS[NO_LINE_BREAK]}"

    if (( CELL_MAX_WIDTH > 0 && CELL_MAX_WIDTH < 5 )); then
        log::error_exit "--cell-max-width must be >= 5 or 0"
    fi

    local align_flag=0
    [[ "$ALIGN" == "true" ]] && align_flag=1
    local no_break_flag=0
    [[ "$NO_LINE_BREAK" == "true" ]] && no_break_flag=1

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

    # Parse header cells
    __markdown::parse_csv_to_cells "${ARGS[HEADER]}" "$LINE_BREAK" "$no_break_flag"
    local -a HEADER_CELLS=("${__MARKDOWN_CELLS[@]}")
    local field_count=${#HEADER_CELLS[@]}

    # Parse data rows into a flattened array with column counts per row
    local -a DATA_CELLS=()
    local -a DATA_ROW_COL_COUNTS=()
    local raw
    for raw in "${DATA_LINES[@]}"; do
        __markdown::parse_csv_to_cells "$raw" "$LINE_BREAK" "$no_break_flag"
        DATA_ROW_COL_COUNTS+=(${#__MARKDOWN_CELLS[@]})
        DATA_CELLS+=("${__MARKDOWN_CELLS[@]}")
    done

    # Compute column widths if alignment is requested
    __MARKDOWN_COL_WIDTHS=()
    if (( align_flag )); then
        __markdown::update_col_widths "${HEADER_CELLS[@]}"
        local idx=0
        for count in "${DATA_ROW_COL_COUNTS[@]}"; do
            local -a row_cells=()
            local j
            for ((j = 0; j < count; j++)); do
                row_cells+=("${DATA_CELLS[idx]}")
                idx=$((idx + 1))
            done
            __markdown::update_col_widths "${row_cells[@]}"
        done
    fi

    # Render header and data rows
    local HEADER_MD
    HEADER_MD=$(__markdown::render_logical_row "$CELL_MAX_WIDTH" "$align_flag" "${HEADER_CELLS[@]}")
    local -a MD_ROWS=()
    MD_ROWS+=("$HEADER_MD")

    idx=0
    for count in "${DATA_ROW_COL_COUNTS[@]}"; do
        local -a row_cells=()
        local j
        for ((j = 0; j < count; j++)); do
            row_cells+=("${DATA_CELLS[idx]}")
            idx=$((idx + 1))
        done
        MD_ROWS+=("$(__markdown::render_logical_row "$CELL_MAX_WIDTH" "$align_flag" "${row_cells[@]}")")
    done

    # Build border
    local BORDER="|"
    if (( align_flag )); then
        BORDER="| "
        local w sep
        for ((i = 0; i < field_count; i++)); do
            w=${__MARKDOWN_COL_WIDTHS[$i]}
            sep=""
            for ((j = 0; j < w; j++)); do
                sep+="-"
            done
            BORDER+="${sep} | "
        done
        BORDER="${BORDER% }"
    else
        for ((i = 0; i < field_count; i++)); do
            BORDER+=" -- |"
        done
    fi

    local header_block="${HEADER_MD}"$'\n'"${BORDER}"$'\n'
    local header_byte=${#header_block}
    local -a DATA_MD_ROWS=("${MD_ROWS[@]:1}")

    # Fast path: no paging limits, no cell truncation, no alignment
    if (( CELL_MAX_WIDTH <= 0 && TABLE_MAX_BYTE <= 0 && TABLE_MAX_LINES <= 0 && align_flag == 0 )); then
        printf '%s' "$header_block"
        local md_row
        for md_row in "${DATA_MD_ROWS[@]}"; do
            printf '%s\n' "$md_row"
        done
        return 0
    fi

    # Build pages
    local -a PAGES=()
    local current_page=""
    local current_byte=$header_byte
    local current_lines=0
    local md_row line_byte line_count need_new_page line_cost

    for md_row in "${DATA_MD_ROWS[@]}"; do
        line_byte=$((${#md_row} + 1))
        line_count=$(__markdown::count_physical_lines "$md_row")
        # table-max-lines counts header + separator + data lines per page.
        # First data row on a page costs 2 (header + separator) + line_count.
        # Subsequent rows cost line_count.
        if (( ${#PAGES[@]} == 0 && current_lines == 0 )); then
            line_cost=$((2 + line_count))
        else
            line_cost=$line_count
        fi

        need_new_page=0
        if (( TABLE_MAX_BYTE > 0 && current_byte + line_byte > TABLE_MAX_BYTE )); then
            need_new_page=1
        fi
        if (( TABLE_MAX_LINES > 0 && current_lines + line_cost > TABLE_MAX_LINES )); then
            need_new_page=1
        fi

        if (( need_new_page )); then
            PAGES+=("$current_page")
            current_page="${md_row}"$'\n'
            current_byte=$((header_byte + line_byte))
            current_lines=$((2 + line_count))
        else
            current_page+="${md_row}"$'\n'
            current_byte=$((current_byte + line_byte))
            current_lines=$((current_lines + line_cost))
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
