
local expected_tool_definition = [[
<|start|>developer<|message|># Instructions

foo

# Tools

## functions

namespace functions {

// Patch a file
type apply_patch = (_: string) => any;

} // namespace functions<|end|>
]]
