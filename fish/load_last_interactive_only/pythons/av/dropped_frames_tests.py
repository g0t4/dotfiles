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

    def test_actual_ffmpeg_samples_that_are_truncated(self):
        # turncation is a good test for closeness (to a frame)
        timestamps=np.array(
              [0.      , 0.033333, 0.066667, 0.1     , 0.133333, 0.166667, \
               0.2     , 0.233333, 0.266667, 0.3     , 0.333333, 0.366667,
               0.4     , 0.433333, 0.466667, 0.5     , 0.533333, 0.566667,
               0.6     , 0.633333, 0.666667, 0.7     , 0.733333, 0.766667,
               0.8     , 0.833333, 0.866667, 0.9     , 0.933333, 0.966667,
               1.      , 1.033333, 1.066667, 1.1     , 1.133333, 1.166667,
               1.2     , 1.233333, 1.266667, 1.3     , 1.333333, 1.366667,
               1.4     , 1.433333, 1.466667, 1.5     , 1.533333, 1.566667,
               1.6     , 1.633333, 1.666667, 1.7     , 1.733333, 1.766667,
               1.8     , 1.833333, 1.866667, 1.9     , 1.933333, 1.966667,
               2.      , 2.033333, 2.066667, 2.1     , 2.133333, 2.166667,
               2.2     , 2.233333, 2.266667, 2.3     , 2.333333, 2.366667,
               2.4     , 2.433333, 2.466667, 2.5     , 2.533333, 2.566667,
               2.6     , 2.633333, 2.666667, 2.7     , 2.733333, 2.866667,
               2.933333, 2.966667, 3.      , 3.033333, 3.066667, 3.1     ,
               3.133333, 3.166667, 3.2     , 3.233333, 3.266667, 3.3     ,
               3.333333, 3.366667, 3.4     , 3.433333, 3.466667, 3.5     ,
               3.533333, 3.566667, 3.6     , 3.633333, 3.666667, 3.7     ,
               3.733333, 3.766667, 3.8     , 3.833333, 3.866667, 3.9     ,
               3.933333, 3.966667])
        missing, extras = find_missing_frames(timestamps, 30, 120)

        expected_missing = [83.0, 84.0, 85.0, 87.0]
        np.testing.assert_array_equal(missing, expected_missing)
        assert extras == []
