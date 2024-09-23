# Check Yor Lua 🔎 The Minimal Testing Framework

I didn't like any testing frameworks so I wrote my own.

![License: UNLICENSE](https://img.shields.io/badge/License-UNLICENSE-blue.svg)

# Documentation

Access the documentation [here](https://sieep-coding.github.io/cyl-docs/).

## See It In Action

![](https://github.com/Sieep-Coding/Check-Your-Lua/blob/main/assets/simple.png)

## Features

View the [file.](https://github.com/Sieep-Coding/Check-Your-Lua/blob/main/checkyour.lua)

- Single file, efficient and portable
- Zero Dependencies
- Colored Output
- Run with `make`, `bash`, or a `Dockerfile`

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

![Unlicense](https://github.com/Sieep-Coding/Check-Your-Lua/blob/main/LICENSE)