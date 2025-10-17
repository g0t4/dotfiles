from short_silences import detect_short_silences

def test_detect_short_silences():
    detected = detect_short_silences("samples/playhead-darkblue1.png")

    expected = {
        "short_silences": [
            {"x_start": 4, "x_end": 5.5},
            {"x_start": 31, "x_end": 32.5},
            {"x_start": 217, "x_end": 218.5},
            {"x_start": 319, "x_end": 320.5},
            {"x_start": 376, "x_end": 378},
            {"x_start": 403, "x_end": 404.5},
            {"x_start": 703, "x_end": 743.5},
            {"x_start": 1024, "x_end": 1025.5},
            {"x_start": 1228, "x_end": 1229.5},
            {"x_start": 1423, "x_end": 1464},
            {"x_start": 1561, "x_end": 1562.5},
            {"x_start": 1741, "x_end": 1744}
        ]
    } # yapf: disable

    assert detected["short_silences"] == expected["short_silences"]
