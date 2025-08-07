# Makefile for GitHub Actions repository
# Provides organized task management with parallel execution capabilities

.PHONY: help all docs lint format check clean install-tools
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
	@echo "  make check        # Quick syntax checks"

# Main targets
all: install-tools docs format lint ## Generate docs, format, and lint everything
	@echo "$(GREEN)✅ All tasks completed successfully$(RESET)"

docs: ## Generate documentation for all actions
	@echo "$(BLUE)📂 Generating documentation...$(RESET)"
	@$(MAKE) -j$(shell nproc 2>/dev/null || echo 4) $(shell find . -mindepth 2 -maxdepth 2 -name "action.yml" | sed 's|/action.yml|/README.md|g')
	@echo "$(GREEN)✅ Documentation generated$(RESET)"

format: format-markdown format-yaml-json format-tables ## Format all files
	@echo "$(GREEN)✅ All files formatted$(RESET)"

lint: lint-markdown lint-yaml lint-actions lint-shell ## Run all linters
	@echo "$(GREEN)✅ All linting completed$(RESET)"

check: check-tools check-syntax ## Quick syntax and tool availability checks
	@echo "$(GREEN)✅ All checks passed$(RESET)"

clean: ## Clean up temporary files and caches
	@echo "$(BLUE)🧹 Cleaning up...$(RESET)"
	@find . -name "*.bak" -delete 2>/dev/null || true
	@find . -name "update_*.log" -mtime +7 -delete 2>/dev/null || true
	@find . -name ".megalinter" -type d -exec rm -rf {} + 2>/dev/null || true
	@echo "$(GREEN)✅ Cleanup completed$(RESET)"

# Documentation generation (parallel execution)
%/README.md: %/action.yml
	@echo "$(BLUE)📄 Generating $@...$(RESET)"
	@dir=$*; \
	repo="ivuorinen/actions/$$dir"; \
	version=$$(grep -E '^# version:' "$<" | cut -d ' ' -f 2 | head -n1); \
	[ -z "$$version" ] && version="main"; \
	printf "# %s\n\n" "$$repo" > "$@"; \
	if npx --yes action-docs@latest --source="$<" --no-banner --include-name-header >> "$@" 2>/dev/null; then \
		$(SED_CMD) "s|PROJECT|$$repo|g; s|VERSION|$$version|g; s|\*\*\*||g" "$@"; \
		[ -f "$@.bak" ] && rm "$@.bak" || true; \
		echo "$(GREEN)✅ Generated $@$(RESET)"; \
	else \
		echo "$(RED)⚠️ Failed to generate $@$(RESET)" | tee -a $(LOG_FILE); \
	fi

# Formatting targets
format-markdown: ## Format markdown files
	@echo "$(BLUE)📝 Formatting markdown...$(RESET)"
	@if npx --yes markdownlint-cli2 --fix "**/*.md" 2>/dev/null; then \
		echo "$(GREEN)✅ Markdown formatted$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️ Markdown formatting issues found$(RESET)" | tee -a $(LOG_FILE); \
	fi

format-yaml-json: ## Format YAML and JSON files
	@echo "$(BLUE)✨ Formatting YAML/JSON...$(RESET)"
	@if npx --yes prettier --write "**/*.md" "**/*.yml" "**/*.yaml" "**/*.json" 2>/dev/null; then \
		echo "$(GREEN)✅ YAML/JSON formatted$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️ YAML/JSON formatting issues found$(RESET)" | tee -a $(LOG_FILE); \
	fi

format-tables: ## Format markdown tables
	@echo "$(BLUE)📊 Formatting tables...$(RESET)"
	@if npx --yes markdown-table-formatter "**/*.md" 2>/dev/null; then \
		echo "$(GREEN)✅ Tables formatted$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️ Table formatting issues found$(RESET)" | tee -a $(LOG_FILE); \
	fi

# Linting targets
lint-markdown: ## Lint markdown files
	@echo "$(BLUE)🔍 Linting markdown...$(RESET)"
	@if npx --yes markdownlint-cli2 --fix "**/*.md" 2>/dev/null; then \
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

lint-actions: ## Lint GitHub Actions workflows
	@echo "$(BLUE)🔍 Linting GitHub Actions...$(RESET)"
	@if command -v actionlint >/dev/null 2>&1; then \
		if actionlint 2>/dev/null; then \
			echo "$(GREEN)✅ Actions linting passed$(RESET)"; \
		else \
			echo "$(YELLOW)⚠️ Actions linting issues found$(RESET)" | tee -a $(LOG_FILE); \
		fi; \
	else \
		echo "$(BLUE)ℹ️ actionlint not available, skipping GitHub Actions linting$(RESET)"; \
	fi

lint-shell: ## Lint shell scripts
	@echo "$(BLUE)🔍 Linting shell scripts...$(RESET)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		if find . -name "*.sh" -exec shellcheck {} + 2>/dev/null; then \
			echo "$(GREEN)✅ Shell linting passed$(RESET)"; \
		else \
			echo "$(YELLOW)⚠️ Shell linting issues found$(RESET)" | tee -a $(LOG_FILE); \
		fi; \
	else \
		echo "$(BLUE)ℹ️ shellcheck not available, skipping shell script linting$(RESET)"; \
	fi

# Check targets
check-tools: ## Check if required tools are available
	@echo "$(BLUE)🔧 Checking required tools...$(RESET)"
	@for cmd in npx sed find grep actionlint shellcheck; do \
		if ! command -v $$cmd >/dev/null 2>&1; then \
			echo "$(RED)❌ Error: $$cmd not found$(RESET)"; \
			echo "  Please install $$cmd (see 'make install-tools')"; \
			exit 1; \
		fi; \
	done
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
	@echo "$(YELLOW)Installing Go tools...$(RESET)"
	@if ! command -v actionlint >/dev/null 2>&1; then \
		if command -v go >/dev/null 2>&1; then \
			echo "  Installing actionlint via go install..."; \
			go install github.com/rhysd/actionlint/cmd/actionlint@latest; \
		else \
			echo "$(RED)⚠️ Go not found. Please install Go to install actionlint$(RESET)"; \
		fi; \
	else \
		echo "  actionlint already installed"; \
	fi
	@echo "$(YELLOW)Checking shellcheck...$(RESET)"
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		echo "$(RED)⚠️ shellcheck not found. Please install:$(RESET)"; \
		echo "  macOS: brew install shellcheck"; \
		echo "  Linux: apt-get install shellcheck"; \
	else \
		echo "  shellcheck already installed"; \
	fi
	@echo "$(GREEN)✅ Tools ready$(RESET)"

# Development targets
dev: ## Development workflow - format then lint
	@$(MAKE) format
	@$(MAKE) lint

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
watch: ## Watch files and auto-format on changes (requires entr)
	@if command -v entr >/dev/null 2>&1; then \
		echo "$(BLUE)👀 Watching for changes... (press Ctrl+C to stop)$(RESET)"; \
		find . -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.sh" | \
		entr -c $(MAKE) format; \
	else \
		echo "$(RED)❌ Error: entr not found. Install with: brew install entr$(RESET)"; \
		exit 1; \
	fi

# Parallel execution for actions
actions = $(shell find . -mindepth 1 -maxdepth 1 -type d -name "*-*" | sed 's|./||')

# Target to process a specific action
process-action-%: ## Process a specific action (internal target)
	@action=$*; \
	if [ -f "./$$action/action.yml" ]; then \
		echo "$(BLUE)🔍 Processing $$action...$(RESET)"; \
		rm "./$$action/README.md" && $(MAKE) "./$$action/README.md"; \
	fi

# Process all actions in parallel
process-all-actions: $(addprefix process-action-,$(actions)) ## Process all actions in parallel
	@echo "$(GREEN)✅ All actions processed$(RESET)"
