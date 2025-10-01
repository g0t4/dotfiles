
## Initial 

implement code for this new shell command/function whatever implementation/language as long as you make sure I can use it in the fish shell.

```shell

$ maths 0xFF
bin: 0b11111111
hex: 0xff
dec: 255

$ maths 0xFF + 0xC
bin: 0b100001011
hex: 0x10b
dec: 267

$ maths 0xFF + 10
bin: 0b100001001
hex: 0x109
dec: 265

$ maths 0b10011100
bin: 0b10011100
hex: 0x9c
dec: 156

$ maths 254
bin: 0b11111110
hex: 0xfe
dec: 254

$ maths 0b1101 + 0xA5C3
bin: 0b1010010111010000
hex: 0xa5d0
dec: 42448



$ maths "0x10 | 0x11"
bin: 0b10001
hex: 0x11
dec: 17

$ maths "0x10 & 0x11"
bin: 0b10000
hex: 0x10
dec: 16

$ maths "0x10 ^ 0x11"
bin: 0b1
hex: 0x1
dec: 1

```


## add support for ascii conversion:

```
$ maths 0x68656c6c6f20776f726c64
ascii: hello world
bin: 0b110100001100101011011000110110001101111001000000111011101101111011100100110110001100100
hex: 0x68656c6c6f20776f726c64
dec: 126207244316550804821666916


```