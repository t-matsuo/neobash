# markdown/table.sh

csv to markdown table

## Overview

convert csv to markdown table

## Index

* [markdown::csv2table](#markdowncsv2table)

### markdown::csv2table

Convert csv to markdown table

#### Options

* **--header \<string\>**

  table header csv (required)

* **--data \<string\>**

  table data csv (required)

* **--line-break \<string\>**

  replacement string for line breaks in quoted csv fields (default: <br>)

* **--cell-max-width \<int\>**

  max cell width after conversion, 0 means unlimited, must be >=5 if >0 (default: 0)

* **--table-max-byte \<int\>**

  max byte size per table output, 0 means unlimited (default: 0)

* **--table-max-line \<int\>**

  max data lines per table output, 0 means unlimited (default: 0)

#### Exit codes

* 0

#### Output on stdout

* table

#### Output on stderr

* None

