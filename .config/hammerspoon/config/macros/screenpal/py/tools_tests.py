from tools import detect_tools, ToolResult

# TODO! add masks to detect cursor when tool is open ...
#   always is 4 pixels wide (columns), solid color too
#      one exception is __SHAPE OVERLAYS__, since they are animated they use a light blue
#      - light blue and pretty constant color with extreme ends
#      - I can track that using a blue mask alone
#   remember cursor can be moved out of selection so its a third position to track (start, end, cursor)

# TODO test if volume edit tool range works on pink too
# TODO also revist and test perf with white dash under the tool

def test_detect_tools_with_pink_volume_add_open():
    detected = detect_tools('samples/pink-volume-add-open.png')

    # TODO revisit how well pink mask is matching ends (notably when cursor is at end/start/middle)
    #    specifically measure the range detected here and improve it if needed:
    #    I am not sure I am matching to the end fully (and need to test for other cursor positions)
    # max col is 810 (1-based) => 810/2 = 405 (1-based) => 404 0-based
    # min col is 577 (1-based) => 577/2 = 288.5 == 289 (1-based) => 288 0-based
    expected_tool = ToolResult(x_start=288, x_end=404)

    assert detected == expected_tool

def test_with_cut_tool_cursor_at_end():
    detected = detect_tools('samples/cut-tool/add-end-selected.png')
    # 1711 left base1 ~= 855 base0
    # 1820 right base1 = 910 base1 = 909 base0
    expected_tool = ToolResult(x_start=855, x_end=909)
    assert detected == expected_tool

def test_with_cut_tool_cursor_at_start():
    detected = detect_tools('samples/cut-tool/add-start-selected.png')
    # left 1727 base1 = 863 base0
    # right 1818 base1 = 908 base0
    expected_tool = ToolResult(x_start=863, x_end=908)
    assert detected == expected_tool

def test_with_blue_shape_overlays():
    detected = detect_tools('samples/overlay/1-add-shape.png')
    # left most:
    #   148/2 = 74
    # right most (edge of blue ball, even though its past edge it works)
    #   524/2 =  262
    expected_tool = ToolResult(x_start=74, x_end=262)
    assert detected == expected_tool

    # I can use a blue mask to find the overlay shapes
    #
    #
    #
    #

def test_freeze_frame_tool():
    detected = detect_tools('samples/freeze/1-freeze-add-cursor-on-end.png')
    # min: 247 base1(left side) => 247/2 = 123.5 (base1) = 124 (base1) => 123 (base0)
    # max: 517 base1 (right side) => 517/2 = 258.5 (base1) = 259 (base1) => 258 (base0)

    expected_tool = ToolResult(x_start=123, x_end=258)
    assert detected == expected_tool
