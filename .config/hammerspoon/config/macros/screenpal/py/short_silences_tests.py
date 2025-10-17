from short_silences import detect_short_silences

def test_detect_short_silences():
    detected = detect_short_silences("samples/playhead-darkblue1.png")

    expected = {
        "short_silences": [
            {"x_start": 4.0, "x_end": 5.5},
            {"x_start": 31.0, "x_end": 32.5},
            {"x_start": 217.0, "x_end": 218.5},
            {"x_start": 319.0, "x_end": 320.5},
            {"x_start": 376.0, "x_end": 378.0},
            {"x_start": 403.0, "x_end": 404.5},
            {"x_start": 703.0, "x_end": 743.5},
            {"x_start": 1024.0, "x_end": 1025.5},
            {"x_start": 1228.0, "x_end": 1229.5},
            {"x_start": 1423.0, "x_end": 1464.0},
            {"x_start": 1561.0, "x_end": 1562.5},
            {"x_start": 1741.0, "x_end": 1744.0},
        ]
    } # yapf: disable

    assert detected["short_silences"] == expected["short_silences"]
