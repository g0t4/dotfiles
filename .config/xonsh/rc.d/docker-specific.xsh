"""Docker, Skopeo, and legacy Docker Hub command conveniences."""

from wes_docker import register_wes_docker

# TODO PRN remove gricfy in fish abbrs or xonsh or both?
# │ 33 │    if replacement.startswith("(grcify ") and replacement.endswith(")"):                                                           │    │
# │ 34 │        # use_grc_with_docker is explicitly "no" in the Fish source.                                                               │    │
# │ 35 │        replacement = replacement[len("(grcify ") : -1]                                                                            │    │


$DOCKER_HIDE_LEGACY_COMMANDS = "1"
register_wes_docker()


# TODO SKIPPED_MIGRATION: hub-tool hard-coded Fish completions. hub-tool v0.4.6
# has built-in `hub-tool completion fish`, but no Xonsh generator. Its upstream
# was archived 2026-05-22 and Homebrew schedules formula disablement 2026-10-08.
