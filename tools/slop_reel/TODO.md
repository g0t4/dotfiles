# Slop Reel next steps

- macOS wrapper implemented: **Slop Reel.app**, dedicated icon, live-checkout
  alias bundle, CLI launch and Finder file-open handling. Desktop acceptance:
  confirm Dock/Spotlight launch, Open With, repeated/multiple opens and quit on
  the normal desktop session (the build session has no desktop screens or
  working Launch Services registration). See README.md for installation.
- Model-assisted change review: use a more sensitive deterministic candidate
  pass, ask a model whether each candidate is meaningful, cache judgments with
  model/prompt/input provenance. Preserve original source frame/time mapping.
- Consider a second “more sensitive” change-navigation threshold if real course
  review needs it. “Any” still needs noise tolerance; compression and subtle
  motion can change pixels even when a screen looks static.
- Review runs of 5/20/etc. source frames around a suspicious change, beyond the
  current seven-neighbor view and seven-change pages.
- See NOTES.md for multimodal/audio, timing-repair and capability-evaluation ideas.
