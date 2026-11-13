# Slop Reel next steps

- macOS application wrapper, following Pip Rot: named **Slop Reel.app**, with a
  dedicated icon, normal Dock identity, CLI launch and file-open handling. Keep
  the source project and independent uv environment; inspect Pip Rot's existing
  install/build scripts before deciding packaging details.
- Model-assisted change review: use a more sensitive deterministic candidate
  pass, ask a model whether each candidate is meaningful, cache judgments with
  model/prompt/input provenance. Preserve original source frame/time mapping.
- Consider a second “more sensitive” change-navigation threshold if real course
  review needs it. “Any” still needs noise tolerance; compression and subtle
  motion can change pixels even when a screen looks static.
- Review runs of 5/20/etc. source frames around a suspicious change, beyond the
  current seven-neighbor view and seven-change pages.
- See NOTES.md for multimodal/audio, timing-repair and capability-evaluation ideas.
