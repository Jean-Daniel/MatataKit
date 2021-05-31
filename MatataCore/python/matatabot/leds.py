import sys
import math
import random


class leds:
    def __init__(self, call):
        self.call = call

    def show_next1(self, color, index):
        data = [0x22, 0x01]
        self.call.blewrite(data)
        self.call.blewait()

    def show_single(self, leftright, r, g, b):
        data = [0x17, 0x01, 0x00, 0x00, 0x00]
        if(leftright == "left"):
            data[1] = 0x01
        elif(leftright == "right"):
            data[1] = 0x02
        elif(leftright == "all"):
            data[1] = 0x03
        data[2] = r
        data[3] = g
        data[4] = b
        self.call.blewrite(data)
        self.call.blewait()

    def show_all(self, r, g, b):
        data = [0x17, 0x01, 0x00, 0x00, 0x00]
        data[1] = 0x03
        data[2] = r
        data[3] = g
        data[4] = b
        self.call.blewrite(data)
        self.call.blewait()

    def color(self, value):
        digit = list(map(str, range(10)))+list("abcdef")
        if(isinstance(value, tuple)):
            string = '#'
            for i in value:
                a1 = i//16
                a2 = i % 16
                string += digit[a1]+digit[a2]
            return string
        elif isinstance(value, str):
            a1 = digit.index(value[1])*16+digit.index(value[2])
            a2 = digit.index(value[3])*16+digit.index(value[4])
            a3 = digit.index(value[5])*16+digit.index(value[6])
        return [a1, a2, a3]

    def trun_ring(self, buf, col):
        arr = self.color(col)
        buf.append(arr[0])
        buf.append(arr[1])
        buf.append(arr[2])
        return buf

    def show_all_hex(self, color):
        data = [0x17, 0x03]
        data = self.trun_ring(data, color)
        self.call.blewrite(data)
        self.call.blewait()

    def show_single_hex(self, index, color):
        data = [0x17, 0x01]
        if(index == "left"):
            data[1] = 0x01
        elif(index == "right"):
            data[1] = 0x02
        elif(index == "all"):
            data[1] = 0x03
        data = self.trun_ring(data, color)
        self.call.blewrite(data)
        self.call.blewait()

    def clear(self):
        data = [0x17, 0x03, 0x00, 0x00, 0x00]
        self.call.blewrite(data)
        self.call.blewait()
