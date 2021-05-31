import sys
import math
import random
import imp
import struct


class infrared_sensor:
    def __init__(self, call):
        self.call = call

    def is_obstacle_ahead(self):
        data = [0x20, 0x04]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_not_obstacle_ahead(self):
        data = [0x20, 0x04]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] == 0):
                return True
            else:
                return False
