--[[

CHECK YOUR LUA
Minimal Lua testing framework.
Nick Stambaugh - nickstambaugh@proton.me
https://github.com/sieep-coding/Check-Your-Lua
https://nickstambaugh.vercel.app
See bottom for license.
]]

local log = {}
function log.info(m)
    print('[INFO] ' .. m)
end

function log.error(m)
    print('[ERROR] ' .. m)
end

local quiet_o_char = string.char(226, 151, 143)
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
local results = { passed = 0, failed = 0, skipped = 0 }

local cyl_start = os.clock()

local function reportResults()
    local colors_reset = color_codes.reset
    io.write(
        color_codes.blue, "Results: ",
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
     --- Whether the error description of a test failure should be shown. True by default.
    show_error = getboolenv('CYL_SHOW_ERROR', true),
    --- Whether test suite should exit on first test failure. False by default.
    stop_on_fail = getboolenv('CYL_STOP_ON_FAIL', false),
    --- Whether we can print UTF-8 characters to the terminal. True by default when supported.
    utf8term = getboolenv('CYL_UTF8TERM', is_utf8term()),
    --- A string with a lua pattern to filter tests. Nil by default.
    filter = os.getenv('LESTER_FILTER') or '',
    --- Function to retrieve time in seconds with milliseconds precision, `os.clock` by default.
    seconds = os.clock,
}

local colors = setmetatable({}, {
    __index = function(_, key)
        return checkyourlua.color and color_codes[key] or ''
    end
})

checkyourlua.color = colors

function checkyourlua.parseargs(arg)
    for _, opt in ipairs(arg or _G.arg) do
        local name, value
        if opt:find('^%-%-filter') then
            name = 'filter'
            value = opt:match('^%-%-filter%=(.*)$')
        elseif opt:find('^%-%-no%-[a-z0-9-]+$') then
            name = opt:match('^%-%-no%-([a-z0-9-]+)$'):gsub('-', '_')
            value = false
        elseif opt:find('^%-%-[a-z0-9-]+$') then
            name = opt:match('^%-%-([a-z0-9-]+)$'):gsub('-', '_')
            value = true
        end
        if value ~= nil and checkyourlua[name] ~= nil and (type(checkyourlua[name]) == "boolean" or type(checkyourlua[name]) == "string") then
            checkyourlua[name] = value
        end
    end
end

function checkyourlua.describe(name, func)
    --Get a start time
    if level == 0 then
        failures = 0
        successes = 0
        skipped = 0
        start = checkyourlua.seconds()
        if not cyl_start then
            cyl_start = start
        end
    end
    --Setup block variable
    level = level + 1
    names[level] = name
    --run it
    func()
    afters[level] = nil
    befores[level] = nil
    level = level - 1
    -- Pretty print statistics for top level describe block.
    if level == 0 and not checkyourlua.quiet and (successes > 0 or failures > 0) then
        local io_write = io.write
        local colors_reset, colors_green = colors.reset, colors.green
        io_write(failures == 0 and colors_green or colors.red, '[====] ',
            colors.magenta, name, colors_reset, ' | ',
            colors_green, successes, colors_reset, ' successes / ')
        if skipped > 0 then
            io_write(colors.yellow, skipped, colors_reset, ' skipped / ')
        end
        if failures > 0 then
            io_write(colors.red, failures, colors_reset, ' failures / ')
        end
        io_write(colors.bright, string.format('%.6f', checkyourlua.seconds() - start), colors_reset, ' seconds\n')
    end
end

--print error line
local function error_line(err)
    local info = debug.getinfo(3)
    local io_write = io.write
    local colors_reset = colors.reset
    local short_src, currentline = info.short_src, info.currentline
    io_write(' (', colors.blue, short_src, colors_reset,
        ':', colors.bright, currentline, colors_reset)
    if err and checkyourlua.show_traceback then
        local fnsrc = short_src .. ':' .. currentline
        for cap1, cap2 in err:gmatch('\t[^\n:]+:(%d+): in function <([^>]+)>\n') do
            if cap2 == fnsrc then
                io_write('/', colors.bright, cap1, colors_reset)
                break
            end
        end
    end
    io_write(')')
end

--print test name
local function testname(name)
    local io_write = io.write
    local colors_reset = colors.reset
    for _, descname in ipairs(names) do
        io_write(colors.magenta, descname, colors_reset, ' | ')
    end
    io_write(colors.bright, name, colors_reset)
end

function checkyourlua.it(name, func, enabled)
    -- Skip the test silently if it does not match the filter.
    if checkyourlua.filter then
        local fullname = table.concat(names, ' | ') .. ' | ' .. name
        if not fullname:match(checkyourlua.filter) then
            return
        end
    end
    local io_write = io.write
    local colors_reset = colors.reset
    -- Skip the test if it's disabled, while displaying a message
    if enabled == false then
        if not checkyourlua.quiet then
            io_write(colors.yellow, '[SKIP] ', colors_reset)
            testname(name)
            io_write('\n')
        else -- Show just a character hinting that the test was skipped.
            local o = (checkyourlua.utf8term and checkyourlua.color) and quiet_o_char or 'o'
            io_write(colors.yellow, o, colors_reset)
        end
        skipped = skipped + 1
        total_skipped = total_skipped + 1
        return
    end
    -- Execute before handlers.
    for _, levelbefores in pairs(befores) do
        for _, beforefn in ipairs(levelbefores) do
            beforefn(name)
        end
    end
    -- Run the test, capturing errors if any.
    local success, err
    if checkyourlua.show_traceback then
        success, err = xpcall(func, error_handler)
    else
        success, err = pcall(func)
        if not success and err then
            err = tostring(err)
        end
    end
    -- Count successes and failures.
    if success then
        successes = successes + 1
        total_successes = total_successes + 1
    else
        failures = failures + 1
        total_failures = total_failures + 1
    end
    -- Print the test run.
    if not checkyourlua.quiet then -- Show test status and complete test name.
        if success then
            io_write(colors.green, '[PASS] ', colors_reset)
        else
            io_write(colors.red, '[FAIL] ', colors_reset)
        end
        testname(name)
        if not success then
            error_line(err)
        end
        io_write('\n')
    else
        if success then -- Show just a character hinting that the test succeeded.
            local o = (checkyourlua.utf8term and checkyourlua.color) and quiet_o_char or 'o'
            io_write(colors.green, o, colors_reset)
        else -- Show complete test name on failure.
            io_write(last_succeeded and '\n' or '',
                colors.red, '[FAIL] ', colors_reset)
            testname(name)
            error_line(err)
            io_write('\n')
        end
    end
    -- Print error message, colorizing its output if possible.
    if err and checkyourlua.show_error then
        if checkyourlua.color then
            local errfile, errline, errmsg, rest = err:match('^([^:\n]+):(%d+): ([^\n]+)(.*)')
            if errfile and errline and errmsg and rest then
                io_write(colors.blue, errfile, colors_reset,
                    ':', colors.bright, errline, colors_reset, ': ')
                if errmsg:match('^%w([^:]*)$') then
                    io_write(colors.red, errmsg, colors_reset)
                else
                    io_write(errmsg)
                end
                err = rest
            end
        end
        io_write(err, '\n\n')
    end
    io.flush()
    -- Stop on failure.
    if not success and checkyourlua.stop_on_fail then
        if checkyourlua.quiet then
            io_write('\n')
            io.flush()
        end
        checkyourlua.exit()
    end
    -- Execute after handlers.
    for _, levelafters in pairs(afters) do
        for _, afterfn in ipairs(levelafters) do
            afterfn(name)
        end
    end
    last_succeeded = success
end

--- Set a function that is called before every test inside a describe block.
-- A single string containing the name of the test about to be run will be passed to `func`.
function checkyourlua.before(func)
    local levelbefores = befores[level]
    if not levelbefores then
        levelbefores = {}
        befores[level] = levelbefores
    end
    levelbefores[#levelbefores + 1] = func
end

--- Set a function that is called after every test inside a describe block.
-- A single string containing the name of the test that was finished will be passed to `func`.
-- The function is executed independently if the test passed or failed.
function checkyourlua.after(func)
    local levelafters = afters[level]
    if not levelafters then
        levelafters = {}
        afters[level] = levelafters
    end
    levelafters[#levelafters + 1] = func
end

function checkyourlua.report()
    local now = checkyourlua.seconds()
    local colors_reset = colors.reset
    io.write(
        colors.green, total_successes, colors_reset, ' successes / ',
        colors.yellow, total_skipped, colors_reset, ' skipped / ',
        colors.red, total_failures, colors_reset, ' failures / ',
        colors.bright, string.format('%.6f', now - (cyl_start or now)), colors_reset, ' seconds\n'
    )
    io.flush()
    local exit_code = results.failed > 0 and 1 or 0
    exitwithCode(exit_code)
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
    if s:find '[^ -~\n\t]' then
        return '"' .. s:gsub('.', function(c) return string.format('\\x%02X', c:byte()) end) .. '"'
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

--- Check if a function does not fail with a error.
function expect.not_fail(func)
    local ok, err = pcall(func)
    if not ok then
        error('expected function to not fail\ngot error:\n' .. expect.tohstring(err), 2)
    end
end

--- Check if a value is not `nil`.
function expect.exist(v)
    if v == nil then
        error('expected value to exist\ngot:\n' .. expect.tohstring(v), 2)
    end
end

--- Check if a value is `nil`.
function expect.not_exist(v)
    if v ~= nil then
        error('expected value to not exist\ngot:\n' .. expect.tohstring(v), 2)
    end
end

--- Check if an expression is evaluates to `true`.
function expect.truthy(v)
    if not v then
        error('expected expression to be true\ngot:\n' .. expect.tohstring(v), 2)
    end
end

--- Check if an expression is evaluates to `false`.
function expect.falsy(v)
    if v then
        error('expected expression to be false\ngot:\n' .. expect.tohstring(v), 2)
    end
end

--- Returns raw tostring result for a value.
local function rawtostring(v)
    local mt = getmetatable(v)
    if mt then
        setmetatable(v, nil)
    end
    local s = tostring(v)
    if mt then
        setmetatable(v, mt)
    end
    return s
end

-- Returns key suffix for a string_eq table key.
local function strict_eq_key_suffix(k)
    if type(k) == 'string' then
        if k:find('^[a-zA-Z_][a-zA-Z0-9]*$') then -- string is a lua field
            return '.' .. k
        elseif k:find '[^ -~\n\t]' then       -- string contains non printable ASCII
            return '["' .. k:gsub('.', function(c) return string.format('\\x%02X', c:byte()) end) .. '"]'
        else
            return '["' .. k .. '"]'
        end
    else
        return string.format('[%s]', rawtostring(k))
    end
end

--- Compare if two values are equal, considering nested tables.
function expect.strict_eq(t1, t2, name)
    if rawequal(t1, t2) then return true end
    name = name or 'value'
    local t1type, t2type = type(t1), type(t2)
    if t1type ~= t2type then
        return false, string.format("expected types to be equal for %s\nfirst: %s\nsecond: %s",
            name, t1type, t2type)
    end
    if t1type == 'table' then
        if getmetatable(t1) ~= getmetatable(t2) then
            return false, string.format("expected metatables to be equal for %s\nfirst: %s\nsecond: %s",
                name, expect.tohstring(t1), expect.tohstring(t2))
        end
        for k, v1 in pairs(t1) do
            local ok, err = expect.strict_eq(v1, t2[k], name .. strict_eq_key_suffix(k))
            if not ok then
                return false, err
            end
        end
        for k, v2 in pairs(t2) do
            local ok, err = expect.strict_eq(v2, t1[k], name .. strict_eq_key_suffix(k))
            if not ok then
                return false, err
            end
        end
    elseif t1 ~= t2 then
        return false, string.format("expected values to be equal for %s\nfirst:\n%s\nsecond:\n%s",
            name, expect.tohstring(t1), expect.tohstring(t2))
    end
    return true
end

--- Check if two values are equal.
function expect.equal(v1, v2)
    local ok, err = expect.strict_eq(v1, v2)
    if not ok then
        error(err, 2)
    end
end

--- Check if two values are not equal.
function expect.not_equal(v1, v2)
    if expect.strict_eq(v1, v2) then
        local v1s, v2s = expect.tohstring(v1), expect.tohstring(v2)
        error('expected values to be not equal\nfirst value:\n' .. v1s .. '\nsecond value:\n' .. v2s, 2)
    end
end

return checkyourlua

--[[

--LICENSE--

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
