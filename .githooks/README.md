# Git Hooks for Jenkins Repository

This directory contains Git hooks that enforce code quality standards.

## Hooks Available

### Pre-commit Hook
- **Purpose**: Ensures all committed files end with proper newlines (POSIX standard)
- **Scope**: Only checks staged files (modified/added files in the commit)
- **Action**: Prevents commit if any staged files are missing EOF newlines
- **Fix**: Provides commands to automatically fix the issues

## Installation

Run the setup script from the repository root:
```bash
./setup-hooks.sh
```

## Manual Installation

If you prefer to install hooks manually:
```bash
cp .githooks/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## EOF Newline Checker

The `tools/check_eof_newline.py` script can be run independently:

### Check all files
```bash
python3 tools/check_eof_newline.py --check
```

### Fix all files (with backup)
```bash
python3 tools/check_eof_newline.py --fix --backup
```

### Check specific files
```bash
python3 tools/check_eof_newline.py --check --filter "*.py"
```

### Check only modified files
```bash
git diff --name-only | python3 tools/check_eof_newline.py --check --filter-from-file /dev/stdin
```

## Supported File Types

The checker automatically detects and processes:
- **C/C++**: `.cpp`, `.hpp`, `.c`, `.h`, etc.
- **Python**: `.py`, `.pyx`, `.pyi`
- **JavaScript/TypeScript**: `.js`, `.ts`, `.jsx`, `.tsx`
- **Web**: `.html`, `.css`, `.scss`, `.json`, `.yaml`
- **Documentation**: `.md`, `.rst`, `.txt`
- **Scripts**: `.sh`, `.bash`, `.zsh`
- **Build files**: `Makefile`, `CMakeLists.txt`, `Dockerfile`, `Jenkinsfile`
- **Config files**: `.conf`, `.cfg`, `.ini`, `.toml`

## Benefits

1. **POSIX Compliance**: Ensures files end with proper newlines as required by POSIX
2. **Tool Compatibility**: Many Unix tools expect files to end with newlines
3. **Git Hygiene**: Prevents "No newline at end of file" warnings in git diff
4. **Consistency**: Maintains consistent file formatting across the codebase

## Troubleshooting

If a commit is blocked:
1. The hook will show which files need fixing
2. Run the suggested fix command
3. Stage the changes: `git add -u`
4. Retry the commit

To bypass the hook (not recommended):
```bash
git commit --no-verify
```
