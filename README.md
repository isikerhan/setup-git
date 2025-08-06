# setup-git

[![Run core tests](https://github.com/isikerhan/setup-git/actions/workflows/run-core-tests.yml/badge.svg)](https://github.com/isikerhan/setup-git/actions/workflows/run-core-tests.yml)
[![Run extended tests](https://github.com/isikerhan/setup-git/actions/workflows/run-extended-tests.yml/badge.svg)](https://github.com/isikerhan/setup-git/actions/workflows/run-extended-tests.yml)

This action installs a specific version of Git by building the source code (or downloading the prebuilt version for Windows) and adds it to the `PATH`.

> [!WARNING]
> [GitHub-hosted runners](https://docs.github.com/en/actions/using-github-hosted-runners)
already come with one of the latest Git versions
preinstalled. __If your GitHub Action workflow does not require a specific version of Git, you probably don’t need to use this action.__

## Usage

See [action.yml](action.yml)

```yaml
- uses: isikerhan/setup-git@v1
  with:
    # Git version for Linux and macOS runners,
    # or Git for Windows version for Windows runners
    git-version: 2.23.0 # or 2.23.0.windows.1 for Windows
    
    # Installed Git binaries are cached by default and reused in subsequent runs
    cache: false # disable cache
    
    # Verbose output is disabled by default
    verbose: true # enable verbose output
    
    # Installation ID is used for identifying the Git installation, and is optional
    # Currently it's only used in the cache key, prepended to it if present
    installation-id: ${{ github.run_id }} # Run ID will be prepended to each cache key.
    # This ensures that each run has a unique cache entry.

```

__Basic Usage:__

```yaml
name: My workflow
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: isikerhan/setup-git@v1
        with:
          git-version: 2.44.3
      - shell: bash
        run: | 
          echo "$(git --version) is ready to use"
          which git
```

__Matrix of Different Operating Systems and Git Versions:__

```yaml
name: My workflow with matrix
on: [push, pull_request]
jobs:
  test:
    name: Run on ${{ matrix.runs-on }} with Git v${{ matrix.git-version }}
    strategy:
      fail-fast: false
      matrix:
        runs-on: [ubuntu-24.04, ubuntu-24.04-arm, ubuntu-22.04, macos-14, macos-13]
        git-version: [2.23.0, 2.44.1]
        # include Windows runners
        include:
          - runs-on: windows-2022
            git-version: 2.23.0.windows.1
          - runs-on: windows-2022
            git-version: 2.44.1.windows.1
          - runs-on: windows-2019
            git-version: 2.23.0.windows.1
          - runs-on: windows-2019
            git-version: 2.44.1.windows.1
    runs-on: ${{ matrix.runs-on }}
    steps:
      - uses: actions/checkout@v4
      - uses: isikerhan/setup-git@v1
        with:
          git-version: ${{ matrix.git-version }}
      - shell: bash
        run: | 
          echo "$(git --version) is ready to use on $RUNNER_TYPE"
          which git
        env: 
          RUNNER_TYPE: ${{ matrix.runs-on }}
```

> [!NOTE]
macOS and Linux runners use standard [Git release](https://www.kernel.org/pub/software/scm/git/) versions,
while Windows runners use [Git for Windows release](https://github.com/git-for-windows/git/releases) versions.

## Supported Platforms

This action is designed for GitHub-hosted runners and is recommended for use on them.
__It may__ also work on [self-hosted runners](https://github.com/git-for-windows/git/releases)
if the [runner image](https://github.com/actions/runner-images) is similar to the ones used by GitHub-hosted runners.
