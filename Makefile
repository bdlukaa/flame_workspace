.DEFAULT_GOAL := help

SHELL := /bin/sh

# Workspace packages. Resolve all of them from the repository root.
PACKAGE_DIRS := \
	flame_workspace \
	flame_workspace_communication_bridge \
	flame_workspace_core \
	flame_workspace_protocol \
	flame_workspace_runtime \
	template

# Fixtures with valid source. The broken fixture is intentionally excluded from
# format/analyze/test because its syntax errors are used by graceful-failure tests.
FIXTURE_DIRS := \
	fixtures/empty_game \
	fixtures/basic_components \
	fixtures/inheritance \
	fixtures/multiple_worlds

BROKEN_FIXTURE_DIR := fixtures/broken_project
ALL_DIRS := $(PACKAGE_DIRS) $(FIXTURE_DIRS) $(BROKEN_FIXTURE_DIR)
CHECK_DIRS := $(PACKAGE_DIRS) $(FIXTURE_DIRS)


.PHONY: help pub-get format analyze test check clean

help:
	@printf '%s\n' \
		'Available targets:' \
		'  make pub-get  Resolve workspace dependencies once, then each fixture.' \
		'  make format   Format Dart files in maintained packages and valid fixtures.' \
		'  make analyze  Analyze maintained packages and valid fixtures.' \
		'  make test     Run tests where a test directory exists.' \
		'  make check    Run pub-get, format, analyze, and test.' \
		'  make clean    Remove generated Dart/Flutter tool artifacts.'

pub-get:
	@printf '\n==> flutter pub get: workspace\n'
	@flutter pub get
	@for dir in $(FIXTURE_DIRS) $(BROKEN_FIXTURE_DIR); do \
		printf '\n==> flutter pub get: %s\n' "$$dir"; \
		(cd "$$dir" && flutter pub get); \
	done

format:
	@for dir in $(CHECK_DIRS); do \
		printf '\n==> dart format --set-exit-if-changed: %s\n' "$$dir"; \
		(cd "$$dir" && dart format --output=none --set-exit-if-changed .); \
	done

analyze:
	@for dir in $(CHECK_DIRS); do \
		case "$$dir" in \
			flame_workspace_protocol) tool='dart analyze' ;; \
			*) tool='flutter analyze' ;; \
		esac; \
		printf '\n==> %s: %s\n' "$$tool" "$$dir"; \
		(cd "$$dir" && $$tool); \
	done

test:
	@for dir in $(CHECK_DIRS); do \
		if [ ! -d "$$dir/test" ]; then \
			printf '\n==> skipping tests: %s (no test directory)\n' "$$dir"; \
			continue; \
		fi; \
		case "$$dir" in \
			flame_workspace_protocol) tool='dart test' ;; \
			*) tool='flutter test --concurrency=1' ;; \
		esac; \
		printf '\n==> %s: %s\n' "$$tool" "$$dir"; \
		(cd "$$dir" && $$tool); \
	done

check: pub-get format analyze test

clean:
	@for dir in $(ALL_DIRS); do \
		printf '\n==> cleaning: %s\n' "$$dir"; \
		rm -rf "$$dir/.dart_tool" "$$dir/build"; \
	done
