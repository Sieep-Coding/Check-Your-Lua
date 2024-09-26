LUA = lua
LUACOV = luacov
LUALCOV = $(LUA) -lluacov

# Run tests
.PHONY: test
test:
	CYL_TEST_SKIP_FAIL=true $(LUA) tests.lua

# Run coverage
.PHONY: coverage
coverage:
	rm -f luacov.stats.out
	$(LUA) -lluacov tests.lua
	CYL_QUIET=true $(LUALCOV) tests.lua
	CYL_COLOR=false $(LUALCOV) tests.lua
	CYL_SHOW_TRACEBACK=false $(LUALCOV) tests.lua
	CYL_SHOW_ERROR=false $(LUALCOV) tests.lua
	CYL_STOP_ON_FAIL=true $(LUALCOV) tests.lua || true
	CYL_QUIET=true CYL_STOP_ON_FAIL=true $(LUALCOV) tests.lua || true
	CYL_FILTER="nested" CYL_TEST_SKIP_FAIL=true $(LUALCOV) tests.lua
	CYL_TEST_SKIP_FAIL=true $(LUALCOV) tests.lua
	CYL_TEST_SKIP_FAIL=true CYL_QUIET=true $(LUALCOV) tests.lua

	$(LUALCOV) tests.lua --quiet
	$(LUALCOV) tests.lua --no-color
	$(LUALCOV) tests.lua --no-show-traceback
	$(LUALCOV) tests.lua --no-show-error
	$(LUALCOV) tests.lua --stop-on-fail || true
	$(LUALCOV) tests.lua --quiet --stop-on-fail || true
	$(LUALCOV) tests.lua --filter="nested" --test-skip-fail
	CYL_TEST_SKIP_FAIL=true $(LUALCOV) tests.lua
	CYL_TEST_SKIP_FAIL=true $(LUALCOV) tests.lua --quiet

	$(LUACOV)
	tail -n 6 luacov.report.out

# Clean target
.PHONY: clean
clean:
	rm -f *.out
