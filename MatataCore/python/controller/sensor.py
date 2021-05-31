import sys
import math
import random
import imp
import time


class sensor:
    def __init__(self, call):
        self.call = call

    def get_rgb_value(self, color):
        data = [0x28, 0x02, 0x01]
        if(color == "red"):
            data[2] = 0x01
        elif(color == "green"):
            data[2] = 0x02
        elif(color == "blue"):
            data[2] = 0x03
        self.call.blewrite(data)
        r = self.call.blewait(0x28)
        if(r == None):
            return 0
        else:
            return r[4]
