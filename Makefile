SHELL = bash

export ENV := $(shell pwd)/env

# Check if inside of libyaml repo:
ifneq ($(wildcard ../src/yaml_private.h),)
    export LIBYAML_ROOT := ..
else
    export LIBYAML_ROOT ?= libyaml
    export LIBYAML_COMMIT ?= master
    export LIBYAML_REPO ?= https://github.com/yaml/libyaml
endif

PARSER := $(LIBYAML_ROOT)/tests/run-parser-test-suite

ifdef env
    export LIBYAML_TEST_SUITE_ENV := $(env)
endif

.ONESHELL:
.PHONY: test
test: $(PARSER) data
	@set -ex
	[[ "$(debug)" ]] && export LIBYAML_TEST_SUITE_DEBUG=1
	export LIBYAML_TEST_SUITE_ENV=$$(./bin/lookup env)
	[[ $$LIBYAML_TEST_SUITE_ENV ]] || exit 1
	set +ex
	(set -x; prove -v test/)
	if [[ $$LIBYAML_TEST_SUITE_ENV == env/default ]]; then
	  ./bin/lookup default-warning
	fi

test-all:
	prove -v test/test-all.sh

$(PARSER): $(LIBYAML_ROOT)
	cd $<
	./bootstrap
	./configure
	make all

$(LIBYAML_ROOT):
	git clone $(LIBYAML_REPO) $@

data:
	@set -ex
	[[ "$(debug)" ]] && export LIBYAML_TEST_SUITE_DEBUG=1
	data=$$(./bin/lookup data); repo=$${data%\ *}; commit=$${data#*\ }
	[[ $$data ]] || exit 1
	echo "repo=$$repo commit=$$commit"
	git clone $$repo $@
	(cd $@ && git reset --hard $$commit)

clean:
	rm -fr data
	rm -f env/tmp-*
