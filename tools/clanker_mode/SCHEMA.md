# Clanker trace format, version 1

This is the reference for readers, formatters, and agents consuming Clanker
traces. No serializer knowledge is required. Traces are JSON Lines (`.jsonl`),
encoded as UTF-8: one JSON object per newline-terminated line. Embedded newlines
in values are escaped. Records are appended, never updated in place.

## File identity and naming

One trace belongs to one Xonsh process, created on first use. Its session ID is
inside the `session` record and is independent of its filename. Renaming a file
does not change its identity. Files are created exclusively with permissions
0600, and existing files are never overwritten to resolve a filename collision.

Filenames use the shell's local start time and grow only on collision:

```text
2026-11-12_1530.jsonl
2026-11-12_1530_1.jsonl
2026-11-12_1530_1b.jsonl
2026-11-12_1531.jsonl
```

The base is `YYYY-MM-DD_HHMM`. On collision, compute microseconds elapsed within
that minute (`second * 1_000_000 + microsecond`) as seven zero-padded lowercase
hex digits. Try its prefixes from one through seven digits, using the shortest
unused filename. The suffix is chronological timestamp precision, not a hash.
The `_` separator makes an unsuffixed filename sort before its suffixed siblings
under ordinary lexicographic ordering. Earlier filenames are never renamed.

If the entire seven-digit value also collides, append `_00000001`, incrementing
that eight-digit hexadecimal counter until exclusive creation succeeds. For
example: `2026-11-12_1530_1b5a4c0_00000001.jsonl`. This fallback handles multiple
processes with exactly the same microsecond start time. Denser clusters can have
longer names; most minutes need no suffix at all.

For increasing local start times, names sort chronologically even within a
minute. Local clock changes, daylight-saving fallback, or concurrent processes
scheduled out of timestamp order can affect that ordering. Use record timestamps
and session IDs for authoritative data; filenames are a human browsing aid.

## Common envelope

Every record has:

| Field | Meaning |
| --- | --- |
| `type` | Record kind, listed below |
| `sequence` | Zero-based integer, increasing by one per record in this file |
| `timestamp` | ISO 8601 UTC event time, with timezone offset |

The first record is always `type: "version"` with `version: 1`. Its sequence is
zero. A reader should reject unsupported format versions rather than guessing.
Subsequent unknown record types or additional fields can be ignored safely by a
reader that does not need them. Physical line order and `sequence` are the event
order, even if the wall clock moves backward.

## Record types

| Type | Additional fields and meaning |
| --- | --- |
| `version` | `version`: integer format version, currently `1` |
| `session` | `session_id`: opaque string; `trace_type`: `"clanker_mode"`; `pid`: shell process ID |
| `turn_start` | `turn_id`: positive integer identifying one `clank` request |
| `message` | `turn_id`, `message`: conversation body; `metadata`: local diagnostics |
| `error` | `turn_id`, `error`: object with exception `class` and string `message` |
| `turn_end` | `turn_id`, `status`: `"success"`, `"error"`, or `"interrupted"` |
| `context_reset` | `after_turn_id`: last allocated turn ID, possibly `0` |

Turn IDs increase across context resets. A normal turn starts with `turn_start`
and ends with `turn_end`. An error record precedes an unsuccessful turn ending.
A crash can leave a turn without its end event.

### Message bodies

`message` contains conversation content, separate from trace-only metadata:

- `role`: `system`, `user`, `assistant`, or `tool`.
- `content`: text or provider-supported content blocks.
- Assistant tool calls use `tool_calls`: a list of objects with `id`,
  `type: "function"`, and `function: {name, arguments}`. `arguments` is a JSON
  **string**, not an object.
- Tool results carry `tool_call_id` matching the originating call, and an optional
  `name`. They are ordinary message records.
- Provider message extensions such as `reasoning_content` or `refusal` may appear.

`metadata` is entirely local and is never part of inference input:

| Field | Meaning |
| --- | --- |
| `finished_at` | UTC time when this message was recorded |
| `response` | Assistant's provider response metadata; keys are provider-dependent |
| `usage` | Assistant's normalized usage dictionary, or `null` if unavailable |
| `provider_message_id` | Optional provider-supplied message ID |
| `invalid_tool_calls` | Optional malformed-call diagnostics |
| `raw_tool_calls` | Original raw calls retained when malformed calls were present |
| `synthetic` | `true` for tool-result placeholders generated when a turn aborts |

There is no top-level response snapshot. Each assistant message retains its own
response and usage. Malformed calls are kept in diagnostics and excluded from
executable/replayed tool calls.

### Context and outbound input

The system message is recorded on the first turn, then held unchanged. Follow-ups
append their messages and retain prior conversation. `context_reset` clears model
context without removing any trace records. The next turn records a fresh system
message. To reconstruct the current context, collect only message records after
the latest reset (or all message records if there has been no reset).

Outbound input is constructed separately. Event envelopes and `metadata` are
never sent. `reasoning_content` from earlier turns is omitted from that input,
while remaining unchanged in the trace. The current LangChain provider also
omits reasoning on the wire within a turn. No automatic summarization or trimming
is applied. Local record timestamps do not affect the model prompt or its prefix.

If a turn aborts with pending tool calls, synthetic result messages close those
calls so the next user turn can be sent as a valid conversation. An interrupted
tool may already have changed shell state. Pending calls are not automatically
retried, and synthetic results must not be displayed as successful tool output.

## Complete example

The first turn calls a tool. A reset follows. The second turn fails before an
assistant response. Each physical line below is one record:

```jsonl
{"type":"version","sequence":0,"timestamp":"2026-11-12T21:30:00+00:00","version":1}
{"type":"session","sequence":1,"timestamp":"2026-11-12T21:30:00+00:00","session_id":"example-session","trace_type":"clanker_mode","pid":12345}
{"type":"turn_start","sequence":2,"timestamp":"2026-11-12T21:30:01+00:00","turn_id":1}
{"type":"message","sequence":3,"timestamp":"2026-11-12T21:30:01+00:00","turn_id":1,"message":{"role":"system","content":"You are Clanker Mode..."},"metadata":{"finished_at":"2026-11-12T21:30:01+00:00"}}
{"type":"message","sequence":4,"timestamp":"2026-11-12T21:30:01+00:00","turn_id":1,"message":{"role":"user","content":"What is two plus two?"},"metadata":{"finished_at":"2026-11-12T21:30:01+00:00"}}
{"type":"message","sequence":5,"timestamp":"2026-11-12T21:30:02+00:00","turn_id":1,"message":{"role":"assistant","content":"","tool_calls":[{"id":"call-1","type":"function","function":{"name":"execute_in_current_xonsh","arguments":"{\"code\": \"print(2 + 2)\"}"}}]},"metadata":{"finished_at":"2026-11-12T21:30:02+00:00","response":{"finish_reason":"tool_calls"},"usage":null}}
{"type":"message","sequence":6,"timestamp":"2026-11-12T21:30:02+00:00","turn_id":1,"message":{"role":"tool","content":"4\n","tool_call_id":"call-1","name":"execute_in_current_xonsh"},"metadata":{"finished_at":"2026-11-12T21:30:02+00:00"}}
{"type":"message","sequence":7,"timestamp":"2026-11-12T21:30:03+00:00","turn_id":1,"message":{"role":"assistant","content":"4"},"metadata":{"finished_at":"2026-11-12T21:30:03+00:00","response":{"finish_reason":"stop"},"usage":{"input_tokens":100,"output_tokens":2,"total_tokens":102}}}
{"type":"turn_end","sequence":8,"timestamp":"2026-11-12T21:30:03+00:00","turn_id":1,"status":"success"}
{"type":"context_reset","sequence":9,"timestamp":"2026-11-12T21:30:10+00:00","after_turn_id":1}
{"type":"turn_start","sequence":10,"timestamp":"2026-11-12T21:30:11+00:00","turn_id":2}
{"type":"message","sequence":11,"timestamp":"2026-11-12T21:30:11+00:00","turn_id":2,"message":{"role":"system","content":"You are Clanker Mode..."},"metadata":{"finished_at":"2026-11-12T21:30:11+00:00"}}
{"type":"message","sequence":12,"timestamp":"2026-11-12T21:30:11+00:00","turn_id":2,"message":{"role":"user","content":"Hello again"},"metadata":{"finished_at":"2026-11-12T21:30:11+00:00"}}
{"type":"error","sequence":13,"timestamp":"2026-11-12T21:30:12+00:00","turn_id":2,"error":{"class":"RuntimeError","message":"Endpoint unavailable"}}
{"type":"turn_end","sequence":14,"timestamp":"2026-11-12T21:30:12+00:00","turn_id":2,"status":"error"}
```

## Live readers and durability

`clank --trace` prints the current trace path. A viewer can follow it with
`tail -n +1 -f /path/to/trace.jsonl`. Parse only newline-terminated records; buffer
an incomplete line until more bytes arrive. After a crash, an incomplete final
line can be ignored while earlier records remain readable.

Records are flushed to the OS after each append, not fsynced after each record.
The writer has one foreground owner per shell. This is a chronological event log,
not a branching graph or an automatic restart/resume format. The running process
keeps the current model context in memory. Existing legacy traces are not migrated.
