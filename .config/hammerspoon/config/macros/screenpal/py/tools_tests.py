from tools import detect_tools, ToolResult

# TODO test if volume edit tool range works on pink too
# TODO also revist and test perf with white dash under the tool

def test_detect_tools_with_pink_volume_add_open():
    detected = detect_tools('samples/pink-volume-add-open.png')

    # TODO revisit how well pink mask is matching ends (notably when cursor is at end/start/middle)
    #    specifically measure the range detected here and improve it if needed:
    #    I am not sure I am matching to the end fully (and need to test for other cursor positions)
    expected_tool = ToolResult(type="volume_add_tool", x_start=289, x_end=403)

    assert detected == expected_tool

# def test_with_cut_tool_cursor_at_end():
#     detected = detect_tools('samples/cut-tool/add-end-selected.png')

# def test_with_cut_tool_cursor_at_start():
#     detected = detect_tools('samples/cut-tool/add-start-selected.png')
