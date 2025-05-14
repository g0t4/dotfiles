
# * using nvidia's pre-built vllm images
# add --gpus all
docker container run --gpus all -i -t --rm  nvcr.io/nvidia/tritonserver:25.02-vllm-python-py3  bash
# this will mount a ton of stuff into the container notably nvidia-smi and of course nvidia drivers and device files
#
# ok here is how to find what vllm version is included:
# https://github.com/triton-inference-server/server/releases/tag/v2.57.0
#  find corresponding release
#    so far its way outdated like 25.04 is vllm 0.8.1  whereas you need 0.8.5+ for 12.8 CUDA support
