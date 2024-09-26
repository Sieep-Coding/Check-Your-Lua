-- Require the checkyour (cyl) module for testing
local cyl = require('checkyour')
local describe, it, expect = cyl.describe, cyl.it, cyl.expect

-- Environment variable to skip failure-inducing tests
local skipfail = os.getenv('CYL_TEST_SKIP_FAIL') == 'true'

-- Parse any arguments passed for test running (if applicable in your framework)
cyl.parse_args()

-- Begin test suite description
describe("cyl", function()
  
  -- A simple flag to demonstrate before/after hooks
  local flag = false
  
  -- Before hook to set up the environment before each test
  cyl.before(function()
    flag = true
  end)
  
  -- After hook to clean up after each test
  cyl.after(function()
    flag = false
  end)

  -- Assertions outside of test functions to ensure setup and teardown
  assert(not flag)

  -- Test example with before/after hooks
  it("before and after", function()
    assert(flag)
  end)

  assert(not flag)

  -- Simple assert test
  it("assert", function()
    assert(true)
  end, true)

  -- Example of a skipped test
  it("skip", function()
    assert(false)
  end, false)

  -- Demonstrating various 'expect' features
  it("expect", function()
    expect.fail(function() error() end)
    expect.fail(function() error'an error' end, 'an error')
    expect.fail(function() error'got my error' end, 'my error')
    expect.not_fail(function() end)
    expect.truthy(true)
    expect.falsy(false)
    expect.exist(1)
    expect.exist(false)
    expect.exist(true)
    expect.exist('')
    expect.not_exist(nil)
    expect.equal(1, 1)
    expect.equal(false, false)
    expect.equal(nil, nil)
    expect.equal(true, true)
    expect.equal('', '')
    expect.equal('asd', 'asd')
    expect.equal('\x01\x02', '\x01\x02')
    expect.equal({a=1}, {a=1})
    expect.not_equal('asd', 'asf')
    expect.not_equal('\x01\x02', '\x01\x03')
    expect.not_equal(1,2)
    expect.not_equal(true,false)
    expect.not_equal(nil,false)
    expect.not_equal({a=2},{a=1})
  end)

  -- Describing tests for failures
  describe("fails", function()
    if not skipfail then
      -- Various test cases to demonstrate how failures are handled
      it("empty error", function()
        error()
      end)
      it("string error", function()
        error 'an error'
      end)
      it("string error with lines", function()
        error '@somewhere:1: an error'
      end)
      it("table error", function()
        error {}
      end)

      it("empty assert", function()
        assert()
      end)
      it("assert false", function()
        assert(false)
      end)
      it("assert false with message", function()
        assert(false, 'my message')
      end)

      it("fail", function()
        expect.fail(function() end)
      end)
      it("fail message", function()
        expect.fail(function() error('error1') end, 'error2')
      end)
      it("not fail", function()
        expect.not_fail(function() error() end)
      end)

      it("exist", function()
        expect.exist(nil)
      end)
      it("not exist", function()
        expect.not_exist(true)
      end)

      it("truthy", function()
        expect.truthy()
      end)
      it("falsy", function()
        expect.falsy(1)
      end)

      it("equal", function()
        expect.equal(1, 2)
      end)
      it("not equal", function()
        expect.not_equal(1, 1)
      end)

      it("equal (table)", function()
        expect.equal({a=1}, {a=2})
      end)

      it("not equal (table)", function()
        expect.not_equal({a=1}, {a=1})
      end)

      it("equal (binary)", function()
        expect.equal('\x01\x02', '\x01\x03')
      end)

      it("not equal (binary)", function()
        expect.not_equal('\x01\x02', '\x01\x02')
      end)
    end
  end)
end)

-- Report results after all tests
cyl.report()

-- If skipfail is true, exit after reporting
if skipfail then
  cyl.exit()
end