.PHONY: test test-lua test-py

test: test-lua test-py

# luajit tests/run.lua [pattern] runs a subset, e.g. luajit tests/run.lua nav
test-lua:
	@luajit tests/run.lua

test-py:
	@PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tools -p 'test_*.py' -v

.PHONY: plan
# The in-game test plans, checked with the installed CheckThat tools (AGENTS.md, CheckThat). make test and
# make check never need them.
CT ?= ct
# The three plans: core, status window and settings, other addons. Each gets its own build/<name>.ct.
PLANS ?= plans/closestvendor.yaml plans/closestvendor.ui.yaml plans/closestvendor.addons.yaml
plan:
	@command -v "$(CT)" >/dev/null 2>&1 || { echo "plan: no CheckThat tools ($(CT) not found); install them with make install-skill BIN_DIR=\$$HOME/bin in CheckThat, or set CT=<path to ct>" >&2; exit 1; }
	@mkdir -p build
	@set -e; for plan in $(PLANS); do \
		name=$$(basename "$$plan" .yaml); \
		echo "== $$plan"; \
		"$(CT)" validate "$$plan"; \
		"$(CT)" compile "$$plan" -o "build/$$name.ct"; \
		"$(CT)" replay-flow "$$plan"; \
		"$(CT)" lines "$$plan" --addon-src ClosestVendor; \
		"$(CT)" offline "$$plan" --client both; \
	done

.PHONY: check
# The same checks the release workflow runs.
check:
	@for toc in ClosestVendor/ClosestVendor_*.toc; do sh tools/check-toc.sh "$$toc" || exit 1; done
	@sh tools/check-tocs-match.sh
	@sh tools/check-version.sh
