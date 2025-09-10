# Project Overview - GitHub Actions Monorepo

## Purpose

This repository contains a collection of 41 reusable GitHub Actions designed to streamline CI/CD processes and ensure code quality.
Each action is fully self-contained and can be used independently in any GitHub repository.

## Key Features

- **Production-Ready Actions** covering setup, linting, building, testing, and deployment
- **Self-Contained Design** - each action works independently without dependencies
- **External Usage Ready** - use any action as `ivuorinen/actions/action-name@main`
- **Multi-Language Support** including Node.js, PHP, Python, Go, C#, Docker, and more
- **Centralized Input Validation** with Python-based validation system
- **Comprehensive Testing** with dual testing framework (ShellSpec + pytest)
- **Modular Build System** using Makefile for development and maintenance

## Architecture

- **Flat Directory Structure**: Each action in its own directory with `action.yml`
- **Validation System**: Centralized Python-based input validation in `validate-inputs/`
- **Testing Framework**: Dual approach with ShellSpec for shell/GitHub Actions and pytest for Python
- **Documentation**: Auto-generated README.md files for each action using action-docs

## Categories (41 Actions Total)

- **Setup (7)**: Version detection and environment setup
- **Utilities (2)**: Version parsing and validation
- **Linting (13)**: Code quality and formatting tools
- **Testing (3)**: Test execution frameworks
- **Build (3)**: Build and compilation processes
- **Publishing (5)**: Package and image publishing
- **Repository (8)**: Repository management and maintenance

## Recent State (August 2025)

- ✅ Fixed critical token interpolation issues
- ✅ Implemented automated action catalog generation
- ✅ All actions verified working with proper GitHub Actions expressions
- ✅ Comprehensive testing infrastructure established
- ✅ Python validation system with extensive test coverage
- ✅ Modern development tooling (uv, ruff, pytest-cov)
- ✅ Project in excellent state with all self-containment goals achieved
