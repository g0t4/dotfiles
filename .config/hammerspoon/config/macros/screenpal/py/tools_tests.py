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
    expected_tool = ToolResult(type="volume_add_tool", x_start=288, x_end=404)

    assert detected == expected_tool

# def test_with_cut_tool_cursor_at_end():
#     detected = detect_tools('samples/cut-tool/add-end-selected.png')
# TODO! cut tool test (at least one)

# def test_with_cut_tool_cursor_at_start():
#     detected = detect_tools('samples/cut-tool/add-start-selected.png')

def test_with_blue_shape_overlays():
    detected = detect_tools('samples/overlay/1-add-shape.png')
    print(detected)
    # left most:
    #   148/2 = 74
    # right most (edge of blue ball, even though its past edge it works)
    #   524/2 =  262
    # TODO REMOVE or FIX tool type logic, do I need tool type? not yet?
    expected_tool = ToolResult(type="volume_add_tool", x_start=74, x_end=262)
    assert detected == expected_tool

    # I can use a blue mask to find the overlay shapes
