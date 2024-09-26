local cyl = require('checkyour')
local describe, it, expect = cyl.describe, cyl.it, cyl.expect

local skipfail = os.getenv('CYL_TEST_SKIP_FAIL') == 'true'
cyl.parseargs()

describe("cyl", function()
  local flag = false
  
  cyl.before(function() flag = true end)
  cyl.after(function() flag = false end)

  assert(not flag)

  it("checks before and after hooks", function()
    assert(flag)
  end)

  assert(not flag)

  it("simple assert", function()
    assert(true)
  end, true)

  it("skipped test", function() assert(false) end, false)

  it("expect functionalities", function()
    expect.fail(function() error() end)
    expect.fail(function() error('an error') end, 'an error')
    expect.not_fail(function() end)
    expect.truthy(true)
    expect.falsy(false)
    expect.exist(1)
    expect.exist('')
    expect.not_exist(nil)
    expect.equal(1, 1)
    expect.not_equal(1, 2)
  end)

  it("string equality checks", function()
    expect.equal("test", "test")
    expect.not_equal("hello", "world")
    expect.truthy("Lua")
  end)


  it("table checks", function()
    expect.exist({a=1})
    expect.not_exist(nil)
    expect.equal(#{}, 0)
    expect.equal(#{"item1", "item2"}, 2)
  end)

  it("function checks", function()
    local function testFunc() return true end
    expect.truthy(testFunc())
    expect.not_exist(nil)
  end)

  it("multiple assertions", function()
    expect.equal(1 + 1, 2)
    expect.equal(3 * 3, 9)
    expect.equal(10 - 5, 5)
    expect.equal(10 / 2, 5)
  end)

  it("complex data structure checks", function()
    local data = { name = "John", age = 30, active = true }
    expect.equal(data.name, "John")
    expect.equal(data.age, 30)
    expect.truthy(data.active)
  end)

  it("array checks", function()
    local array = {1, 2, 3}
    expect.equal(#array, 3)
    expect.equal(array[1], 1)
    expect.equal(array[2], 2)
    expect.equal(array[3], 3)
  end)

  it("nested tables", function()
    local nested = { person = { name = "Alice", age = 25 } }
    expect.equal(nested.person.name, "Alice")
    expect.equal(nested.person.age, 25)
  end)

  it("length checks", function()
    expect.equal(#"Lua", 3)
    expect.equal(#"", 0)
  end)

  it("type checks", function()
    expect.equal(type(42), "number")
    expect.equal(type("hello"), "string")
    expect.equal(type({}), "table")
    expect.equal(type(true), "boolean")
  end)

  it("error handling", function()
    expect.fail(function() error("Expected failure.") end, "Expected failure.")
    expect.not_fail(function() end)
  end)

  it("truthy checks with various types", function()
    expect.truthy(1.23)
    expect.truthy("non-empty")
    expect.truthy({})
  end)

  it("table field existence", function()
    local example = {a = 1, b = 2}
    expect.exist(example.a)
    expect.not_exist(example.c)
  end)

  it("complex conditions", function()
    local condition = true
    if condition then
      expect.truthy(condition)
    end
  end)

  it("string length checks", function()
    expect.equal(#"Hello, World!", 13)
    expect.equal(#"", 0)
  end)
end)

cyl.report()

if cyl.exit then
    cyl.exit()
else
    print("Skipping cyl.exit() since it's not defined.")
end
