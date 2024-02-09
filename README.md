# RepoExtractor Script Documentation

## Overview

The `extract_repo.bash` script utilizes `git filter-repo` to extract a
single directory from a Git repository and create a new repository with
only that directory. This script simplifies the process of extracting
specific directories for further analysis or sharing.

## Usage

```bash
./extract_repo.bash [-h] [-v] [--develop] [--create-repo] [--push] [-o org] -d directory -r repo --newrepo newrepo
```

### Options

- `-d <directory>`, `--directory <directory>`: Specify the name of the directory
  to extract. Note: This is the *name* of the directory, not the path to the
  directory in the repo.
- `-r <repo>`, `--repo <repo>`: Specify the GitHub repository to extract from.
- `-o <org>`, `--org <org>`: Specify the GitHub organization to extract from (default: `GEOS-ESM`).
- `--newrepo <new_repo_name>`: Specify the name of the new repository to create.
- `-h`, `--help`: Print help and exit.
- `-v`, `--verbose`: Print debug information.
- `-n`, `--dry-run`: Perform a dry-run without making any changes.
- `--develop`: Checkout and push the develop branch in addition to the default branch.
- `--create-repo`: Create the new repository on GitHub. This uses files in the
  `default-files/` directory to populate the new repository with the usual boilerplate files.
- `--push`: Push the new repository to the remote.

### Example

```bash
./extract_repo.bash -d "src" -o "my-org" -r "my-repo" --newrepo "my-new-repo"
```

This command will create a new directory named `my-new-repo` under the
`working-dir` directory, clone the `my-repo` repository from the `my-org` organization
into it, run `git filter-repo` to extract the `src` directory, create a new
repository named `my-new-repo` with only the `src` directory, and push the new
repository to the remote.

## Dependencies

- Bash
- git
- [git filter-repo](https://github.com/newren/git-filter-repo)
- gh (GitHub CLI)

## Authors

- @mathomp4

## Contributions

Contributions are welcome! Please feel free to submit issues or pull requests on the [GitHub repository](https://github.com/GMAO-SI-Team/RepoExtractor).