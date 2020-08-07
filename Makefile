.PHONY = src build \
         test src-test \
         clean-all clean \
         clean-src clean-test clean-docs

# Build metadata

BUILD_META = 
BUILD_META_HEAD_FILE = src/version/build-meta-head.lua
BUILD_META_FILE = src/version/build-meta.lua

# Rojo

ROJO = rojo

OUT_FILE = Modules.rbxmx
ROJO_PROJECT_BUILD = build.project.json

ROJO_PROJECT_TEST = test.project.json
TEST_FILE = test.rbxlx

# Documentation

LDOC_LUA = ldoc.lua.bat
LDOC_CONFIG = config.ld

PYTHON = python
PIP = $(PYTHON) -m pip
VENV = venv

DOCS_REQUIREMENTS = requirements-docs.txt
MKDOCS = $(PYTHON) -m mkdocs
MKDOCS_CONFIG = mkdocs.yml

DOCS_FILTER_LUA_MODULE = docs.filter
DOCS_SRC = docs
DOCS_SITE = site
DOCS_BUILD = docs-build
DOCS_JSON = docs.json

LDOC2MKDOCS = $(PYTHON) -m ldoc2mkdocs

# Utilities

RM = rm
CP = cp

build : $(OUT_FILE)

$(OUT_FILE) : src
	$(ROJO) build $(ROJO_PROJECT_BUILD) --output Modules.rbxmx

src : $(wildcard src/**/*)
	$(CP) $(BUILD_META_HEAD_FILE) $(BUILD_META_FILE)
	$(file >>$(BUILD_META_FILE),$(BUILD_META))

test : $(TEST_FILE)

$(TEST_FILE) : src src-test
	$(ROJO) build $(ROJO_PROJECT_TEST) --output $(TEST_FILE)

src-test : $(wildcard test/**/*)

venv :
	$(PYTHON) -m venv $(VENV)

docs : clean-docs
	mkdir $(DOCS_BUILD)
	$(CP) -r $(DOCS_SRC)/* $(DOCS_BUILD)
	$(LDOC_LUA) . --config $(LDOC_CONFIG) --filter $(DOCS_FILTER_LUA_MODULE) > $(DOCS_BUILD)/$(DOCS_JSON)
	$(LDOC2MKDOCS) $(DOCS_BUILD)/$(DOCS_JSON) $(DOCS_BUILD) --pretty
	$(MKDOCS) build --config-file $(MKDOCS_CONFIG) --clean

clean : clean-src clean-test clean-docs

clean-src :
	$(RM) -f $(OUT_FILE)

clean-test :
	$(RM) -f $(TEST_FILE)

clean-docs :
	$(RM) -rf $(DOCS_BUILD)
	$(RM) -rf $(DOCS_SITE)
