# azure-build-policy-apply

## dependencies

- azure-cli (+ devops extension)
- bash
- curl
- jq

Should work on all POSIX-compatible systems (`#!/usr/bin/env`)

## before use

```
1. set $pat variable
2. echo $pat | az devops login
```

## use sample

recolic.net test

```
# pat=111111111111111111111111111111111111111 ./apply.sh --org-url https://dev.azure.com/azvse --proj-name aztest --repo-id a4822210-511f-427f-a36d-26a14c29cc89 --branch bensl/tmpbuild/114514 --build-definition-id 2
```

