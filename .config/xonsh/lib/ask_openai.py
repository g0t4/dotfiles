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


def register_ask_openai():
    fish_funcs = (
        '_ask_write_state',
        'ask_dump_config',
        'ask_clear',
        'ask_use_anthropic',
        'ask_use_deepseek',
        'ask_use_ask_lan',
        'ask_use_inception',
        'ask_use_xai',
        'ask_use_groq',
        'ask_use_openai',
        'ask_use_lmstudio',
        'ask_use_ollama',
        'ask_use_vllm',
        'get_openai_models',
        'ask_openai',
    )
    wrap_fish_functions(XSH.aliases, fish_funcs)



