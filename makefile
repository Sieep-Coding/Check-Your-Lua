PROJECT_NAME = check-your-lua
SRC_DIR = src
BIN_DIR = bin
TEST_DIR = tests
BUILD_DIR = build
LUA = lua
LDFLAGS = 

# Source files and binaries
SOURCES = $(wildcard $(SRC_DIR)/*.lua)
TEST_SOURCES = $(wildcard $(TEST_DIR)/*.lua)
BINARY = $(BIN_DIR)/$(PROJECT_NAME)

# Default target
.PHONY: all
all: build

# Build target
.PHONY: build
build: $(BINARY)

$(BINARY): $(SOURCES)
	@mkdir -p $(BIN_DIR)
	@echo "Building $(PROJECT_NAME)..."
	@cp $(SOURCES) $(BIN_DIR)

# Test target
.PHONY: test
test: build
	@echo "Running tests..."
	@$(LUA) $(TEST_SOURCES)

# Clean target
.PHONY: clean
clean:
	@echo "Cleaning up..."
	@rm -rf $(BIN_DIR)

# Install target
.PHONY: install
install: build
	@echo "Installing $(PROJECT_NAME)..."
	@cp $(BINARY) /usr/local/bin/

# Help target
.PHONY: help
help:
	@echo "Makefile commands:"
	@echo "  make        Build the project"
	@echo "  make test   Run tests"
	@echo "  make clean  Clean build artifacts"
	@echo "  make install Install the project"
	@echo "  make help   Display this help message"

