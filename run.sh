#!/bin/sh

set -e

LUA="lua"
LUACOV="luacov"
LUALCOV="$LUA -lluacov"
TEST_FILE="tests.lua"

run_tests() {
    echo "Running tests..."
    CYL_TEST_SKIP_FAIL=true $LUA $TEST_FILE
}

run_coverage() {
    echo "Running coverage..."
    rm -f luacov.stats.out

    $LUA -lluacov $TEST_FILE

    CYL_QUIET=true $LUALCOV $TEST_FILE
    CYL_COLOR=false $LUALCOV $TEST_FILE
    CYL_SHOW_TRACEBACK=false $LUALCOV $TEST_FILE
    CYL_SHOW_ERROR=false $LUALCOV $TEST_FILE
    CYL_STOP_ON_FAIL=true $LUALCOV $TEST_FILE || true
    CYL_QUIET=true CYL_STOP_ON_FAIL=true $LUALCOV $TEST_FILE || true
    CYL_FILTER="nested" CYL_TEST_SKIP_FAIL=true $LUALCOV $TEST_FILE
    CYL_TEST_SKIP_FAIL=true $LUALCOV $TEST_FILE
    CYL_TEST_SKIP_FAIL=true $LUALCOV $TEST_FILE --quiet
    CYL_TEST_SKIP_FAIL=true $LUALCOV $TEST_FILE --no-color
    CYL_TEST_SKIP_FAIL=true $LUALCOV $TEST_FILE --no-show-traceback
    CYL_TEST_SKIP_FAIL=true $LUALCOV $TEST_FILE --no-show-error
    CYL_TEST_SKIP_FAIL=true $LUALCOV $TEST_FILE --stop-on-fail || true
    CYL_TEST_SKIP_FAIL=true $LUALCOV $TEST_FILE --quiet --stop-on-fail || true
    CYL_FILTER="nested" CYL_TEST_SKIP_FAIL=true $LUALCOV $TEST_FILE

    $LUACOV
    tail -n 6 luacov.report.out
}

clean() {
    echo "Cleaning up..."
    rm -f *.out
}

case "$1" in
    test)
        run_tests
        ;;
    coverage)
        run_coverage
        ;;
    clean)
        clean
        ;;
    help)
        echo "Usage: $0 {test|coverage|clean|help}"
        ;;
    *)
        echo "Invalid command. Use 'help' for usage."
        exit 1
        ;;
esac
