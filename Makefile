# Makefile for Chase algorithm implementation

.PHONY: all test clean

# Compiler
GNAT = gnatmake

# Directories
OBJ_DIR = obj
BIN_DIR = bin

# Files
ADS_FILES = chase.ads
ADB_FILES = chase.adb tests.adb

all: $(BIN_DIR)/tests

# Create directories
$(OBJ_DIR) $(BIN_DIR):
	mkdir -p $@

# Build the test executable
$(BIN_DIR)/tests: $(ADS_FILES) $(ADB_FILES) $(OBJ_DIR) $(BIN_DIR)
	$(GNAT) -o $(BIN_DIR)/tests tests.adb -g

# Run tests
test: $(BIN_DIR)/tests
	@echo "Running Chase algorithm tests..."
	@$(BIN_DIR)/tests

# Clean
clean:
	rm -rf $(OBJ_DIR)/* $(BIN_DIR)/*

# Build everything
build: all

# Run tests with verbose output
verbose_test: $(BIN_DIR)/tests
	@echo "Running tests with verbose output..."
	@$(BIN_DIR)/tests
