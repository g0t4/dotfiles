## Use `apply_patch` to edit files.

Uses a diff format that's easy to parse and apply.

*** Begin Patch
[ one or more file operations ]
*** End Patch

Each “operation” MUST start with one of three “headers”:
*** Add File: <path>
*** Delete File: <path>
*** Update File: <path>

UpdateFile may be followed by MoveTo to rename it:
*** Move to: <new_path>

Then one or more “hunks”, each introduced by @@ (optionally followed by a hunk header).

Within a hunk each line starts with:
+ for inserted text,
- for removed text, or
  space (" ") for context (unchanged lines to match)

At the end of a truncated hunk you can emit:
*** End of File

### Here is the grammar:

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

### A patch can combine operations:

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

### Reminders

Prefer commands for simple edits:
- `rm foo.json` to delete
- `mv foo.json bar.json` to rename


Tips on a failure:
- Split bigger patches into smaller patches
- Watch out for whitespace differences

### More exmaples

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
