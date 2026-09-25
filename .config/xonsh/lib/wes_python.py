"""generated from Fish"""

from __future__ import annotations

import re
import os
import platform

from xonsh.built_ins import XSH
from wes_abbreviations import abbr
from wes_fish_migration import (
    wrap_fish_functions,
    abbr_from_fish_function,
    platform_abbreviation,
    unsupported_abbreviation,
)


def register_wes_python():
    fish_funcs = (
        'relative_path',
        'venv_status',
        'uv_add',
        'uv_remove',
        'uv_reinstall_package',
        'pstree_grep',
        'detect_encoding',
        'wcl',
        'wrc',
        'rich_colors',
        'rich_emoji',
        'matplotlib_colors',
        'apply_patch_multi',
        '__ptw_one',
    )
    wrap_fish_functions(XSH.aliases, fish_funcs)
    abbr('py_profile_import_time', 'PYTHONPROFILEIMPORTTIME=1 python -c from sentence_transformers import SentenceTransformer')
    abbr('ipy', 'ipython3')
    abbr('py', 'ipython3')
    abbr('pyt', 'python3')
    abbr('pyth', 'python3')
    abbr('pytho', 'python3')
    abbr('python', 'python3')
    abbr('pip', 'pip3')
    abbr('ve', 'python3 -m venv --clear --upgrade-deps')
    abbr('vedir', 'echo $VIRTUAL_ENV')
    abbr('ves', 'venv_status')
    abbr('veinit', 'uv venv')
    abbr('veinit12', 'uv venv --python 3.12')
    abbr('ved', 'deactivate')
    abbr('vea', 'source .venv*/bin/activate.fish')
    abbr('pipir', 'uv add -r requirements.txt && rm requirements.txt # REMINDER TO MIGRATE to pyproject.toml + uv')
    abbr('uva', 'uv_add')
    abbr('uvau', 'uv add --upgrade')
    abbr('uvaup', 'uv add --upgrade-package')
    abbr('uvl', 'uv lock')
    abbr('uvlu', 'uv lock --upgrade')
    abbr('uvlup', 'uv lock --upgrade-package')
    abbr('uvlc', 'uv lock --check')
    abbr('uvs', 'uv sync')
    abbr('uvsa', 'uv sync --all-extras')
    abbr('uvse', 'uv sync --extra')
    abbr('uvrm', 'uv_remove')
    abbr('uvr', 'uv run')
    abbr('uvt', 'uv tree')
    abbr('uvtree', 'uv tree --outdated')
    abbr('uvv', 'uv venv')
    abbr('uvi_bootstrap', 'uv init --no-description --no-readme && uv add yapf rope ipython rich')
    abbr('uvi', 'uv init --no-description --no-readme')
    abbr('uvinw', 'uv init --no-description --no-readme --no-workspace')
    abbr('uvp', 'uv pip')
    abbr('uvpi', 'uv pip install')
    abbr('uvpie', 'uv pip install --editable .')
    abbr('uvpir', 'uv pip install -r requirements.txt')
    abbr('uv_pip_install_upgrade', 'uv pip install --upgrade $(uv pip list --outdated | tail +3 | cut -d  -f1)')
    abbr('uvls', 'uv pip list')
    abbr('uvpls', 'uv pip list')
    abbr('uvplo', 'uv pip list --outdated')
    abbr('uvpy', 'uv python list')
    abbr('uvt', 'uv tool')
    abbr('uvtr', 'uv tool run')
    abbr('uvtls', 'uv tool list')
    abbr('uvtlso', 'uv tool list --outdated')
    abbr('uvti', 'uv tool install')
    abbr('uvtup', 'uv tool upgrade --all')
    abbr('uvtun', 'uv tool uninstall')
    abbr('uvx', 'uv tool run')
    abbr('uvpy', 'uv python list')
    abbr('uv_build', 'uv build --no-sources')
    abbr('uv_publish', 'uv publish')
    abbr('uv_clean', 'uv clean')
    abbr('ptw_prints', 'ptw --clear -- --capture=no --log-cli-level=INFO')
    abbr('ptw_one', abbr_from_fish_function('__ptw_one'))
    abbr('pt', 'pytest')
    abbr('ptc', 'pytest --collect-only')
    abbr('ptk', 'pytest -k "%"', cursor_marker="%")
    abbr('pytest_nocapture', 'pytest --capture=no')
    abbr('pytest_info_logs', 'pytest --log-cli-level=INFO')
    abbr('-s', '--capture=no', position="anywhere", commands=('pytest',))


