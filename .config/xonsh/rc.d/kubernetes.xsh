from wes_kubernetes import register_wes_kubernetes

$KUBECTL_EXTERNAL_DIFF = "icdiff -r"
register_wes_kubernetes()

# TODO SKIPPED_MIGRATION: Fish's generated k3s and kubectl-shell completions.
