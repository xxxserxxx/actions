# Arch packager

Github Action to build (and release) [AUR](https://aur.archlinux.org/) packages for [Arch Linux](https://www.archlinux.org/).

## Usage

Create a workflow file `.github/workflows/post-release.yml` with the content below (replacing or removing the release step args):

```yml
name: Post release triggers

on: 
  release:
    types: [published]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Get tag name
        shell: bash
        run: echo "##[set-output name=tag;]$(echo ${GITHUB_REF##*/})"
        id: tag_name

      - name: Release Arch AUR packages
        uses: xxxserxxx/actions/arch-package@master
        with:
          args: gotop%20-V=${{ steps.tag_name.outputs.tag }}
        env:
          VERSION: ${{ steps.tag_name.outputs.tag }}

      - uses: stefanzweifel/git-auto-commit-action@v4.0.0
        with:
            commit_message: Update packages to version "${{ steps.tag_name.outputs.tag }}"

            # Optional glob pattern of files which should be added to the commit
            file_pattern: .

            # Optional commit user and author settings
            commit_user_name: Tap Updater
            commit_user_email: ser@ser1.net
            commit_author: Tap Updater <ser@ser1.net>
```

The `VERSION` environment variable is **required**.

The (optional) arguments is list of tests that are run during the process. Each entry must be URL encoded (spaces, at least), and be in the format `command '=' expected_result`.  In the example above, the test will check that the version command for gotop returns the expected version tag.

The action is performing these steps:

1. Package the `aur/PKGBUILD` (source code) package, including updating the PKGBUILD hashes and .SRCINFO metadata
2. Install the resulting package 
3. Run any tests
4. Publish the AUR
5. Repeat for `aur-bin/PKGBUILD`

The tool uses [aurpublish](https://github.com/eli-schwartz/aurpublish) to publish the packages.
