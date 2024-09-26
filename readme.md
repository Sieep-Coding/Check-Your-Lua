# Check Your Lua 🔎 The Minimal Testing Framework

> [!WARNING]
> Work in Progress. This library is not ready for usage. ⚠️

A single-file, minimal Lua testing framework designed for simplicity and ease of use.

Portable and easy to run.

After trying various testing frameworks, I decided to create my own.

![License: UNLICENSE](https://img.shields.io/badge/License-UNLICENSE-blue.svg)

# Documentation

Access the documentation [here](https://sieep-coding.github.io/cyl-docs/).

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
- Easily run tests using `make`, `bash`, or a `Dockerfile`.
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

### `run.sh`
1. **Build the Project**:
```bash
./run.sh build
```

2. **Run Test**:
 ```bash
./run.sh test
```

### Dockerfile
1. **Build the Project**:
```bash
docker build -t check-your-lua .
```

2. **Run Test**:
 ```bash
docker run --rm check-your-lua lua tests/tests.lua  # Replace test_file.lua with your actual test file

```

## License

[Unlicense](https://github.com/Sieep-Coding/Check-Your-Lua/blob/main/LICENSE)

## Credits

A lot of code is lifted from the [Lester testing framework](https://github.com/edubart/lester).

Hats off to them for the original base code I could build upon.
