# Makefile for GitHub Actions repository
# Provides organized task management with parallel execution capabilities

.PHONY: help all docs update-catalog lint format check clean install-tools test test-unit test-integration test-coverage generate-tests generate-tests-dry test-generate-tests docker-build docker-push docker-test docker-login docker-all release release-dry release-prep release-tag release-undo update-version-refs bump-major-version check-version-refs
.DEFAULT_GOAL := help

# Colors for output
GREEN := $(shell printf '\033[32m')
YELLOW := $(shell printf '\033[33m')
RED := $(shell printf '\033[31m')
BLUE := $(shell printf '\033[34m')
RESET := $(shell printf '\033[0m')

# Configuration
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

# Log file with timestamp
LOG_FILE := update_$(shell date +%Y%m%d_%H%M%S).log

# Detect OS for sed compatibility
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	SED_CMD := sed -i .bak
else
	SED_CMD := sed -i
endif

# Help target - shows available commands
help: ## Show this help message
	@echo "$(BLUE)GitHub Actions Repository Management$(RESET)"
	@echo ""
	@echo "$(GREEN)Available targets:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(RESET) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(GREEN)Examples:$(RESET)"
	@echo "  make all          # Generate docs, format, and lint everything"
	@echo "  make docs         # Generate documentation only"
	@echo "  make lint         # Run all linters"
	@echo "  make format       # Format all files"
	@echo "  make test         # Run all tests (unit + integration)"
	@echo "  make check        # Quick syntax checks"

# Main targets
all: install-tools update-validators docs update-catalog format lint precommit ## Generate docs, format, lint, and run pre-commit
	@echo "$(GREEN)✅ All tasks completed successfully$(RESET)"

docs: ## Generate documentation for all actions
	@echo "$(BLUE)📂 Generating documentation...$(RESET)"
	@failed=0; \
	for dir in $$(find . -mindepth 2 -maxdepth 2 -name "action.yml" | sed 's|/action.yml||' | sed 's|./||'); do \
		echo "$(BLUE)📄 Updating $$dir/README.md...$(RESET)"; \
		repo="ivuorinen/actions/$$dir"; \
		printf "# %s\n\n" "$$repo" > "$$dir/README.md"; \
		if npx --yes action-docs -n -s "$$dir/action.yml" --no-banner >> "$$dir/README.md" 2>/dev/null; then \
			$(SED_CMD) "s|\*\*\*PROJECT\*\*\*|$$repo|g" "$$dir/README.md"; \
			$(SED_CMD) "s|\*\*\*VERSION\*\*\*|main|g" "$$dir/README.md"; \
			$(SED_CMD) "s|\*\*\*||g" "$$dir/README.md"; \
			[ "$(UNAME_S)" = "Darwin" ] && rm -f "$$dir/README.md.bak"; \
			echo "$(GREEN)✅ Updated $$dir/README.md$(RESET)"; \
		else \
			echo "$(RED)⚠️ Failed to update $$dir/README.md$(RESET)" | tee -a $(LOG_FILE); \
			failed=$$((failed + 1)); \
		fi; \
	done; \
	[ $$failed -eq 0 ] && echo "$(GREEN)✅ All documentation updated successfully$(RESET)" || { echo "$(RED)❌ $$failed documentation updates failed$(RESET)"; exit 1; }

update-catalog: ## Update action catalog in README.md
	@echo "$(BLUE)📚 Updating action catalog...$(RESET)"
	@if command -v npm >/dev/null 2>&1; then \
		npm run update-catalog; \
	else \
		echo "$(RED)❌ npm not found. Please install Node.js$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Action catalog updated$(RESET)"

update-validators: ## Update validation rules for all actions
	@echo "$(BLUE)🔧 Updating validation rules...$(RESET)"
	@if command -v uv >/dev/null 2>&1; then \
		cd validate-inputs && uv run scripts/update-validators.py; \
	else \
		echo "$(RED)❌ uv not found. Please install uv (see 'make install-tools')$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Validation rules updated$(RESET)"

update-validators-dry: ## Preview validation rules changes (dry run)
	@echo "$(BLUE)🔍 Previewing validation rules changes...$(RESET)"
	@if command -v uv >/dev/null 2>&1; then \
		cd validate-inputs && uv run scripts/update-validators.py --dry-run; \
	else \
		echo "$(RED)❌ uv not found. Please install uv (see 'make install-tools')$(RESET)"; \
		exit 1; \
	fi

format: format-markdown format-yaml-json format-python ## Format all files
	@echo "$(GREEN)✅ All files formatted$(RESET)"

lint: lint-markdown lint-yaml lint-shell lint-python ## Run all linters
	@echo "$(GREEN)✅ All linting completed$(RESET)"

check: check-tools check-syntax check-local-refs ## Quick syntax and tool availability checks
	@echo "$(GREEN)✅ All checks passed$(RESET)"

clean: ## Clean up temporary files and caches
	@echo "$(BLUE)🧹 Cleaning up...$(RESET)"
	@find . -name "*.bak" -delete 2>/dev/null || true
	@find . -name "update_*.log" -mtime +7 -delete 2>/dev/null || true
	@find . -name ".megalinter" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)✅ Cleanup completed$(RESET)"

precommit: ## Run pre-commit hooks on all files
	@echo "$(BLUE)🔍 Running pre-commit hooks...$(RESET)"
	@if command -v pre-commit >/dev/null 2>&1; then \
		if PRE_COMMIT_USE_UV=1 pre-commit run --all-files; then \
			echo "$(GREEN)✅ All pre-commit hooks passed$(RESET)"; \
		else \
			echo "$(RED)❌ Some pre-commit hooks failed$(RESET)"; \
			exit 1; \
		fi; \
	else \
		echo "$(RED)❌ pre-commit not found. Please install:$(RESET)"; \
		echo "  brew install pre-commit"; \
		echo "  or: pip install pre-commit"; \
		exit 1; \
	fi

# Local action reference validation
check-local-refs: ## Check for ../action-name references that should be ./action-name
	@echo "$(BLUE)🔍 Checking local action references...$(RESET)"
	@if command -v uv >/dev/null 2>&1; then \
		uv run _tools/fix-local-action-refs.py --check; \
	else \
		echo "$(RED)❌ uv not found. Please install uv (see 'make install-tools')$(RESET)"; \
		exit 1; \
	fi

fix-local-refs: ## Fix ../action-name references to ./action-name
	@echo "$(BLUE)🔧 Fixing local action references...$(RESET)"
	@if command -v uv >/dev/null 2>&1; then \
		uv run _tools/fix-local-action-refs.py; \
	else \
		echo "$(RED)❌ uv not found. Please install uv (see 'make install-tools')$(RESET)"; \
		exit 1; \
	fi

fix-local-refs-dry: ## Preview local action reference fixes (dry run)
	@echo "$(BLUE)🔍 Previewing local action reference fixes...$(RESET)"
	@if command -v uv >/dev/null 2>&1; then \
		uv run _tools/fix-local-action-refs.py --dry-run; \
	else \
		echo "$(RED)❌ uv not found. Please install uv (see 'make install-tools')$(RESET)"; \
		exit 1; \
	fi

# Version management targets
release: ## Create a new release with version tags (usage: make release [VERSION=v2025.10.18])
	@VERSION_TO_USE=$$(if [ -n "$(VERSION)" ]; then echo "$(VERSION)"; else date +v%Y.%m.%d; fi); \
	echo "$(BLUE)🚀 Creating release $$VERSION_TO_USE...$(RESET)"; \
	sh _tools/release.sh "$$VERSION_TO_USE"

release-dry: ## Preview release without making changes (usage: make release-dry VERSION=v2025.11.01)
	@if [ -z "$(VERSION)" ]; then \
		VERSION_TO_USE=$$(date +v%Y.%m.%d); \
	else \
		VERSION_TO_USE="$(VERSION)"; \
	fi; \
	echo "$(BLUE)🔍 Previewing release $$VERSION_TO_USE (dry run)...$(RESET)"; \
	sh _tools/release.sh --dry-run "$$VERSION_TO_USE"

release-prep: ## Update action refs and commit (no tags) (usage: make release-prep [VERSION=v2025.11.01])
	@VERSION_TO_USE=$$(if [ -n "$(VERSION)" ]; then echo "$(VERSION)"; else date +v%Y.%m.%d; fi); \
	echo "$(BLUE)🔧 Preparing release $$VERSION_TO_USE...$(RESET)"; \
	sh _tools/release.sh --prep-only "$$VERSION_TO_USE"; \
	echo "$(GREEN)✅ Preparation complete$(RESET)"; \
	echo "$(YELLOW)Next: make release-tag VERSION=$$VERSION_TO_USE$(RESET)"

release-tag: ## Create tags only (assumes prep done) (usage: make release-tag VERSION=v2025.11.01)
	@if [ -z "$(VERSION)" ]; then \
		echo "$(RED)❌ Error: VERSION parameter required for release-tag$(RESET)"; \
		echo "Usage: make release-tag VERSION=v2025.11.01"; \
		exit 1; \
	fi; \
	echo "$(BLUE)🏷️  Creating tags for release $(VERSION)...$(RESET)"; \
	sh _tools/release.sh --tag-only "$(VERSION)"

release-undo: ## Rollback the most recent release (delete tags and reset HEAD)
	@echo "$(BLUE)🔙 Rolling back release...$(RESET)"; \
	sh _tools/release-undo.sh

update-version-refs: ## Update all action references to a specific version tag (usage: make update-version-refs MAJOR=v2025)
	@if [ -z "$(MAJOR)" ]; then \
		echo "$(RED)❌ Error: MAJOR parameter required$(RESET)"; \
		echo "Usage: make update-version-refs MAJOR=v2025"; \
		exit 1; \
	fi
	@echo "$(BLUE)🔧 Updating action references to $(MAJOR)...$(RESET)"
	@sh _tools/update-action-refs.sh "$(MAJOR)"
	@echo "$(GREEN)✅ Action references updated$(RESET)"

bump-major-version: ## Replace one major version with another (usage: make bump-major-version OLD=v2025 NEW=v2026)
	@if [ -z "$(OLD)" ] || [ -z "$(NEW)" ]; then \
		echo "$(RED)❌ Error: OLD and NEW parameters required$(RESET)"; \
		echo "Usage: make bump-major-version OLD=v2025 NEW=v2026"; \
		exit 1; \
	fi
	@echo "$(BLUE)🔄 Bumping version from $(OLD) to $(NEW)...$(RESET)"
	@sh _tools/bump-major-version.sh "$(OLD)" "$(NEW)"
	@echo "$(GREEN)✅ Major version bumped$(RESET)"

check-version-refs: ## List all current SHA-pinned action references
	@echo "$(BLUE)🔍 Checking action references...$(RESET)"
	@sh _tools/check-version-refs.sh

# Formatting targets
format-markdown: ## Format markdown files
	@echo "$(BLUE)📝 Formatting markdown...$(RESET)"
	@if npx --yes markdownlint-cli2 --fix "**/*.md" "#node_modules" "#.worktrees" 2>/dev/null; then \
		echo "$(GREEN)✅ Markdown formatted$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️ Markdown formatting issues found$(RESET)" | tee -a $(LOG_FILE); \
	fi

format-yaml-json: ## Format YAML and JSON files
	@echo "$(BLUE)✨ Formatting YAML/JSON...$(RESET)"
	@if command -v yamlfmt >/dev/null 2>&1; then \
		if yamlfmt . 2>/dev/null; then \
			echo "$(GREEN)✅ YAML formatted with yamlfmt$(RESET)"; \
		else \
			echo "$(YELLOW)⚠️ YAML formatting issues found with yamlfmt$(RESET)" | tee -a $(LOG_FILE); \
		fi; \
	else \
		echo "$(BLUE)ℹ️ yamlfmt not available, skipping$(RESET)"; \
	fi
	@if npx --yes prettier --write "**/*.md" "**/*.yml" "**/*.yaml" "**/*.json" 2>/dev/null; then \
		echo "$(GREEN)✅ YAML/JSON formatted with prettier$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️ YAML/JSON formatting issues found with prettier$(RESET)" | tee -a $(LOG_FILE); \
	fi
	@echo "$(BLUE)📊 Formatting tables...$(RESET)"
	@if npx --yes markdown-table-formatter "**/*.md" 2>/dev/null; then \
		echo "$(GREEN)✅ Tables formatted$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️ Table formatting issues found$(RESET)" | tee -a $(LOG_FILE); \
	fi

format-tables: ## Format markdown tables
	@echo "$(BLUE)📊 Formatting tables...$(RESET)"
	@if npx --yes markdown-table-formatter "**/*.md" 2>/dev/null; then \
		echo "$(GREEN)✅ Tables formatted$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️ Table formatting issues found$(RESET)" | tee -a $(LOG_FILE); \
	fi

format-python: ## Format Python files with ruff
	@echo "$(BLUE)🐍 Formatting Python files...$(RESET)"
	@if command -v uv >/dev/null 2>&1; then \
		if uvx ruff format . --no-cache; then \
			echo "$(GREEN)✅ Python files formatted$(RESET)"; \
		else \
			echo "$(YELLOW)⚠️ Python formatting issues found$(RESET)" | tee -a $(LOG_FILE); \
		fi; \
	else \
		echo "$(BLUE)ℹ️ uv not available, skipping Python formatting$(RESET)"; \
	fi

# Linting targets
lint-markdown: ## Lint markdown files
	@echo "$(BLUE)🔍 Linting markdown...$(RESET)"
	@if npx --yes markdownlint-cli2 --fix "**/*.md" "#node_modules" "#.worktrees"; then \
		echo "$(GREEN)✅ Markdown linting passed$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️ Markdown linting issues found$(RESET)" | tee -a $(LOG_FILE); \
	fi

lint-yaml: ## Lint YAML files
	@echo "$(BLUE)🔍 Linting YAML...$(RESET)"
	@if npx --yes yaml-lint "**/*.yml" "**/*.yaml" 2>/dev/null; then \
		echo "$(GREEN)✅ YAML linting passed$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️ YAML linting issues found$(RESET)" | tee -a $(LOG_FILE); \
	fi

lint-shell: ## Lint shell scripts
	@echo "$(BLUE)🔍 Linting shell scripts...$(RESET)"
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		echo "$(RED)❌ shellcheck not found. Please install shellcheck:$(RESET)"; \
		echo "  brew install shellcheck"; \
		echo "  or: apt-get install shellcheck"; \
		exit 1; \
	fi
	@if find . -name "*.sh" -not -path "./_tests/*" -not -path "./.worktrees/*" -exec shellcheck -x {} +; then \
		echo "$(GREEN)✅ Shell linting passed$(RESET)"; \
	else \
		echo "$(RED)❌ Shell linting issues found$(RESET)"; \
		exit 1; \
	fi

lint-python: ## Lint Python files with ruff and pyright
	@echo "$(BLUE)🔍 Linting Python files...$(RESET)"
	@ruff_passed=true; pyright_passed=true; \
	if command -v uv >/dev/null 2>&1; then \
		uvx ruff check --fix . --no-cache; \
		if ! uvx ruff check . --no-cache; then \
			echo "$(YELLOW)⚠️ Python linting issues found$(RESET)" | tee -a $(LOG_FILE); \
			ruff_passed=false; \
		fi; \
		if command -v pyright >/dev/null 2>&1; then \
			if ! pyright --pythonpath $$(which python3) validate-inputs/ _tests/framework/; then \
				echo "$(YELLOW)⚠️ Python type checking issues found$(RESET)" | tee -a $(LOG_FILE); \
				pyright_passed=false; \
			fi; \
		else \
			echo "$(BLUE)ℹ️ pyright not available, skipping type checking$(RESET)"; \
		fi; \
	else \
		echo "$(BLUE)ℹ️ uv not available, skipping Python linting$(RESET)"; \
	fi; \
	if $$ruff_passed && $$pyright_passed; then \
		echo "$(GREEN)✅ Python linting and type checking passed$(RESET)"; \
	fi

# Check targets
check-tools: ## Check if required tools are available
	@echo "$(BLUE)🔧 Checking required tools...$(RESET)"
	@for cmd in npx sed find grep shellcheck; do \
		if ! command -v $$cmd >/dev/null 2>&1; then \
			echo "$(RED)❌ Error: $$cmd not found$(RESET)"; \
			echo "  Please install $$cmd (see 'make install-tools')"; \
			exit 1; \
		fi; \
	done
	@if ! command -v yamlfmt >/dev/null 2>&1; then \
		echo "$(YELLOW)⚠️ yamlfmt not found (optional for YAML formatting)$(RESET)"; \
	fi
	@echo "$(GREEN)✅ All required tools available$(RESET)"

check-syntax: ## Check syntax of shell scripts and YAML files
	@echo "$(BLUE)🔍 Checking syntax...$(RESET)"
	@failed=0; \
	find . -name "*.sh" -not -path "./_tests/*" -not -path "./.worktrees/*" -print0 | while IFS= read -r -d '' file; do \
		if ! bash -n "$$file" 2>&1; then \
			echo "$(RED)❌ Syntax error in $$file$(RESET)" >&2; \
			failed=1; \
		fi; \
	done; \
	if [ "$$failed" -eq 1 ]; then \
		echo "$(RED)❌ Shell script syntax errors found$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Syntax checks passed$(RESET)"

install-tools: ## Install/update required tools
	@echo "$(BLUE)📦 Installing/updating tools...$(RESET)"
	@echo "$(YELLOW)Installing NPM tools...$(RESET)"
	@npx --yes action-docs@latest --version >/dev/null
	@npx --yes markdownlint-cli2 --version >/dev/null
	@npx --yes prettier --version >/dev/null
	@npx --yes markdown-table-formatter --version >/dev/null
	@npx --yes yaml-lint --version >/dev/null
	@echo "$(YELLOW)Checking shellcheck...$(RESET)"
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		echo "$(RED)⚠️ shellcheck not found. Please install:$(RESET)"; \
		echo "  macOS: brew install shellcheck"; \
		echo "  Linux: apt-get install shellcheck"; \
	else \
		echo "  shellcheck already installed"; \
	fi
	@echo "$(YELLOW)Checking yamlfmt...$(RESET)"
	@if ! command -v yamlfmt >/dev/null 2>&1; then \
		echo "$(RED)⚠️ yamlfmt not found. Please install:$(RESET)"; \
		echo "  macOS: brew install yamlfmt"; \
		echo "  Linux: go install github.com/google/yamlfmt/cmd/yamlfmt@latest"; \
	else \
		echo "  yamlfmt already installed"; \
	fi
	@echo "$(YELLOW)Checking uv...$(RESET)"
	@if ! command -v uv >/dev/null 2>&1; then \
		echo "$(RED)⚠️ uv not found. Please install:$(RESET)"; \
		echo "  macOS: brew install uv"; \
		echo "  Linux: curl -LsSf https://astral.sh/uv/install.sh | sh"; \
		echo "  Or see: https://docs.astral.sh/uv/getting-started/installation/"; \
		exit 1; \
	else \
		echo "  uv already installed"; \
	fi
	@echo "$(YELLOW)Checking pre-commit...$(RESET)"
	@if ! command -v pre-commit >/dev/null 2>&1; then \
		echo "$(BLUE)ℹ️ pre-commit not found. Installing via uv tool...$(RESET)"; \
		uv tool install pre-commit; \
		echo "  pre-commit installed"; \
	else \
		echo "  pre-commit already installed"; \
	fi
	@echo "$(YELLOW)Installing git hooks with pre-commit...$(RESET)"
	@if [ -d .git ] && command -v pre-commit >/dev/null 2>&1; then \
		if ~/.local/bin/pre-commit install 2>/dev/null || pre-commit install 2>/dev/null; then \
			echo "  Git hooks installed"; \
		fi; \
	fi
	@echo "$(YELLOW)Installing Python dependencies from pyproject.toml...$(RESET)"
	@uv sync --all-extras
	@echo "  Python dependencies installed"
	@echo "$(GREEN)✅ All tools installed/updated$(RESET)"

# Development targets
dev: ## Development workflow - format then lint
	@$(MAKE) format
	@$(MAKE) lint

dev-python: ## Python development workflow - format, lint, test
	@echo "$(BLUE)🐍 Running Python development workflow...$(RESET)"
	@$(MAKE) format-python
	@$(MAKE) lint-python
	@$(MAKE) test-python

ci: check docs lint ## CI workflow - check, docs, lint (no formatting)
	@echo "$(GREEN)✅ CI workflow completed$(RESET)"

# Statistics
stats: ## Show repository statistics
	@echo "$(BLUE)📊 Repository Statistics$(RESET)"
	@printf "%-20s %6s\n" "Actions:" "$(shell find . -mindepth 2 -maxdepth 2 -name "action.yml" | wc -l | tr -d ' ')"
	@printf "%-20s %6s\n" "Shell scripts:" "$(shell find . -name "*.sh" | wc -l | tr -d ' ')"
	@printf "%-20s %6s\n" "YAML files:" "$(shell find . -name "*.yml" -o -name "*.yaml" | wc -l | tr -d ' ')"
	@printf "%-20s %6s\n" "Markdown files:" "$(shell find . -name "*.md" | wc -l | tr -d ' ')"
	@printf "%-20s %6s\n" "Total files:" "$(shell find . -type f | wc -l | tr -d ' ')"

# Watch mode for development
# Testing targets
test: test-python test-update-validators test-actions ## Run all tests (Python + Update validators + GitHub Actions)
	@echo "$(GREEN)✅ All tests completed$(RESET)"

test-actions: ## Run GitHub Actions tests (unit + integration)
	@echo "$(BLUE)🧪 Running GitHub Actions tests...$(RESET)"
	@if ./_tests/run-tests.sh --type all --format console; then \
		echo "$(GREEN)✅ All GitHub Actions tests passed$(RESET)"; \
	else \
		echo "$(RED)❌ Some GitHub Actions tests failed$(RESET)"; \
		exit 1; \
	fi

test-python: ## Run Python validation tests
	@echo "$(BLUE)🐍 Running Python tests...$(RESET)"
	@if command -v uv >/dev/null 2>&1; then \
		if uv run pytest -v --tb=short; then \
			echo "$(GREEN)✅ Python tests passed$(RESET)"; \
		else \
			echo "$(RED)❌ Python tests failed$(RESET)"; \
			exit 1; \
		fi; \
	else \
		echo "$(BLUE)ℹ️ uv not available, skipping Python tests$(RESET)"; \
	fi

test-python-coverage: ## Run Python tests with coverage
	@echo "$(BLUE)📊 Running Python tests with coverage...$(RESET)"
	@if command -v uv >/dev/null 2>&1; then \
		uv run pytest --cov=validate-inputs --cov-report=term-missing; \
	else \
		echo "$(BLUE)ℹ️ uv not available, skipping Python coverage tests$(RESET)"; \
	fi

test-update-validators: ## Run tests for update-validators.py script
	@echo "$(BLUE)🔧 Running update-validators.py tests...$(RESET)"
	@if command -v uv >/dev/null 2>&1; then \
		if uv run pytest validate-inputs/tests/test_update_validators.py -v --tb=short; then \
			echo "$(GREEN)✅ Update-validators tests passed$(RESET)"; \
		else \
			echo "$(RED)❌ Update-validators tests failed$(RESET)"; \
			exit 1; \
		fi; \
	else \
		echo "$(BLUE)ℹ️ uv not available, skipping update-validators tests$(RESET)"; \
	fi

test-unit: ## Run unit tests only
	@echo "$(BLUE)🔬 Running unit tests...$(RESET)"
	@./_tests/run-tests.sh --type unit --format console

test-integration: ## Run integration tests only
	@echo "$(BLUE)🔗 Running integration tests...$(RESET)"
	@./_tests/run-tests.sh --type integration --format console

test-coverage: ## Run tests with coverage reporting
	@echo "$(BLUE)📊 Running tests with coverage...$(RESET)"
	@./_tests/run-tests.sh --type all --coverage --format console

test-action: ## Run tests for specific action (usage: make test-action ACTION=node-setup)
	@if [ -z "$(ACTION)" ]; then \
		echo "$(RED)❌ Error: ACTION parameter required$(RESET)"; \
		echo "Usage: make test-action ACTION=node-setup"; \
		exit 1; \
	fi
	@echo "$(BLUE)🎯 Running tests for action: $(ACTION)$(RESET)"
	@./_tests/run-tests.sh --action $(ACTION) --format console

generate-tests: ## Generate missing tests for actions and validators (won't overwrite existing tests)
	@echo "$(BLUE)🧪 Generating missing tests...$(RESET)"
	@if command -v uv >/dev/null 2>&1; then \
		if uv run validate-inputs/scripts/generate-tests.py; then \
			echo "$(GREEN)✅ Test generation completed$(RESET)"; \
		else \
			echo "$(RED)❌ Test generation failed$(RESET)"; \
			exit 1; \
		fi; \
	else \
		echo "$(RED)❌ uv not found. Please install uv (see 'make install-tools')$(RESET)"; \
		exit 1; \
	fi

generate-tests-dry: ## Preview what tests would be generated without creating files
	@echo "$(BLUE)👁️ Preview test generation (dry run)...$(RESET)"
	@if command -v uv >/dev/null 2>&1; then \
		uv run validate-inputs/scripts/generate-tests.py --dry-run --verbose; \
	else \
		echo "$(RED)❌ uv not found. Please install uv (see 'make install-tools')$(RESET)"; \
		exit 1; \
	fi

test-generate-tests: ## Test the test generation system itself
	@echo "$(BLUE)🔬 Testing test generation system...$(RESET)"
	@if command -v uv >/dev/null 2>&1; then \
		if uv run pytest validate-inputs/tests/test_generate_tests.py -v; then \
			echo "$(GREEN)✅ Test generation tests passed$(RESET)"; \
		else \
			echo "$(RED)❌ Test generation tests failed$(RESET)"; \
			exit 1; \
		fi; \
	else \
		echo "$(RED)❌ uv not found. Please install uv (see 'make install-tools')$(RESET)"; \
		exit 1; \
	fi

# Docker targets
docker-build: ## Build the testing-tools Docker image
	@echo "$(BLUE)🐳 Building testing-tools Docker image...$(RESET)"
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "$(RED)❌ Docker not found. Please install Docker.$(RESET)"; \
		exit 1; \
	fi
	@if bash _tools/docker-testing-tools/build.sh; then \
		echo "$(GREEN)✅ Docker image built successfully$(RESET)"; \
	else \
		echo "$(RED)❌ Docker build failed$(RESET)"; \
		exit 1; \
	fi

docker-test: ## Test the Docker image locally
	@echo "$(BLUE)🧪 Testing Docker image...$(RESET)"
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "$(RED)❌ Docker not found$(RESET)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Testing basic functionality...$(RESET)"
	@docker run --rm ghcr.io/ivuorinen/actions:testing-tools whoami
	@docker run --rm ghcr.io/ivuorinen/actions:testing-tools shellspec --version
	@docker run --rm ghcr.io/ivuorinen/actions:testing-tools act --version
	@echo "$(GREEN)✅ Docker image tests passed$(RESET)"

docker-login: ## Authenticate with GitHub Container Registry
	@echo "$(BLUE)🔐 Authenticating with ghcr.io...$(RESET)"
	@TOKEN=""; \
	TOKEN_SOURCE=""; \
	if [ -n "$${GITHUB_TOKEN-}" ]; then \
		echo "$(BLUE)Using GITHUB_TOKEN from environment$(RESET)"; \
		TOKEN="$${GITHUB_TOKEN}"; \
		TOKEN_SOURCE="env"; \
	elif command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then \
		echo "$(BLUE)Using token from GitHub CLI (gh)$(RESET)"; \
		TOKEN=$$(gh auth token); \
		TOKEN_SOURCE="gh"; \
	else \
		echo "$(RED)❌ No authentication method available$(RESET)"; \
		echo ""; \
		echo "$(YELLOW)To authenticate with ghcr.io, you need a token with 'write:packages' scope$(RESET)"; \
		echo ""; \
		echo "$(GREEN)Option 1: Use environment variable$(RESET)"; \
		echo "  export GITHUB_TOKEN=ghp_xxxxxxxxxxxx"; \
		echo "  make docker-login"; \
		echo ""; \
		echo "$(GREEN)Option 2: Use GitHub CLI with proper scopes$(RESET)"; \
		echo "  gh auth login --scopes 'write:packages'"; \
		echo "  make docker-login"; \
		echo ""; \
		echo "$(GREEN)Option 3: Create a Personal Access Token$(RESET)"; \
		echo "  1. Go to: https://github.com/settings/tokens/new"; \
		echo "  2. Check: write:packages (includes read:packages)"; \
		echo "  3. Generate token and use with Option 1"; \
		exit 1; \
	fi; \
	if printf '%s' "$${TOKEN}" | docker login ghcr.io -u ivuorinen --password-stdin 2>&1 | tee /tmp/docker-login.log | grep -q "Login Succeeded"; then \
		echo "$(GREEN)✅ Successfully authenticated with ghcr.io$(RESET)"; \
		rm -f /tmp/docker-login.log; \
	else \
		echo "$(RED)❌ Authentication failed$(RESET)"; \
		echo ""; \
		if grep -q "scope" /tmp/docker-login.log 2>/dev/null; then \
			echo "$(YELLOW)⚠️ Token does not have required 'write:packages' scope$(RESET)"; \
			echo ""; \
			if [ "$$TOKEN_SOURCE" = "gh" ]; then \
				echo "$(BLUE)GitHub CLI tokens need package permissions.$(RESET)"; \
				echo ""; \
				if [ -n "$${GITHUB_TOKEN-}" ]; then \
					echo "$(YELLOW)Note: GITHUB_TOKEN is set in your environment, which prevents gh auth refresh.$(RESET)"; \
					echo "Clear it first, then refresh:"; \
					echo ""; \
					echo "$(GREEN)For Fish shell:$(RESET)"; \
					echo "  set -e GITHUB_TOKEN"; \
					echo "  gh auth refresh --scopes 'write:packages'"; \
					echo ""; \
					echo "$(GREEN)For Bash/Zsh:$(RESET)"; \
					echo "  unset GITHUB_TOKEN"; \
					echo "  gh auth refresh --scopes 'write:packages'"; \
				else \
					echo "Run:"; \
					echo "  gh auth refresh --scopes 'write:packages'"; \
				fi; \
				echo ""; \
				echo "Then try again:"; \
				echo "  make docker-login"; \
			else \
				echo "Your GITHUB_TOKEN needs 'write:packages' scope."; \
				echo ""; \
				echo "$(GREEN)Create a new token:$(RESET)"; \
				echo "  1. Go to: https://github.com/settings/tokens/new"; \
				echo "  2. Check: write:packages (includes read:packages)"; \
				echo "  3. Generate and copy the token"; \
				echo ""; \
				echo "$(GREEN)For Fish shell:$(RESET)"; \
				echo "  set -gx GITHUB_TOKEN ghp_xxxxxxxxxxxx"; \
				echo ""; \
				echo "$(GREEN)For Bash/Zsh:$(RESET)"; \
				echo "  export GITHUB_TOKEN=ghp_xxxxxxxxxxxx"; \
			fi; \
		fi; \
		rm -f /tmp/docker-login.log; \
		exit 1; \
	fi

docker-push: ## Push the testing-tools image to ghcr.io
	@echo "$(BLUE)📤 Pushing Docker image to ghcr.io...$(RESET)"
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "$(RED)❌ Docker not found$(RESET)"; \
		exit 1; \
	fi
	@if ! docker images ghcr.io/ivuorinen/actions:testing-tools -q | grep -q .; then \
		echo "$(RED)❌ Image not found. Run 'make docker-build' first$(RESET)"; \
		exit 1; \
	fi
	@PUSH_OUTPUT=$$(docker push ghcr.io/ivuorinen/actions:testing-tools 2>&1); \
	PUSH_EXIT=$$?; \
	echo "$${PUSH_OUTPUT}"; \
	if [ $$PUSH_EXIT -ne 0 ]; then \
		echo ""; \
		if echo "$${PUSH_OUTPUT}" | grep -q "scope"; then \
			echo "$(RED)❌ Token does not have required 'write:packages' scope$(RESET)"; \
			echo ""; \
			echo "$(YELLOW)Fix the authentication:$(RESET)"; \
			echo ""; \
			if [ -n "$${GITHUB_TOKEN-}" ]; then \
				echo "$(BLUE)Option 1: Clear GITHUB_TOKEN and use gh auth$(RESET)"; \
				echo ""; \
				echo "For Fish shell:"; \
				echo "  set -e GITHUB_TOKEN"; \
				echo "  gh auth refresh --scopes 'write:packages'"; \
				echo "  make docker-push"; \
				echo ""; \
				echo "For Bash/Zsh:"; \
				echo "  unset GITHUB_TOKEN"; \
				echo "  gh auth refresh --scopes 'write:packages'"; \
				echo "  make docker-push"; \
				echo ""; \
				echo "$(BLUE)Option 2: Create a new token with write:packages scope$(RESET)"; \
			else \
				echo "$(BLUE)Option 1: Use GitHub CLI$(RESET)"; \
				echo "  gh auth refresh --scopes 'write:packages'"; \
				echo "  make docker-push"; \
				echo ""; \
				echo "$(BLUE)Option 2: Use Personal Access Token$(RESET)"; \
			fi; \
			echo "  1. Go to: https://github.com/settings/tokens/new"; \
			echo "  2. Check: write:packages"; \
			echo "  3. Generate and copy token"; \
			echo ""; \
			echo "  For Fish shell:"; \
			echo "    set -gx GITHUB_TOKEN ghp_xxxxxxxxxxxx"; \
			echo "    make docker-push"; \
			echo ""; \
			echo "  For Bash/Zsh:"; \
			echo "    export GITHUB_TOKEN=ghp_xxxxxxxxxxxx"; \
			echo "    make docker-push"; \
			exit 1; \
		elif echo "$${PUSH_OUTPUT}" | grep -q "denied\|unauthorized"; then \
			echo "$(YELLOW)⚠️ Authentication required. Attempting login...$(RESET)"; \
			if $(MAKE) docker-login; then \
				echo ""; \
				echo "$(BLUE)Retrying push...$(RESET)"; \
				if ! docker push ghcr.io/ivuorinen/actions:testing-tools; then \
					echo "$(RED)❌ Retry push failed$(RESET)"; \
					exit 1; \
				fi; \
			else \
				exit 1; \
			fi; \
		else \
			echo "$(RED)❌ Push failed$(RESET)"; \
			exit 1; \
		fi; \
	fi
	@echo "$(GREEN)✅ Image pushed successfully$(RESET)"
	@echo ""
	@echo "Image available at:"
	@echo "  ghcr.io/ivuorinen/actions:testing-tools"

docker-all: docker-build docker-test docker-push ## Build, test, and push Docker image
	@echo "$(GREEN)✅ All Docker operations completed$(RESET)"

watch: ## Watch files and auto-format on changes (requires entr)
	@if command -v entr >/dev/null 2>&1; then \
		echo "$(BLUE)👀 Watching for changes... (press Ctrl+C to stop)$(RESET)"; \
		find . \( -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" \) \
			-not -path "./_tests/*" -not -path "./.worktrees/*" -not -path "./node_modules/*" | \
		entr -c $(MAKE) format; \
	else \
		echo "$(RED)❌ Error: entr not found. Install with: brew install entr$(RESET)"; \
		exit 1; \
	fi
