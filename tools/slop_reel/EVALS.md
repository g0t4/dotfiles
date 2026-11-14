# Slop Reel evaluation notes and TODOs

This document tracks evaluation ideas that are not yet implemented. Keep deterministic fixtures, autonomous model behavior, human judgment, and future editing actions distinct in both traces and reporting.

## Current foundation and scope

Slop Reel currently provides playback, source-frame stepping, neighboring-frame inspection, deterministic material-change navigation, explicit `/frame` or `/frames` image questions, and agent-selected frames through the read-only `inspect_video` tool (current frame, frame/time ranges, paginated material changes). Chat has no autonomous playback controls. Changed-frame tool results include measured brightness; evals should distinguish measurement-assisted detection from visual-only model judgments. It receives individual JPEGs capped at 640 pixels on the longest edge, not source-resolution images, audio, or an encoded video. The waveform is a playback aid, not model input. Audio, synchronized audiovisual analysis, localization tools, cut previews, and editing below are future work.

The change index is an in-memory list of threshold-crossing transitions rebuilt for each window; it is not a semantic scene index or a persistent evaluation cache. Displayed diffs compare each frame with its immediately preceding source frame. A proposed cut needs a separate comparison between its outgoing and incoming frames, which may be far apart.

See [README.md](README.md) for implemented behavior and [NOTES.md](NOTES.md) for the broader black-frame, audio/video synchronization, model-input sizing, and ASR-timing evaluation backlog. This document expands the sensitive-content and editorial-review experiments; it does not replace that backlog. Existing fixture and player tests validate mechanics, not model detection quality.

For future eval runs, reuse the shared append-only JSONL trace format with `trace_type=slop_reel`, but save validation traces/artifacts under the sibling `~/.local/state/nvim/ask-openai/slop_reel_validation/` directory. Retain exact model-visible inputs, model/backend/settings, prompt and tool versions, preprocessing transforms, source-frame mappings, responses, failures, and human judgments. Chat already records tool calls/replies and automatically generated image observations in its message stream; `metadata.tool_observation` links those observations to call IDs. Additional eval judgments/metrics will need an explicit schema. Preserve original course clips; generated assets belong in `face2camera/slop_reel/`, as described in NOTES.md.

## On-screen sensitive-element review

Evaluate whether a vision-capable model can notice potentially sensitive elements in screenshots or video frames. Initial synthetic fixtures should include:

- a test credit-card number rendered in realistic UI context;
- profanity or other language that may need editorial review;
- dummy credentials, tokens, email addresses, phone numbers, and customer identifiers;
- visually similar benign controls to measure false positives;
- frames with no sensitive elements so that abstaining is a scored behavior.

Use synthetic values only. Record the model's classification, rationale, confidence or uncertainty, and the exact fixture/frame identifier. Score detection separately from localization:

- sensitivity detection: precision, recall, false-positive rate, and false-negative rate by category;
- calibration: whether uncertainty rises for ambiguous or partially obscured content;
- consistency: repeated runs, layout changes, scale changes, and distractors;
- context judgment: whether the model distinguishes a harmless test value from a plausible disclosure without claiming certainty it does not have.

Separate visible-content detection from the editorial decision that it needs redaction. Synthetic values are the ground truth for what is displayed, not automatically proof that a disclosure is harmless in the scenario. Define acceptable treatment per fixture, include benign lookalikes and disclosure-relevant contexts, and allow “context insufficient.” Treat model-reported confidence as a prediction to validate against outcomes, not a calibrated probability by default. Define whether metrics count elements, frames, or temporal events; deduplicate repeated sightings when reporting event-level results.

Measure media-selection recall separately from model recall on supplied frames. A change threshold or sparse sampling can omit a small sensitive element; inspect the first source frame explicitly because it has no preceding-frame change event. Compare full-frame, higher-resolution, and cropped inputs before assuming the current 640-pixel chat attachments preserve readable text. Accept flexible answer wording while scoring category, count, and localization against explicit tolerances.

## Next step: Locate Anything tool calls

TODO: investigate and integrate **Locate Anything** (or another localization tool) so the reviewer model can request a region after it identifies an element worth reviewing. No such integration exists in Slop Reel today; verify the intended tool's interface and point/box/mask support before designing the binding. The tool should return coordinates or a region for the requested visual concept.

Evaluate the complete reviewer loop without assuming that detection implies accurate localization:

1. The model reviews a frame and identifies a potentially sensitive element.
2. The model describes what it wants localized and why.
3. The harness invokes Locate Anything with that model-authored request.
4. The returned point, box, or mask is recorded with the model action.
5. The reviewer UI highlights the region without changing the underlying source.
6. A human quickly confirms, rejects, or reclassifies the proposed sensitivity.

Localization scoring should include point-in-ground-truth-region accuracy, box intersection-over-union where available, wrong-instance selection when several similar elements exist, and coverage across multiple sensitive elements in one frame. Also test the failure modes independently: correct sensitivity with wrong coordinates, correct coordinates with wrong sensitivity, incomplete coverage, and unnecessary highlights.

Every result must identify its source frame and coordinate space: normalized or pixel coordinates, input dimensions, and the resize/crop/padding transform back to the source. Keep original, model-input, tool-input, and UI-preview geometry distinct. Score localization in a declared common space, and verify overlays land on the corresponding source content. Mask outputs need mask-specific overlap/coverage metrics rather than box IoU alone.

## Reviewer experience

TODO: use Locate Anything results as non-destructive visual annotations in the reviewer so a person can rapidly judge sensitivity. Preserve:

- the original frame;
- the highlighted review overlay;
- category, rationale, and uncertainty;
- model and tool-call trace;
- human accept/reject/reclassify decision;
- timing for detection, localization, and human review.

This human-in-the-loop workflow is useful before automatic editing exists and provides labeled evidence for improving the eval.

## Longer-term video-editor integration

Deferred integration idea: pass approved coordinates or masks into a video editor to blur, cover, track, or remove sensitive content across frames. Slop Reel currently reviews media and does not edit or export it. Whether editing belongs here or in a separate project remains open. When ideas or code are shared between reviewing and editing, retain an explicit boundary:

- reviewer proposes and highlights;
- human authorizes the editorial decision;
- editor performs a reversible edit;
- exported media is verified independently from the detection/localization score.

Future temporal evals should measure tracking stability, missed frames, excessive redaction, scene-cut behavior, and whether removing an element damages nearby legitimate content.

## Best jump-cut point

TODO: add a review mode where the user marks a mistake or unwanted interval and asks, “What is the most imperceptible jump cut I can make here?” The output should be a proposed outgoing frame and incoming frame, timestamps, a previewable cut, and an explanation of the tradeoffs. A proposal is not an edit until the user accepts it.

Start with the cached changed-frame index rather than fixed-rate sampling. For each plausible before/after pair near the marked interval, provide either the model or an algorithmic scorer with:

- representative changed frames and timestamps;
- a visual diff or heat map between candidate boundary frames;
- changed-region boxes and overall diff magnitude;
- how long each visual state persists;
- optional neighboring frames to reveal motion direction;
- later experiments with aligned transcript, silence, audio waveform, and sentence boundaries.

Changed frames alone may be sufficient for screen recordings where the best cut preserves the same slide, window layout, cursor position, camera framing, or presenter pose. Test that hypothesis before adding richer context.

### Two-dimensional boundary search

Do not reduce the task to choosing one fixed cut timestamp. Treat it as a constrained search over both ends of the removed range:

- `t_out`: the last retained moment before the cut;
- `t_in`: the first retained moment after the cut;
- remove the open interval between them;
- require the removed interval to cover the complete mistake selected by the user or inferred by the reviewer.

These are conceptual boundaries. Store proposals as zero-based source-frame indices plus source presentation timestamps, including nonzero starts and variable frame intervals. For rendering, define the exact retained ranges: retain through outgoing frame `i` and resume at incoming frame `j`, removing frames `i+1` through `j-1`. The last retained frame has a display duration; its PTS alone is not the end of the retained segment. Map audio boundaries onto the same presentation timeline and test sync independently. Avoid deriving exact source positions from nominal FPS.

The user may provide only a rough “I messed up here” region. The agent can add semantic structure around it:

- clean lead-in before the mistake;
- the false start, error, pause, or unwanted action;
- retake 1 and its usable start;
- retake 2 and its usable start;
- later complete retakes or a return to the intended workflow.

For spoken mistakes, this segmentation requires human labels or validated transcript/audio input. The current image-only chat cannot establish which words were spoken or whether a retake is semantically complete. An initial visual-only experiment should use human-marked valid regions and report that limitation.

Each retake creates a possible incoming search region rather than one prescribed frame. The outgoing boundary is also free to move within the last semantically valid portion of the lead-in. The optimizer should evaluate pairs `(t_out, t_in)` across those regions and find the least perceptible transition that still removes the unwanted material. This lets it discover, for example, that trimming slightly earlier before the mistake and entering halfway into retake 2 produces a much smaller visual discontinuity than cutting exactly where the speaker stopped and restarted.

Use the changed-frame index for coarse candidate generation, not as a hard restriction on the final boundary. After finding promising changed-state pairs, refine around each candidate at frame-level resolution so either endpoint can land between indexed changes. For a large candidate matrix, precompute frame embeddings or perceptual hashes and use nearest-neighbor search to avoid comparing every possible pair exhaustively.

The objective should retain separate components rather than hiding everything in one unexplained score:

`score(t_out, t_in) = visual_discontinuity + motion_discontinuity + audio_discontinuity + semantic_penalty + removal_penalty`

This is a schematic objective, not a directly comparable sum of raw measurements. Declare normalization, weights, and which signals were available; do not score missing audio as perfect continuity. Enforce coverage of the marked mistake and any protected content as hard constraints before ranking feasible pairs. Report human boundary distance as a secondary measure: several different cuts may be equally acceptable.

Return a small Pareto-style set when objectives conflict: the visually smoothest cut, the most semantically complete cut, and a balanced recommendation. Always include the exact removed interval and which mistake/retake segmentation justified it.

Important failure cases include selecting an incoming frame from a failed retake, leaving part of the mistake in place, deleting useful instruction before the mistake, matching two visually similar but semantically different states, and choosing a beautiful still-frame match that produces an obvious motion or audio discontinuity during playback.

### Semantic change tolerance

The agent should contribute knowledge about **what is allowed to vary and what must remain continuous** for a particular cut. The amount of pixel change is not an objective measure of edit quality.

For a talking-head recording, a tiny change around the mouth, eyes, hands, or head angle may be highly noticeable because viewers track the presenter. A larger low-frequency change in background bokeh, exposure, or camera focus may be harmless. Conversely, a deliberate full-scene change, slide transition, camera-angle change, or completed UI navigation can provide a natural cut boundary even though its raw diff is enormous.

The agent can label regions and transitions by editorial salience:

- **must remain continuous:** mouth shape around speech, eye line, head pose, hand gesture, cursor trajectory, active selection, partially completed typing, and ongoing animation;
- **usually tolerant:** minor bokeh movement, subtle focus breathing, sensor noise, compression changes, small lighting drift, and background motion that does not attract attention;
- **natural discontinuity:** a completed sentence, purposeful pause, slide change, scene change, camera cut, window switch, completed command, or stable UI state transition;
- **context dependent:** scroll position, zoom level, presenter posture, and cursor position, depending on what the viewer is expected to follow.

These labels should modify or rerank algorithmic candidates, not silently replace measured signals. A useful hybrid score applies semantic region weights and transition bonuses to the underlying visual, motion, and audio differences. Preserve those weights in the trace so the reviewer can see why a numerically larger diff outranked a smaller one.

Treat these categories as context-dependent hypotheses, not universal editing rules. A completed command or sentence may still be mid-gesture, and a mouth-shape change can be acceptable across a deliberate camera cut. Validate them through short rendered previews and human ratings.

The model may use Locate Anything or another region detector to identify the presenter's face, mouth, hands, cursor, active UI control, or other attention-critical regions. Evaluate whether those semantic masks improve human-rated cuts over uniform full-frame comparison.

Add counterexample fixtures where:

- the lowest whole-frame diff contains a conspicuous mouth or head jump;
- a focus adjustment creates a large background diff but an acceptable cut;
- a large scene transition is preferred over a nearly matching mid-gesture frame;
- two visually similar frames represent different semantic states;
- a slightly larger visual change preserves complete speech or action while the minimum-diff cut truncates it.

### Algorithmic baseline

This may be substantially algorithmic. Build a deterministic baseline that ranks candidate frame pairs by a weighted discontinuity score, then compare model ranking against it. Candidate signals include:

- perceptual image distance, both full-frame and within changed regions;
- structural similarity of stable background regions;
- cursor position, selection, scroll position, and UI-state continuity;
- presenter face, pose, gaze, and framing when a camera is present;
- motion direction and velocity on either side of the cut;
- cut duration and distance from the user-marked mistake;
- eventually, audio energy, zero crossings, word boundaries, and room-tone continuity.

The existing index accelerates navigation among transitions detected at the current fixed threshold. It stores scores only for detected changes, not all frame pairs, decoded pixels, masks, or semantic stable states. Lowering the threshold therefore needs another scan or a new cache of per-frame measurements; changing pixel-delta, blur, or resolution also requires recomputing image differences. Coarse candidate generation followed by local frame-level refinement remains useful, but threshold sweeps are not already cheap merely because an index exists.

### Model-assisted mode

Evaluate whether a vision model can improve on the deterministic ranking by recognizing semantic continuity that a pixel score misses. The model may select from bounded candidates, request a finer neighborhood around one candidate, or abstain when every available cut is visibly bad. It should not invent frame timestamps or claim imperceptibility without a rendered preview and human judgment.

Compare at least these conditions:

1. algorithmic scorer using changed frames and pairwise diffs;
2. model using changed frames only;
3. model using changed frames plus diff overlays;
4. model or hybrid scorer with local neighboring frames;
5. later, multimodal scoring with transcript and audio context.

### Evaluation and reviewer workflow

Use deliberately recorded mistakes with several plausible cut points and retain the unedited source. Score:

- human-rated visual noticeability of the rendered cut;
- audio noticeability when audio is included;
- semantic completeness before and after the cut;
- distance from a human editor's preferred boundaries;
- whether the proposal removes the full marked mistake without removing useful material;
- time saved compared with manually scrubbing for boundaries;
- calibration and useful abstention when no good cut exists.

The reviewer should be able to arrow through ranked proposals, toggle the pairwise diff, loop a short before/after preview, and accept or reject a proposal. Preserve candidate scores, model/tool traces, threshold level, human selection, and final rendered verification so a fast-feeling suggestion is not confused with an actually imperceptible edit.

## Open design questions

- Which sensitivity categories are fixed policy versus reviewer-configurable?
- Should Locate Anything receive the raw frame, a cropped frame, or both?
- How should multiple matches and uncertain matches be represented?
- What confidence threshold should trigger a highlight rather than an abstention?
- Which human decisions become ground truth, and how are reviewer disagreements retained?
- How do we prevent fixture text or tool descriptions from leaking the expected answer to the model?
- How wide should the search window be around a user-marked mistake?
- Which visual-diff signals generalize across slides, terminals, GUI demonstrations, and talking-head footage?
- Which regions should be weighted by fixed heuristics, detected automatically, or labeled by the agent?
- When should a major scene change receive a cut-boundary bonus rather than a discontinuity penalty?
- Should the model choose timestamps directly or only rerank candidates produced by the algorithm?
- What human rating protocol best distinguishes “acceptable,” “noticeable but harmless,” and “disruptive” cuts?
