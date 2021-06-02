import sys
import math
import random


class leds:
    def __init__(self, call):
        self.call = call

    def show_next(self, color, index):
        data = [0x18, 0x05, 0x05, 0x02]
        if(color == "white"):
            data[2] = 0x01
        elif(color == "red"):
            data[2] = 0x02
        elif(color == "yellow"):
            data[2] = 0x03
        elif(color == "green"):
            data[2] = 0x04
        elif(color == "blue"):
            data[2] = 0x05
        elif(color == "purple"):
            data[2] = 0x06
        elif(color == "black"):
            data[2] = 0x07
        if(index == "random"):
            data[3] = random.randint(1, 7)
        else:
            data[3] = index
        self.call.blewrite(data)
        self.call.blewait()

    def show_previous(self, color, index):
        data = [0x18, 0x04, 0x05, 0x02]
        if(color == "white"):
            data[2] = 0x01
        elif(color == "red"):
            data[2] = 0x02
        elif(color == "yellow"):
            data[2] = 0x03
        elif(color == "green"):
            data[2] = 0x04
        elif(color == "blue"):
            data[2] = 0x05
        elif(color == "purple"):
            data[2] = 0x06
        elif(color == "black"):
            data[2] = 0x07
        if(index == "random"):
            data[3] = random.randint(1, 7)
        else:
            data[3] = index
        self.call.blewrite(data)
        self.call.blewait()

    def show_all(self, color, index):
        data = [0x18, 0x02, 0x05, 0x02]
        if(color == "white"):
            data[2] = 0x01
        elif(color == "red"):
            data[2] = 0x02
        elif(color == "yellow"):
            data[2] = 0x03
        elif(color == "green"):
            data[2] = 0x04
        elif(color == "blue"):
            data[2] = 0x05
        elif(color == "purple"):
            data[2] = 0x06
        elif(color == "black"):
            data[2] = 0x07
        if(index == "random"):
            data[3] = random.randint(1, 7)
        else:
            data[3] = int(index)
        self.call.blewrite(data)
        self.call.blewait()

    def show_single(self, index, r, g, b):
        data = [0x18, 0x08, 0x00, 0x00, 0x00, 0x00]
        data[2] = int(index)-1
        data[3] = r
        data[4] = g
        data[5] = b
        self.call.blewrite(data)
        self.call.blewait()

    def color(self, value):
        digit = list(map(str, range(10))) + list("abcdef")
        if isinstance(value, tuple):
            string = '#'
            for i in value:
                a1 = i // 16
                a2 = i % 16
                string += digit[a1] + digit[a2]
            return string
        elif isinstance(value, str):
            a1 = digit.index(value[1]) * 16 + digit.index(value[2])
            a2 = digit.index(value[3]) * 16 + digit.index(value[4])
            a3 = digit.index(value[5]) * 16 + digit.index(value[6])
            return [a1, a2, a3]

    def trun_ring(self, buf, col):
        arr = self.color(col)
        buf.append(arr[0])
        buf.append(arr[1])
        buf.append(arr[2])
        return buf

    def show_ring(self, led1, led2, led3, led4, led5, led6, led7, led8, led9, led10, led11, led12):
        data = [0x18, 0x07]
        data = self.trun_ring(data, led1)
        data = self.trun_ring(data, led2)
        data = self.trun_ring(data, led3)
        data = self.trun_ring(data, led4)
        data = self.trun_ring(data, led5)
        data = self.trun_ring(data, led6)
        data = self.trun_ring(data, led7)
        data = self.trun_ring(data, led8)
        data = self.trun_ring(data, led9)
        data = self.trun_ring(data, led10)
        data = self.trun_ring(data, led11)
        data = self.trun_ring(data, led12)
        self.call.blewrite(data)
        self.call.blewait()

    def clear(self):
        data = [0x18, 0x03, 0x00, 0x00, 0x00]
        self.call.blewrite(data)
        self.call.blewait()

    def show_animation(self, mode):
        data = [0x18, 0x06, 0x00]
        if(mode == "spoondrift"):
            data[2] = 0x01
        elif(mode == "meteor"):
            data[2] = 0x02
        elif(mode == "rainbow"):
            data[2] = 0x03
        elif(mode == "firefly"):
            data[2] = 0x04
        elif(mode == "colorwipe"):
            data[2] = 0x05
        elif(mode == "breathe"):
            data[2] = 0x06
        elif(mode == "random"):
            data[2] = random.randint(1, 6)
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
        self.show_ring(color, color, color, color, color, color,
                       color, color, color, color, color, color)

    def show_single_hex(self, index, color):
        if(math.isinf(index)):
            index = 0
        elif(math.isnan(index)):
            index = 0
        else:
            index = int(index)
        if(index == 0):
            data = [0x18, 0x03]
            data = self.trun_ring(data, color)
            self.call.blewrite(data)
            self.call.blewait()
        else:
            if(index > 0):
                index = index - 1
                index = index % 12
            if(index < 0):
                index = 13 + index
                index = index % 12
            data = [0x18, 0x08, index]
            data = self.trun_ring(data, color)
            self.call.blewrite(data)
            self.call.blewait()
