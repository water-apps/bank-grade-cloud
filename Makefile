TF ?= terraform
MODULES := $(wildcard modules/*) examples/vend-payments-prod

.PHONY: test fmt validate policy python evidence access-review

test: fmt policy python validate

fmt:
	$(TF) fmt -check -recursive

validate:
	@for d in $(MODULES); do echo "== $$d"; (cd $$d && $(TF) init -backend=false -input=false >/dev/null && $(TF) validate) || exit 1; done

policy:
	opa test policy/ -v

python:
	python3 -m unittest discover -s tests -v

# make evidence CONTROL=DATA-01 PERIOD=2026-Q3
evidence:
	python3 tools/evidence/evidence.py --control $(CONTROL) --period $(PERIOD)

# make access-review QUARTER=2026-Q3 AS_OF=2026-10-01
access-review:
	python3 tools/access_review/access_review.py --quarter $(QUARTER) --as-of $(AS_OF)
