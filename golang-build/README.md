# Go Builder

Github Action to cross-compile Go project binaries for multiple platforms in a single run.

This fork is based on a copy of dockercore/golang-cross which includes headers and support cross-compiling for Darwin and Windows using CGO.  The copy is updated to Go 1.14, and this fork will be updated to use dockercore/golang-cross directly as soon as they update from Go 1.13.  This fork also adds all of the ARM architectures, and provides syntax to enable CGO on specific OS/ARCH combinations.

## Usage

Create a workflow file `.github/workflows/push.yml` with the content below:

```yml
name: Build Go binaries

on: push

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@master

      - name: Make binaries
        uses: xxxserxxx/actions/golang-build@master
```

Basic workflow configuration will compile binaries for the following platforms,
with CGO disabled:

- linux: 386/amd64/arm5/arm6/arm7/aarch64
- darwin: 386/amd64
- windows: 386/amd64 

Alternatively you can provide a list of target architectures in `arg`. The format of the args is OS/ARCH[/CGO]

- GO is linux, darwin, windows, or freebsd
- ARCH is 386, amd64, arm5, arm6, arm7, or aarch64
- CGO is 0 or 1 (defaults to 0)

For example:

```yml
- name: Make binaries
  uses: xxxserxxx/actions/golang-build@master
  with:
    args: linux/amd64 darwin/amd64/1
```

will produce two compile GOOS=Linux, GOARCH=amd64, and CGO_ENABLED=0; and GOOS=darwin, GOARCH=amd64, and CGO_ENABLED=1.

Example output:

```bash
----> Setting up Go repository
----> Building project for: darwin/amd64
  adding: test-go-action_darwin_amd64 (deflated 50%)
----> Building project for: darwin/386
  adding: test-go-action_darwin_386 (deflated 45%)
----> Building project for: linux/amd64
  adding: test-go-action_linux_amd64 (deflated 50%)
----> Building project for: linux/386
  adding: test-go-action_linux_386 (deflated 45%)
----> Building project for: windows/amd64
  adding: test-go-action_windows_amd64 (deflated 50%)
----> Building project for: windows/386
  adding: test-go-action_windows_386 (deflated 46%)
----> Build is complete. List of files at /github/workspace/.release:
total 16436
drwxr-xr-x 2 root root    4096 Feb  5 00:03 .
drwxr-xr-x 5 root root    4096 Feb  5 00:02 ..
-rwxr-xr-x 1 root root 1764764 Feb  5 00:02 test-go-action_darwin_386
-rw-r--r-- 1 root root  978566 Feb  5 00:02 test-go-action_darwin_386.zip
-rwxr-xr-x 1 root root 2003480 Feb  5 00:02 test-go-action_darwin_amd64
-rw-r--r-- 1 root root 1008819 Feb  5 00:02 test-go-action_darwin_amd64.zip
-rwxr-xr-x 1 root root 1676585 Feb  5 00:02 test-go-action_linux_386
-rw-r--r-- 1 root root  918555 Feb  5 00:02 test-go-action_linux_386.zip
-rwxr-xr-x 1 root root 1906945 Feb  5 00:02 test-go-action_linux_amd64
-rw-r--r-- 1 root root  952985 Feb  5 00:02 test-go-action_linux_amd64.zip
-rwxr-xr-x 1 root root 1728000 Feb  5 00:03 test-go-action_windows_386
-rw-r--r-- 1 root root  930942 Feb  5 00:03 test-go-action_windows_386.zip
-rwxr-xr-x 1 root root 1957376 Feb  5 00:02 test-go-action_windows_amd64
-rw-r--r-- 1 root root  972286 Feb  5 00:02 test-go-action_windows_amd64.zip
```
