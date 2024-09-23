--[[
CHECK YOUR LUA
Minimal Lua test framework.
CHECK YOUR LUA - v0.0.1 - 22/Sep/2024
Nick Stambaugh - nickstambaugh@proton.me
https://github.com/sieep-coding/check-your-lua
https://nickstambaugh.vercel.app
]]

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

    -- checks for terminal support for UTF-8
local function is_utf8term()
    local lang = os.getenv('lang')
    return (lang and lang:lower():match('utf%-?8$')) and true or false
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
        quiet = getboolenv('LESTER_QUIET', false),
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
        error("expected function to fail", 2)
    elseif expected ~= nil then
        local found = expected == err
        if not found and type(expected) == 'string' then
            found = string.find(tostring(err), expected, 1, true) ~= nil
        end
        if not found then
            error('expected function to fail\nexpected:\n'..tostring(expected)..'\ngot:\n'..tostring(err), 2)
        end
    end
    return true
end