import sys
import unittest
from maths import hex_to_ascii, main
from io import StringIO

class TestMathsFunctions(unittest.TestCase):
    
    def run_main_with(self, expr):
        
        original_stdout = sys.stdout
        sys.stdout = StringIO()
        sys.argv = ["maths.py", expr]
        main()
        output = sys.stdout.getvalue()
        sys.stdout = original_stdout
        return output

    def test_replace_numbers_simple(self):
        expr = '0xFF + 0xC'
        should_include = """bin: 0b100001011
hex: 0x10b
dec: 267"""
        self.assertIn(should_include, self.run_main_with(expr))
        
    def test_replace_numbers_mixed(self):
        expr = '0xFF + 10'
        should_include = """bin: 0b100001001
hex: 0x109
dec: 265"""
        self.assertIn(should_include, self.run_main_with(expr))
    
    def test_replace_numbers_binary(self):
        expr = '0b10011100'
        should_include = """bin: 0b10011100
hex: 0x9c
dec: 156"""
        self.assertIn(should_include, self.run_main_with(expr))
    
    def test_replace_numbers_bitwise_or(self):
        expr = '0x10 | 0x11'
        should_include = """bin: 0b10001
hex: 0x11
dec: 17"""
        self.assertIn(should_include, self.run_main_with(expr))
    
    def test_replace_numbers_bitwise_and(self):
        expr = '0x10 & 0x11'
        should_include = """bin: 0b10000
hex: 0x10
dec: 16
"""
        self.assertIn(should_include, self.run_main_with(expr))
    
    def test_replace_numbers_bitwise_xor(self):
        expr = '0x10 ^ 0x11'
        should_include = """bin: 0b1
hex: 0x1
dec: 1"""
        self.assertIn(should_include, self.run_main_with(expr))
    
    # def test_hex_to_ascii_valid(self):
    #     self.assertEqual(hex_to_ascii('0x68656c6c6f20776f726c64'), 'hello world')
    #     self.assertEqual(hex_to_ascii('68656c6c6f'), 'hello')
    #     self.assertEqual(hex_to_ascii('0x414143'), 'AAC')
    #     self.assertEqual(hex_to_ascii('0x414152'), 'AAR')
    
    # def test_hex_to_ascii_invalid(self):
    #     self.assertIsNone(hex_to_ascii('0xZZZ'))
    #     self.assertIsNone(hex_to_ascii('0x123G'))
    #     # self.assertIsNone(hex_to_ascii('0x')) # not handled in impl
    
if __name__ == '__main__':
    unittest.main()