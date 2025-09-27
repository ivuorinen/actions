# Makefile for GitHub Actions repository
# Provides organized task management with parallel execution capabilities

.PHONY: help all docs lint format check clean install-tools test test-unit test-integration test-coverage generate-tests generate-tests-dry test-generate-tests
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
all: install-tools update-validators docs format lint ## Generate docs, format, and lint everything
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

update-validators: ## Update validation rules for all actions
	@echo "$(BLUE)🔧 Updating validation rules...$(RESET)"
	@cd validate-inputs && python3 scripts/update-validators.py
	@echo "$(GREEN)✅ Validation rules updated$(RESET)"

update-validators-dry: ## Preview validation rules changes (dry run)
	@echo "$(BLUE)🔍 Previewing validation rules changes...$(RESET)"
	@cd validate-inputs && python3 scripts/update-validators.py --dry-run

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

# Local action reference validation
check-local-refs: ## Check for ../action-name references that should be ./action-name
	@echo "$(BLUE)🔍 Checking local action references...$(RESET)"
	@python3 _tools/fix-local-action-refs.py --check

fix-local-refs: ## Fix ../action-name references to ./action-name
	@echo "$(BLUE)🔧 Fixing local action references...$(RESET)"
	@python3 _tools/fix-local-action-refs.py

fix-local-refs-dry: ## Preview local action reference fixes (dry run)
	@echo "$(BLUE)🔍 Previewing local action reference fixes...$(RESET)"
	@python3 _tools/fix-local-action-refs.py --dry-run

# Formatting targets
format-markdown: ## Format markdown files
	@echo "$(BLUE)📝 Formatting markdown...$(RESET)"
	@if npx --yes markdownlint-cli2 --fix "**/*.md" "#node_modules" 2>/dev/null; then \
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
	@if npx --yes markdownlint-cli2 --fix "**/*.md" "#node_modules"; then \
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
	@if command -v shellcheck >/dev/null 2>&1; then \
		if find . -name "*.sh" -not -path "./_tests/*" -exec shellcheck -x {} + 2>/dev/null; then \
			echo "$(GREEN)✅ Shell linting passed$(RESET)"; \
		else \
			echo "$(YELLOW)⚠️ Shell linting issues found$(RESET)" | tee -a $(LOG_FILE); \
		fi; \
	else \
		echo "$(BLUE)ℹ️ shellcheck not available, skipping shell script linting$(RESET)"; \
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
	@find . -name "*.sh" -exec bash -n {} \; 2>/dev/null || { \
		echo "$(RED)❌ Shell script syntax errors found$(RESET)"; exit 1; \
	}
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
	@echo "$(YELLOW)Installing Python dependencies...$(RESET)"
	@uv pip install PyYAML pytest pytest-cov ruff
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
	@echo "Actions: $(shell find . -mindepth 2 -maxdepth 2 -name "action.yml" | wc -l)"
	@echo "Shell scripts: $(shell find . -name "*.sh" | wc -l)"
	@echo "YAML files: $(shell find . -name "*.yml" -o -name "*.yaml" | wc -l)"
	@echo "Markdown files: $(shell find . -name "*.md" | wc -l)"
	@echo "Total files: $(shell find . -type f | wc -l)"

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
	@if command -v python3 >/dev/null 2>&1; then \
		if python3 validate-inputs/scripts/generate-tests.py; then \
			echo "$(GREEN)✅ Test generation completed$(RESET)"; \
		else \
			echo "$(RED)❌ Test generation failed$(RESET)"; \
			exit 1; \
		fi; \
	else \
		echo "$(RED)❌ Python 3 not found$(RESET)"; \
		exit 1; \
	fi

generate-tests-dry: ## Preview what tests would be generated without creating files
	@echo "$(BLUE)👁️ Preview test generation (dry run)...$(RESET)"
	@if command -v python3 >/dev/null 2>&1; then \
		python3 validate-inputs/scripts/generate-tests.py --dry-run --verbose; \
	else \
		echo "$(RED)❌ Python 3 not found$(RESET)"; \
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
		echo "$(BLUE)ℹ️ uv not available, running with python3$(RESET)"; \
		python3 -m pytest validate-inputs/tests/test_generate_tests.py -v || exit 1; \
	fi

watch: ## Watch files and auto-format on changes (requires entr)
	@if command -v entr >/dev/null 2>&1; then \
		echo "$(BLUE)👀 Watching for changes... (press Ctrl+C to stop)$(RESET)"; \
		find . -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" | \
		entr -c $(MAKE) format; \
	else \
		echo "$(RED)❌ Error: entr not found. Install with: brew install entr$(RESET)"; \
		exit 1; \
	fi
