local cyl = require('checkyour')
local expect = cyl.expect
local skipfail = os.getenv('CYL_TEST_SKIP_FAIL') == true

local function testExample()
    expect.fail(function () error("test failure") end, "Test failure")
end

testExample()