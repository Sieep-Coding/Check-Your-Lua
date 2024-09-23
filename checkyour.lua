--[[

CHECK YOUR LUA
Minimal Lua testing framework.
Nick Stambaugh - nickstambaugh@proton.me
https://github.com/sieep-coding/Check-Your-Lua
https://nickstambaugh.vercel.app

--Licsense--

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>

]]

local log = {}
function log.info(m)
    print('[INFO] '..m)    
end

function log.error(m)
    print('[ERROR] '..m)   
end

log.info('Check Your Lua has started.')

-- Color codes.
local color_codes = {
    reset = string.char(27) .. '[0m',
    bright = string.char(27) .. '[1m',
    red = string.char(27) .. '[31m',
    green = string.char(27) .. '[32m',
    yellow = string.char(27) .. '[33m',
    blue = string.char(27) .. '[34m',
    magenta = string.char(27) .. '[35m',
}

    -- Variables used internally for the CYL state.
local cyl_start = nil
local last_succeeded = false
local level = 0
local successes = 0
local total_successes = 0
local failures = 0
local total_failures = 0
local skipped = 0
local total_skipped = 0
local start = 0
local befores = {}
local afters = {}
local names = {}
local results = {passed=0, failed=0, skipped=0}

local cyl_start = os.clock()

local function reportResults()
    local colors_reset = color_codes.reset
    io.write(
        color_codes.green, "Results: ",
        color_codes.green, results.passed, colors_reset, " passed / ",
        color_codes.red, results.failed, colors_reset, " failed / ",
        color_codes.yellow, results.skipped, colors_reset, " skipped\n"
    )
    io.write(color_codes.bright, string.format("Total Time: %.6f seconds\n", os.clock() - cyl_start), colors_reset)
    io.flush()
end

    -- checks for terminal support for UTF-8
local function is_utf8term()
    local lang = os.getenv('lang')
    return (lang and lang:lower():match('utf%-?8$')) and true or false
end

local function exitwithCode(code)
    os.exit(code)
end

local function error_handler(err)
    return debug.traceback(tostring(err), 2)
end

-- Returns whether a system environment variable is "true".
local function getboolenv(varname, default)
    local val = os.getenv(varname)
    if val == 'true' then
        return true
    elseif val == 'false' then
        return false
    end
    return default
end

--The Check Your Lua Module
local checkyourlua = {
        --- Whether the output should  be colorized. True by default.
        color = getboolenv('CYL_COLOR', true),
        --- Whether lines of passed tests should not be printed. False by default.
        quiet = getboolenv('CYL_QUIET', false),
        --- Whether a traceback must be shown on test failures. True by default.
        show_traceback = getboolenv('CYL_SHOW_TRACEBACK', true),
        --- Whether we can print UTF-8 characters to the terminal. True by default when supported.
        utf8term = getboolenv('CYL_UTF8TERM', is_utf8term()),
        --- Function to retrieve time in seconds with milliseconds precision, `os.clock` by default.
        seconds = os.clock,
    }

local colors = setmetatable({}, {__index = function (_, key)
     return checkyourlua.color and color_codes[key] or ''
end})

checkyourlua.color = colors

function checkyourlua.report()
    local now = checkyourlua.seconds()
    local colors_reset = colors.reset
    io.write (
    colors.green, total_successes, colors_reset, 'successes / ',
    colors.yellow, total_skipped, colors_reset, 'skipped / ',
    colors.red, total_failures, colors_reset, 'failures / ',
    colors.bright, string.format('%.6f', now - (cyl_start or now)), colors_reset, ' seconds\n'
)
io.flush()
return total_failures == 0
end


function ExitCYL()
    collectgarbage()
    collectgarbage()
    os.exit(total_failures == 0, true)
end

-- local quiet_o_char = string.char(226, 151, 143)

local expect = {}
checkyourlua.expect = expect


function expect.tohstring(v)
    local s = tostring(v)
    if s:find'[^ -~\n\t]' then
      return '"'..s:gsub('.', function(c) return string.format('\\x%02X', c:byte()) end)..'"'
    end
    return s
  end

--check if function fails
function expect.fail(func, expected)
    local ok, err = pcall(func)
    if ok then
        log.error("Expected function to fail, but it succeeded.")
        results.failed = results.failed + 1
    elseif expected ~= nil and not (expected == err or string.find(tostring(err), expected, 1, true)) then
        log.error(string.format("Expected: %s, Got: %s", expected, tostring(err)))
        results.failed = results.failed + 1
    else
        results.passed = results.passed + 1
    end
    return true
end

-- Example test
local function testExample()
    expect.fail(function() error("Test failure!") end, "Test failure!")
    expect.fail(function() error("Test failure!") end, "Test failure!")
    expect.fail(function() error("Test failure!") end, "Test failure!")
    expect.fail(function() error("Test failure!") end, "Test failure!")
    expect.fail(function() error("Test failure!") end, "Test failure!")
    expect.fail(function() error("Test failure!") end, "Test failure!")
    expect.fail(function() error("Test failure!") end, "Test failure!")
end

-- Run tests
testExample()
reportResults()