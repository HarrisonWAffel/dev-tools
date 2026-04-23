# dev-tools

A collection of scripts and Helm charts for setting up development and test infrastructure.

## Helm Charts

A Helm repository index (`index.yaml`) and packaged chart tarballs (`packages/`) are included in this repo. To use them, clone the repo and install directly from the local chart source:

```bash
helm install registry charts/registry/ -n registry --create-namespace
```

### registry

A private Docker registry with optional authentication and pull-through cache support. Backed by the Rancher LocalPath Provisioner, so it works out of the box on RKE2.

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
