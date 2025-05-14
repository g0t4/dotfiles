#!/usr/bin/env fish

# appears I can use unsloth[cu128-torch270] with torch 2.7.0
uv pip install unsloth[cu128-torch270] --dry-run
#  find extras "sets" here:
#      https://pypi.org/project/unsloth/
Resolved 84 packages in 265ms
Would uninstall 3 packages
Would install 25 packages
 + accelerate==1.6.0
 + bitsandbytes==0.45.5
 + cut-cross-entropy==25.1.1
 + datasets==3.6.0
 + diffusers==0.33.1
 - dill==0.4.0
 + dill==0.3.8
 + docstring-parser==0.16
 + hf-transfer==0.1.9
 + multiprocess==0.70.16
 + pandas==2.2.3
 + peft==0.15.2
 - protobuf==5.29.4
 + protobuf==3.20.3
 + pyarrow==20.0.0
 + python-dateutil==2.9.0.post0
 + pytz==2025.2
 + shtab==1.7.2
 + trl==0.15.2
 + typeguard==4.4.2
 - typing-extensions==4.12.2
 + typing-extensions==4.13.2
 + tyro==0.9.20
 + tzdata==2025.2
 + unsloth==2025.5.2
 + unsloth-zoo==2025.5.4
 + xformers==0.0.30
 + xxhash==3.5.0

# OK so... only concern would be the protobuf drop to 3.20.3?!


# tips from someone that has unsloth working on 50 series:
#   https://github.com/unslothai/unsloth/issues/1679#issuecomment-2776622643
#   mentions... unsloth[colab-new] ??/
#    I did a dry run on it and got same deps as above for cu128-torch270
# AND unsloth[cu128onlytorch270] => no differences on dry-run either
#  must be supported now OOB?!
#  yeah in dry run,see unsloth is 2025.5.2
#    seems to match to https://github.com/unslothai/unsloth/releases/tag/May-2025
#    qwen3 rollout too
