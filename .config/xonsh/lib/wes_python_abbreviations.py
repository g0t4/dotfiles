"""Python abbreviations generated from Fish python-specific.fish."""

from __future__ import annotations

from wes_abbreviations import AbbreviationRegistry, abbr
from wes_misc_abbreviation_bridge import fish_abbreviation, platform_abbreviation


FISH_FUNCTIONS = (
    'relative_path',  # Fish line 35
    'venv_status',  # Fish line 47
    'uv_add',  # Fish line 68
    'uv_remove',  # Fish line 100
    'uv_reinstall_package',  # Fish line 113
    'pstree_grep',  # Fish line 175
    'detect_encoding',  # Fish line 181
    'wcl',  # Fish line 188
    'wrc',  # Fish line 228
    'rich_colors',  # Fish line 234
    'rich_emoji',  # Fish line 239
    'matplotlib_colors',  # Fish line 244
    'apply_patch_multi',  # Fish line 255
    '__ptw_one',  # Fish line 286
)


def register_python_abbreviations(registry: AbbreviationRegistry):
    abbr(registry, 'py_profile_import_time', 'PYTHONPROFILEIMPORTTIME=1 python -c "from sentence_transformers import SentenceTransformer"')  # Fish line 7
    abbr(registry, 'ipy', 'ipython3')  # Fish line 15
    abbr(registry, 'py', 'ipython3')  # Fish line 16
    abbr(registry, 'pyt', 'python3')  # Fish line 18
    abbr(registry, 'pyth', 'python3')  # Fish line 19
    abbr(registry, 'pytho', 'python3')  # Fish line 20
    abbr(registry, 'python', 'python3')  # Fish line 21
    abbr(registry, 'pip', 'pip3')  # Fish line 23
    abbr(registry, 'py_pgrep', 'pgrep -lf "python.*3.13.5"')  # Fish line 27
    abbr(registry, 'py_kill', platform_abbreviation('pkill -ilf "python.*3.13.5"', 'pkill -if "python.*3.13.5"'))  # Fish line 28
    abbr(registry, 've', 'python3 -m venv --clear --upgrade-deps')  # Fish line 32
    abbr(registry, 'vedir', 'echo $VIRTUAL_ENV')  # Fish line 33
    abbr(registry, 'ves', 'venv_status')  # Fish line 46
    abbr(registry, 'veinit', 'uv venv')  # Fish line 57
    abbr(registry, 'veinit12', 'uv venv --python 3.12')  # Fish line 58
    abbr(registry, 'ved', 'deactivate')  # Fish line 62
    abbr(registry, 'vea', 'source .venv*/bin/activate.xsh')  # Fish line 63
    abbr(registry, 'pipir', 'uv add -r requirements.txt && rm requirements.txt # REMINDER TO MIGRATE to pyproject.toml + uv')  # Fish line 65
    abbr(registry, 'uva', 'uv_add')  # Fish line 67
    abbr(registry, 'uvau', 'uv add --upgrade')  # Fish line 84
    abbr(registry, 'uvaup', 'uv add --upgrade-package')  # Fish line 85
    abbr(registry, 'uvl', 'uv lock')  # Fish line 89
    abbr(registry, 'uvlu', 'uv lock --upgrade')  # Fish line 90
    abbr(registry, 'uvlup', 'uv lock --upgrade-package')  # Fish line 91
    abbr(registry, 'uvlc', 'uv lock --check')  # Fish line 92
    abbr(registry, 'uvs', 'uv sync')  # Fish line 93
    abbr(registry, 'uvsa', 'uv sync --all-extras')  # Fish line 96
    abbr(registry, 'uvse', 'uv sync --extra')  # Fish line 97
    abbr(registry, 'uvrm', 'uv_remove')  # Fish line 99
    abbr(registry, 'uvr', 'uv run')  # Fish line 122
    abbr(registry, 'uvtree', 'uv tree --outdated')  # Fish line 124
    abbr(registry, 'uvv', 'uv venv')  # Fish line 125
    abbr(registry, 'uvi_bootstrap', 'uv init --no-description --no-readme && uv add yapf rope ipython rich')  # Fish line 129
    abbr(registry, 'uvi', 'uv init --no-description --no-readme')  # Fish line 132
    abbr(registry, 'uvinw', 'uv init --no-description --no-readme --no-workspace')  # Fish line 133
    abbr(registry, 'uva_common', 'uv add ipython ipykernel yapf rope rich httpx pytest pytest-watch')  # Fish line 136
    abbr(registry, 'uvi_common', 'uv init --no-description --no-readme && uv add ipython ipykernel yapf rope rich httpx pytest pytest-watch')  # Fish line 137
    abbr(registry, 'uvi_cli', 'uv init --no-description --no-readme && uv add ipython ipykernel yapf rope rich httpx pytest pytest-watch typer')  # Fish line 138
    abbr(registry, 'uvi_web', 'uv init --no-description --no-readme && uv add ipython ipykernel yapf rope rich httpx pytest pytest-watch fastapi')  # Fish line 139
    abbr(registry, 'uvp', 'uv pip')  # Fish line 143
    abbr(registry, 'uvpi', 'uv pip install')  # Fish line 144
    abbr(registry, 'uvpie', 'uv pip install --editable .')  # Fish line 145
    abbr(registry, 'uvpir', 'uv pip install -r requirements.txt')  # Fish line 146
    abbr(registry, 'uv_pip_install_upgrade', "uv pip install --upgrade $(uv pip list --outdated | tail +3 | cut -d' ' -f1)")  # Fish line 147
    abbr(registry, 'uvls', 'uv pip list')  # Fish line 148
    abbr(registry, 'uvpls', 'uv pip list')  # Fish line 149
    abbr(registry, 'uvplo', 'uv pip list --outdated')  # Fish line 150
    abbr(registry, 'uvt', 'uv tool')  # Fish line 155
    abbr(registry, 'uvtr', 'uv tool run')  # Fish line 156
    abbr(registry, 'uvtls', 'uv tool list')  # Fish line 159
    abbr(registry, 'uvti', 'uv tool install')  # Fish line 160
    abbr(registry, 'uvtup', 'uv tool upgrade --all')  # Fish line 161
    abbr(registry, 'uvtun', 'uv tool uninstall')  # Fish line 162
    abbr(registry, 'uvx', 'uv tool run')  # Fish line 163
    abbr(registry, 'uvpy', 'uv python list')  # Fish line 167
    abbr(registry, 'uv_build', 'uv build --no-sources')  # Fish line 171
    abbr(registry, 'uv_publish', 'uv publish')  # Fish line 172
    abbr(registry, 'uv_clean', 'uv clean')  # Fish line 173
    abbr(registry, 'ptw_prints', 'ptw --clear -- --capture=no --log-cli-level=INFO')  # Fish line 272
    abbr(registry, 'ptw_one', fish_abbreviation('__ptw_one'), cursor_marker="%")  # Fish line 284
    abbr(registry, 'pt', 'pytest')  # Fish line 307
    abbr(registry, 'ptc', 'pytest --collect-only')  # Fish line 308
    abbr(registry, 'ptk', 'pytest -k "%"', cursor_marker="%")  # Fish line 309
    abbr(registry, 'pytest_nocapture', 'pytest --capture=no')  # Fish line 311
    abbr(registry, 'pytest_info_logs', 'pytest --log-cli-level=INFO')  # Fish line 312
    abbr(registry, '-s', '--capture=no', position="anywhere", commands=('pytest',))  # Fish line 314
