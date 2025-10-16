from zoom_level import main

def test_zoom_level_1():
    result = main("samples/zoom/zoom1.png")
    assert result == {"level": 1}

def test_zoom_level_2():
    result = main("samples/zoom/zoom2.png")
    assert result == {"level": 2}

def test_zoom_level_3():
    result = main("samples/zoom/zoom3.png")
    assert result == {"level": 3}

def test_zoom_level_none():
    result = main("samples/zoom/zoom-none.png")
    assert result == {"error": "Could not detect zoom level - no blue bar found"}
