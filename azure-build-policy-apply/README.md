# azure-build-policy-apply

## dependencies

- azure-cli (+ devops extension)
- bash
- curl
- jq

Should work on all POSIX-compatible systems (`#!/usr/bin/env`)

## use sample

recolic.net test

```
# pat=111111111111111111111111111111111111111 ./apply.sh --org-url https://dev.azure.com/azvse --proj-name aztest --repo-id a4822210-511f-427f-a36d-26a14c29cc89 --branch bensl/tmpbuild/114514 --build-definition-id 2
```

MS PROD

```
./apply.sh --org-url https://msazure.visualstudio.com --proj-name One --repo-name Networking-Datapath-HostSdnStack-SMAgent --branch bensl/tmpbuild/1207.1 --pipeline-name Overlake-Build-PullRequest

repo_id: 12e0c399-4e80-42b6-aff2-dc693505d5f7
build_definition_id: 270313
```

