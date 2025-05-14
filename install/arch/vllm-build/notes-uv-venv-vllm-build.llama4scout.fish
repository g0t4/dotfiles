#!/usr/bin/env fish

# THIS TIME I GOT vllm built w/ uv! which is awesome b/c I can wipe the .venv at any time and really quickly rebuild it from scratchusing uv caches
cd "$HOME/repos/github/vllm-project/vllm-latest" || exit

if command -q trash
    trash .venv
else
    rm -rf .venv # wipe out venv to be safe
end

uv venv # since already have pyproject, create the venv but DO NOT SYNC deps
# this will use pyproject's constraints for python version and selected 3.11 last time I did this 👍
python use_existing_torch.py # do not uv run else it installs deps liseted in pyproject and fubars your venv
# !! only using uv to manage a "classic python venv",  only use `uv pip` do not do any `uv run` or `uv sync`

# now install latest torch using cu128
uv pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
# can use 2.7.0 stable now with 12.8:
# uv pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
#
# some deps
uv pip install -r requirements/build.txt
uv pip install transformers # no direct torch deps
# FYI wow took seconds to rebuild entire venv (up to this point!)... b/c of uv cache!

# FYI most cores pegged already w/o this so probably don't need MAX_JOBS
export MAX_JOBS=(nproc)
echo $MAX_JOBS
uv pip install -e . --no-build-isolation # crap forgot multicpu flag

# PRN ... if you need other deps, likely in one of these spots
# uv pip install -r requirements/common.txt ?
# uv pip install xformers --no-deps? # careful this has a dep to torch
