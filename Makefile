.PHONY: check clean help

help:
	@echo "make check   — verify everything (syntax, schemas, hook behaviour, install round trip)"
	@echo "make clean   — remove the throwaway test fixture"

check:
	@bash scripts/check.sh

clean:
	@rm -rf .check-fixture && echo "removed .check-fixture"
