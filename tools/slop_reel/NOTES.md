# Slop Reel: direction and experiments

The goal is a collaborative review tool: watch a recording, inspect exact frames
around a suspected problem, and ask an assistant about supplied media. Eventually
ask “find the black frame” or “which word did I stumble on?” without repeatedly
replaying the same passage. Playback/frame zoom is useful independently of AI.

## POC boundary

Implemented first: native split player/chat, waveform, accurate bidirectional
stepping, seven-frame popup, explicit `/frame` and `/frames` image questions,
private voiced dictation, and read-only agent-selected frame/time/change inspection.
No audio attachment, autonomous player tools, timeline editing, or model-driven
whole-video scanning yet. A proposed `/clip [question]` would capture a default
one-second interval centered on the playhead, clamped to the source bounds.
Audio and video tracks may need separate request parts with explicit timing labels.
Do not infer synchronized understanding merely from acceptance of both parts.

## Backend and model findings (2026-11-13)

- The live `build21.lan:8011/v1/models` advertises
  `ggml-org/gemma-4-E4B-it-GGUF:Q8_0` with text/image/audio/video input and text output.
  User service `gemma-4-e4b-it.service` uses llama-server, Jinja, flash attention,
  CUDA device 0, and automatic Hugging Face projector loading. Keep it for this POC.
- A real 640-pixel course frame was successfully described: server reported about
  54 ms prompt processing and 126 ms generation for 25 tokens. This is one warmup
  observation, not a benchmark or a comparison against another backend.
- [llama.cpp multimodal documentation](https://github.com/ggml-org/llama.cpp/blob/master/docs/multimodal.md)
  supports image, audio and video input. [Server request documentation](https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md)
  documents `image_url`, `input_audio` and `input_video`. Audio accepts mp3/wav/flac;
  this is not a reason to migrate to vLLM/SGLang for image questions.
- An additional one-second WAV request using `input_audio` returned HTTP 200,
  but the model claimed no audio was present (in reasoning, without a final answer).
  Audio understanding remains unverified; inspect actual server parsing/projector
  behavior before treating API acceptance as successful audio support.
- [Gemma 4 model card](https://huggingface.co/google/gemma-4-E4B) lists E4B audio
  support, image/video understanding, image-before-question and audio-after-question
  ordering recommendations, and visual-token budgets. It describes up to 30 seconds
  of audio and 60 seconds of video at one frame/second. These are model-card guidance,
  not validated optimal settings for these recordings or this backend.
- Bookmark [LiquidAI/LFM3-Omni-2B](https://huggingface.co/LiquidAI/LFM3-Omni-2B): its
  model card explicitly claims joint understanding of video and its soundtrack.
  Validate that claim with timing-sensitive tests rather than general summaries.
- Other candidate endpoints/models: Muse Glimmer 30B and DeepSeek v4 Flash Vision
  Experimental. Confirm exact deployment IDs/capabilities before enabling them.
- Compare backends only against the same prompts, sampling, model weights/precision
  and media. Measure preprocessing, prompt processing, first token, generation,
  memory, throughput, quality and timing accuracy. If a replacement proves better,
  use a new user-service name including the backend, retaining rollback configuration.

## Capability questions

1. Does the model understand synchronized audio/video, or only independent tracks?
2. Can separate tracks plus timestamps recover temporal relationships?
3. What image resolutions, frame counts/rates, codecs and audio sample rates give
   the best latency/quality tradeoff? Measure rather than choosing from intuition.
4. Does it localize anomalies accurately enough to navigate the real source?

## Evaluation backlog

Keep generated ground truth separate from model-visible prompts. Log exact inputs,
answers, elapsed/server timing and source frame/time mappings. Accept flexible answer
wording; score observations, counts and localization with explicit tolerances.

### Video only

- One black frame: open-ended “any problems?” plus targeted detection; report source
  frame/time localization error and false positives. Ensure the frame was supplied.
- Multiple black frames: counts, missed detections, positions, false positives.
- Subtle unrelated frame: a full slide icon flashes before its entrance animation.
- Obvious unrelated frame: a visibly unrelated image interrupts the sequence.
- Separate sampling recall from understanding: sparse video sampling may never
  expose a one-frame glitch, regardless of the model's visual ability.

### Audio only

- Narration with a stumble: detection and timing.
- Transcription accuracy and word/segment timestamps.
- Timing precision when describing spoken segments.

### Audio plus video

- “When the speaker says WORD, what is their facial expression?”
- Joint summaries of on-screen events and narration.
- Deliberately shifted soundtracks, repeated words and visually similar scenes to
  distinguish synchronized grounding from plausible independent descriptions.

### Repairing ASR / Whisper word timestamps

Compare the same ground-truth utterances using:
- Waveform image plus transcript with a VL model.
- Audio plus transcript with an omni model.
- Waveform plus audio plus transcript with an omni model.

Measure whether a model can align individual words better than the original ASR,
including silence, repeated words and stumbles. Waveform amplitude alone does not
identify words; treat this as a hypothesis to test, not an assumed capability.

## Test media policy

Original course clips: `face2camera/video1/*.mp4`. Preserve them.
Generated fixtures, sliced/resampled derivatives, and future downloaded test assets:
`/Users/wesdemos/FCT Dropbox/Wes Higbee/Sync/auto-edit-videos/face2camera/slop_reel/`.
Keep provenance and exact ground truth alongside future eval assets. No outside
media downloads are needed for the initial checks.
