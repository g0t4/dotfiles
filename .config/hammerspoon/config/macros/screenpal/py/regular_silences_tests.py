from regular_silences import detect_regular_silences

def test_detect_regular_silences():
    detected = detect_regular_silences("samples/timeline03a.png")

    expected = {"regular_silences": [{"x_start": 754, "x_end": 891}, {"x_start": 1450, "x_end": 1653}]} # yapf: disable

    assert detected["regular_silences"] == expected["regular_silences"]
