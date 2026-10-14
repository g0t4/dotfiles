"""Apply-patch directives layered on Pygments' ordinary diff rules."""

from pygments.lexer import inherit
from pygments.lexers.diff import DiffLexer
from pygments.token import Comment, Generic


class ApplyPatchLexer(DiffLexer):
    name = "Apply Patch"
    aliases = ["apply-patch", "apply_patch"]
    filenames = []
    tokens = {
        "root": [
            (r"^\*\*\* Add File: .*$(?:\n)?", Generic.Inserted),
            (r"^\*\*\* Delete File: .*$(?:\n)?", Generic.Deleted),
            (r"^\*\*\* Update File: .*$(?:\n)?", Generic.Heading),
            (r"^\*\*\* Move to: .*$(?:\n)?", Generic.Subheading),
            (r"^\*\*\* (?:Begin Patch|End Patch|End of File)$(?:\n)?", Comment),
            inherit,
        ],
    }
