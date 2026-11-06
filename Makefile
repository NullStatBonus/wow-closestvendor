.PHONY: test test-lua test-py

test: test-lua test-py

# luajit tests/run.lua [pattern] runs a subset, e.g. luajit tests/run.lua nav
test-lua:
	@luajit tests/run.lua

test-py:
	@PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tools -p 'test_*.py' -v

.PHONY: check
# The same checks the release workflow runs.
check:
	@for toc in ClosestVendor/ClosestVendor_*.toc; do sh tools/check-toc.sh "$$toc" || exit 1; done
	@sh tools/check-tocs-match.sh
	@sh tools/check-version.sh
