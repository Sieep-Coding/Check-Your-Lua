# Use an official Lua runtime as a parent image
FROM lua:5.4 AS base

# Set environment variables
ENV PROJECT_NAME check-your-lua
ENV SRC_DIR /app/src
ENV TEST_DIR /app/tests
ENV LUA lua
ENV LUACOV luacov
ENV LUALCOV="$LUA -lluacov"

# Set the working directory
WORKDIR /app

# Copy the source files and tests into the container
COPY src/ $SRC_DIR/
COPY tests/ $TEST_DIR/

# Install luacov (if needed)
RUN luarocks install luacov

# Run tests
FROM base AS test
CMD ["/bin/sh", "-c", "CYL_TEST_SKIP_FAIL=true $LUA $TEST_DIR/tests.lua"]

# Run coverage
FROM base AS coverage
CMD ["/bin/sh", "-c", "\
  rm -f luacov.stats.out; \
  $LUA -lluacov $TEST_DIR/tests.lua; \
  CYL_QUIET=true $LUALCOV $TEST_DIR/tests.lua; \
  CYL_COLOR=false $LUALCOV $TEST_DIR/tests.lua; \
  CYL_SHOW_TRACEBACK=false $LUALCOV $TEST_DIR/tests.lua; \
  CYL_SHOW_ERROR=false $LUALCOV $TEST_DIR/tests.lua; \
  CYL_STOP_ON_FAIL=true $LUALCOV $TEST_DIR/tests.lua || true; \
  CYL_QUIET=true CYL_STOP_ON_FAIL=true $LUALCOV $TEST_DIR/tests.lua || true; \
  CYL_FILTER=\"nested\" CYL_TEST_SKIP_FAIL=true $LUALCOV $TEST_DIR/tests.lua; \
  CYL_TEST_SKIP_FAIL=true $LUALCOV $TEST_DIR/tests.lua; \
  CYL_TEST_SKIP_FAIL=true CYL_QUIET=true $LUALCOV $TEST_DIR/tests.lua; \
  $LUALCOV $TEST_DIR/tests.lua --quiet; \
  $LUALCOV $TEST_DIR/tests.lua --no-color; \
  $LUALCOV $TEST_DIR/tests.lua --no-show-traceback; \
  $LUALCOV $TEST_DIR/tests.lua --no-show-error; \
  $LUALCOV $TEST_DIR/tests.lua --stop-on-fail || true; \
  $LUALCOV $TEST_DIR/tests.lua --quiet --stop-on-fail || true; \
  $LUALCOV $TEST_DIR/tests.lua --filter=\"nested\" --test-skip-fail; \
  CYL_TEST_SKIP_FAIL=true $LUALCOV $TEST_DIR/tests.lua; \
  CYL_TEST_SKIP_FAIL=true $LUALCOV $TEST_DIR/tests.lua --quiet; \
  luacov; \
  tail -n 6 luacov.report.out; \
"]

# Clean target (optional)
FROM base AS clean
CMD ["/bin/sh", "-c", "rm -f *.out"]
