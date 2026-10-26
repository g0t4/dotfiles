from test_setup import XONSH_LIB

import io
import subprocess
import sys

sys.path.insert(0, str(XONSH_LIB))
import wes_kgdump


def test_scope_discovery_and_filtering(monkeypatch):
    calls = []

    def run(command, **kwargs):
        calls.append(command)
        return subprocess.CompletedProcess(command, 0, "pods\nservices\n")

    monkeypatch.setattr(wes_kgdump.subprocess, "run", run)
    output = io.StringIO()
    assert wes_kgdump.kgdump(["-t", "pod"], stdout=output) == 0
    assert calls == [
        ["kubectl", "api-resources", "--verbs=list", "--namespaced=false", "-o", "name"],
        ["kubectl", "get", "--show-kind", "--ignore-not-found", "pods"],
        ["kubectl", "api-resources", "--verbs=list", "--namespaced=true", "-o", "name"],
        ["kubectl", "get", "--show-kind", "--ignore-not-found", "pods", "-A"],
    ]
    assert "NOT NAMESPACED:" in output.getvalue()


def test_namespace_skips_cluster_scope_and_preserves_failure(monkeypatch):
    calls = []

    def run(command, **kwargs):
        calls.append(command)
        return subprocess.CompletedProcess(command, 0 if "api-resources" in command else 7, "pods\n")

    monkeypatch.setattr(wes_kgdump.subprocess, "run", run)
    assert wes_kgdump.kgdump(["kube-system"], stdout=io.StringIO()) == 7
    assert len(calls) == 2
    assert "--namespaced=true" in calls[0]
    assert calls[1][-2:] == ["-n", "kube-system"]


def test_invalid_regex_does_not_run_kubectl(monkeypatch):
    def run(*args, **kwargs):
        raise AssertionError("unexpected kubectl invocation")

    monkeypatch.setattr(wes_kgdump.subprocess, "run", run)
    assert wes_kgdump.kgdump(["-t", "["], stderr=io.StringIO()) == 2
