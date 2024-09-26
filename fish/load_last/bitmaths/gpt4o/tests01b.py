import unittest
from unittest.mock import patch
import solution01

class TestMathsFunction(unittest.TestCase):

    @patch('sys.argv', ['solution01.py', '0xFF'])
    def test_hexadecimal(self):
        with patch('builtins.print') as mocked_print:
            solution01.main()
            mocked_print.assert_any_call('bin: 0b11111111')
            mocked_print.assert_any_call('hex: 0xff')
            mocked_print.assert_any_call('dec: 255')

    @patch('sys.argv', ['solution01.py', '0b10011100'])
    def test_binary(self):
        with patch('builtins.print') as mocked_print:
            solution01.main()
            mocked_print.assert_any_call('bin: 0b10011100')
            mocked_print.assert_any_call('hex: 0x9c')
            mocked_print.assert_any_call('dec: 156')

    @patch('sys.argv', ['solution01.py', '254'])
    def test_decimal(self):
        with patch('builtins.print') as mocked_print:
            solution01.main()
            mocked_print.assert_any_call('bin: 0b11111110')
            mocked_print.assert_any_call('hex: 0xfe')
            mocked_print.assert_any_call('dec: 254')

    @patch('sys.argv', ['solution01.py', '0xFF + 0xC'])
    def test_expression(self):
        with patch('builtins.print') as mocked_print:
            solution01.main()
            mocked_print.assert_any_call('bin: 0b100001011')
            mocked_print.assert_any_call('hex: 0x10b')
            mocked_print.assert_any_call('dec: 267')

    @patch('sys.argv', ['solution01.py', '0b1101 + 0xA5C3'])
    def test_mixed_expression(self):
        with patch('builtins.print') as mocked_print:
            solution01.main()
            mocked_print.assert_any_call('bin: 0b1010010111010000')
            mocked_print.assert_any_call('hex: 0xa5d0')
            mocked_print.assert_any_call('dec: 42448')

    @patch('sys.argv', ['solution01.py', '0x10 | 0x11'])
    def test_bitwise_or(self):
        with patch('builtins.print') as mocked_print:
            solution01.main()
            mocked_print.assert_any_call('bin: 0b10001')
            mocked_print.assert_any_call('hex: 0x11')
            mocked_print.assert_any_call('dec: 17')

    @patch('sys.argv', ['solution01.py', '0x10 & 0x11'])
    def test_bitwise_and(self):
        with patch('builtins.print') as mocked_print:
            solution01.main()
            mocked_print.assert_any_call('bin: 0b10000')
            mocked_print.assert_any_call('hex: 0x10')
            mocked_print.assert_any_call('dec: 16')

    @patch('sys.argv', ['solution01.py', '0x10 ^ 0x11'])
    def test_bitwise_xor(self):
        with patch('builtins.print') as mocked_print:
            solution01.main()
            mocked_print.assert_any_call('bin: 0b1')
            mocked_print.assert_any_call('hex: 0x1')
            mocked_print.assert_any_call('dec: 1')

    @patch('sys.argv', ['solution01.py'])
    def test_no_argument(self):
        with patch('builtins.print') as mocked_print:
            solution01.main()
            mocked_print.assert_any_call('Usage: maths <expression>')

if __name__ == '__main__':
    unittest.main()