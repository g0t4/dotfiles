"""Tests for the Vim-style Ctrl-A / Ctrl-X number helpers."""

import test_setup  # noqa: F401  (adds xonsh/lib to sys.path)

from wes_number import (  # noqa: E402
    decrement_number,
    find_number_range,
    increment_number,
)


def test_increment_basic_positive():
    # cursor at end of line, targets the trailing number
    assert increment_number("echo 5", 6) == ("echo 6", 6)


def test_decrement_basic_positive():
    assert decrement_number("echo 5", 6) == ("echo 4", 6)


def test_increment_negative_number():
    # cursor right after the number
    assert increment_number("echo -5", 7) == ("echo -4", 7)


def test_decrement_negative_number():
    # BUG (previously): decrementing -5 searched backward and found "5",
    # producing 4 instead of -6.
    assert decrement_number("echo -5", 7) == ("echo -6", 7)


def test_increment_negative_crosses_zero_removes_sign():
    assert increment_number("-5", 2, count=6) == ("1", 1)


def test_decrement_positive_crosses_zero_adds_sign():
    assert decrement_number("5", 1, count=6) == ("-1", 2)


def test_cursor_inside_number():
    # cursor between the digits of 12
    assert increment_number("echo 12", 6) == ("echo 13", 7)


def test_cursor_on_minus_sign_keeps_it_attached():
    # cursor right before the "-" of "-5"
    assert decrement_number("echo -5", 5) == ("echo -6", 7)


def test_cursor_before_minus_sign_keeps_it_attached():
    # cursor immediately before the "-" of "-5"
    assert increment_number("echo -5", 5) == ("echo -4", 7)


def test_cursor_after_minus_but_before_digits():
    # cursor between "-" and "5" in "echo -5"
    # (BUG previously: forward search grabbed "5", dropping the sign)
    assert increment_number("echo -5", 6) == ("echo -4", 7)


def test_leading_zeros_preserved():
    assert increment_number("007", 3) == ("008", 3)
    assert decrement_number("007", 3) == ("006", 3)


def test_leading_zeros_negative_preserved():
    assert increment_number("-007", 4) == ("-006", 4)
    assert decrement_number("-007", 4) == ("-008", 4)


def test_lone_zero_is_not_padded():
    assert increment_number("0", 1) == ("1", 1)
    assert decrement_number("0", 1) == ("-1", 2)


def test_count_argument():
    assert increment_number("5", 1, count=3) == ("8", 1)
    assert decrement_number("5", 1, count=3) == ("2", 1)


def test_no_number_returns_none():
    assert increment_number("echo hello", 10) is None
    assert decrement_number("echo hello", 10) is None
    assert find_number_range("echo hello", 10) is None


def test_picks_next_number_after_cursor():
    # cursor before the second number
    assert increment_number("5 10", 2) == ("5 11", 4)


def test_cursor_between_numbers_picks_next():
    assert increment_number("5 10", 2) == ("5 11", 4)


def test_subtraction_operator_not_a_number():
    # "5 - 3": the "-" is an operator, cursor on it should target "3"
    assert find_number_range("5 - 3", 2) == (4, 5)
    assert decrement_number("5 - 3", 2) == ("5 - 2", 5)


def test_number_after_digits_with_sign_operator():
    # "5 -3" with a space is a negative number
    assert find_number_range("5 -3", 2) == (2, 4)
    assert decrement_number("5 -3", 2) == ("5 -4", 4)


def test_multiple_numbers_picks_cursor_span_first():
    # cursor sits inside the first number, must not skip to the second
    assert increment_number("12 34", 1) == ("13 34", 2)


def test_negative_zero_normalizes_to_zero():
    assert increment_number("-0", 2) == ("1", 1)
