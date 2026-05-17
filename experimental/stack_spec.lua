local cyl = require('checkyour')
local describe, it, expect = cyl.describe, cyl.it, cyl.expect

local Stack = require('stack')

describe("Stack", function ()
    it("Starts with a size of 0 / empty", function ()
        local s = Stack.new()
        expect.equal(s:size(), 0)
    end)
end)

cyl.report()
cyl.exit()