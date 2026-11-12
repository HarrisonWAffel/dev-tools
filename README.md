# dev-tools

A collection of scripts and Helm charts for setting up development and test infrastructure.

## PR test command

Members of the repository's owning organization can comment on an open pull
request to run selected Go tests:

```text
/ptest rke2,testsA k3s,testsB
```

Each whitespace-separated entry adds a matrix job with `V2PROV_TEST_DIST` and
`V2PROV_TEST_RUN_REGEX`. Distributions must be `rke2` or `k3s`; an empty
distribution (`/ptest testsA` or `/ptest ,testsA`) defaults to `rke2`.
Supply 1 to 16 entries.
The first comma separates the distribution from the regex; remaining commas
belong to the regex. Regexes cannot contain whitespace and are passed unchanged
to `go test -run`.

The command workflow must be on the default branch. It calls that branch's
trusted `matrix-test.yml` workflow, checks out the PR's exact head commit
(including fork PRs), and posts a link to the run. PR workflow changes are not
executed. Test jobs receive only a read-only repository token, with no inherited
secrets or persisted checkout credentials. Tests themselves execute PR code, so
members should review it before triggering a run.

Configure `ADD_TO_PROJECT_PAT` with organization membership read access, including
private memberships (`read:org` for a classic PAT). The command is unavailable in
repositories owned by personal accounts.

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
