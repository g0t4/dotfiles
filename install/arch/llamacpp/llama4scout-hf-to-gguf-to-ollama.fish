#
# * prepare llamal.cpp tools
# FYI IIUC it uses python scripts for conversion, UNSURE if it also uses compiled executables too (hence setup that too)
cd ~/repos/github/ggml-org/llama.cpp
# see build steps for llama+CUDA in sep file

uv venv # create venv (not sync though)

# had to install a few packages that resolver didn't wanna do... even though the packages meet the criteria?!
uv pip install numpy==1.26.4
uv pip install requests==2.32.3

# then, can install request in one go:
uv pip install -r requirements.txt

# * download model from huggingface
# signup for gated access to llama4 models (DONE)
#
# download the model
huggingface-cli download meta-llama/Llama-4-Scout-17B-16E-Instruct --local-dir /evo/converts/llama4-hf/llama4-scout
# basically clones the repo
# 200 GB!

# * hf => gguf (not yet quantized)
# ** docs: https://github.com/ggml-org/llama.cpp/blob/master/examples/quantize/README.md
#
# FAILs... not yet suppported... not surprising.. now I am ready for when it is ready!
# FYI should detect bfloat16 (check output to be sure)
python3 convert_hf_to_gguf.py --outfile /evo/converts/llama4-gguf/llama4scout.gguf /evo/converts/llama4-hf/llama4-scout
# INFO:hf-to-gguf:Loading model: llama4-scout
# ERROR:hf-to-gguf:Model Llama4ForConditionalGeneration is not supported
#
# ALTERNATIVES:
# FYI mentioned in llama.cpp README:
#   https://github.com/akx/ggify
#   clone it, cd:
#   source venv for llama.cpp
#   pip install -e .
# FYI hf space to do the conversion
#   https://huggingface.co/spaces/ggml-org/gguf-my-repo
#

# *** TODO quantize it next
./quantize /evo/converts/llama4-gguf/llama4scout.gguf /evo/converts/llama4-gguf/llama4scout.Q8_0.gguf Q8_0
# TODO try Q4_K_M too
#

# *** ollama Modelfile/metadata
# make modelfile to import it to ollama
#  might need to specify some params like special tokens
#  check for ollama llama4 support
#  I suspect llama4 will be supported soon and I can just download from ollama.com/library... would be nice to do a conversion myself but I can't do much with that if the tools still don't support the newer model arch!
