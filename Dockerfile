# Use an official Lua runtime as a parent image
FROM lua:5.4

# Set environment variables
ENV PROJECT_NAME check-your-lua
ENV SRC_DIR /app/src
ENV BIN_DIR /app/bin
ENV TEST_DIR /app/tests
ENV LUA lua

# Set the working directory
WORKDIR /app

# Copy the source files to the container
COPY src/ $SRC_DIR/
COPY tests/ $TEST_DIR/

# Default command (can be overridden when running the container)
CMD ["lua", "$SRC_DIR/main.lua"]  # Replace main.lua with your entry point if needed
