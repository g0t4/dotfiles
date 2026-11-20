# Xonsh startup profiler TODO

## Active experiments

- Remove the Fish subprocess from every `cd` used to update the shared z database.
  A bare Fish launch costs roughly 10–20 ms before the database update itself.
- Add a native Xonsh F4 binding for the verbose-prompt toggle instead of retaining
  a wrapped Fish function that cannot mutate the parent Xonsh environment.
- Revisit `$UPDATE_OS_ENVIRON`: measure whether enabling it after rc construction
  can safely replace repeated synchronization during startup.

## Profiler improvements

- Retain raw wall-clock samples in JSON snapshots.
- Add bootstrap confidence intervals for median differences between snapshots.
- Consider a separate, explicitly stateful `cd` profiler that sandboxes z data,
  directory history, local config, and auto-venv transitions.
- Improve deep-mode dependency reporting so foundational rc omissions explain
  which later files failed, rather than recording one large stderr string.

## Scenario lifecycle

Add a temporary A/B scenario to `STARTUP_CASES` while evaluating an optimization.
Once the optimization becomes the normal configuration, remove that scenario so
the default profiler stays fast. Preserve the evidence in committed history or a
saved JSON snapshot instead of repeatedly benchmarking an already-removed cost.

## Completed wins

- Deferred xompletion discovery until the first completion request.
- Replaced recursive xompletion globbing with a pruned `os.walk`.
- Made the iTerm doctor on-demand.
- Built PATH in memory and assigned it once.
- Removed Git and Mercurial subprocesses from prompt repository resolution.
- Disabled unused xontrib autoload discovery.
- Enabled Xonsh's persistent command cache after validating cache reuse, command
  addition/removal, PATH replacement, and auto-venv behavior.
