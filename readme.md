# Check Your Lua 🔎 The Minimal Testing Framework

> [!WARNING]
> Work in Progress. This library is not ready for usage. ⚠️

A single-file, minimal Lua testing framework designed for simplicity and ease of use.

Portable and easy to run.

After trying various testing frameworks, I decided to create my own.

![License: UNLICENSE](https://img.shields.io/badge/License-UNLICENSE-blue.svg)

[![asciicast](https://asciinema.org/a/qz1efJAuVhYQTyzAC40kEQ6OB.svg)](https://asciinema.org/a/qz1efJAuVhYQTyzAC40kEQ6OB)

# Documentation

Access the documentation [here](https://sieep-coding.github.io/cyl-docs/).

Just drop `checkyour.lua` in your project and then `require` it. 

It will return a table with its functionality.

I will be adding it to [Luarocks](https://luarocks.org/) soon.

### Example

```lua
local checkyourlua = require 'checkyourlua'
local describe, it, expect = checkyourlua.describe, checkyourlua.it, checkyourlua.expect

-- Customize checkyourlua configuration.
checkyourlua.show_traceback = false

describe('my project', function()
  checkyourlua.before(function()
    -- This function is run before every test.
  end)

  describe('module1', function() -- Describe blocks can be nested.
    it('feature1', function()
      expect.equal('something', 'something') -- Pass.
    end)

    it('feature2', function()
      expect.truthy(false) -- Fail.
    end)

    local feature3_test_enabled = false
    it('feature3', function() -- This test will be skipped.
      expect.truthy(false) -- Fail.
    end, feature3_test_enabled)
  end)
end)

checkyourlua.report() -- Print overall statistic of the tests run.
checkyourlua.exit() -- Exit with success if all tests passed.
```

## See It In Action

![](https://github.com/Sieep-Coding/Check-Your-Lua/blob/main/assets/simple.png)

![](https://github.com/Sieep-Coding/Check-Your-Lua/blob/main/assets/passing.png)

![](https://github.com/Sieep-Coding/Check-Your-Lua/blob/main/assets/output.png)

## Features

View the [source file.](https://github.com/Sieep-Coding/Check-Your-Lua/blob/main/checkyour.lua)

- Single file, efficient, and portable.
- Compatible with Lua 5.1 and above.
- Zero dependencies for easy integration.
- Colored output for better readability.
- Displays execution time and performance metrics.
- Excellent logging capabilities.
- Easily run tests using `make` or `bash`.
- Licensed under the Unlicense for maximum freedom.
- Extensive [documentation](https://sieep-coding.github.io/cyl-docs/) available.

## Build Instructions

### Makefile

1. **Build the Project**:
```bash
make build
```

2. **Run Test**:
 ```bash
make test
```

3. **Show Test Coverage**:
 ```bash
make coverage
```

### `run.sh`
1. **Make Bash Script an Executable**
```bash   
chmod +x bash.sh
```
2. **Build the Project**:
```bash
./run.sh build
```

3. **Run Test**:
 ```bash
./run.sh test
```

4. **Show Test Coverage**:
 ```bash
./run.sh coverage
```

## License

[Unlicense](https://github.com/Sieep-Coding/Check-Your-Lua/blob/main/LICENSE)

## Credits

A lot of code is lifted from the [Lester testing framework](https://github.com/edubart/lester).

Hats off to them for the original base code I could build upon.
