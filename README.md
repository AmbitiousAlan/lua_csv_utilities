# CSV/Lua Utilities

A small collection of Lua-based tools and experiments for working with CSV files—treating them not just as data, but sometimes as **code** or structure.

This repo contains several utilities that help parse, transform, and reason about CSV data in Lua. Some are pure Lua, others are performance-minded C bindings.

---

## 🔧 Included Tools

### `csvluaruntime.lua`
A ~200-line utility that lets you **run CSV files as lightweight Lua programs**.  
Useful for treating structured CSVs as declarative input formats or mini DSLs.

- Parses one or more CSVs from the command line
- Finds **"corners"**—cells with both the cell above and to the left empty—to define logical regions
- Enables block-based data processing or interpretation

---

### `csv_to_array2d.lua`
Converts CSV files to 2D Lua arrays, and **vice versa**.  
The Lua version requires no compilation and is useful for lightweight scripting.

---

### `lua_parse_csv.c`
A minimal C-based CSV parser that outputs a Lua 2D table structure.  
Faster than the Lua-only version. Comes with:

- `lua_parse_csv_build.sh` — compile script for building the shared object

---

### `table_to_array2d.lua`
Bi-directional conversion between deeply nested Lua tables and 2D arrays.  
Designed for editing structured Lua tables in spreadsheet form:

- `table_to_array2d(t, branch_filter, kv_filter)`
  - `branch_filter(key, value, path)` – return `true` to recurse into this branch
  - `kv_filter(key, value, path)` – return `true` to include this key-value in the CSV
- `array2d_to_table(array2d, branch_filter, out_table)`
  - If `out_table` is provided, it must be the same table passed to `table_to_array2d`
  - In that case, the same `branch_filter` **must** be used to preserve structure
  - If `out_table` is `nil`, a new table is constructed
  - Do **not** remove rows from the CSV before using `array2d_to_table`, or the structure may break

This allows a roundtrip workflow:  
→ convert table → edit CSV in spreadsheet → load CSV back into table

---

### `lua_users_utilities.lua`
Contains a single utility: **deep table copy**, adapted from [lua-users.org](http://lua-users.org/wiki/CopyTable).  
More helpers may be added as needed.

---

## 💡 Use Cases

These tools are experimental and modular—you can combine them to:

- Interpret structured CSV as logic blocks
- Roundtrip Lua tables into editable spreadsheet formats
- Build small table-driven engines or configuration processors
- Convert between Lua tables and CSV for scripting or debugging

---

## 🛠 Building the C Parser

To build the optional fast parser:

```sh
sh lua_parse_csv_build.sh
```

This will produce a shared object usable from Lua via `require`.

---

## 📁 File Overview

| File                    | Description                                               |
|-------------------------|-----------------------------------------------------------|
| `csvluaruntime.lua`     | CSV as program (corner-based DSL)                         |
| `csv_to_array2d.lua`    | Pure Lua CSV ⇄ 2D array                                   |
| `lua_parse_csv.c`       | C-based CSV parser                                        |
| `lua_parse_csv_build.sh`| Build script for the above                                |
| `table_to_array2d.lua`  | Nested table ⇄ 2D array (spreadsheet-friendly)            |
| `lua_users_utilities.lua` | Deep table copy function                                |
| `README.md`             | This file                                                 |


---

<sub>**Note:** Lua has several great libraries to make your life easier:</sub>  
<sub>• [inspect](https://github.com/kikito/inspect.lua) – human-readable table printer</sub>  
<sub>• [binser](https://github.com/bakpakin/binser) – binary serializer</sub>  
<sub>• [rxi/json.lua](https://github.com/rxi/json.lua) – fast minimal JSON library</sub>  
<sub>• [xml2lua](https://github.com/manoelcampos/xml2lua) – convert XML to Lua tables and back</sub>

