---
title: Check Your Lua Quick Reference
description: A concise, single-page guide to using the minimal Check Your Lua (CYL) framework.
---

## Installation & Setup

Install the framework directly from the official repository via LuaRocks:

```bash
luarocks install checkyour
```

Alternatively, download `checkyour.lua` and place it in your project root, then require it.

```lua
local cyl = require('checkyour')
local describe, it, expect = cyl.describe, cyl.it, cyl.expect

cyl.parseargs() -- Parses command-line flags

-- Tests go here...

cyl.report()
cyl.exit() -- Returns 0 if pass, 1 if fail
```

Run tests using the standard interpreter:
```bash
lua tests.lua
```

---

## Organizing Tests

### Describe & It Blocks
Group test cases logically. Describe blocks can be nested seamlessly.

```lua
describe("authentication", function()
  describe("validation", function()
    it("accepts valid email addresses", function()
      -- Assertions here
    end)
  end)
end)
```

### Lifecycle Hooks
Run setup or teardown logic before and after every `it` block within the current scope.

```lua
describe("database suite", function()
  local db
  cyl.before(function() db = connect_db() end)
  cyl.after(function() db:close() end)

  it("queries records", function() expect.exist(db) end)
end)
```

### Skipping Tests
Pass `false` as the third argument to `it()` to skip execution temporarily.

```lua
it("wip feature", function()
  expect.equal(1, 2)
end, false)
```

---

## Assertions Reference

| Matcher | Description |
| :--- | :--- |
| `expect.exist(v)` | Passes if `v` is not `nil`. |
| `expect.not_exist(v)` | Passes if `v` is specifically `nil`. |
| `expect.truthy(v)` | Passes if `v` is not `nil` and not `false`. |
| `expect.falsy(v)` | Passes if `v` is `nil` or `false`. |
| `expect.equal(a, b)` | Asserts deep structural equality (handles nested tables). |
| `expect.not_equal(a, b)` | Asserts that `a` and `b` structurally differ. |
| `expect.type(v, t)` | Checks type matches string `t` (e.g., `"table"`, `"number"`). |
| `expect.near(a, b, d)` | Asserts numbers `a` and `b` are within delta `d` (floats). |
| `expect.contains(t, v)` | Checks if array `t` contains value `v`, or substring if `t` is a string. |
| `expect.length(v, n)` | Asserts that `#v == n` for strings or sequences. |
| `expect.fail(func, [msg])` | Passes if calling `func` throws an error (optional substring match). |
| `expect.not_fail(func)` | Passes if calling `func` executes cleanly. |

---

## Configuration Flags

Pass configuration switches via environment variables or command-line flags.

| Environment Variable | CLI Flag | Description |
| :--- | :--- | :--- |
| `CYL_QUIET=true` | `--quiet` | Compact character output mode (`◯◯◯[FAIL]`). |
| `CYL_STOP_ON_FAIL=true` | `--stop-on-fail` | Aborts test run immediately upon first failure. |
| `CYL_COLOR=false` | `--no-color` | Disables ANSI terminal coloring sequences. |
| `CYL_FILTER="pattern"` | `--filter="pattern"` | Runs only tests matching the specified pattern. |
| `CYL_SHOW_TRACEBACK=false` | `--no-show-traceback`| Suppresses traceback dumps on test failures. |

```bash
# Examples:
CYL_QUIET=true lua tests.lua
lua tests.lua --filter="user" --stop-on-fail
```