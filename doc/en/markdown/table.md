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

* **--table-max-lines \<int\>**

  max table lines per page (header and separator line included), 0 means unlimited (default: 0)

* **--page-break \<string\>**

  page separator string, %page and %total are replaced (default: <!-- page %page/%total -->)

* **--align \<bool\>**

  if true, align columns by padding cells with spaces (default: false)

* **--no-line-break \<bool\>**

  if true, preserve line breaks inside quoted fields as physical rows instead of replacing them (default: false)

#### Exit codes

* 0

#### Output on stdout

* table

#### Output on stderr

* None

