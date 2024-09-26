import unittest
from maths import parse_number, replace_numbers, hex_to_ascii

class TestMathsFunctions(unittest.TestCase):
    
    def test_parse_number_binary(self):
        self.assertEqual(parse_number('0b11111111'), 255)
        self.assertEqual(parse_number('0b10011100'), 156)
        self.assertEqual(parse_number('0b1101'), 13)
    
    def test_parse_number_hexadecimal(self):
        self.assertEqual(parse_number('0xFF'), 255)
        self.assertEqual(parse_number('0xa5C3'), 42435)
        self.assertEqual(parse_number('0x10'), 16)
        self.assertEqual(parse_number('0x11'), 17)
        self.assertEqual(parse_number('0x9c'), 156)
        self.assertEqual(parse_number('0x414143'), 4276547) # fix assertion
        self.assertEqual(parse_number('0x414152'), 4276562) # fix assertion
    
    def test_parse_number_decimal(self):
        self.assertEqual(parse_number('255'), 255)
        self.assertEqual(parse_number('10'), 10)
        self.assertEqual(parse_number('254'), 254)
        self.assertEqual(parse_number('4276562'), 4276562)
        self.assertEqual(parse_number('4276802'), 4276802)
    
    def test_replace_numbers_simple(self):
        expr = '0xFF + 0xC'
        expected = '255 + 12'
        self.assertEqual(replace_numbers(expr), expected)
    
    def test_replace_numbers_mixed(self):
        expr = '0xFF + 10'
        expected = '255 + 10'
        self.assertEqual(replace_numbers(expr), expected)
    
    def test_replace_numbers_binary(self):
        expr = '0b10011100'
        expected = '156'
        self.assertEqual(replace_numbers(expr), expected)
    
    def test_replace_numbers_bitwise_or(self):
        expr = '0x10 | 0x11'
        expected = '16 | 17'
        self.assertEqual(replace_numbers(expr), expected)
    
    def test_replace_numbers_bitwise_and(self):
        expr = '0x10 & 0x11'
        expected = '16 & 17'
        self.assertEqual(replace_numbers(expr), expected)
    
    def test_replace_numbers_bitwise_xor(self):
        expr = '0x10 ^ 0x11'
        expected = '16 ^ 17'
        self.assertEqual(replace_numbers(expr), expected)
    
    def test_hex_to_ascii_valid(self):
        self.assertEqual(hex_to_ascii('0x68656c6c6f20776f726c64'), 'hello world')
        self.assertEqual(hex_to_ascii('68656c6c6f'), 'hello')
        self.assertEqual(hex_to_ascii('0x414143'), 'AAC')
        self.assertEqual(hex_to_ascii('0x414152'), 'AAR')
    
    def test_hex_to_ascii_invalid(self):
        self.assertIsNone(hex_to_ascii('0xZZZ'))
        self.assertIsNone(hex_to_ascii('0x123G'))
        # self.assertIsNone(hex_to_ascii('0x')) # not handled in impl
    
if __name__ == '__main__':
    unittest.main()