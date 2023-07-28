PROJECT_NAME = $(notdir $(shell pwd))
PROJECT_LIB = ./lib$(PROJECT_NAME).a

BINARY = app.bin
TEST = test.bin

GLOBAL_INCLUDE_DIR := /usr/local/include
GLOBAL_LIB_DIR := /usr/local/lib

BUILD_DIR := ./build
LIB_DIR := ./lib
INCLUDE_DIR := ./include
SRC_DIR := ./src/core
MAIN_DIR := ./src

# use := here so the find only runs once
SRC_FILES := $(shell find $(SRC_DIR) -type f -name *.c)
OBJ_FILES := $(patsubst $(SRC_DIR)/%,$(BUILD_DIR)/%,$(SRC_FILES:.c=.o))
DEP_FILES := $(OBJ_FILES:.o=.d)

CC := clang
IFLAGS := -I$(GLOBAL_INCLUDE_DIR) -I$(INCLUDE_DIR)
LFLAGS := -L$(GLOBAL_LIB_DIR) -L$(LIB_DIR)
DFLAGS := -MP -MD
CFLAGS := -Wall -Wextra -g -O0

# tell make where to look for source files
VPATH = $(sort $(dir $(SRC_FILES))) $(MAIN_DIR)

.PHONY: build test
build: $(BINARY)
test: $(TEST)

# how to build the binaries
$(BINARY) $(TEST): $(OBJ_FILES)
	@echo "link: $^"
	$(CC) $(LFLAGS) -o $@ $^

# add in the per-target specific objects
$(BINARY): $(BUILD_DIR)/main.o
$(TEST): $(BUILD_DIR)/test.o

# how to build one object file from one assembly file
$(BUILD_DIR)/%.o: $(BUILD_DIR)/%.s
	@echo "assemble: $^"
	$(CC) -c $(CFLAGS) -o $@ $<

# how to build one assembly file from one preproc file
$(BUILD_DIR)/%.s: $(BUILD_DIR)/%.i
	@echo "compile: $^"
	$(CC) -S $(CFLAGS) -o $@ $<

# how to build one preproc file from one source file
$(BUILD_DIR)/%.i: %.c
	@echo "preprocess: $^"
	$(CC) -E $(IFLAGS) $(DFLAGS) -o $@ $<

clean:
	rm -rf $(BINARY) $(TEST) $(BUILD_DIR)/[^.]*

IIDIR := $(GLOBAL_INCLUDE_DIR)
ILDIR := $(GLOBAL_LIB_DIR)

install: $(PROJECT_LIB)
	@mkdir -p $(IIDIR) $(ILDIR)
	install -d $(IIDIR) $(ILDIR)
	install -m 644 $(shell find $(INCLUDE_DIR) -type f -name *.h) $(IIDIR)
	install -m 644 $(shell find $(LIB_DIR) -type f -name *.a) $(PROJECT_LIB) $(ILDIR)
	rm $(PROJECT_LIB)

uninstall:
	rm -rfd $(IIDIR)
	rm -f $(ILDIR)/$(notdir $(PROJECT_LIB))

$(PROJECT_LIB): $(OBJ_FILES)
	ar -cvq $@ $^

.SECONDARY:
-include $(DEP_FILES)
