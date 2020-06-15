SHELL = bash

ifeq ($(LIBYAML_ROOT),)
  export LIBYAML_ROOT := libyaml
else
  ifeq ($(wildcard $(LIBYAML_ROOT)/src/yaml_private.h),)
    $(error LIBYAML_ROOT=$(LIBYAML_ROOT) is not a libyaml repo clone directory)
  endif
endif

export LIBYAML_REPO ?= https://github.com/yaml/libyaml
export LIBYAML_COMMIT ?= master

PARSER_TEST := $(LIBYAML_ROOT)/tests/run-parser-test-suite

# .ONESHELL is great but needs make 4.1+
# .ONESHELL:
.PHONY: test
test: $(PARSER_TEST) data
	( \
	  export LIBYAML_TEST_SUITE_ENV=$$(LIBYAML_TEST_SUITE_ENV=$(debug) ./bin/lookup env); \
	  [[ $$LIBYAML_TEST_SUITE_ENV ]] || exit 1; \
	  prove -v test/; \
	  [[ $$LIBYAML_TEST_SUITE_ENV != env/default ]] || \
	    ./bin/lookup default-warning \
	)

test-all:
	prove -v test/test-all.sh

$(PARSER_TEST): $(LIBYAML_ROOT)
	echo PARSER_TEST=$(PARSER_TEST)
	echo LIBYAML_ROOT=$(LIBYAML_ROOT)
	ls -l $(LIBYAML_ROOT)/tests
	( \
	  cd $< && \
	  ./bootstrap && \
	  ./configure && \
	  make all \
	)

$(LIBYAML_ROOT):
	git clone $(LIBYAML_REPO) $@
	( \
	  cd $@ && \
	  git reset --hard $(LIBYAML_COMMIT) \
	)

data:
	( \
	  data=$$(LIBYAML_TEST_SUITE_DEBUG=$(debug) ./bin/lookup data); repo=$${data%\ *}; commit=$${data#*\ }; \
	  [[ $$repo && $$commit ]] || exit 1; \
	  echo "repo=$$repo commit=$$commit"; \
	  git clone $$repo $@; \
	  cd $@ && git reset --hard $$commit \
	)

clean:
	rm -fr data libyaml
	rm -f env/tmp-*
