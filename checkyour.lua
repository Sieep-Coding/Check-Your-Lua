--[[
CHECK YOUR LUA - Minimal Lua Testing Framework
Nick Stambaugh - nickstambaugh@proton.me
https://github.com/sieep-coding/Check-Your-Lua
https://nickstambaugh.dev

Public Domain (Unlicense) - See bottom for details.

INSTALL via LuaRocks:
  luarocks install checkyour

USAGE:
  local cyl = require('checkyour')
  local describe, it, expect = cyl.describe, cyl.it, cyl.expect

  describe("my module", function()
    it("does the thing", function()
      expect.equal(1 + 1, 2)
    end)
  end)

  cyl.report()
  cyl.exit()
]]


local VERSION = "1.0.0"

local log = {}
function log.info(m)  print('[INFO] '  .. tostring(m)) end
function log.error(m) print('[ERROR] ' .. tostring(m)) end


local ESC = string.char(27)
local color_codes = {
  reset   = ESC .. '[0m',
  bright  = ESC .. '[1m',
  red     = ESC .. '[31m',
  green   = ESC .. '[32m',
  yellow  = ESC .. '[33m',
  blue    = ESC .. '[34m',
  magenta = ESC .. '[35m',
  cyan    = ESC .. '[36m',
}

-- UTF-8 bullet used in quiet mode
local QUIET_DOT = string.char(226, 151, 143)


local function is_utf8term()
  local lang = os.getenv('LANG') or os.getenv('LC_ALL') or ''
  return lang:lower():match('utf%-?8$') ~= nil
end

local function is_windows()
  local os_name = os.getenv('OS') or ''
  if os_name:lower():match('windows') then return true end
  local handle = io.popen('uname -s 2>/dev/null')
  if not handle then return false end
  local result = handle:read('*a')
  handle:close()
  return result and result:lower():match('windows') ~= nil
end

local function exit_with_code(code)
  if is_windows() then
    os.exit(code, true)
  else
    os.exit(code)
  end
end


local function getboolenv(name, default)
  local v = os.getenv(name)
  if v == 'true'  then return true  end
  if v == 'false' then return false end
  return default
end


local last_succeeded  = false
local level           = 0
local successes       = 0
local total_successes = 0
local failures        = 0
local total_failures  = 0
local skipped         = 0
local total_skipped   = 0
local start           = 0
local befores         = {}
local afters          = {}
local names           = {}
local cyl_start       = os.clock()


local cyl = {
  version        = VERSION,
  color          = getboolenv('CYL_COLOR',          true),
  quiet          = getboolenv('CYL_QUIET',           false),
  show_traceback = getboolenv('CYL_SHOW_TRACEBACK',  true),
  show_error     = getboolenv('CYL_SHOW_ERROR',      true),
  stop_on_fail   = getboolenv('CYL_STOP_ON_FAIL',    false),
  utf8term       = getboolenv('CYL_UTF8TERM',        is_utf8term()),
  filter         = os.getenv('CYL_FILTER') or '',
  seconds        = os.clock,
}

-- Color proxy: returns empty string when colors disabled
local colors = setmetatable({}, {
  __index = function(_, key)
    return cyl.color and color_codes[key] or ''
  end
})
cyl.color = colors   -- expose for tests that inspect it


---Parse command-line arguments from `arg` (or a custom table).
---Supports: --flag, --no-flag, --filter=pattern
---@param arg_table table|nil defaults to _G.arg
function cyl.parseargs(arg_table)
  arg_table = arg_table or _G.arg or {}
  for _, opt in ipairs(arg_table) do
    local name, value
    if opt:find('^%-%-filter=') then
      name  = 'filter'
      value = opt:match('^%-%-filter%=(.*)$')
    elseif opt:find('^%-%-no%-[a-z0-9-]+$') then
      name  = opt:match('^%-%-no%-([a-z0-9-]+)$'):gsub('-', '_')
      value = false
    elseif opt:find('^%-%-[a-z0-9-]+$') then
      name  = opt:match('^%-%-([a-z0-9-]+)$'):gsub('-', '_')
      value = true
    end
    if value ~= nil and cyl[name] ~= nil then
      local t = type(cyl[name])
      if t == 'boolean' or t == 'string' then
        cyl[name] = value
      end
    end
  end
end


local function error_handler(err)
  return debug.traceback(tostring(err), 2)
end

local function print_test_name(name)
  local io_write = io.write
  for _, descname in ipairs(names) do
    io_write(colors.magenta, descname, colors.reset, ' | ')
  end
  io_write(colors.bright, name, colors.reset)
end

local function print_error_line(err)
  local info = debug.getinfo(3)
  local io_write = io.write
  io_write(' (', colors.blue, info.short_src, colors.reset,
    ':', colors.bright, info.currentline, colors.reset)
  if err and cyl.show_traceback then
    local fnsrc = info.short_src .. ':' .. info.currentline
    for cap1, cap2 in err:gmatch('\t[^\n:]+:(%d+): in function <([^>]+)>\n') do
      if cap2 == fnsrc then
        io_write('/', colors.bright, cap1, colors.reset)
        break
      end
    end
  end
  io_write(')')
end


---Group related tests under a named block.
---@param name string
---@param func function
function cyl.describe(name, func)
  if level == 0 then
    failures  = 0
    successes = 0
    skipped   = 0
    start     = cyl.seconds()
    if not cyl_start then cyl_start = start end
  end

  level = level + 1
  names[level] = name
  func()
  afters[level]  = nil
  befores[level] = nil
  level = level - 1

  if level == 0 and not cyl.quiet and (successes > 0 or failures > 0) then
    local iw = io.write
    iw(failures == 0 and colors.green or colors.red, '[====] ',
      colors.magenta, name, colors.reset, ' | ',
      colors.green, successes, colors.reset, ' passed / ')
    if skipped  > 0 then iw(colors.yellow, skipped,  colors.reset, ' skipped / ') end
    if failures > 0 then iw(colors.red,    failures, colors.reset, ' failed / ')  end
    iw(colors.bright, string.format('%.6f', cyl.seconds() - start), colors.reset, 's\n')
  end
end

---Define a single test case inside a describe block.
---@param name    string
---@param func    function
---@param enabled boolean|nil  pass `false` to skip
function cyl.it(name, func, enabled)
  -- Filter
  if cyl.filter and cyl.filter ~= '' then
    local fullname = table.concat(names, ' | ') .. ' | ' .. name
    if not fullname:match(cyl.filter) then return end
  end

  local iw = io.write

  -- Skip
  if enabled == false then
    if not cyl.quiet then
      iw(colors.yellow, '[SKIP] ', colors.reset)
      print_test_name(name)
      iw('\n')
    else
      local dot = (cyl.utf8term and color_codes.yellow ~= '') and QUIET_DOT or ' o '
      iw(colors.yellow, dot, colors.reset)
    end
    skipped       = skipped + 1
    total_skipped = total_skipped + 1
    return
  end

  -- Before hooks
  for _, levelbefores in pairs(befores) do
    for _, fn in ipairs(levelbefores) do fn(name) end
  end

  -- Run
  local success, err
  if cyl.show_traceback then
    success, err = xpcall(func, error_handler)
  else
    success, err = pcall(func)
    if not success and err then err = tostring(err) end
  end

  -- Stats
  if success then
    successes       = successes + 1
    total_successes = total_successes + 1
  else
    failures       = failures + 1
    total_failures = total_failures + 1
  end

  -- Output
  if not cyl.quiet then
    iw(success and colors.green or colors.red,
      success and '[PASS] ' or '[FAIL] ', colors.reset)
    print_test_name(name)
    if not success then print_error_line(err) end
    iw('\n')
  else
    if success then
      local dot = (cyl.utf8term and color_codes.green ~= '') and QUIET_DOT or ' o '
      iw(colors.green, dot, colors.reset)
    else
      iw(last_succeeded and '\n' or '', colors.red, '[FAIL] ', colors.reset)
      print_test_name(name)
      print_error_line(err)
      iw('\n')
    end
  end

  -- Error detail
  if err and cyl.show_error then
    if color_codes.blue ~= '' then
      local ef, el, em, rest = err:match('^([^:\n]+):(%d+): ([^\n]+)(.*)')
      if ef and el and em and rest then
        iw(colors.blue, ef, colors.reset, ':', colors.bright, el, colors.reset, ': ')
        iw(em:match('^%w([^:]*)$') and (colors.red .. em .. colors.reset) or em)
        err = rest
      end
    end
    iw(err, '\n\n')
  end
  io.flush()

  if not success and cyl.stop_on_fail then
    if cyl.quiet then iw('\n') end
    io.flush()
    cyl.exit()
  end

  -- After hooks
  for _, levelafters in pairs(afters) do
    for _, fn in ipairs(levelafters) do fn(name) end
  end

  last_succeeded = success
end

---Register a function to run before each `it` in the current `describe`.
---@param func function
function cyl.before(func)
  if not befores[level] then befores[level] = {} end
  table.insert(befores[level], func)
end

---Register a function to run after each `it` in the current `describe`.
---@param func function
function cyl.after(func)
  if not afters[level] then afters[level] = {} end
  table.insert(afters[level], func)
end

function cyl.cleanbefores(func)
  local lb = befores[level]
  if not lb then return end
  for i, fn in ipairs(lb) do
    if fn == func then table.remove(lb, i); return end
  end
end

function cyl.cleanafter(func)
  local la = afters[level]
  if not la then return end
  for i, fn in ipairs(la) do
    if fn == func then table.remove(la, i); return end
  end
end

---Print a final summary line.
function cyl.report()
  local now     = cyl.seconds()
  local elapsed = now - (cyl_start or now)
  io.write(
    colors.green,  total_successes, colors.reset, ' passed / ',
    colors.yellow, total_skipped,   colors.reset, ' skipped / ',
    colors.red,    total_failures,  colors.reset, ' failed / ',
    colors.bright, string.format('%.6f', elapsed), colors.reset, 's\n'
  )
  io.flush()
end

---Exit the process with code 0 (all pass) or 1 (any failure).
function cyl.exit()
  collectgarbage()
  exit_with_code(total_failures == 0 and 0 or 1)
end

local expect = {}
cyl.expect = expect


---Return a human-readable string for any value.
---@param v any
---@return string
function expect.tohstring(v)
  local s = tostring(v)
  if s:find('[^ -~\n\t]') then
    return '"' .. s:gsub('.', function(c)
      return string.format('\\x%02X', c:byte())
    end) .. '"'
  end
  return s
end

local function rawtostring(v)
  local mt = getmetatable(v)
  if mt then setmetatable(v, nil) end
  local s = tostring(v)
  if mt then setmetatable(v, mt) end
  return s
end

local function key_suffix(k)
  if type(k) == 'string' then
    if k:find('^[a-zA-Z_][a-zA-Z0-9_]*$') then return '.' .. k end
    if k:find('[^ -~\n\t]') then
      return '["' .. k:gsub('.', function(c)
        return string.format('\\x%02X', c:byte())
      end) .. '"]'
    end
    return '["' .. k .. '"]'
  end
  return string.format('[%s]', rawtostring(k))
end


---Deep structural equality check (recursive over tables).
---@param t1 any
---@param t2 any
---@param name string|nil path prefix for error messages
---@return boolean, string|nil
function expect.strict_eq(t1, t2, name)
  if rawequal(t1, t2) then return true end
  name = name or 'value'
  local t1t, t2t = type(t1), type(t2)
  if t1t ~= t2t then
    return false, string.format(
      "type mismatch for %s\n  expected: %s\n  got:      %s", name, t2t, t1t)
  end
  if t1t == 'table' then
    if getmetatable(t1) ~= getmetatable(t2) then
      return false, string.format("metatable mismatch for %s", name)
    end
    for k, v1 in pairs(t1) do
      local ok, err = expect.strict_eq(v1, t2[k], name .. key_suffix(k))
      if not ok then return false, err end
    end
    for k, v2 in pairs(t2) do
      local ok, err = expect.strict_eq(v2, t1[k], name .. key_suffix(k))
      if not ok then return false, err end
    end
    return true
  end
  return false, string.format(
    "not equal for %s\n  expected: %s\n  got:      %s",
    name, expect.tohstring(t2), expect.tohstring(t1))
end


---Assert that calling `func` raises an error.
---Optionally assert the error message contains `expected`.
---@param func function
---@param expected string|nil
function expect.fail(func, expected)
  local ok, err = pcall(func)
  if ok then
    error('expected function to raise an error, but it succeeded', 2)
  elseif expected then
    local msg = tostring(err)
    if msg ~= expected and not msg:find(expected, 1, true) then
      error(string.format(
        'expected error containing:\n  %s\ngot:\n  %s', expected, msg), 2)
    end
  end
end

---Assert that calling `func` does NOT raise an error.
---@param func function
function expect.not_fail(func)
  local ok, err = pcall(func)
  if not ok then
    error('expected function to succeed, got error:\n' ..
      expect.tohstring(err), 2)
  end
end

---Assert that `v` is not nil.
---@param v any
function expect.exist(v)
  if v == nil then
    error('expected a non-nil value, got nil', 2)
  end
end

---Assert that `v` is nil.
---@param v any
function expect.not_exist(v)
  if v ~= nil then
    error('expected nil, got:\n  ' .. expect.tohstring(v), 2)
  end
end

---Assert that `v` is truthy (not nil and not false).
---@param v any
function expect.truthy(v)
  if not v then
    error('expected a truthy value, got:\n  ' .. expect.tohstring(v), 2)
  end
end

---Assert that `v` is falsy (nil or false).
---@param v any
function expect.falsy(v)
  if v then
    error('expected a falsy value, got:\n  ' .. expect.tohstring(v), 2)
  end
end

---Assert deep equality between two values.
---@param v1 any
---@param v2 any
function expect.equal(v1, v2)
  local ok, err = expect.strict_eq(v1, v2)
  if not ok then error(err, 2) end
end

---Assert that two values are NOT deeply equal.
---@param v1 any
---@param v2 any
function expect.not_equal(v1, v2)
  if expect.strict_eq(v1, v2) then
    error('expected values to differ, but both are:\n  ' ..
      expect.tohstring(v1), 2)
  end
end


---Assert that `v` is of the given Lua type string.
---@param v    any
---@param expected_type string  e.g. "number", "string", "table", "boolean"
function expect.type(v, expected_type)
  local got = type(v)
  if got ~= expected_type then
    error(string.format(
      'expected type %q, got %q\n  value: %s',
      expected_type, got, expect.tohstring(v)), 2)
  end
end


---Assert that string `s` matches the Lua pattern `pattern`.
---@param s       string
---@param pattern string  Lua pattern (not a plain substring)
function expect.matches(s, pattern)
  if type(s) ~= 'string' then
    error('expect.matches: first argument must be a string, got ' .. type(s), 2)
  end
  if not s:find(pattern) then
    error(string.format(
      'expected string to match pattern:\n  pattern: %s\n  got:     %s',
      pattern, expect.tohstring(s)), 2)
  end
end

---Assert that string `s` does NOT match the Lua pattern `pattern`.
---@param s       string
---@param pattern string
function expect.not_matches(s, pattern)
  if type(s) ~= 'string' then
    error('expect.not_matches: first argument must be a string, got ' .. type(s), 2)
  end
  if s:find(pattern) then
    error(string.format(
      'expected string NOT to match pattern:\n  pattern: %s\n  got:     %s',
      pattern, expect.tohstring(s)), 2)
  end
end


---Assert that two numbers are within `delta` of each other.
---Useful for floating-point comparisons.
---@param a     number
---@param b     number
---@param delta number  allowed absolute difference (default 1e-9)
function expect.near(a, b, delta)
  delta = delta or 1e-9
  if type(a) ~= 'number' or type(b) ~= 'number' then
    error('expect.near: both arguments must be numbers', 2)
  end
  if math.abs(a - b) > delta then
    error(string.format(
      'expected %s ≈ %s (within %s)\n  difference: %s',
      a, b, delta, math.abs(a - b)), 2)
  end
end

-- ── NEW: table / string contains ─────────────────────────────────────────────

---Assert that table `t` contains value `v` (linear search by equality).
---Also works for substrings: if `t` is a string, checks plain substring.
---@param t any  table or string
---@param v any
function expect.contains(t, v)
  if type(t) == 'string' then
    if not t:find(tostring(v), 1, true) then
      error(string.format(
        'expected string to contain:\n  %s\ngot:\n  %s',
        expect.tohstring(v), expect.tohstring(t)), 2)
    end
    return
  end
  if type(t) ~= 'table' then
    error('expect.contains: first argument must be a table or string', 2)
  end
  for _, item in ipairs(t) do
    if rawequal(item, v) then return end
  end
  error(string.format(
    'expected table to contain:\n  %s', expect.tohstring(v)), 2)
end

---Assert that table `t` does NOT contain value `v`.
---@param t table
---@param v any
function expect.not_contains(t, v)
  if type(t) ~= 'table' then
    error('expect.not_contains: first argument must be a table', 2)
  end
  for _, item in ipairs(t) do
    if rawequal(item, v) then
      error(string.format(
        'expected table NOT to contain:\n  %s', expect.tohstring(v)), 2)
    end
  end
end

-- ── NEW: length assertion ─────────────────────────────────────────────────────

---Assert that `#v == n`.
---@param v any  table or string
---@param n number
function expect.length(v, n)
  local actual = #v
  if actual ~= n then
    error(string.format(
      'expected length %d, got %d', n, actual), 2)
  end
end

-- ────────────────────────────────────────────────────────────────────────────
-- Module export
-- ────────────────────────────────────────────────────────────────────────────

return cyl

--[[
LICENSE - PUBLIC DOMAIN (Unlicense)

This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or distribute
this software, for any purpose, commercial or non-commercial, and by any means.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
For more information: https://unlicense.org
]]