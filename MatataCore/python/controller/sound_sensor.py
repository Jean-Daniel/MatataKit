import sys
import math
import random
import imp


class sound_sensor:
    def __init__(self, call):
        self.call = call

    def is_sound_detected(self):
        data = [0x20, 0x03]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False
