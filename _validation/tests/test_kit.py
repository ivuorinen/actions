"""Unit tests for every check in the validation kit.

``CASES`` holds valid/invalid examples per check type; ``test_every_check_is_covered``
guarantees no check is added to the kit without tests. Security-sensitive behaviour
(token formats, path traversal, injection, SemVer pre-releases, CalVer day rollover) is
asserted explicitly so a regression cannot pass silently.
"""

from __future__ import annotations

import inspect
import pkgutil
import time

import kit
import pytest

# Python's int() takes all of these. A shell integer test errors on the first two, and the rest
# are not the plain digits a consumer of the input can rely on.
NOT_SHELL_INTEGERS = ["1_0", "٣", "+3", " 3", "3 ", "3\n"]

# check type -> {"valid": [...accepted...], "invalid": [...rejected...]}
CASES: dict[str, dict[str, list[str]]] = {
    "github_token": {
        "valid": [
            "ghp_" + "a" * 36,
            "gho_" + "b" * 36,
            "ghu_" + "c" * 36,
            "ghs_" + "d" * 36,
            "ghs_1234567_" + "e" * 200 + "." + "f" * 40 + "." + "g" * 256,
            # stateless ghs_<app-id>_<JWT>: base64url segments contain - and _, joined by .
            "ghs_1234567_" + "Ab-Cd_Ef" * 40 + "." + "Gh-Ij_Kl" * 30 + "." + "Mn-Op_Qr" * 48,
            # body length is unbounded (GitHub warns against relying on the 40-char size)
            "ghs_" + "z" * 1200,
            "ghr_" + "h" * 36,
            "ghe_" + "i" * 36,
            "github_pat_" + "j" * 71,
        ],
        "invalid": [
            "plain-token",
            "ghp_short",
            "github_pat_" + "a" * 49,
            "ghs_" + "a" * 35,
            "$(rm -rf /)",
            "${ evil; }",
            # the runner expands neither of these before validate.py reads the value
            "$NPM_TOKEN",
            "${NPM_TOKEN}",
            "${{ secrets.GITHUB_TOKEN }}",
        ],
    },
    "opaque_token": {
        # fabricated values shaped like real tokens, built up so no scanner reads them as secrets
        "valid": [
            "npm_" + "aB3dE6gH9j" * 3 + "k1M2n3",
            "dckr_pat_" + "aB3-dE6_gH9" * 2 + "k1M2n",
            "dckr_oat_" + "aB3-dE6_gH9" * 2 + "k1M2n",
            "ghp_" + "a" * 36,
            # a JWT-shaped and a base64-shaped token from a self-hosted registry
            "aGVhZGVy" + "." + "cGF5bG9hZA" + "." + "c2ln-_",
            "YWJj" + "+ZGVm/Z2hp=",
            # the format is the issuer's to define, so an unrecognised one is not an error
            "some-registry-token-format",
        ],
        "invalid": [
            "has space",
            " npm_leading",
            "npm_trailing ",
            "npm_abc\n",
            "npm_abc\nsecond-line",
            "npm_abc\r\nsecond-line",
            "npm\tabc",
            "npm\x00abc",
            "npm\x7fabc",
            "npm\x85abc",
            "npm\xa0abc",
            "npm" + chr(0x2028) + "abc",
            "ghp_" + "a" * 36 + "; rm -rf /",
            "$(rm -rf /)",
        ],
    },
    "semantic_version": {
        "valid": [
            "1.2.3",
            "v1.2.3",
            "10.20.30",
            "1.0",
            "1",
            "1.0.0-rc.1",
            "2.0.0+build.1",
            "latest",
        ],
        "invalid": ["1.2.a", "a.b.c", "1.2.3-", "1.2.3+", "1.2.3.4.5"],
    },
    "docker_image_version": {
        "valid": [
            "v0.34.2",
            "0.34.2",
            "1.0.0-rc.1",
            "latest",
            "v0.34.2@sha256:" + "a" * 64,
            "1.0.0-rc.1@sha256:" + "0" * 64,
        ],
        "invalid": [
            # A Docker tag cannot hold "+", so SemVer build metadata cannot name an image.
            "1.0.0+build",
            "1.0.0+build@sha256:" + "0" * 64,
            "v0.34.2\n",
            " v0.34.2",
            "v0.34.2@sha256:" + "a" * 63,
            "v0.34.2@sha256:" + "a" * 65,
            "v0.34.2@sha256:" + "A" * 64,
            "v0.34.2@sha512:" + "a" * 64,
            "v0.34.2@",
            "@sha256:" + "a" * 64,
            "v0.34.2@sha256:" + "a" * 64 + "\nimage=other",
            "v0.34.2\nimage=other",
            "v0.34.2;malicious",
            "1.2.3-",
            "1.2.3+",
        ],
    },
    "strict_semantic_version": {
        "valid": ["1.2.3", "v1.2.3", "V1.2.3", "1.2.3-rc.1", "1.2.3+build.7", "latest"],
        "invalid": ["1.2", "1", "v1.2", "v1", "vv1.2.3", "abc"],
    },
    "no_prefix_version": {
        "valid": ["1.2.3", "1.2", "1"],
        "invalid": ["v1.2.3", "V1.2.3", "abc"],
    },
    "calver_version": {
        "valid": ["2025.04.05", "2025.4.5", "2025.04", "2025-04-05", "24.3.1", "v2024.3.1"],
        "invalid": ["2024.13.1", "2024.2.30", "2024.3.32", "24.3", "2024.3.1.1"],
    },
    "dotnet_version": {
        "valid": ["8", "8.0", "8.0.100", "8.0.x", "8.0.100-preview.1"],
        "invalid": ["v8", "8.0.0.0", "abc"],
    },
    "terraform_version": {
        "valid": ["1.5.7", "1.5.7-rc1", "v1.5.7", "latest"],
        "invalid": ["1.5", "abc"],
    },
    "node_version": {
        "valid": [
            "20",
            "20.1",
            "20.11.0",
            "v20",
            "latest",
            "current",
            "node",
            "lts/*",
            "lts/-1",
            "lts/-12",
            "lts/iron",
            "lts/Hydrogen",
        ],
        "invalid": [
            "abc",
            "20.x",
            # setup-node matches these case-sensitively and has no bare `lts` keyword
            "lts",
            "LTS/iron",
            "LATEST",
            # setup-node's LTS forms are lts/<name>, lts/* and lts/-n, with n >= 1
            "lts/",
            "lts/0",
            "lts/1",
            "lts/-0",
            "lts/-1.5",
            "lts/-٣",
            "lts/**",
            "lts/iron/x",
            "lts/../iron",
            "lts/iron jod",
            "lts/iron\nx",
            "lts/*\nfoo",
            "lts/iron;id",
            "lts/$(x)",
            "lts/${x}",
            "lts/${{ github.ref }}",
            "lts/ïron",
            # setup-node does not trim U+0085, and surrounding whitespace is not stripped here
            "lts/*\x85",
            " 20",
            "20\n",
            # not digits setup-node reads
            "٢٠",
            # pre-release and build metadata are not part of an LTS alias or a plain version
            "lts/iron-rc.1",
            "lts/iron+build",
            "lts/-1-rc.1",
            "lts/-1+build",
            "20.1.0-rc.1",
            "20.1.0+build",
            "20.11.0-rc.1",
            "20.11.0+build",
        ],
    },
    "go_version": {
        "valid": ["1.21", "1.21.5", "1.21.x", "v1.21", "stable", "oldstable"],
        "invalid": ["abc", "1"],
    },
    "golangci_lint_version": {
        "valid": [
            "2.1.0",
            "v2.1.0",
            "V2.1.0",
            "2.1",
            "2",
            "2.1.0-rc.1",
            "v2.1.0-rc.1",
            "2.1.0+build",
            "latest",
        ],
        "invalid": [
            # go-lint installs the /v2 module path, which Go requires to match the major.
            "v3.0.0",
            "10.0.0",
            "1.64.8",
            "v1.64.8",
            "1.64",
            "1",
            "v1",
            "0.1.0",
            "1.64.8-rc.1",
            "1.64.8+build",
            "abc",
            "2.x",
        ],
    },
    "docker_architectures": {
        "valid": ["linux/amd64", "linux/amd64,linux/arm64", "linux/arm/v7"],
        "invalid": ["windows/amd64", "linux/amd64,bogus"],
    },
    "docker_image_name": {
        "valid": [
            "myapp",
            "registry.example.com/ns/app",
            "my-app",
            "ns/sub/app",
            # dots are legal in both the bare name and the registry host
            "my.app",
            "docker.io/library/nginx",
            "my.registry.local/app.name",
        ],
        "invalid": ["MyApp", "my app", "/leading", "-myapp", "myapp-", "_myapp"],
    },
    "docker_tag": {
        "valid": [
            "v1.0.0",
            "latest",
            "sha-1234567",
            "1.0.0",
            "a",
            "_underscore",
            "ends-with-dash-",
            "ends.with.dot.",
            "UPPER_lower",
            "1.0.0-rc.1",
            "v2025.04.05-rc.1",
            "a" * 128,
        ],
        "invalid": [
            "-bad",
            ".bad",
            "in valid",
            "registry:5000",
            "path/tag",
            "tag@sha256",
            "1.0.0+build",
            "2025.4.5+sha.abc1234",
            "a" * 129,
            "tag\n",
            "täg",
        ],
    },
    "docker_tag_list": {
        "valid": [
            "latest",
            "latest,v1.0.0",
            "v1.0.0,v1.0,v1,latest",
            "sha-1234567",
            "_private",
            "trailing-",
            "a" * 128,
        ],
        "invalid": [
            "latest,,v1.0.0",
            "latest,",
            ",latest",
            "latest, v1.0.0",
            "latest ,v1.0.0",
            "-bad",
            ".bad",
            "in valid",
            "latest\n",
            "latest\nv1.0.0",
            "a:b",
            "a/b",
            "a@b",
            "täg",
            "a" * 129,
            "latest," + "a" * 129,
        ],
    },
    "cache_mode": {"valid": ["max", "min", "inline"], "invalid": ["fast", "MAX"]},
    "network_mode": {"valid": ["host", "none", "default"], "invalid": ["bridge"]},
    "jactionlint_profile": {
        "valid": ["correctness", "default"],
        "invalid": ["pedantic", "Correctness", "correctness,default", " default"],
    },
    "sbom_format": {
        "valid": ["spdx-json"],
        "invalid": ["spdx", "json", "cyclonedx-json", "syft-json"],
    },
    "registry_enum": {"valid": ["dockerhub", "github", "both"], "invalid": ["gcr"]},
    "cache_config": {
        "valid": [
            "type=gha",
            "type=gha,mode=max",
            "type=gha,scope=my-image,mode=max,ignore-error=true,timeout=5m",
            "type=gha,url=https://cache.example/abc/,url_v2=https://r.example/,token=a.b-c_d",
            "type=gha,repository=octo/app,ghtoken=ghs_abc,version=2",
            "type=gha,scope=refs/heads/feature/#12",
            "type=inline",
            "type=registry,ref=x",
            "type=registry,ref=ghcr.io/user/app:cache,mode=max,oci-mediatypes=true",
            "type=registry,ref=localhost:5000/app:buildcache,image-manifest=true",
            "type=registry,ref=app:c,compression=zstd,compression-level=3,force-compression=true",
            "type=registry,ref=registry.local:5000/app:c,registry.insecure=true",
            "type=registry,ref=ghcr.io/user/app@sha256:abc123",
            "type=registry,ref=[::1]:5000/app:cache",
            "type=local,src=/tmp/cache",
            "type=local,src=/tmp/my cache",
            "type=local,dest=/tmp/my cache,mode=max",
            "type=local,dest=/tmp/cache,mode=max,tag=latest,reset=true",
            "type=local,src=path/to/dir,digest=sha256:abc123",
            "type=s3,region=eu-west-1,bucket=my_bucket,name=main;abc123",
            "type=s3,region=auto,bucket=b,endpoint_url=http://minio:9000,use_path_style=true",
            "type=s3,region=r,bucket=b,access_key_id=AK,secret_access_key=ab+c/d==,session_token=t",
            "type=s3,region=r,bucket=b,prefix=p/,blobs_prefix=b/,manifests_prefix=m/",
            "type=s3,region=r,bucket=b,touch_refresh=24h,upload_parallelism=4,retry_mode=adaptive",
            "type=azblob,account_url=https://acct.blob.core.windows.net,name=my_image",
            "type=azblob,account_url=https://a.blob.core.windows.net/?sv=1&sig=a%2Bb",
            "type=azblob,account_name=acct,container=c,secret_access_key=ab+c/d==",
            # pre-release and build-metadata versions are distinct SemVer constructs
            "type=registry,ref=ghcr.io/user/app:1.0.0-rc.1",
            "type=registry,ref=ghcr.io/user/app:v2025.04.05-rc.1",
            "type=registry,ref=ghcr.io/user/app:1.0.0+build",
            "type=gha,scope=2025.4.5+sha.abc1234",
            # a YAML block scalar's trailing newline; the action strips it
            "type=gha,mode=max\n",
        ],
        "invalid": [
            "type=evil",
            "gha",
            "mode=max",
            # not a BuildKit cache backend
            "type=oci",
            # only a local src or dest path may hold spaces
            "type=gha --push",
            "type=gha,mode=max --push",
            "type=local,mode=max --push",
            # one spec per input, and no extra output keys
            "type=gha\ntype=inline",
            "type=gha\ninjected=1",
            "type=gha\r\ninjected=1",
            # keys buildx does not document, or documents for another backend
            "type=gha,evil=1",
            "type=registry,ref=x,src=/tmp/cache",
            "type=local,src=/tmp/cache,ref=x",
            "type=inline,ref=x",
            "type=azblob,bucket=b",
            # malformed specs
            "type=gha,",
            "type=gha,,mode=max",
            "type=gha,mode",
            "type=gha,mode=",
            "mode=max,type=gha",
            "TYPE=gha",
            # buildx parses the spec as CSV, so a quote would change its fields
            'type=registry,ref="a,b"',
            "type=gha,scope=$(whoami)",
        ],
    },
    "namespace_with_lookahead": {
        "valid": ["my-org", "abc", "a1-b2"],
        "invalid": ["My-Org", "-bad", "a" * 256],
    },
    "codeql_language": {
        "valid": ["python", "javascript,python", "go", "csharp"],
        "invalid": ["cobol", "python,bogus"],
    },
    "codeql_build_mode": {"valid": ["none", "manual", "autobuild"], "invalid": ["auto"]},
    "codeql_queries": {
        "valid": ["security-extended", "security-and-quality,default", "my/pack"],
        "invalid": ["a,,b", "bad query"],
    },
    "codeql_packs": {
        "valid": ["scope/name", "scope/name@1.0.0", "a/b,c/d"],
        "invalid": ["a,,b", "bad pack"],
    },
    "codeql_config": {
        "valid": ["name: my-config", "paths:\n  - src"],
        "invalid": ["!!python/object/apply:os.system", "x: !!ruby/object {}"],
    },
    "category_format": {
        "valid": ["my-analysis", "/my:cat", "a/b/c"],
        "invalid": ["bad cat", "a;b"],
    },
    "file_path": {
        "valid": [
            "file.txt",
            "path/to/file.txt",
            "folder/sub/file.ext",
            "./-dash.txt",
            "dist-1.0.0-rc.1",
            "dist-1.0.0+build",
            "releases/1.0.0-rc.1/file.txt",
            "releases/1.0.0+build/file.txt",
        ],
        "invalid": [
            "../file.txt",
            "/absolute/path",
            "~/home",
            "path/../file",
            "%2e%2e/etc",
            "src/$VAR",
            "file.txt\n",
            # a command would read a leading dash as an option
            "-x",
            "--help",
            "-",
            # only a build context, secret or dotnet project path may hold a space
            "my dir/file.txt",
        ],
    },
    "dotnet_project": {
        "valid": [
            "App.sln",
            "src/App/App.csproj",
            "src/My App/App.csproj",
            "releases/1.0.0-rc.1/App.csproj",
            "releases/1.0.0+build/App.csproj",
        ],
        "invalid": [
            "../App.sln",
            "/abs/App.csproj",
            "~/App.sln",
            "src/$VAR/App.csproj",
            "App.sln;id",
            # dotnet would read a leading dash as an option
            "-p:Configuration=Debug",
            # a space only separates path characters
            " App.sln",
            "App.sln ",
        ],
    },
    "docker_local_path": {
        "valid": [
            ".",
            "./app",
            "subdir/",
            "Dockerfile",
            "./docker/Dockerfile.prod",
            "build/docker-context",
            # '@' or a github.com directory is only remote in the forms buildx recognises
            "packages/@scope/app",
            "app@1.2.3/Dockerfile",
            "./github.com/org/app",
            "releases/1.0.0-rc.1/Dockerfile",
            "releases/1.0.0+build/Dockerfile",
        ],
        "invalid": [
            "https://example.com/repo.git",
            "http://example.com/Dockerfile",
            "git://example.com/repo.git",
            "ssh://git@example.com/repo.git",
            "HTTPS://example.com/repo.git",
            "docker-image://alpine",
            "file:///etc/passwd",
            "git@github.com:org/repo.git",
            "user@example.com:repo",
            "@example.com:repo",
            "a!b@example.com:repo",
            "github.com/org/repo",
            "https%3A%2F%2Fexample.com/repo.git",
            # '-' is stdin to buildx; a leading dash would be read as a flag
            "-",
            "--load",
            "../file.txt",
            "path/../file",
            "/absolute/path",
            "~/home",
            "%2e%2e/etc",
            "%2fetc",
            "Dockerfile\n",
            # only a build context or secret path may hold a space
            "my dir/Dockerfile",
        ],
    },
    "docker_build_contexts": {
        "valid": [
            "shared=./shared",
            "shared=libs/shared,other=services/other",
            "shared=libs/shared, other=services/other",
            # a YAML block scalar's trailing newline is not a second line
            "shared=libs/shared,other=services/other\n",
            # names are image references to buildx, not environment-variable keys
            "my-context=./shared",
            "base-1.0.0-rc.1=./shared",
            "base-1.0.0+build=./shared",
            "alpine:3.20=docker-image://alpine:3.19",
            "docker.io/library/alpine:3.20=./vendor/alpine",
            "localhost:5000/base=./base",
            # references: nothing here is a runner path
            "alpine=docker-image://alpine:3.20",
            "alpine=docker-image://alpine@sha256:" + "a" * 64,
            "base=docker-image://ghcr.io/org/base:1.0.0-rc.1",
            "base=docker-image://ghcr.io/org/base:1.0.0+build",
            "base=target:builder",
            "project=https://github.com/org/project.git",
            "project=https://github.com/org/project.git#main:subdir",
            "project=http://example.com/context.tar.gz",
            "project=git://example.com/project.git",
            "project=ssh://git@example.com/project.git",
            "project=git@github.com:org/project.git",
            "project=github.com/org/project",
            # oci-layout: only the part before the tag / digest is a path
            "layout=oci-layout://./layout",
            "layout=oci-layout://layout:1.3",
            "layout=oci-layout://a:1.3",
            "layout=oci-layout://layout:1.0.0-rc.1",
            "layout=oci-layout://layout:1.0.0+build",
            "layout=oci-layout://layout@sha256:" + "b" * 64,
            "layout=oci-layout://layout:1.3@sha256:" + "b" * 64,
            "layout=oci-layout://@scope/layout@sha256:" + "b" * 64,
            "shared=releases/1.0.0-rc.1",
            "shared=releases/1.0.0+build",
            # the action passes one entry as one argument, so a path may hold spaces
            "shared=./my dir",
            "shared=./my  dir/sub dir",
            "layout=oci-layout://my dir:1.3",
            "shared=./-shared",
        ],
        "invalid": [
            "shared=/etc",
            "shared=/home/runner/work/_temp",
            "shared=../..",
            "shared=libs/../../..",
            "shared=~/.ssh",
            "shared=%2fetc",
            "shared=%2e%2e/%2e%2e",
            "ok=./a,bad=/etc",
            "ok=./a\nbad=/etc",
            # the action splits on commas only, so a line break would stay inside an entry
            "shared=libs/shared\nother=services/other",
            "shared=libs/shared,\nother=services/other",
            "shared=libs/shared\r\nother=services/other",
            "shared=libs/shared\rother=services/other",
            "alpine=docker-image://alpine:3.20\ninjected=1",
            "shared=libs/shared\x00",
            "ok=./a, bad=../b",
            # a scheme buildx does not treat as remote falls through to the local path lookup
            "shared=file:///etc",
            "shared=unknown://../../etc",
            # not scp-style to buildx either, so this is a local path and must pass the path checks
            "shared=a!b@example.com:../../etc",
            "layout=oci-layout:///etc/layout",
            "layout=oci-layout:///etc/layout:1.0.0-rc.1",
            "layout=oci-layout://../layout:1.3",
            "layout=oci-layout://~/layout",
            "layout=oci-layout://",
            "layout=oci-layout://:1.3",
            "layout=oci-layout://https://example.com/layout",
            # an image reference, build target or URL never holds whitespace
            "alpine=docker-image://alpine --allow network.host",
            "project=https://example.com/project.git --secret",
            "base=target:a b",
            "a b=./shared",
            # a space may only separate path characters, it cannot hide an absolute path
            "shared= /etc",
            "\xa0shared=./a",
            "layout=oci-layout:// /etc:1.3",
            "noequals",
            "shared=",
            "=./shared",
            "-flag=./shared",
            "shared=-shared",
            "layout=oci-layout://-layout:1.3",
            "shared=./a;rm",
            "shared=$(whoami)",
        ],
    },
    "docker_secrets": {
        "valid": [
            "npmrc=.npmrc",
            "npmrc=.npmrc,aws=config/aws-credentials",
            "npmrc=.npmrc, aws=config/aws-credentials",
            # a YAML block scalar's trailing newline is not a second line
            "npmrc=.npmrc,aws=config/aws-credentials\n",
            "GIT_AUTH_TOKEN=.secrets/token",
            "my-secret=secrets/token.txt",
            "my.secret=secrets/token.txt",
            # the value goes to buildx as src=, so an env= form stays a relative file name
            "token=env=API_KEY",
            "key=releases/1.0.0-rc.1/key",
            "key=releases/1.0.0+build/key",
            # the action passes one entry as one argument, so a path may hold spaces
            "npmrc=.npmrc,aws=config/aws credentials",
            "npmrc=./-npmrc",
        ],
        "invalid": [
            "aws=/home/runner/.aws/credentials",
            "docker=/home/runner/.docker/config.json",
            "aws=~/.aws/credentials",
            "npmrc=../../.npmrc",
            "npmrc=sub/../../.npmrc",
            "npmrc=%2fetc%2fpasswd",
            "npmrc=%2e%2e/.npmrc",
            "ok=.npmrc,bad=/etc/passwd",
            "ok=.npmrc\nbad=/etc/passwd",
            # the action splits on commas only, so a line break would stay inside an entry
            "npmrc=.npmrc\naws=config/aws-credentials",
            "npmrc=.npmrc,\naws=config/aws-credentials",
            "npmrc=.npmrc\r\naws=config/aws-credentials",
            "npmrc=.npmrc\raws=config/aws-credentials",
            "npmrc=.npmrc\x00",
            "ok=.npmrc, bad=../.npmrc",
            # full buildx syntax is split on the comma, so src= here is its own file secret
            "id=npmrc,src=/etc/passwd",
            # buildx reads a --secret value as CSV, where a double quote is quoting
            'npmrc="/etc/passwd"',
            'npmrc=my"file',
            "npmrc='/etc/passwd'",
            "npmrc=\\/etc/passwd",
            # a space may only separate path characters, it cannot hide an absolute path
            "npmrc= /etc/passwd",
            "\xa0npmrc=.npmrc",
            "npmrc=$HOME/.npmrc",
            "noequals",
            "npmrc=",
            "=.npmrc",
            "-n=.npmrc",
            "npmrc=-npmrc",
            "a b=.npmrc",
        ],
    },
    "output_path": {
        "valid": [
            "codeql-results",
            "results",
            "./results",
            "out/sarif",
            "out/1.0.0-rc.1",
            "out/1.0.0+build",
        ],
        "invalid": [
            "..",
            "../results",
            "../../../../tmp/x",
            "results/../other",
            "results/..",
            "a..b",
            ".",
            "./",
            "./.",
            "/absolute",
            "//absolute",
            "C:/absolute",
            "~/home",
            "a;b",
            "$(x)",
            "%2e%2e/etc",
            "results\n",
        ],
    },
    "branch_name": {
        "valid": ["main", "feature/x", "release-1.0", "dev_branch"],
        "invalid": ["a..b", "~x", "x^", "a:b", "-bad", ".bad", "/bad"],
    },
    "file_extensions": {
        "valid": [".js", ".js,.ts", ".jsx,.tsx,.mjs"],
        "invalid": ["js", ".js,,.ts", ".j-s"],
    },
    "path_list": {
        "valid": [
            "src/",
            "a,b",
            "*.js",
            "src/**/*.ts",
            "./-x/*.js",
            "a-1.0.0-rc.1,b-1.0.0+build",
            # a comma inside braces is part of the glob, so -b is no separate item
            "src/{a,-b}.js",
            "src/{a,-b{c,d}}.js",
            "**/*.{js,ts},src/{a,b}.md",
            "{src,lib}/**/*.ts",
            "{,src/}*.md",
            "a/~b",
        ],
        "invalid": [
            "a;b",
            "../x",
            "$(x)",
            "-x",
            "--help",
            "a,-b",
            "a, -b",
            "{a,b},-c",
            "-{a,b}",
            # an unclosed or unmatched brace groups nothing, so -b is a separate item
            "{a,-b",
            "a},-b",
            # a tool in fix mode writes to what the globs match, so each stays in the workspace
            "/etc/passwd",
            "src,/etc/*",
            "~/x",
            "{/etc,src}/x",
            "{src,{lib,/etc}}/x",
            "{,/}etc",
            "{~,a}/x",
            # .. built from braces: each expansion is checked, not only the raw text
            "{.,a}./x",
            ".{.,}/x",
            "src/{a,.}./x",
            # more expansions than a list of paths needs
            "{a,b}" * 9,
        ],
    },
    "email": {
        "valid": ["a@b.com", "user+tag@example.org", "test.email@domain.co.uk"],
        "invalid": ["notanemail", "@example.com", "user@"],
    },
    "registry_url": {
        "valid": [
            "https://example.com",
            # $VAR is literal data: the runner never expands it in an input
            "https://example.com/$VAR",
            "https://registry.npmjs.org/",
            "https://npm.example.com:8443/api/npm/repo/",
            "https://npm.example.com:65535/",
            "https://npm.example.com/my%20project/npm/registry/",
            "https://npm.example.com/@scope/",
            "https://npm.example.com/1.0.0-rc.1/",
            "https://npm.example.com/1.0.0+build/",
            # https is fine for any host, including one that merely looks like loopback
            "https://localhost",
            "https://localhost.example.com/",
            # cleartext is accepted for these two exact loopback hosts only
            "http://localhost",
            "http://localhost/",
            "http://localhost:4873",
            "http://localhost:4873/npm/",
            "http://127.0.0.1",
            "http://127.0.0.1:4873/",
        ],
        "invalid": [
            "ftp://x.com",
            "javascript:alert(1)",
            "https://x;rm",
            "not-a-url",
            "1.0.0-rc.1",
            "1.0.0+build",
            # cleartext to anything but the exact loopback hosts
            "http://registry.npmjs.org",
            "http://a.b:8080/p",
            "http://localhost.evil.example",
            "http://localhost.evil.example:4873/",
            "http://localhost-evil.example",
            "http://localhostevil.example",
            "http://127.0.0.1.evil.example",
            "http://127.0.0.2",
            "http://127.1",
            "http://0.0.0.0:4873",
            "http://[::1]:4873",
            "http://LOCALHOST",
            "HTTP://localhost",
            "HTTPS://registry.npmjs.org",
            # userinfo leaks into logs, and can make a remote host read as a local one
            "https://user:pass@registry.example.com",
            "https://user:pass@registry.example.com/",
            "https://user@registry.example.com",
            "https://user:123@registry.example.com",
            "https://:pass@registry.example.com",
            "http://user:pass@localhost:4873",
            "http://localhost@evil.example",
            "http://localhost:4873@evil.example",
            "http://127.0.0.1@evil.example/",
            "https://registry.example.com\\@evil.example",
            # a registry is a host and a path; npm appends package names to it
            "https://registry.example.com/?token=abc",
            "https://registry.example.com?token=abc",
            "https://registry.example.com/#fragment",
            "http://localhost?@evil.example",
            "http://localhost#@evil.example",
            "http://localhost\\@evil.example",
            "https://registry.example.com/a\\b",
            # no line breaks, traversal, or out-of-range ports
            "https://registry.npmjs.org\n",
            "https://registry.npmjs.org/\n",
            "http://localhost\n",
            "https://registry.npmjs.org/\n//evil.example/",
            "https://registry.npmjs.org/../../etc",
            "https://registry.npmjs.org/a/..",
            "https://registry.npmjs.org/%2e%2e/etc",
            "https://registry.npmjs.org/%2E%2E/etc",
            "https://registry.npmjs.org/.%2e/etc",
            "https://registry.npmjs.org/%2e./etc",
            "https://registry.npmjs.org/%0aevil",
            "https://registry.npmjs.org:65536/",
            "http://localhost:99999",
            "http://localhost:٤٨",
        ],
    },
    "scope": {"valid": ["@my-org", "@a"], "invalid": ["my-org", "@1bad"]},
    "username": {
        "valid": ["user", "user-name", "user_name", "a" * 39],
        "invalid": ["a" * 40, "user;name", "-bad"],
    },
    "git_author_name": {
        "valid": ["GitHub Actions", "github-actions[bot]", "Ismo Vuorinen", "user_name"],
        "invalid": ["a;b", "a`b`", "a\nb", "a" * 101],
    },
    "boolean": {
        "valid": ["true", "false"],
        "invalid": ["TRUE", "True", "False", " true", "false\n", "yes", "1", "maybe"],
    },
    "repository_list": {
        "valid": [
            "owner/repo",
            "owner/repo\nowner2/repo2",
            "my-org/my.repo_1",
            "a/b",
            "o1/repo-1.0.0-rc.1",
        ],
        "invalid": [
            "not-a-repo",
            "owner//repo",
            "owner/repo\nbad target",
            "/leading",
            "-owner/repo",
            "--help/repo",
            "owner-/repo",
            "-/repo",
            "my_org/repo",
            "my.org/repo",
            "owner/repo+build",
            "owner/repo\n-owner/repo",
            "owner/repo/extra",
            "owner/",
        ],
    },
    "mode_enum": {"valid": ["check", "fix"], "invalid": ["lint"]},
    "report_format": {"valid": ["json", "sarif", "github-actions"], "invalid": ["yaml"]},
    "golangci_report_format": {
        "valid": ["sarif", "json", "text", "github-actions", "line-number", "colored-line-number"],
        # Formats of other linters, and v2 formats go-lint cannot count issues in.
        "invalid": ["stylish", "compact", "junit", "checkstyle", "tab", "yaml"],
    },
    "coverage_driver": {"valid": ["none", "xdebug", "pcov", "xdebug3"], "invalid": ["phpdbg"]},
    "framework_mode": {"valid": ["auto", "laravel", "generic"], "invalid": ["symfony"]},
    "language_enum": {"valid": ["php", "python", "go", "dotnet"], "invalid": ["ruby"]},
    "severity_enum": {
        "valid": ["HIGH", "HIGH,CRITICAL", "LOW,MEDIUM,HIGH"],
        "invalid": ["high", "HIGH,BOGUS"],
    },
    "scanner_list": {
        "valid": ["vuln", "vuln,secret,config", "vuln,misconfig,secret"],
        "invalid": ["vuln,bogus", "misconfigs"],
    },
    "linter_list": {
        "valid": ["gosec", "gosec,govet", "errcheck", "gosec,\tgovet"],
        "invalid": ["gosec,,govet", "lint;er", "lint er"],
    },
    "plugin_list": {
        "valid": [
            "prettier-plugin-x",
            "@scope/plugin",
            "a,b",
            "a, b",
            "a,\tb",
            "conventional-changelog-conventionalcommits@^9.3.1",
            "@scope/plugin@1.0.0",
            "plugin@1.0.0-rc.1",
            "plugin@1.0.0+build",
            "a@1.0.0-rc.1,@scope/b@2.0.0+build",
        ],
        # "|" is not a separator: the install splits on commas only, so "a|b" is one name.
        # npm reads a spec ending in .tgz, .tar.gz or .tar as a tarball on disk.
        "invalid": [
            "a,,b",
            "bad plugin",
            "a|b",
            "a|b,c",
            "evil.tgz",
            "x@1.tgz",
            "a,plugin.tar.gz",
            "@scope/x.TAR",
        ],
    },
    "npm_spec_list": {
        "valid": [
            "conventional-changelog-conventionalcommits@^9.3.1",
            "@semantic-release/git@10.0.1",
            "@semantic-release/git",
            "semver",
            "JSONStream@1",
            "semver@~7.5",
            "semver@7.x",
            "semver@*",
            "semver@latest",
            "semver@1.0.0-rc.1",
            "semver@1.0.0+build",
            "semver@v2025.04.05-rc.1",
            "semver@2025.4.5+sha.abc1234",
            "@semantic-release/changelog@6.0.0 @semantic-release/git",
            # a YAML block scalar, as in upstream's docs, keeps its newlines and the trailing one
            "@semantic-release/changelog@6.0.0\n@semantic-release/git\n",
            "@semantic-release/git\n",
            "\n  semver@7\n\n  ms@2\t debug\r\n",
        ],
        "invalid": [
            # neither separator splits upstream's list, so these never installed two plugins
            "a|b",
            "a@1|b@2",
            "a,b",
            "a@1,b@2",
            "a, b",
            "a|",
            ",a",
            # read as an npm option rather than a package
            "-g",
            "--registry=https://example.invalid",
            "semver --force",
            # read by npm as a tarball on disk rather than a registry package
            "evil.tgz",
            "x@1.tgz",
            "semver plugin.tar.gz",
            "@scope/x.TAR",
            # not a package name
            "@scope",
            "@scope/",
            "@/name",
            "_private",
            ".hidden",
            "pakéte",
            "a@",
            "a@-1",
            "a@1@2",
            # valid for `npm install`, but not a registry package with a version
            "./local",
            "../local",
            "/abs/path",
            "~/local",
            "user/repo",
            "github:user/repo",
            "https://example.invalid/a.tgz",
            "a@npm:b",
            # shell syntax on the release that passes this list through a shell, `>` and `<` in
            # a comparator range included
            "a@>=1.0.0",
            "a@<2.0.0",
            "a;b",
            "a&b",
            "a#b",
            "$(x)",
            "${x}",
            "$x",
            "`x`",
            "'a'",
            '"a"',
            "a\\b",
            # whitespace that upstream's shell or its splitter does not treat as a separator
            "a\xa0b",
            "a\x0bb",
            "a\x0cb",
            "a\x85b",
            "a\N{LINE SEPARATOR}b",
        ],
    },
    "php_extensions": {
        "valid": ["mbstring", "mbstring, gd", "intl,bcmath"],
        "invalid": ["a,,b", "ext;ra"],
    },
    "key_value_list": {
        "valid": ["FOO=bar", "FOO=bar\nBAZ=qux", "KEY="],
        "invalid": ["FOO=bar;rm", "noequals", "1BAD=x"],
    },
    "comma_key_value_list": {
        "valid": [
            "FOO=bar",
            "NODE_ENV=production,VERSION=1.0.0",
            "KEY=",
            "FOO=hello world",
            "FOO=hello  world,BAR=two words",
            "CFLAGS=-O2 -Wall",
            "OPTS=--enable-foo --disable-bar",
            "GLOB=*.go",
            "URL=https://example.com/a?b=c",
            "EQUATION=a=b",
            "QUOTED='hello world'",
            "A=1, B=2",
            "A=1,",
            "A=1,,B=2",
            # pre-release and build-metadata versions are distinct SemVer constructs
            "VERSION=1.0.0-rc.1",
            "VERSION=v2025.04.05-rc.1",
            "VERSION=1.0.0+build",
            "VERSION=2025.4.5+sha.abc1234",
            # a YAML block scalar's trailing newline; the action strips it
            "A=1,B=2\n",
            "A=1\r\n",
        ],
        "invalid": [
            "noequals",
            "1BAD=x",
            "BAD-KEY=x",
            "=value",
            "FOO=bar;rm",
            "FOO=$(whoami)",
            # every comma-separated item is validated, not just the first
            "FOO=bar,noequals",
            "FOO=bar,--flag=value",
            "FOO=bar,-f=value",
            # a newline would be an extra step output
            "FOO=bar\nBAZ=qux",
            "FOO=bar\ninjected=1",
            "FOO=bar\n,BAZ=qux",
            "FOO=bar\rBAZ=qux",
            "FOO=bar\x1b[0m",
            # the shell trim keeps a no-break space, so it would stay in the name
            "\xa0FOO=bar",
            "A=1,\xa0FOO=bar",
        ],
    },
    "timeout_with_unit": {"valid": ["5m", "30s", "500ms", "1h"], "invalid": ["5", "5min", "m5"]},
    "prefix": {"valid": ["v", "rel-", "a.b_c"], "invalid": ["a b", "a@b", "a:b", "-v", "--draft"]},
    "json_format": {"valid": ["{}", '{"a": 1}', "[1, 2, 3]"], "invalid": ["{bad", "not json"]},
    "composer_args": {
        "valid": [
            "--no-progress --prefer-dist --optimize-autoloader",
            "--no-dev -o -a -n -q -vvv",
            "  --no-scripts   --no-plugins  ",
            "--prefer-install=source",
            "--audit --audit-format=json",
            "--ignore-platform-reqs",
            "--ignore-platform-req=ext-*",
            "--ignore-platform-req=php+",
            "--apcu-autoloader-prefix=1.0.0-rc.1",
        ],
        "invalid": [
            "rm; foo",
            "$(whoami)",
            "a`b`",
            # Move the install. Composer also accepts abbreviated long options.
            "--working-dir=/tmp",
            "--working-dir",
            "--work=/tmp",
            "-d/tmp",
            "-d",
            "--no-dev --working-dir=/tmp",
            # Turn off Composer's security blocking.
            "--no-blocking",
            "--no-security-blocking",
            # Leave no usable vendor/ for the rest of the action.
            "--dry-run",
            "--download-only",
            "--no-install",
            "--no-autoloader",
            "--help",
            "--version",
            # Not options, or options outside the exact spellings.
            "--",
            "vendor/package",
            "-oa",
            "1.0.0-rc.1",
            "1.0.0+build",
            # Only a space separates words, as the old check also required.
            "--no-dev\t--no-scripts",
            "--no-dev\n--no-scripts",
            # Option values are restricted too.
            "--prefer-install=vendor/*",
            "--audit-format=xml",
            "--ignore-platform-req=a/b",
            "--ignore-platform-req=1.0.0+build+",
            "--apcu-autoloader-prefix=1.0.0+build",
            # These words reach Composer as arguments, so an expression cannot hide them.
            "${{ x }} --working-dir=/tmp",
            "${{ x }}--working-dir=/tmp",
            "${{ --working-dir=/tmp }}",
            "${{ -d/tmp }}",
        ],
    },
    "positive_integer": {
        "valid": ["1", "100"],
        # int() raises on the last one, past its 4300-digit limit
        "invalid": ["0", "-1", "abc", *NOT_SHELL_INTEGERS, "9" * 5000],
    },
    "numeric_range_1_10": {
        "valid": ["1", "10", "5"],
        "invalid": ["0", "11", "abc", *NOT_SHELL_INTEGERS],
    },
    # sharp refuses a quality of 0
    "numeric_range_1_100": {"valid": ["1", "100", "50"], "invalid": ["0", "101", "-1"]},
    "numeric_range_1_128": {"valid": ["1", "128"], "invalid": ["0", "129"]},
    "numeric_range_256_32768": {"valid": ["256", "32768"], "invalid": ["255", "32769"]},
    "numeric_range_0_10000": {"valid": ["0", "10000"], "invalid": ["10001", "-1"]},
}

# Inline YAML with no format beyond blocking unsafe tags, so expression-like text is ordinary
# content to it.
FREE_FORM = {"codeql_config"}
# Their values legitimately span several lines.
MULTILINE = {"codeql_config", "json_format", "key_value_list", "npm_spec_list", "repository_list"}
# The action trims each item, so a block scalar's final newline is harmless. One inside is not.
OUTER_NEWLINE_OK = {"comma_key_value_list", "docker_build_contexts", "docker_secrets"}
# Validates only its leading `type=<backend>`, so what follows it is not inspected yet.
PREFIX_ONLY = {"cache_config"}
SCALAR_CHECKS = [
    "boolean",
    "calver_version",
    "dotnet_version",
    "go_version",
    "no_prefix_version",
    "node_version",
    "numeric_range_1_10",
    "positive_integer",
    "semantic_version",
    "strict_semantic_version",
    "terraform_version",
]
# A secret's example is a `${{ }}` reference, because a reader must never paste the secret
# itself. The runner expands it before validate.py runs, so the check sees the secret and
# never this text: there is nothing here to run the check against.
SECRET_CHECKS = {"github_token", "opaque_token"}


def test_every_check_is_covered():
    assert set(CASES) == set(kit.CHECKS), "every kit check must have CASES (and vice versa)"


@pytest.mark.parametrize("check", sorted(CASES))
def test_valid_values_accepted(check):
    fn = kit.CHECKS[check]
    for value in CASES[check]["valid"]:
        assert fn(value) is None, f"{check} should accept {value!r}"


@pytest.mark.parametrize("check", sorted(CASES))
def test_invalid_values_rejected(check):
    fn = kit.CHECKS[check]
    for value in CASES[check]["invalid"]:
        assert fn(value) is not None, f"{check} should reject {value!r}"


# Inputs of these types all declare a default (tests/test_spec.py), so blank only comes from a
# caller passing it, and the steps that read them then skip their work instead of failing.
REFUSES_BLANK = {"boolean", "numeric_range_1_10", "report_format", "golangci_report_format"}


@pytest.mark.parametrize("check", sorted(set(kit.CHECKS) - REFUSES_BLANK))
def test_empty_value_is_optional(check):
    assert kit.CHECKS[check]("") is None
    assert kit.CHECKS[check]("   ") is None


@pytest.mark.parametrize("check", sorted(REFUSES_BLANK))
def test_blank_value_is_refused(check):
    assert kit.CHECKS[check]("") is not None
    assert kit.CHECKS[check]("   ") is not None


def test_only_ascii_whitespace_is_blank():
    # The steps test blank with tr -d '[:space:]' in the C locale. A value of only Unicode
    # spaces is not blank there, so it has to be checked here instead of skipped.
    assert kit.common._skip(" \t\n\v\f\r")
    assert not kit.common._skip("\N{NO-BREAK SPACE}")
    assert not kit.common._skip("\x1c")
    assert kit.CHECKS["docker_image_name"]("\N{NO-BREAK SPACE}") is not None


def test_the_public_blank_rule_is_the_one_the_checks_use():
    # The test harness imports is_blank; the generated validators inline _skip.
    assert kit.common.is_blank is kit.common._skip


def test_every_kit_module_is_gathered():
    # A module left out of MODULES would leave its checks out of CHECKS and its helpers out of
    # the validators, with nothing failing to say so.
    modules = {info.name for info in pkgutil.iter_modules(kit.__path__)}
    assert modules == {module.__name__.rpartition(".")[2] for module in kit.MODULES}


def test_each_check_is_defined_in_one_module():
    # CHECKS is a dict, so of two modules defining one check name it would keep only one.
    names = [
        name
        for module in kit.MODULES
        for name, function in vars(module).items()
        if name.startswith("check_")
        and inspect.isfunction(function)
        and function.__module__ == module.__name__
    ]
    assert sorted(names) == sorted(f"check_{check}" for check in kit.CHECKS)


@pytest.mark.parametrize("check", ["boolean", "numeric_range_1_10", "positive_integer"])
def test_version_shaped_values_are_refused(check):
    # These are compared or counted in shell, so neither SemVer form means anything to them.
    assert kit.CHECKS[check]("1.0.0-rc.1") is not None
    assert kit.CHECKS[check]("1.0.0+build") is not None


@pytest.mark.parametrize(
    "value",
    ["${{ inputs.whatever }}", "${{ x }}\nkey=value", "${{ env.X }}/../etc/passwd"],
)
@pytest.mark.parametrize("check", sorted(set(kit.CHECKS) - FREE_FORM))
def test_literal_expression_is_rejected(check, value):
    # validate.py reads INPUT_* after the runner has expanded the input, so a `${{` still
    # present is data from the caller, never a reference waiting to be resolved.
    assert kit.CHECKS[check](value) is not None


@pytest.mark.parametrize(
    "check", sorted(set(kit.CHECKS) - MULTILINE - PREFIX_ONLY - OUTER_NEWLINE_OK)
)
def test_single_line_checks_reject_newlines(check):
    fn = kit.CHECKS[check]
    value = CASES[check]["valid"][0]
    for bad in (value + "\n", "\n" + value, value + "\nkey=value", value + ",\n" + value):
        assert fn(bad) is not None, f"{check} should reject {bad!r}"


@pytest.mark.parametrize("check", sorted(OUTER_NEWLINE_OK))
def test_outer_newline_is_accepted_but_an_inner_one_is_not(check):
    fn = kit.CHECKS[check]
    value = CASES[check]["valid"][0]
    assert fn(value + "\n") is None
    assert fn("\n" + value) is None
    assert fn(value + "\nkey=value") is not None


# Python's \d matches any Unicode digit; the tools these values reach read only ASCII ones.
NON_ASCII_DIGITS = str.maketrans("0123456789", "٠١٢٣٤٥٦٧٨٩")


@pytest.mark.parametrize("check", SCALAR_CHECKS)
def test_scalar_checks_reject_non_ascii_digits(check):
    fn = kit.CHECKS[check]
    for value in CASES[check]["valid"]:
        translated = value.translate(NON_ASCII_DIGITS)
        if translated != value:
            assert fn(translated) is not None, f"{check} should reject {translated!r}"


@pytest.mark.parametrize("check", SCALAR_CHECKS)
def test_scalar_checks_judge_the_value_as_given(check):
    # the action uses the raw input, so a check must not trim it before judging it
    fn = kit.CHECKS[check]
    value = CASES[check]["valid"][0]
    assert fn(" " + value) is not None
    assert fn(value + " ") is not None


@pytest.mark.parametrize("value", ["+5", "1_0", "٣", "5\n", "1" * 5000])
@pytest.mark.parametrize("check", ["positive_integer", "numeric_range_1_10", "numeric_range_1_100"])
def test_integer_checks_accept_only_ascii_digits(check, value):
    assert kit.CHECKS[check](value) is not None


# The expansion is iterative: deep nesting gets a reason, not a RecursionError traceback.
def test_path_list_reasons_about_deeply_nested_braces():
    assert kit.paths.check_path_list("{" * 2000 + "a" + "}" * 2000) is None
    assert kit.paths.check_path_list("{" * 2000 + "/a" + "}" * 2000) is not None


# Each expansion reads a run of unclosed braces once. Rescanning the rest of the text from each
# of them took about a billion character visits for this input; one pass takes a fraction of a
# second, so the bound only catches that.
def test_path_list_reads_unclosed_braces_once():
    started = time.perf_counter()
    assert kit.paths.check_path_list("{" * 2000 + "a" + "}" * 1000) is None
    assert time.perf_counter() - started < 10


# An unclosed or unmatched brace stays literal, wherever it is, and the closed groups around it
# still expand.
@pytest.mark.parametrize(
    ("item", "expansions"),
    [
        ("{a,{b}", ["{a,b"]),
        ("{{a,b}", ["{a", "{b"]),
        ("a}{b,c}", ["a}b", "a}c"]),
        ("{a,b", ["{a,b"]),
        ("}{a,b}{", ["}a{", "}b{"]),
    ],
)
def test_brace_expansions_keep_unbalanced_braces_literal(item, expansions):
    expanded = kit.paths._brace_expansions(item)
    assert expanded is not None
    assert sorted(expanded) == expansions


@pytest.mark.parametrize(
    ("check", "value", "accepted"),
    [
        ("semantic_version", "1.0.0-rc.1", True),
        ("semantic_version", "1.0.0+build", True),
        ("strict_semantic_version", "1.0.0-rc.1", True),
        ("strict_semantic_version", "1.0.0+build", True),
        ("no_prefix_version", "1.0.0-rc.1", True),
        ("no_prefix_version", "1.0.0+build", True),
        ("terraform_version", "1.0.0-rc.1", True),
        ("terraform_version", "1.0.0+build", False),
        ("dotnet_version", "8.0.100-rc.1", True),
        ("dotnet_version", "8.0.100+build", False),
        ("calver_version", "v2025.04.05-rc.1", False),
        ("calver_version", "2025.4.5+sha.abc1234", False),
    ],
)
def test_version_suffixes_match_the_whole_value(check, value, accepted):
    fn = kit.CHECKS[check]
    assert (fn(value) is None) is accepted
    assert fn(value + "\n") is not None


def test_token_rejects_partial_prefix_only():
    assert kit.tokens.check_github_token("ghp_") is not None
    assert kit.tokens.check_github_token("github_pat_") is not None


def test_calver_rejects_impossible_dates():
    check = kit.versions.check_calver_version
    assert check("2025.02.30") is not None  # Feb 30
    assert check("2024.02.29") is None  # 2024 is a leap year
    assert check("2025.02.29") is not None  # 2025 is not
    assert check("2000.02.29") is None  # a century divisible by 400 is a leap year
    assert check("2100.02.29") is not None  # one divisible only by 100 is not
    assert check("24.02.29") is None  # YY reads as 20YY
    assert check("2025.04.31") is not None  # April has 30 days
    assert check("2025.04.30") is None
    assert check("2025.01.31") is None


def test_semver_prerelease_and_build_metadata():
    assert kit.versions.check_semantic_version("1.0.0-rc.1") is None
    assert kit.versions.check_semantic_version("2.0.0-rc.1+build.1") is None
    assert kit.versions.check_semantic_version("1.0.0-") is not None


@pytest.mark.parametrize(
    "value",
    [
        "1.0.0-rc.1",
        "v1.0.0-rc.1",
        "v2025.04.05-rc.1",
        "1.0.0+build",
        "v1.0.0+build",
        "2025.4.5+sha.abc1234",
        "v1.0.0-rc.1+build.7",
    ],
)
def test_strict_semver_prerelease_and_build_metadata(value):
    assert kit.versions.check_strict_semantic_version(value) is None


def test_docker_tag_list_prerelease_and_build_metadata():
    # `-` is legal in a Docker tag and `+` is not, so the two SemVer suffixes part ways here
    assert kit.docker.check_docker_tag_list("1.0.0-rc.1") is None
    assert kit.docker.check_docker_tag_list("latest,v2025.04.05-rc.1") is None
    assert kit.docker.check_docker_tag_list("1.0.0+build") is not None
    assert kit.docker.check_docker_tag_list("latest,2025.4.5+sha.abc1234") is not None


def test_opaque_token_refuses_line_breaks_behind_an_expression():
    # a value that merely *starts* as an expression must not carry a line to a file sink
    assert kit.tokens.check_opaque_token("${{ secrets.NPM_TOKEN }}\n") is not None
    assert kit.tokens.check_opaque_token("${{ secrets.NPM_TOKEN }}\nsecond-line") is not None
    assert kit.tokens.check_opaque_token("${{ secrets.NPM_TOKEN }}\x00") is not None


def test_opaque_token_verdicts_do_not_rely_on_the_expression_bypass(monkeypatch):
    # with `_skip` narrowed to its empty-value half, real tokens still pass, unsafe values
    # still fail, and a literal expression (which no runner resolved) no longer gets through.
    # The check reads _skip from its own module, which imports it from common.
    monkeypatch.setattr(kit.tokens, "_skip", lambda value: value.strip() == "")
    assert kit.tokens.check_opaque_token("") is None
    assert kit.tokens.check_opaque_token("   ") is None
    assert kit.tokens.check_opaque_token("npm_" + "a" * 36) is None
    assert kit.tokens.check_opaque_token("dckr_pat_" + "a" * 27) is None
    assert kit.tokens.check_opaque_token("has space") is not None
    assert kit.tokens.check_opaque_token("npm_abc\n") is not None
    assert kit.tokens.check_opaque_token("${{ secrets.NPM_TOKEN }}") is not None


# Accepted by both repository-file version rules. The forms come from what the setup
# actions and the tools themselves document: setup-go (1.25.x, 1.24.0-rc.1), go.dev
# toolchains (1.23rc1), setup-python (3.13t, 3.13-dev, 3.14t-dev), setup-dotnet (8.0.x,
# 8.0.4xx, 10.0.100-preview.1.25120.13).
DETECTED_DOTTED = [
    "8.0",
    "8.0.100",
    "3.12",
    "1.22.3",
    "8.4",
    "1.25.x",
    "1.23rc1",
    "3.13t",
    "3.13.1t",
    "3.13-dev",
    "3.14t-dev",
    "8.0.x",
    "8.0.4xx",
    "10.0.100-preview.1.25120.13",
    # pre-release and build metadata are distinct SemVer constructs; test both, and CalVer
    "1.0.0-rc.1",
    "1.0.0+build",
    "1.0.0-rc.1+build.5",
    "2025.04.05-rc.1",
    "2025.4.5+sha.abc1234",
]

# Rejected by both. `$` would accept the trailing newline; `\d` would accept the Arabic digit.
DETECTED_REJECTED = [
    "",
    " ",
    "latest",
    "v1.2.3",  # clean_version strips the prefix before the check runs
    "${{ inputs.x }}",  # no _skip gate: this is file content, not an action input
    "8.4;evil",
    "8.4&evil",
    "8.4|evil",
    "8.4`evil`",
    "8.4$(evil)",
    "8.4$IFS",
    "8.4 evil",
    "8.4\tevil",
    "8.4>evil",
    "8.4<evil",
    '8.4"evil',
    "8.4'evil",
    "8.4\\evil",
    "8.4=evil",
    "8.4/../evil",
    "8.4\n",
    "8.4\nkey=value",
    "8.4\r\nkey=value",
    "8.0\npackage-manager=evil\ninjected=1",
    "\n8.4",
    "8.4\x00",
    "٣.١٢",  # Arabic-Indic digits
    "8.0.*",
    "8.0.",
    "8..0",
    ".8.0",
    "1.0.0-",
    "1.0.0+",
    "-8.0",
    "+8.0",
]


@pytest.mark.parametrize("value", DETECTED_DOTTED)
@pytest.mark.parametrize(
    "rule", [kit.versions.is_detected_version, kit.versions.is_detected_dotnet_version]
)
def test_detected_version_rules_accept(rule, value):
    """Both rules accept the dotted forms the setup actions and the tools document."""
    assert rule(value) is True


@pytest.mark.parametrize("value", DETECTED_REJECTED)
@pytest.mark.parametrize(
    "rule", [kit.versions.is_detected_version, kit.versions.is_detected_dotnet_version]
)
def test_detected_version_rules_reject(rule, value):
    """Both rules reject blanks, prefixes, shell syntax, line breaks and malformed dots."""
    assert rule(value) is False


@pytest.mark.parametrize("value", ["8", "10", "8.x"])
def test_only_dotnet_accepts_a_bare_major(value):
    """setup-dotnet documents 8 and 8.x; the other setup actions need a minor version."""
    assert kit.versions.is_detected_dotnet_version(value) is True
    assert kit.versions.is_detected_version(value) is False


def test_detected_version_rules_are_not_input_checks():
    """They judge a version read from a repository file, not an action input.

    Most input checks accept an empty value, an optional input left blank; a detected
    version must never be empty, so these rules stay out of ``CHECKS``.
    """
    assert not any(name.startswith("is_detected") for name in kit.CHECKS)


def test_every_check_has_a_documentation_example():
    """`make docs` substitutes kit.EXAMPLES into generated READMEs; a check with no
    example would leave a generic placeholder in published documentation."""
    assert set(kit.EXAMPLES) == set(kit.CHECKS), (
        "every kit check must have an EXAMPLE (and vice versa) — see kit.EXAMPLES"
    )


def test_only_secret_examples_are_expressions():
    expressions = {check for check, value in kit.EXAMPLES.items() if value.startswith("${{")}
    assert expressions == SECRET_CHECKS


@pytest.mark.parametrize("check", sorted(set(kit.EXAMPLES) - SECRET_CHECKS))
def test_documentation_example_passes_its_own_check(check):
    """The example is published as copy-pasteable documentation, so it has to be a value
    the action would actually accept. Tightening a regex without updating its example
    fails here rather than shipping an invalid example."""
    value = kit.EXAMPLES[check]
    assert kit.CHECKS[check](value) is None, (
        f"kit.EXAMPLES[{check!r}] = {value!r} is rejected by its own check"
    )


def test_returns_are_strings_or_none():
    for check, fn in kit.CHECKS.items():
        result = fn("definitely-not-valid-%%%")
        assert result is None or isinstance(result, str), f"{check} returned {type(result)}"
