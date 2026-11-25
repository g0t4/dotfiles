## Editing file contents with `apply_patch`

Prefer `apply_patch` for changes to file contents. For a simple file deletion or
rename, use shell commands such as `rm foo.json` or `mv foo.json bar.json`.
Choose the tool that fits the change.

`apply_patch` accepts the patch text in its `patch` argument. It uses this format:

*** Begin Patch
[ one or more file operations ]
*** End Patch

Each file operation starts with one of these headers:
*** Add File: <path>
*** Delete File: <path>
*** Update File: <path>

An Update File header may be followed by Move to when changing contents and
renaming the file together:
*** Move to: <new_path>

Then one or more “hunks”, each introduced by @@ (optionally followed by a hunk header).

Within a hunk each line starts with:
+ for inserted text,
- for removed text, or
  space (" ") for context (unchanged lines to match)

At the end of a truncated hunk you can emit:
*** End of File

Include enough unchanged context to identify the change uniquely. Use an `@@`
function or class anchor when nearby lines alone are ambiguous.

### Patch grammar

Patch := Begin { FileOp } End
Begin := "*** Begin Patch" NEWLINE
End := "*** End Patch" NEWLINE
FileOp := AddFile | DeleteFile | UpdateFile
AddFile := "*** Add File: " path NEWLINE { "+" line NEWLINE }
DeleteFile := "*** Delete File: " path NEWLINE
UpdateFile := "*** Update File: " path NEWLINE [ MoveTo ] { Hunk }
MoveTo := "*** Move to: " newPath NEWLINE
Hunk := "@@" [ header ] NEWLINE { HunkLine } [ "*** End of File" NEWLINE ]
HunkLine := (" " | "-" | "+") text NEWLINE

### Combining file operations

A patch can coordinate changes across files, including adding or deleting files:

*** Begin Patch
*** Add File: hello.txt
+Hello world
*** Update File: src/app.py
*** Move to: src/main.py
@@ def greet():
-print("Hi")
+print("Hello, world!")
*** Delete File: obsolete.txt
*** End Patch

### If a patch fails

- Inspect the current file before retrying; its contents may differ from the patch.
- Check whitespace and surrounding context.
- Split a large patch into smaller patches when that makes the failure easier to locate.

### Keeping patches focused

Here's a patch file to change the type of `win`:

```diff
*** Begin Patch
*** Update File: src/gap.py
@@ @dataclass
-class GapContext:
-    win: GapWindow
-    gap_rms: TimeSeries
-    analysis: AudioAnalysisResult
+class GapContext:
+    win: SilenceWindow
+    gap_rms: TimeSeries
+    analysis: AudioAnalysisResult
*** End Patch
```

This can be simplified to:

```diff
*** Begin Patch
*** Update File: src/gap.py
@@
-class GapContext:
-    win: GapWindow
+class GapContext:
+    win: SilenceWindow
*** End Patch
```

Or, if the `win` property is globally unique:

```diff
*** Begin Patch
*** Update File: src/gap.py
@@
-    win: GapWindow
+    win: SilenceWindow
*** End Patch
```
