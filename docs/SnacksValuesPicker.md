# Snacks values picker

`SnacksValuesPicker` opens a searchable list of strings and inserts one or more
values into the buffer and cursor position that were current when it opened.
It requires [snacks.nvim](https://github.com/folke/snacks.nvim) and does not
require a MetaFly database.

```lua
require("MetaFly.picker.SnacksValuesPicker").open({ "apple", "pear", "plum" })
```

Use the normal Snacks picker controls to filter the list. Press `Tab` or
`Shift-Tab` to mark values. Marked values are inserted in selection order;
if none are marked, the highlighted value is used. Identical values can be
marked independently. Escape cancels without changing the buffer.

- `Enter` inserts values separated by `, `, for example `apple, pear`.
- `Ctrl-X` inserts Markdown list items, one per line, for example:

  ```markdown
  - apple
  - pear
  ```

Insertion is characterwise at the saved cursor position: text before the cursor
stays before the first value, and text after it stays after the last value. Start
at the beginning of an empty line if the Markdown items should occupy complete
lines. The saved position is a byte offset; it is not tracked if the original
buffer is edited while the picker is open. If the original buffer is unavailable
or cannot be changed, an error is reported instead.

Values must be single-line strings. An empty list or a confirmation without an
item produces a warning; invalid values produce an error.
