"""Kubernetes, K3s, K3d, Minikube, and Helm abbreviations."""

from xonsh.built_ins import XSH

aliases = XSH.aliases

from wes_kubernetes_abbreviations import (
    FISH_FUNCTIONS,
    register_wes_kubernetes_abbreviations,
)
from wes_fish_migration import wrap_fish_functions


$KUBECTL_EXTERNAL_DIFF = "icdiff -r"
register_wes_kubernetes_abbreviations()
wrap_fish_functions(aliases, FISH_FUNCTIONS)


# TODO SKIPPED_MIGRATION: Fish's generated k3s and kubectl-shell completions.
