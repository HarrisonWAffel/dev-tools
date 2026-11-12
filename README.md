# dev-tools

A collection of scripts and Helm charts for setting up development and test infrastructure.

## PR test command (`test-slash-command.yml`, `slash-matrix-test.yml`)

The owner of a personal repository or members of the repository's owning
organization can comment on an open pull request to run selected Go tests:

```text
/ptest rke2,Test_Basic k3s,Test_Advanced
```

Each whitespace-separated entry creates one job with `V2PROV_TEST_DIST` and
`V2PROV_TEST_RUN_REGEX`. Specify `rke2` or `k3s` before the comma; omitting the
distribution (`Test_Basic` or `,Test_Basic`) defaults to `rke2`. Supply 1 to 16
entries. Regexes are limited to 256 characters, cannot contain whitespace, and
may only use `A-Z a-z 0-9 _ ( ) [ ] | . ^ $ * ?`. Entries for the same
distribution must produce distinct, nonempty result names of at most 120
characters after regex punctuation and the first `Test` are removed.

The command is handled in two stages:

1. `test-slash-command.yml` runs on the comment in the trusted base repository
   context. It never checks out PR code. It validates the request, replies with
   the PR head commit and matrix (recorded in a hidden marker), and applies the
   `ptest` label.
2. Adding the label triggers `slash-matrix-test.yml` as a `pull_request` run,
   so fork PRs get the usual sandbox (read-only token, no secrets, PR-scoped
   cache) and results show up in the PR's checks. It reads the latest request
   comment authored by `github-actions[bot]` and refuses to run if the PR head
   has moved since the request. It calls `matrix-test.yml`, which tests the PR
   merge commit.

Tests execute PR code, so review it before running the command.
`test-slash-command.yml` must exist on the default branch. `ADD_TO_PROJECT_PAT`
must be able to add and remove labels on PRs in this repository (a label added
with `GITHUB_TOKEN` would not trigger the second workflow). For organization
repositories it must also read organization membership, including private
memberships (`read:org` for a classic PAT).

## Helm Charts

A Helm repository index (`index.yaml`) and packaged chart tarballs (`packages/`) are included in this repo. To use them, clone the repo and install directly from the local chart source:

```bash
helm install registry charts/registry/ -n registry --create-namespace
```

### registry

A private Docker registry with optional authentication and pull-through cache support. Backed by the Rancher local-path provisioner by default. K3s includes it; on RKE2 and other distros, run `scripts/install-local-path.sh` first.

Good for testing software that needs to interact with an authenticated registry without standing up a full-blown solution.

```bash
helm install registry dev-tools/registry -n registry --create-namespace
```

See [charts/registry/README.md](charts/registry/README.md) for the full list of configuration options.

## Packaging charts

When charts are updated, regenerate the Helm repository index:

```bash
helm package charts/<chart-name>/ -d packages/
helm repo index packages/ --url https://harrisonwaffel.github.io/dev-tools/packages
mv packages/index.yaml ./index.yaml
```
