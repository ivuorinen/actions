"""sync-labels/sync.py keeps its own owner/repo pattern (it runs without _validation).

The two copies must accept exactly the same targets, so this holds them to one input set.
"""

import kit
import pytest
import sync

TARGETS = [
    "owner/repo",
    "my-org/my.repo_1",
    "a/b",
    "o1/repo-1.0.0-rc.1",
    "owner/repo+build",
    "-owner/repo",
    "--help/repo",
    "owner-/repo",
    "-/repo",
    "my_org/repo",
    "my.org/repo",
    "not-a-repo",
    "owner//repo",
    "/leading",
    "owner/repo/extra",
    "owner/",
]


@pytest.mark.parametrize("target", TARGETS)
def test_sync_and_kit_agree_on_repository_targets(target):
    kit_accepts = kit.check_repository_list(target) is None
    sync_accepts = sync._REPO.fullmatch(target) is not None
    assert kit_accepts == sync_accepts, target
