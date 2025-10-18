# Validation System Architecture

## Status: PRODUCTION READY ✅

- 769 tests passing (100%)
- Zero linting issues
- Modular architecture complete

## Architecture

### Core Components

- **BaseValidator**: Abstract interface for all validators
- **ValidatorRegistry**: Dynamic discovery, loads custom validators from `<action>/CustomValidator.py`
- **ConventionMapper**: Auto-detection via 100+ naming patterns (priority-based matching)

### Specialized Validators (9)

`token.py`, `version.py` (SemVer/CalVer), `boolean.py`, `numeric.py`, `docker.py`, `file.py`, `network.py`, `security.py`, `codeql.py`

### Custom Validators (20+)

Actions with complex validation have `CustomValidator.py` in their directory. Registry auto-discovers them.

Examples: `docker-build/CustomValidator.py`, `sync-labels/CustomValidator.py`, `codeql-analysis/CustomValidator.py`

## Convention-Based Detection

Automatic validator selection from input names:

- Priority 100: Exact (`dry-run` → boolean)
- Priority 95: Language-specific (`-python-version` → python_version)
- Priority 90: Suffixes (`-token` → token)
- Priority 85: Contains (`email` → email)
- Priority 80: Prefixes (`is-` → boolean)

## Test Generation

`validate-inputs/scripts/generate-tests.py`:

- Non-destructive (preserves existing tests)
- Intelligent pattern detection for input types
- Template-based scaffolding for validators
- ShellSpec + pytest generation

## Usage

```python
from validators.registry import ValidatorRegistry
validator = ValidatorRegistry().get_validator("docker-build")
result = validator.validate_inputs({"context": ".", "platforms": "linux/amd64"})
```

## File Structure

```text
validate-inputs/
├── validator.py              # Main entry
├── validators/               # 9 specialized + base + registry + conventions
├── scripts/
│   ├── update-validators.py  # Rule generator
│   └── generate-tests.py     # Test generator
└── tests/                    # 769 pytest tests

<action>/CustomValidator.py   # Action-specific validators
```

## Key Features

- Convention-based auto-detection
- GitHub expression support (`${{ }}`)
- Error propagation between validators
- Security validation (injection, secrets)
- CalVer, SemVer, flexible versioning
- Docker platforms, registries
- Token formats (GitHub, NPM, PyPI)
