from tools import detect_tools, ToolResult

def test_detect_tools_with_pink_volume_add_open():
    detected = detect_tools('samples/pink-volume-add-open.png')

    expected_tool = ToolResult(type="volume_add_tool", x_start=289, x_end=403)

    assert detected == expected_tool

# def test_with_cut_tool_cursor_at_end():
#     detected = detect_tools('samples/cut-tool/add-end-selected.png')

# def test_with_cut_tool_cursor_at_start():
#     detected = detect_tools('samples/cut-tool/add-start-selected.png')
