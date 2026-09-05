"""Kubernetes, K3s, K3d, Minikube, and Helm abbreviations."""

from wes_kubernetes_abbreviations import (
    FISH_FUNCTIONS,
    register_kubernetes_abbreviations,
)
from wes_misc_functions import register_misc_fish_functions


$KUBECTL_EXTERNAL_DIFF = "icdiff -r"
register_kubernetes_abbreviations()
register_misc_fish_functions(aliases, FISH_FUNCTIONS)


# TODO SKIPPED_MIGRATION: Fish's generated k3s and kubectl-shell completions.
