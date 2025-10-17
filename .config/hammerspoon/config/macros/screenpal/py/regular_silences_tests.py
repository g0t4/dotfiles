from regular_silences import detect_regular_silences

def test_detect_regular_silences():
    detected = detect_regular_silences("samples/timeline03a.png")

    expected = {"regular_silences": [{"x_start": 754.0, "x_end": 891.0}, {"x_start": 1450.0, "x_end": 1653.0}]} # yapf: disable

    assert detected["regular_silences"] == expected["regular_silences"]
