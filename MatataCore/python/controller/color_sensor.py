import sys
import math
import random
import imp
import struct


class color_sensor:
    def __init__(self, call):
        self.call = call

    def get_light_strength(self):
        data = [0x28, 0x02, 0x04]
        self.call.blewrite(data)
        r = self.call.blewait(0x28)
        if(r == None):
            return 0
        return r[4]

    def is_white(self):
        data = [0x20, 0x01, 0x01]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_red(self):
        data = [0x20, 0x01, 0x02]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_yellow(self):
        data = [0x20, 0x01, 0x03]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_green(self):
        data = [0x20, 0x01, 0x04]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_blue(self):
        data = [0x20, 0x01, 0x05]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_purple(self):
        data = [0x20, 0x01, 0x06]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_black(self):
        data = [0x20, 0x01, 0x07]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_bright(self):
        data = [0x20, 0x05, 0x01]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_dark(self):
        data = [0x20, 0x05, 0x02]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False
