import numpy as np
from numpy._typing import NDArray
import rich
from dropped_frames import find_missing_frames

class TestMissingFrames:

    def test_negative_are_extras(self):
        timestamps: NDArray[np.float64] = np.array([-2.0, -1.0, 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]) / 30
        missing, extras = find_missing_frames(timestamps, 30, 10)
        assert missing == []
        expected_extras = np.array([-2.0, -1.0])
        np.testing.assert_array_equal(extras, expected_extras)

    def test_all_ten_present(self):
        timestamps: NDArray[np.float64] = np.array([0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]) / 30
        missing, extras = find_missing_frames(timestamps, 30, 10)
        assert missing == []
        assert extras == []

    def test_one_of_ten_is_missing(self):
        timestamps: NDArray[np.float64] = np.array([0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 8.0, 9.0]) / 30
        missing, extras = find_missing_frames(timestamps, 30, 10)
        assert missing == [7]
        assert extras == []

    def test_two_in_a_row_are_missing(self):
        timestamps: NDArray[np.float64] = np.array([0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 8.0, 9.0]) / 30
        missing, extras = find_missing_frames(timestamps, 30, 10)
        assert missing == [6.0, 7.0]
        assert extras == []

    def test_first_missing(self):
        timestamps: NDArray[np.float64] = np.array([2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]) / 30
        missing, extras = find_missing_frames(timestamps, 30, 10)
        assert missing == [0.0, 1.0]
        assert extras == []

    def test_last_missing(self):
        timestamps: NDArray[np.float64] = np.array([0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]) / 30
        missing, extras = find_missing_frames(timestamps, 30, 10)
        assert missing == [8.0, 9.0]
        assert extras == []

    def test_negatives_and_first_missing(self):
        timestamps: NDArray[np.float64] = np.array([-2.0, -1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]) / 30
        missing, extras = find_missing_frames(timestamps, 30, 10)
        expected_missing = np.array([0.0, 1.0])
        np.testing.assert_array_equal(missing, expected_missing)
        expected_extras = np.array([-2.0, -1.0])
        np.testing.assert_array_equal(extras, expected_extras)

    def test_frames_past_end_are_extras(self):
        timestamps: NDArray[np.float64] = np.array([0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0]) / 30
        missing, extras = find_missing_frames(timestamps, 30, 10)
        expected_missing = np.array([])
        np.testing.assert_array_equal(missing, expected_missing)
        expected_extras = np.array([10.0, 11.0, 12.0])
        np.testing.assert_array_equal(extras, expected_extras)

    def test_all_missing(self):
        timestamps: NDArray[np.float64] = np.array([])
        missing, extras = find_missing_frames(timestamps, 30, 10)
        assert missing == [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
        assert extras == []

    def test_all_missing_with_extras_before(self):
        timestamps: NDArray[np.float64] = np.array([-1.0]) / 30
        missing, extras = find_missing_frames(timestamps, 30, 10)
        assert missing == [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
        assert extras == [-1.0]

    def test_all_missing_with_midframe_extras_before(self):
        timestamps: NDArray[np.float64] = np.array([-1.5]) / 30
        missing, extras = find_missing_frames(timestamps, 30, 10)
        assert missing == [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
        assert extras == [-1.5]

    def test_all_missing_with_midframe_extras_after(self):
        timestamps: NDArray[np.float64] = np.array([10.5]) / 30
        missing, extras = find_missing_frames(timestamps, 30, 10)
        assert missing == [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
        assert extras == [10.5]
