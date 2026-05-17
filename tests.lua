local cyl = require('checkyour')
local describe, it, expect = cyl.describe, cyl.it, cyl.expect
local skipfail = os.getenv('CYL_TEST_SKIP_FAIL') == 'true'

cyl.parseargs()

describe("hooks", function()
  local flag = false
  local order = {}

  cyl.before(function() flag = true; table.insert(order, "before") end)
  cyl.after(function()  flag = false; table.insert(order, "after")  end)

  assert(not flag)

  it("before sets flag", function()
    assert(flag)
  end)

  assert(not flag)

  it("after resets flag between tests", function()
    assert(flag)
    expect.truthy(#order >= 2)
  end)
end)

describe("skip", function()
  it("this test runs", function()
    expect.truthy(true)
  end)

  it("this test is skipped", function()
    assert(false, "should never run")
  end, false)

  it("enabled=true explicitly runs", function()
    expect.truthy(true)
  end, true)
end)

describe("expect.equal and expect.not_equal", function()
  it("compares numbers", function()
    expect.equal(1, 1)
    expect.not_equal(1, 2)
  end)

  it("compares strings", function()
    expect.equal("lua", "lua")
    expect.not_equal("hello", "world")
  end)

  it("compares booleans", function()
    expect.equal(true, true)
    expect.equal(false, false)
    expect.not_equal(true, false)
  end)

  it("deep-compares flat tables", function()
    expect.equal({1, 2, 3}, {1, 2, 3})
    expect.not_equal({1, 2}, {1, 3})
  end)

  it("deep-compares nested tables", function()
    expect.equal({ a = { b = 1 } }, { a = { b = 1 } })
    expect.not_equal({ a = { b = 1 } }, { a = { b = 2 } })
  end)

  it("deep-compares mixed key tables", function()
    expect.equal({ name = "Ada", age = 36 }, { name = "Ada", age = 36 })
  end)
end)

describe("expect.truthy and expect.falsy", function()
  it("truthy values", function()
    expect.truthy(true)
    expect.truthy(1)
    expect.truthy(0)
    expect.truthy("")
    expect.truthy({})
    expect.truthy(1.23)
    expect.truthy("non-empty")
  end)

  it("falsy values", function()
    expect.falsy(false)
    expect.falsy(nil)
  end)
end)

describe("expect.exist and expect.not_exist", function()
  it("exist passes for non-nil", function()
    expect.exist(0)
    expect.exist(false)
    expect.exist("")
    expect.exist({})
    expect.exist(function() end)
  end)

  it("not_exist passes only for nil", function()
    expect.not_exist(nil)
    local t = {}
    expect.not_exist(t.missing_key)
  end)
end)

describe("expect.fail and expect.not_fail", function()
  it("fail catches any error", function()
    expect.fail(function() error("boom") end)
    expect.fail(function() error() end)
  end)

  it("fail matches a substring", function()
    expect.fail(function() error("something went wrong") end, "went wrong")
  end)

  it("not_fail passes for clean functions", function()
    expect.not_fail(function() end)
    expect.not_fail(function() return 42 end)
  end)

  it("fail catches runtime errors", function()
    expect.fail(function()
      local t = nil
      return t.field
    end)
  end)
end)

describe("expect.type", function()
  it("identifies all primitive types", function()
    expect.type(42,           "number")
    expect.type(3.14,         "number")
    expect.type("hello",      "string")
    expect.type(true,         "boolean")
    expect.type(false,        "boolean")
    expect.type(nil,          "nil")
    expect.type({},           "table")
    expect.type(print,        "function")
    expect.type(function()end,"function")
  end)

  it("identifies coroutines as thread", function()
    local co = coroutine.create(function() end)
    expect.type(co, "thread")
  end)
end)

describe("expect.near", function()
  it("passes when values are within default delta", function()
    expect.near(1.0, 1.0)
    expect.near(0.1 + 0.2, 0.3, 1e-9)
  end)

  it("passes with a custom delta", function()
    expect.near(10, 10.5, 1.0)
    expect.near(math.pi, 3.14, 0.01)
  end)

  it("fails when values exceed delta", function()
    expect.fail(function()
      expect.near(1.0, 2.0, 0.5)
    end)
  end)
end)

describe("expect.matches and expect.not_matches", function()
  it("matches a digit pattern", function()
    expect.matches("hello123", "%d+")
  end)

  it("matches start anchor", function()
    expect.matches("Lua 5.5", "^Lua")
  end)

  it("not_matches when pattern absent", function()
    expect.not_matches("hello", "%d+")
  end)

  it("matches capture groups", function()
    expect.matches("2024-05-17", "%d%d%d%d%-%d%d%-%d%d")
  end)

  it("fails when string does not match", function()
    expect.fail(function()
      expect.matches("abc", "%d+")
    end)
  end)
end)

describe("expect.contains and expect.not_contains", function()
  it("finds a value in a sequence table", function()
    expect.contains({1, 2, 3}, 2)
    expect.contains({"a", "b", "c"}, "b")
  end)

  it("not_contains when value is absent", function()
    expect.not_contains({1, 2, 3}, 99)
  end)

  it("finds a substring in a string", function()
    expect.contains("hello world", "world")
    expect.contains("Lua 5.5", "5.5")
  end)

  it("fails when value is missing from table", function()
    expect.fail(function()
      expect.contains({1, 2, 3}, 99)
    end)
  end)
end)

describe("expect.length", function()
  it("checks string length", function()
    expect.length("Lua", 3)
    expect.length("", 0)
    expect.length("Hello, World!", 13)
  end)

  it("checks table sequence length", function()
    expect.length({}, 0)
    expect.length({1, 2, 3}, 3)
    expect.length({"a", "b"}, 2)
  end)

  it("fails on wrong length", function()
    expect.fail(function()
      expect.length("abc", 5)
    end)
  end)
end)

describe("expect.strict_eq", function()
  it("returns true for equal primitives", function()
    local ok = expect.strict_eq(1, 1)
    expect.truthy(ok)
  end)

  it("returns false with message for mismatched types", function()
    local ok, msg = expect.strict_eq(1, "1")
    expect.falsy(ok)
    expect.exist(msg)
    expect.matches(msg, "mismatch")
  end)

  it("returns false with path hint for nested mismatch", function()
    local ok, msg = expect.strict_eq({a = {b = 1}}, {a = {b = 2}})
    expect.falsy(ok)
    expect.matches(msg, "a%.b")
  end)
end)

describe("nested describe blocks", function()
  describe("inner level one", function()
    it("runs inside nested block", function()
      expect.truthy(true)
    end)

    describe("inner level two", function()
      it("runs inside doubly-nested block", function()
        expect.equal(1 + 1, 2)
      end)
    end)
  end)
end)

describe("cleanbefores and cleanafter", function()
  local calls = {}

  local function hook() table.insert(calls, "hook") end

  cyl.before(hook)

  it("hook fires before this test", function()
    expect.truthy(#calls >= 1)
  end)

  cyl.cleanbefores(hook)

  local before_count = #calls

  it("hook is removed; count unchanged after cleanbefores", function()
    expect.equal(#calls, before_count)
  end)
end)

describe("version", function()
  it("cyl.version is a semver string", function()
    expect.type(cyl.version, "string")
    expect.matches(cyl.version, "^%d+%.%d+%.%d+$")
  end)
end)

describe("cyl.seconds", function()
  it("returns a number", function()
    expect.type(cyl.seconds(), "number")
  end)

  it("is monotonically non-decreasing", function()
    local t1 = cyl.seconds()
    local t2 = cyl.seconds()
    expect.truthy(t2 >= t1)
  end)
end)

describe("real-world patterns", function()
  it("arithmetic identities", function()
    expect.equal(1 + 1, 2)
    expect.equal(3 * 3, 9)
    expect.equal(10 - 5, 5)
    expect.near(10 / 3, 3.333, 0.001)
    expect.equal(10 // 3, 3)
    expect.equal(10 % 3, 1)
  end)

  it("string building with table.concat", function()
    local parts = {}
    for i = 1, 5 do parts[i] = tostring(i) end
    expect.equal(table.concat(parts, "-"), "1-2-3-4-5")
  end)

  it("table as a record", function()
    local person = { name = "Alice", age = 25, active = true }
    expect.equal(person.name, "Alice")
    expect.equal(person.age, 25)
    expect.truthy(person.active)
    expect.not_exist(person.email)
  end)

  it("nil-removal from tables", function()
    local t = { a = 1, b = 2, c = 3 }
    t.b = nil
    expect.not_exist(t.b)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    expect.equal(count, 2)
  end)

  it("multiple return values", function()
    local function minmax(a, b)
      if a < b then return a, b else return b, a end
    end
    local lo, hi = minmax(7, 3)
    expect.equal(lo, 3)
    expect.equal(hi, 7)
  end)

  it("closure captures upvalue", function()
    local function counter()
      local n = 0
      return function() n = n + 1; return n end
    end
    local inc = counter()
    expect.equal(inc(), 1)
    expect.equal(inc(), 2)
    expect.equal(inc(), 3)
  end)

  it("pcall returns status and error", function()
    local ok, err = pcall(function() error("oops") end)
    expect.falsy(ok)
    expect.matches(tostring(err), "oops")
  end)
end)

cyl.report()
cyl.exit()