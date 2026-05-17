# Check Your Lua (CYL)

A minimal, zero-dependency Lua testing framework for writing clear, expressive unit tests.

**Author:** Nick Stambaugh 

---

## Installation

1. Download `checkyour.lua` and place it in your project directory
2. Require it in your test file: `local cyl = require('checkyour')`

That's it! No dependencies or external tools required (unless you want coverage reports).

---

## Quick Start

Create a test file `tests.lua`:

```lua
local cyl = require('checkyour')
local describe, it, expect = cyl.describe, cyl.it, cyl.expect

cyl.parseargs()

describe("math operations", function()
    it("adds numbers correctly", function()
        expect.equal(2 + 2, 4)
    end)
    
    it("multiplies numbers correctly", function()
        expect.equal(3 * 5, 15)
    end)
end)

cyl.report()
cyl.exit()
```

Run your tests:

```bash
lua tests.lua
```

---

## Core Concepts

### Describe Blocks

Organize tests into logical groups:

```lua
describe("string utilities", function()
    -- tests go here
end)
```

Describe blocks can be nested:

```lua
describe("user management", function()
    describe("validation", function()
        it("rejects invalid emails", function() end)
    end)
end)
```

### Individual Tests

Write test cases with the `it()` function:

```lua
it("description of what it should do", function()
    -- assertions here
end)
```

### Skip Tests

Disable a test without removing it by passing `false`:

```lua
it("feature not yet implemented", function()
    expect.equal(1, 2)  -- won't run
end, false)
```

### Setup & Teardown

Use `before()` and `after()` hooks to set up state before each test and clean up after:

```lua
describe("database operations", function()
    local db
    
    cyl.before(function()
        db = setupTestDatabase()
    end)
    
    cyl.after(function()
        cleanupTestDatabase(db)
    end)
    
    it("connects to database", function()
        expect.exist(db)
    end)
end)
```

---

## Assertions

### Value Existence

```lua
expect.exist(value)      -- passes if value is not nil
expect.not_exist(nil)    -- passes if value is nil
```

### Truthiness

```lua
expect.truthy(true)      -- passes if value is truthy
expect.truthy("text")    -- passes (non-empty strings are truthy)
expect.truthy({})        -- passes (tables are truthy)

expect.falsy(false)      -- passes if value is falsy
expect.falsy(nil)        -- passes (nil is falsy)
```

### Equality

```lua
expect.equal(1, 1)                                   -- exact equality
expect.equal("hello", "hello")                       -- string comparison
expect.equal({a=1, b=2}, {a=1, b=2})                -- deep table comparison
expect.not_equal(1, 2)                               -- inequality check
```

### Functions

```lua
expect.fail(function() error("oops") end)            -- passes if function errors
expect.fail(function() error("oops") end, "oops")   -- passes if error contains message
expect.not_fail(function() return 42 end)            -- passes if function doesn't error
```

### Complete Example

```lua
describe("user validation", function()
    it("validates user data", function()
        local user = { name = "Alice", age = 30, active = true }
        
        expect.exist(user)
        expect.equal(user.name, "Alice")
        expect.equal(user.age, 30)
        expect.truthy(user.active)
        expect.not_exist(user.deleted)
    end)
    
    it("rejects invalid input", function()
        expect.fail(function()
            validateUser(nil)
        end, "invalid user")
    end)
end)
```

---

## Configuration

Configure CYL using environment variables or command-line arguments.

### Environment Variables

```bash
# Disable colored output
CYL_COLOR=false lua tests.lua

# Suppress passing test output (quiet mode)
CYL_QUIET=true lua tests.lua

# Hide stack traces on failures
CYL_SHOW_TRACEBACK=false lua tests.lua

# Hide error messages on failures
CYL_SHOW_ERROR=false lua tests.lua

# Exit on first failure
CYL_STOP_ON_FAIL=true lua tests.lua

# Run only tests matching a pattern
CYL_FILTER="database" lua tests.lua

# UTF-8 support for compact output
CYL_UTF8TERM=true lua tests.lua
```

### Command-Line Arguments

Pass configuration as arguments to your test script:

```bash
lua tests.lua --quiet --no-color

lua tests.lua --filter="auth"

lua tests.lua --stop-on-fail
```

In your test file, parse arguments with:

```lua
cyl.parseargs()  -- parses _G.arg
-- or
cyl.parseargs(custom_args)
```

---

## Output Modes

### Normal Mode (default)

Clear, colorized output showing each test result:

```
[PASS] user validation | validates user data
[PASS] user validation | rejects invalid input
[SKIP] feature | not yet ready
[FAIL] database | handles connections (tests/db.lua:42)
[====] user validation | 2 passed / 1 failed / 0 skipped / 0.003421s
```

### Quiet Mode

Compact character-based output for CI/CD pipelines:

```bash
CYL_QUIET=true lua tests.lua
```

Output: `◯◯◯[FAIL] database | handles connections`

### Filtered Tests

Run only tests matching a pattern:

```bash
CYL_FILTER="auth" lua tests.lua      # runs tests with "auth" in name
CYL_FILTER="user|admin" lua tests.lua # regex patterns work
```

---

## Running Tests

### Basic Test Run

```bash
lua tests.lua
```

### With Makefile

Create a `Makefile` for convenience:

```makefile
.PHONY: test
test:
	lua tests.lua

.PHONY: test-quiet
test-quiet:
	CYL_QUIET=true lua tests.lua

.PHONY: test-fast
test-fast:
	CYL_STOP_ON_FAIL=true lua tests.lua

.PHONY: clean
clean:
	rm -f *.out
```

Run tests with:

```bash
make test
make test-quiet
make test-fast
```

### With Shell Script

Use the provided `run.sh` for more control:

```bash
chmod +x run.sh
./run.sh test      # run all tests
./run.sh coverage  # generate coverage report
./run.sh clean     # clean up generated files
./run.sh help      # show usage
```

### Coverage Reports (Optional)

Install `luacov` for coverage analysis:

```bash
luarocks install luacov
make coverage  # or ./run.sh coverage
```

---

## Best Practices

### One Assertion Per Test (Usually)

Keep tests focused on a single behavior:

```lua
-- Good
it("adds positive numbers", function()
    expect.equal(2 + 3, 5)
end)

it("adds negative numbers", function()
    expect.equal(-2 + (-3), -5)
end)

-- Avoid
it("does addition", function()
    expect.equal(2 + 3, 5)
    expect.equal(-2 + (-3), -5)
    expect.equal(0 + 0, 0)
    -- now if one fails, you don't know which one
end)
```

### Use Descriptive Test Names

```lua
-- Good
it("returns error when user not found", function() end)

-- Avoid
it("user test", function() end)
```

### Test Edge Cases

```lua
describe("array operations", function()
    it("handles empty arrays", function()
        expect.equal(#getItems({}), 0)
    end)
    
    it("handles single item", function()
        expect.equal(#getItems({1}), 1)
    end)
    
    it("handles multiple items", function()
        expect.equal(#getItems({1, 2, 3}), 3)
    end)
end)
```

### Use Before/After for Setup

```lua
describe("file operations", function()
    local testfile = "test_data.txt"
    
    cyl.before(function()
        createFile(testfile, "test content")
    end)
    
    cyl.after(function()
        deleteFile(testfile)
    end)
    
    it("reads file content", function()
        expect.equal(readFile(testfile), "test content")
    end)
end)
```

---

## Real-World Examples

### Testing a Module

```lua
local cyl = require('checkyourlua')
local math_utils = require('math_utils')
local describe, it, expect = cyl.describe, cyl.it, cyl.expect

cyl.parseargs()

describe("math_utils", function()
    describe("clamp", function()
        it("clamps values below minimum", function()
            expect.equal(math_utils.clamp(5, 10, 20), 10)
        end)
        
        it("clamps values above maximum", function()
            expect.equal(math_utils.clamp(25, 10, 20), 20)
        end)
        
        it("returns value in range", function()
            expect.equal(math_utils.clamp(15, 10, 20), 15)
        end)
    end)
end)

cyl.report()
cyl.exit()
```

### Testing with State Management

```lua
describe("counter", function()
    local counter
    
    cyl.before(function()
        counter = { count = 0 }
    end)
    
    it("increments counter", function()
        counter.count = counter.count + 1
        expect.equal(counter.count, 1)
    end)
    
    it("resets counter state between tests", function()
        -- counter.count is back to 0 because of before()
        expect.equal(counter.count, 0)
    end)
    
    it("handles multiple increments", function()
        counter.count = counter.count + 5
        expect.equal(counter.count, 5)
    end)
end)
```

---

## Troubleshooting

### Tests Not Running

**Problem:** `it()` blocks aren't executing.

**Solution:** Make sure `describe()` is called before the `it()` blocks, and call `cyl.report()` and `cyl.exit()` at the end.

### Colored Output Not Showing

**Problem:** Terminal output has escape codes visible.

**Solution:** Set `CYL_COLOR=false` or ensure your terminal supports ANSI colors.

### Tests Hanging

**Problem:** Script seems to hang.

**Solution:** Check if you're calling `cyl.exit()` at the end. Without it, the script may not terminate cleanly.

### Module Not Found

**Problem:** `require('checkyourlua')` fails.

**Solution:** Verify the file is named exactly `checkyourlua.lua` and is in the same directory or Lua path.

---

## Exit Codes

CYL returns different exit codes for CI/CD integration:

- `0`: All tests passed
- `1`: One or more tests failed

Use in shell scripts:

```bash
lua tests.lua
if [ $? -eq 0 ]; then
    echo "All tests passed!"
else
    echo "Some tests failed."
    exit 1
fi
```

---

## Performance

CYL is lightweight with minimal overhead. Typical test suites run at thousands of tests per second on modern hardware. For extremely large test suites (10,000+ tests), consider:

- Using `CYL_QUIET=true` for faster output
- Using `CYL_STOP_ON_FAIL=true` during development
- Filtering tests with `CYL_FILTER` to run subsets

---

## Contributing

Found a bug or have a suggestion? Check out the repository:
https://github.com/sieep-coding/Check-Your-Lua

---

## License

This software is released into the public domain under the Unlicense. See LICENSE or https://unlicense.org for details.