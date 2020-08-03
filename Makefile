.PHONY = build test src

ROJO = rojo

BUILD_META = return {}
BUILD_META_FILE = src/version/build-meta.lua

OUT_FILE = Modules.rbxmx
ROJO_PROJECT_BUILD = build.project.json

ROJO_PROJECT_TEST = test.project.json
TEST_FILE = test.rbxlx

build : $(OUT_FILE)

$(OUT_FILE) : src
	$(ROJO) build $(ROJO_PROJECT_BUILD) --output Modules.rbxmx

src : $(wildcard src/**/*)
	$(file > $(BUILD_META_FILE),$(BUILD_META))

test : $(TEST_FILE)

$(TEST_FILE) : src testsrc
	$(ROJO) build $(ROJO_PROJECT_TEST) --output $(TEST_FILE)

testsrc : $(wildcard test/**/*)
