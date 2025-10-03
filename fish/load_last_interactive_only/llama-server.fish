# Fish shell completion for llama-server
# Place this file in ~/.config/fish/completions/

# Disable file completion by default
complete -c llama-server -f

# Help and version
complete -c llama-server -s h -l help -d 'Print usage and exit'
complete -c llama-server -l usage -d 'Print usage and exit'
complete -c llama-server -l version -d 'Show version and build info'
complete -c llama-server -l completion-bash -d 'Print source-able bash completion script'
complete -c llama-server -l verbose-prompt -d 'Print a verbose prompt before generation'

# Threading options
complete -c llama-server -s t -l threads -d 'Number of threads to use during generation' -r
complete -c llama-server -s tb -l threads-batch -d 'Number of threads for batch/prompt processing' -r
complete -c llama-server -s C -l cpu-mask -d 'CPU affinity mask (hex)' -r
complete -c llama-server -s Cr -l cpu-range -d 'Range of CPUs for affinity' -r
complete -c llama-server -l cpu-strict -d 'Use strict CPU placement (0|1)' -xa '0 1'
complete -c llama-server -l prio -d 'Process/thread priority' -xa 'low normal medium high realtime -1 0 1 2 3'
complete -c llama-server -l poll -d 'Polling level (0-100)' -r
complete -c llama-server -s Cb -l cpu-mask-batch -d 'CPU affinity mask for batch (hex)' -r
complete -c llama-server -s Crb -l cpu-range-batch -d 'CPU range for batch' -r
complete -c llama-server -l cpu-strict-batch -d 'Strict CPU placement for batch (0|1)' -xa '0 1'
complete -c llama-server -l prio-batch -d 'Priority for batch' -r
complete -c llama-server -l poll-batch -d 'Polling for batch (0|1)' -xa '0 1'

# Context and prediction
complete -c llama-server -s c -l ctx-size -d 'Size of the prompt context' -r
complete -c llama-server -s n -l predict -l n-predict -d 'Number of tokens to predict' -r
complete -c llama-server -s b -l batch-size -d 'Logical maximum batch size' -r
complete -c llama-server -s ub -l ubatch-size -d 'Physical maximum batch size' -r
complete -c llama-server -l keep -d 'Number of tokens to keep from initial prompt' -r
complete -c llama-server -l swa-full -d 'Use full-size SWA cache'
complete -c llama-server -l kv-unified -s kvu -d 'Use single unified KV buffer'
complete -c llama-server -s fa -l flash-attn -d 'Flash Attention use' -xa 'on off auto'
complete -c llama-server -l no-perf -d 'Disable performance timings'

# Escape sequences
complete -c llama-server -s e -l escape -d 'Process escape sequences'
complete -c llama-server -l no-escape -d 'Do not process escape sequences'

# RoPE options
complete -c llama-server -l rope-scaling -d 'RoPE frequency scaling method' -xa 'none linear yarn'
complete -c llama-server -l rope-scale -d 'RoPE context scaling factor' -r
complete -c llama-server -l rope-freq-base -d 'RoPE base frequency' -r
complete -c llama-server -l rope-freq-scale -d 'RoPE frequency scaling factor' -r

# YaRN options
complete -c llama-server -l yarn-orig-ctx -d 'YaRN: original context size' -r
complete -c llama-server -l yarn-ext-factor -d 'YaRN: extrapolation mix factor' -r
complete -c llama-server -l yarn-attn-factor -d 'YaRN: attention magnitude scale' -r
complete -c llama-server -l yarn-beta-slow -d 'YaRN: high correction dim' -r
complete -c llama-server -l yarn-beta-fast -d 'YaRN: low correction dim' -r

# KV cache options
complete -c llama-server -s nkvo -l no-kv-offload -d 'Disable KV offload'
complete -c llama-server -s nr -l no-repack -d 'Disable weight repacking'
complete -c llama-server -s ctk -l cache-type-k -d 'KV cache data type for K' -xa 'f32 f16 bf16 q8_0 q4_0 q4_1 iq4_nl q5_0 q5_1'
complete -c llama-server -s ctv -l cache-type-v -d 'KV cache data type for V' -xa 'f32 f16 bf16 q8_0 q4_0 q4_1 iq4_nl q5_0 q5_1'
complete -c llama-server -s dt -l defrag-thold -d 'KV cache defragmentation threshold (deprecated)' -r
complete -c llama-server -s np -l parallel -d 'Number of parallel sequences' -r

# Memory options
complete -c llama-server -l mlock -d 'Force system to keep model in RAM'
complete -c llama-server -l no-mmap -d 'Do not memory-map model'
complete -c llama-server -l numa -d 'NUMA optimizations' -xa 'distribute isolate numactl'

# Device/GPU options
complete -c llama-server -s dev -l device -d 'Devices to use for offloading' -r
complete -c llama-server -l list-devices -d 'List available devices and exit'
complete -c llama-server -l override-tensor -s ot -d 'Override tensor buffer type' -r
complete -c llama-server -l cpu-moe -s cmoe -d 'Keep all MoE weights in CPU'
complete -c llama-server -l n-cpu-moe -s ncmoe -d 'Keep first N MoE layers in CPU' -r
complete -c llama-server -s ngl -l gpu-layers -l n-gpu-layers -d 'Max layers to store in VRAM' -r
complete -c llama-server -s sm -l split-mode -d 'How to split model across GPUs' -xa 'none layer row'
complete -c llama-server -s ts -l tensor-split -d 'Fraction to offload to each GPU' -r
complete -c llama-server -s mg -l main-gpu -d 'GPU to use for model/intermediate results' -r
complete -c llama-server -l check-tensors -d 'Check model tensor data for invalid values'
complete -c llama-server -l override-kv -d 'Override model metadata by key' -r
complete -c llama-server -l no-op-offload -d 'Disable offloading host tensor operations'

# LoRA and control vectors
complete -c llama-server -l lora -d 'Path to LoRA adapter' -rF
complete -c llama-server -l lora-scaled -d 'Path to LoRA adapter with scaling' -rF
complete -c llama-server -l control-vector -d 'Add a control vector' -rF
complete -c llama-server -l control-vector-scaled -d 'Add control vector with scaling' -rF
complete -c llama-server -l control-vector-layer-range -d 'Layer range for control vector' -r

# Model options
complete -c llama-server -s m -l model -d 'Model path' -rF
complete -c llama-server -s mu -l model-url -d 'Model download URL' -r
complete -c llama-server -s dr -l docker-repo -d 'Docker Hub model repository' -r
complete -c llama-server -s hf -s hfr -l hf-repo -d 'Hugging Face model repository' -r
complete -c llama-server -s hfd -s hfrd -l hf-repo-draft -d 'HF repo for draft model' -r
complete -c llama-server -s hff -l hf-file -d 'Hugging Face model file' -r
complete -c llama-server -s hfv -s hfrv -l hf-repo-v -d 'HF repo for vocoder model' -r
complete -c llama-server -s hffv -l hf-file-v -d 'HF file for vocoder model' -r
complete -c llama-server -s hft -l hf-token -d 'Hugging Face access token' -r

# Logging options
complete -c llama-server -l log-disable -d 'Disable logging'
complete -c llama-server -l log-file -d 'Log to file' -rF
complete -c llama-server -l log-colors -d 'Set colored logging' -xa 'on off auto'
complete -c llama-server -s v -l verbose -l log-verbose -d 'Set verbosity to infinity'
complete -c llama-server -l offline -d 'Offline mode: use cache, prevent network access'
complete -c llama-server -s lv -l verbosity -l log-verbosity -d 'Set verbosity threshold' -r
complete -c llama-server -l log-prefix -d 'Enable prefix in log messages'
complete -c llama-server -l log-timestamps -d 'Enable timestamps in log messages'

# Draft model cache options
complete -c llama-server -s ctkd -l cache-type-k-draft -d 'KV cache type for K (draft)' -xa 'f32 f16 bf16 q8_0 q4_0 q4_1 iq4_nl q5_0 q5_1'
complete -c llama-server -s ctvd -l cache-type-v-draft -d 'KV cache type for V (draft)' -xa 'f32 f16 bf16 q8_0 q4_0 q4_1 iq4_nl q5_0 q5_1'

# Sampling parameters
complete -c llama-server -l samplers -d 'Samplers in order (semicolon-separated)' -r
complete -c llama-server -s s -l seed -d 'RNG seed' -r
complete -c llama-server -l sampling-seq -l sampler-seq -d 'Simplified sampler sequence' -r
complete -c llama-server -l ignore-eos -d 'Ignore end of stream token'
complete -c llama-server -l temp -d 'Temperature' -r
complete -c llama-server -l top-k -d 'Top-k sampling' -r
complete -c llama-server -l top-p -d 'Top-p sampling' -r
complete -c llama-server -l min-p -d 'Min-p sampling' -r
complete -c llama-server -l top-nsigma -d 'Top-n-sigma sampling' -r
complete -c llama-server -l xtc-probability -d 'XTC probability' -r
complete -c llama-server -l xtc-threshold -d 'XTC threshold' -r
complete -c llama-server -l typical -d 'Locally typical sampling' -r
complete -c llama-server -l repeat-last-n -d 'Last n tokens for penalize' -r
complete -c llama-server -l repeat-penalty -d 'Penalize repeat sequence' -r
complete -c llama-server -l presence-penalty -d 'Presence penalty' -r
complete -c llama-server -l frequency-penalty -d 'Frequency penalty' -r

# DRY sampling
complete -c llama-server -l dry-multiplier -d 'DRY sampling multiplier' -r
complete -c llama-server -l dry-base -d 'DRY sampling base value' -r
complete -c llama-server -l dry-allowed-length -d 'Allowed length for DRY sampling' -r
complete -c llama-server -l dry-penalty-last-n -d 'DRY penalty for last n tokens' -r
complete -c llama-server -l dry-sequence-breaker -d 'Sequence breaker for DRY sampling' -r

# Dynamic temperature
complete -c llama-server -l dynatemp-range -d 'Dynamic temperature range' -r
complete -c llama-server -l dynatemp-exp -d 'Dynamic temperature exponent' -r

# Mirostat
complete -c llama-server -l mirostat -d 'Mirostat sampling mode' -xa '0 1 2'
complete -c llama-server -l mirostat-lr -d 'Mirostat learning rate' -r
complete -c llama-server -l mirostat-ent -d 'Mirostat target entropy' -r

# Logit bias and grammar
complete -c llama-server -s l -l logit-bias -d 'Modify token likelihood' -r
complete -c llama-server -l grammar -d 'BNF-like grammar for generation' -r
complete -c llama-server -l grammar-file -d 'File to read grammar from' -rF
complete -c llama-server -s j -l json-schema -d 'JSON schema to constrain generations' -r
complete -c llama-server -s jf -l json-schema-file -d 'File with JSON schema' -rF

# Server-specific options
complete -c llama-server -l swa-checkpoints -d 'Max SWA checkpoints per slot' -r
complete -c llama-server -l no-context-shift -d 'Disable context shift'
complete -c llama-server -l context-shift -d 'Enable context shift'
complete -c llama-server -s r -l reverse-prompt -d 'Halt generation at prompt' -r
complete -c llama-server -s sp -l special -d 'Enable special tokens output'
complete -c llama-server -l no-warmup -d 'Skip warming up the model'
complete -c llama-server -l spm-infill -d 'Use Suffix/Prefix/Middle pattern for infill'
complete -c llama-server -l pooling -d 'Pooling type for embeddings' -xa 'none mean cls last rank'

# Batching
complete -c llama-server -s cb -l cont-batching -d 'Enable continuous batching'
complete -c llama-server -s nocb -l no-cont-batching -d 'Disable continuous batching'

# Multimodal
complete -c llama-server -l mmproj -d 'Path to multimodal projector file' -rF
complete -c llama-server -l mmproj-url -d 'URL to multimodal projector file' -r
complete -c llama-server -l no-mmproj -d 'Disable multimodal projector'
complete -c llama-server -l no-mmproj-offload -d 'Do not offload mmproj to GPU'

# Draft model options
complete -c llama-server -l override-tensor-draft -s otd -d 'Override tensor buffer type (draft)' -r
complete -c llama-server -l cpu-moe-draft -s cmoed -d 'Keep all MoE weights in CPU (draft)'
complete -c llama-server -l n-cpu-moe-draft -s ncmoed -d 'Keep first N MoE layers in CPU (draft)' -r

# Network and server options
complete -c llama-server -s a -l alias -d 'Set alias for model name' -r
complete -c llama-server -l host -d 'IP address or UNIX socket to bind' -r
complete -c llama-server -l port -d 'Port to listen on' -r
complete -c llama-server -l path -d 'Path to serve static files from' -rF
complete -c llama-server -l api-prefix -d 'Prefix path the server serves from' -r
complete -c llama-server -l no-webui -d 'Disable the Web UI'

# Server modes
complete -c llama-server -l embedding -l embeddings -d 'Restrict to embedding use case'
complete -c llama-server -l reranking -l rerank -d 'Enable reranking endpoint'

# Security
complete -c llama-server -l api-key -d 'API key for authentication' -r
complete -c llama-server -l api-key-file -d 'File containing API keys' -rF
complete -c llama-server -l ssl-key-file -d 'PEM-encoded SSL private key file' -rF
complete -c llama-server -l ssl-cert-file -d 'PEM-encoded SSL certificate file' -rF

# Advanced server options
complete -c llama-server -l chat-template-kwargs -d 'Additional params for JSON template parser' -r
complete -c llama-server -s to -l timeout -d 'Server read/write timeout (seconds)' -r
complete -c llama-server -l threads-http -d 'Threads for HTTP request processing' -r
complete -c llama-server -l cache-reuse -d 'Min chunk size for cache reuse via KV shifting' -r

# Endpoints
complete -c llama-server -l metrics -d 'Enable Prometheus metrics endpoint'
complete -c llama-server -l props -d 'Enable POST /props endpoint'
complete -c llama-server -l slots -d 'Enable slots monitoring endpoint'
complete -c llama-server -l no-slots -d 'Disable slots monitoring endpoint'
complete -c llama-server -l slot-save-path -d 'Path to save slot KV cache' -rF

# Chat template and reasoning
complete -c llama-server -l jinja -d 'Use Jinja template for chat'
complete -c llama-server -l reasoning-format -d 'Controls thought tag handling' -xa 'none deepseek auto'
complete -c llama-server -l reasoning-budget -d 'Amount of thinking allowed' -r
complete -c llama-server -l chat-template -d 'Set custom Jinja chat template' -r
complete -c llama-server -l prefix -d 'Prefix for non-chat models' -r
complete -c llama-server -l suffix -d 'Suffix for non-chat models' -r

# Speculative decoding
complete -c llama-server -s md -l model-draft -d 'Draft model for speculative decoding' -rF
complete -c llama-server -s ngld -l gpu-layers-draft -d 'Max layers to store in VRAM (draft)' -r
complete -c llama-server -l draft -d 'Number of tokens to draft for speculation' -r
complete -c llama-server -s devd -l device-draft -d 'Devices for draft model offloading' -r
complete -c llama-server -s ngl-d -l n-gpu-layers-draft -d 'Layers in VRAM for draft model' -r

# Lookup cache
complete -c llama-server -l lookup-ngram-min -d 'Min ngram size for lookup cache' -r

# System prompt
complete -c llama-server -l system-prompt -d 'System prompt for chat template' -r
complete -c llama-server -l system-prompt-file -d 'File with system prompt' -rF
