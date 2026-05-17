--[[
CHECK YOUR LUA - Minimal Lua Testing Framework
Nick Stambaugh - nickstambaugh@proton.me
https://github.com/sieep-coding/Check-Your-Lua
https://nickstambaugh.dev

Public Domain License - See bottom for details.
]]

local log = {}
function log.info(m)
    print('[INFO] ' .. m)
end

function log.error(m)
    print('[ERROR] ' .. m)
end

-- UTF-8 quiet character for minimal output mode
local quiet_o_char = string.char(226, 151, 143)

-- ANSI color codes for terminal output
local color_codes = {
    reset = string.char(27) .. '[0m',
    bright = string.char(27) .. '[1m',
    red = string.char(27) .. '[31m',
    green = string.char(27) .. '[32m',
    yellow = string.char(27) .. '[33m',
    blue = string.char(27) .. '[34m',
    magenta = string.char(27) .. '[35m',
}

-- Internal state management
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

-- Platform detection utilities
local function is_utf8term()
    local lang = os.getenv('LANG') or os.getenv('LC_ALL') or ''
    return lang:lower():match('utf%-?8$') ~= nil
end

local function is_windows()
    local os_name = os.getenv('OS')
    if os_name and os_name:lower():match('windows') then
        return true
    end
    local handle = io.popen('uname -s 2>/dev/null')
    if not handle then return false end
    local result = handle:read('*a')
    handle:close()
    return result and result:lower():match('windows') ~= nil
end

-- Exit handler for cross-platform compatibility
local function exitwithCode(code)
    if is_windows() then
        os.exit(code, true)
    else
        os.exit(code)
    end
end

-- Error handler with stack trace
local function error_handler(err)
    return debug.traceback(tostring(err), 2)
end

-- Parse boolean environment variables with defaults
local function getboolenv(varname, default)
    local val = os.getenv(varname)
    if val == 'true' then return true
    elseif val == 'false' then return false
    end
    return default
end

-- Main CYL module
local checkyourlua = {
    color = getboolenv('CYL_COLOR', true),
    quiet = getboolenv('CYL_QUIET', false),
    show_traceback = getboolenv('CYL_SHOW_TRACEBACK', true),
    show_error = getboolenv('CYL_SHOW_ERROR', true),
    stop_on_fail = getboolenv('CYL_STOP_ON_FAIL', false),
    utf8term = getboolenv('CYL_UTF8TERM', is_utf8term()),
    filter = os.getenv('CYL_FILTER') or '',
    seconds = os.clock,
}

-- Color wrapper with conditional output
local colors = setmetatable({}, {
    __index = function(_, key)
        return checkyourlua.color and color_codes[key] or ''
    end
})

checkyourlua.color = colors

-- Parse command-line arguments
function checkyourlua.parseargs(arg)
    arg = arg or _G.arg
    for _, opt in ipairs(arg) do
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
        if value ~= nil and checkyourlua[name] ~= nil then
            local t = type(checkyourlua[name])
            if t == 'boolean' or t == 'string' then
                checkyourlua[name] = value
            end
        end
    end
end

-- Describe block for organizing tests
function checkyourlua.describe(name, func)
    if level == 0 then
        failures = 0
        successes = 0
        skipped = 0
        start = checkyourlua.seconds()
        if not cyl_start then cyl_start = start end
    end
    
    level = level + 1
    names[level] = name
    func()
    afters[level] = nil
    befores[level] = nil
    level = level - 1
    
    -- Print summary for top-level describe blocks
    if level == 0 and not checkyourlua.quiet and (successes > 0 or failures > 0) then
        local io_write = io.write
        io_write(failures == 0 and colors.green or colors.red, '[====] ',
            colors.magenta, name, colors.reset, ' | ',
            colors.green, successes, colors.reset, ' passed / ')
        if skipped > 0 then
            io_write(colors.yellow, skipped, colors.reset, ' skipped / ')
        end
        if failures > 0 then
            io_write(colors.red, failures, colors.reset, ' failed / ')
        end
        io_write(colors.bright, string.format('%.6f', checkyourlua.seconds() - start), 
            colors.reset, 's\n')
    end
end

-- Print error location information
local function error_line(err)
    local info = debug.getinfo(3)
    local io_write = io.write
    local short_src, currentline = info.short_src, info.currentline
    io_write(' (', colors.blue, short_src, colors.reset,
        ':', colors.bright, currentline, colors.reset)
    if err and checkyourlua.show_traceback then
        local fnsrc = short_src .. ':' .. currentline
        for cap1, cap2 in err:gmatch('\t[^\n:]+:(%d+): in function <([^>]+)>\n') do
            if cap2 == fnsrc then
                io_write('/', colors.bright, cap1, colors.reset)
                break
            end
        end
    end
    io_write(')')
end

-- Print formatted test name
local function testname(name)
    local io_write = io.write
    for _, descname in ipairs(names) do
        io_write(colors.magenta, descname, colors.reset, ' | ')
    end
    io_write(colors.bright, name, colors.reset)
end

-- Individual test case
function checkyourlua.it(name, func, enabled)
    -- Apply filter if specified
    if checkyourlua.filter and checkyourlua.filter ~= '' then
        local fullname = table.concat(names, ' | ') .. ' | ' .. name
        if not fullname:match(checkyourlua.filter) then return end
    end
    
    local io_write = io.write
    
    -- Handle skipped tests
    if enabled == false then
        if not checkyourlua.quiet then
            io_write(colors.yellow, '[SKIP] ', colors.reset)
            testname(name)
            io_write('\n')
        else
            local o = (checkyourlua.utf8term and checkyourlua.color) and quiet_o_char or ' o '
            io_write(colors.yellow, o, colors.reset)
        end
        skipped = skipped + 1
        total_skipped = total_skipped + 1
        return
    end
    
    -- Execute before hooks
    for _, levelbefores in pairs(befores) do
        for _, beforefn in ipairs(levelbefores) do
            beforefn(name)
        end
    end
    
    -- Run test with error handling
    local success, err
    if checkyourlua.show_traceback then
        success, err = xpcall(func, error_handler)
    else
        success, err = pcall(func)
        if not success and err then err = tostring(err) end
    end
    
    -- Update statistics
    if success then
        successes = successes + 1
        total_successes = total_successes + 1
    else
        failures = failures + 1
        total_failures = total_failures + 1
    end
    
    -- Print test result
    if not checkyourlua.quiet then
        io_write(success and colors.green or colors.red,
            success and '[PASS] ' or '[FAIL] ', colors.reset)
        testname(name)
        if not success then error_line(err) end
        io_write('\n')
    else
        if success then
            local o = (checkyourlua.utf8term and checkyourlua.color) and quiet_o_char or ' o '
            io_write(colors.green, o, colors.reset)
        else
            io_write(last_succeeded and '\n' or '',
                colors.red, '[FAIL] ', colors.reset)
            testname(name)
            error_line(err)
            io_write('\n')
        end
    end
    
    -- Print error details
    if err and checkyourlua.show_error then
        if checkyourlua.color then
            local errfile, errline, errmsg, rest = 
                err:match('^([^:\n]+):(%d+): ([^\n]+)(.*)')
            if errfile and errline and errmsg and rest then
                io_write(colors.blue, errfile, colors.reset,
                    ':', colors.bright, errline, colors.reset, ': ')
                if errmsg:match('^%w([^:]*)$') then
                    io_write(colors.red, errmsg, colors.reset)
                else
                    io_write(errmsg)
                end
                err = rest
            end
        end
        io_write(err, '\n\n')
    end
    io.flush()
    
    -- Stop on first failure if configured
    if not success and checkyourlua.stop_on_fail then
        if checkyourlua.quiet then
            io_write('\n')
            io.flush()
        end
        checkyourlua.exit()
    end
    
    -- Execute after hooks
    for _, levelafters in pairs(afters) do
        for _, afterfn in ipairs(levelafters) do
            afterfn(name)
        end
    end
    last_succeeded = success
end

-- Register before hook
function checkyourlua.before(func)
    if not befores[level] then befores[level] = {} end
    table.insert(befores[level], func)
end

-- Register after hook
function checkyourlua.after(func)
    if not afters[level] then afters[level] = {} end
    table.insert(afters[level], func)
end

-- Remove before hook
function checkyourlua.cleanbefores(func)
    local levelbefores = befores[level]
    if not levelbefores then return end
    for i, beforefn in ipairs(levelbefores) do
        if beforefn == func then
            table.remove(levelbefores, i)
            return
        end
    end
end

-- Remove after hook
function checkyourlua.cleanafter(func)
    local levelafters = afters[level]
    if not levelafters then return end
    for i, afterfn in ipairs(levelafters) do
        if afterfn == func then
            table.remove(levelafters, i)
            return
        end
    end
end

-- Print final test report
function checkyourlua.report()
    local now = checkyourlua.seconds()
    local elapsed = now - (cyl_start or now)
    io.write(
        colors.green, total_successes, colors.reset, ' passed / ',
        colors.yellow, total_skipped, colors.reset, ' skipped / ',
        colors.red, total_failures, colors.reset, ' failed / ',
        colors.bright, string.format('%.6f', elapsed), colors.reset, 's\n'
    )
    io.flush()
end

-- Exit with appropriate code
function checkyourlua.exit()
    collectgarbage()
    exitwithCode(total_failures == 0 and 0 or 1)
end

-- Expect assertion library
local expect = {}
checkyourlua.expect = expect

-- Convert value to readable string
function expect.tohstring(v)
    local s = tostring(v)
    if s:find '[^ -~\n\t]' then
        return '"' .. s:gsub('.', function(c) 
            return string.format('\\x%02X', c:byte()) 
        end) .. '"'
    end
    return s
end

-- Get raw tostring without metatable
local function rawtostring(v)
    local mt = getmetatable(v)
    if mt then setmetatable(v, nil) end
    local s = tostring(v)
    if mt then setmetatable(v, mt) end
    return s
end

-- Get key suffix for error messages
local function strict_eq_key_suffix(k)
    if type(k) == 'string' then
        if k:find('^[a-zA-Z_][a-zA-Z0-9_]*$') then
            return '.' .. k
        elseif k:find '[^ -~\n\t]' then
            return '["' .. k:gsub('.', function(c) 
                return string.format('\\x%02X', c:byte()) 
            end) .. '"]'
        else
            return '["' .. k .. '"]'
        end
    else
        return string.format('[%s]', rawtostring(k))
    end
end

-- Check if function fails
function expect.fail(func, expected)
    local ok, err = pcall(func)
    if ok then
        error('expected function to fail, but it succeeded', 2)
    elseif expected and not (expected == err or 
        tostring(err):find(expected, 1, true)) then
        error(string.format('expected error containing: %s\ngot: %s', 
            expected, tostring(err)), 2)
    end
end

-- Check if function doesn't fail
function expect.not_fail(func)
    local ok, err = pcall(func)
    if not ok then
        error('expected function to not fail\ngot error:\n' .. 
            expect.tohstring(err), 2)
    end
end

-- Check if value exists (not nil)
function expect.exist(v)
    if v == nil then
        error('expected value to exist\ngot: nil', 2)
    end
end

-- Check if value doesn't exist (is nil)
function expect.not_exist(v)
    if v ~= nil then
        error('expected value to not exist\ngot:\n' .. expect.tohstring(v), 2)
    end
end

-- Check if value is truthy
function expect.truthy(v)
    if not v then
        error('expected value to be truthy\ngot:\n' .. expect.tohstring(v), 2)
    end
end

-- Check if value is falsy
function expect.falsy(v)
    if v then
        error('expected value to be falsy\ngot:\n' .. expect.tohstring(v), 2)
    end
end

-- Deep equality check for tables
function expect.strict_eq(t1, t2, name)
    if rawequal(t1, t2) then return true end
    name = name or 'value'
    local t1type, t2type = type(t1), type(t2)
    if t1type ~= t2type then
        return false, string.format("expected types to match for %s\nfirst: %s\nsecond: %s",
            name, t1type, t2type)
    end
    if t1type == 'table' then
        if getmetatable(t1) ~= getmetatable(t2) then
            return false, string.format("expected metatables to match for %s", name)
        end
        for k, v1 in pairs(t1) do
            local ok, err = expect.strict_eq(v1, t2[k], 
                name .. strict_eq_key_suffix(k))
            if not ok then return false, err end
        end
        for k, v2 in pairs(t2) do
            local ok, err = expect.strict_eq(v2, t1[k], 
                name .. strict_eq_key_suffix(k))
            if not ok then return false, err end
        end
    elseif t1 ~= t2 then
        return false, string.format(
            "expected values to be equal for %s\nfirst:\n%s\nsecond:\n%s",
            name, expect.tohstring(t1), expect.tohstring(t2))
    end
    return true
end

-- Check if two values are equal
function expect.equal(v1, v2)
    local ok, err = expect.strict_eq(v1, v2)
    if not ok then error(err, 2) end
end

-- Check if two values are not equal
function expect.not_equal(v1, v2)
    if expect.strict_eq(v1, v2) then
        error('expected values to be not equal\nfirst:\n' .. 
            expect.tohstring(v1) .. '\nsecond:\n' .. expect.tohstring(v2), 2)
    end
end

return checkyourlua

--[[
LICENSE - PUBLIC DOMAIN (Unlicense)

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

For more information, please refer to https://unlicense.org
]]