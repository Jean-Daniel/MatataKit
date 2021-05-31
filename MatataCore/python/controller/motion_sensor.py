import sys
import math
import random
import imp
import struct


class motion_sensor:
    def __init__(self, call):
        self.call = call

    def is_shaked(self):
        data = [0x20, 0x02, 0x01]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_halo_up(self):
        data = [0x20, 0x02, 0x02]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_halo_down(self):
        data = [0x20, 0x02, 0x03]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_stable(self):
        data = [0x20, 0x02, 0x02]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return False
            else:
                return True

    def is_tilted_left(self):
        data = [0x20, 0x02, 0x04]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_tilted_right(self):
        data = [0x20, 0x02, 0x05]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_tilted_forward(self):
        data = [0x20, 0x02, 0x06]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_tilted_backward(self):
        data = [0x20, 0x02, 0x07]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_fall(self):
        data = [0x20, 0x02, 0x08]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_color(self, color):
        return True

    def is_pressed(self, key):
        return True

    def is_sound_detected(self):
        return True

    def is_obstacle_disappear(self):
        return True

    def get_pitch(self):
        data = [0x28, 0x01, 0x05]
        self.call.blewrite(data)
        r = self.call.blewait(0x28)
        if(r == None):
            return 0
        re = r[4] << 24 | r[5] << 16 | r[6] << 8 | r[7]
        re = re & 0xffffffff
        f = struct.unpack('<f', struct.pack('I', re))[0]
        return f

    def get_yaw(self):
        data = [0x28, 0x01, 0x06]
        self.call.blewrite(data)
        r = self.call.blewait(0x28)
        if(r == None):
            return 0
        else:
            re = r[4] << 24 | r[5] << 16 | r[6] << 8 | r[7]
            re = re & 0xffffffff
            f = struct.unpack('<f', struct.pack('I', re))[0]
            return f

    def get_roll(self):
        data = [0x28, 0x01, 0x04]
        self.call.blewrite(data)
        r = self.call.blewait(0x28)
        if(r == None):
            return 0
        else:
            re = r[4] << 24 | r[5] << 16 | r[6] << 8 | r[7]
            re = re & 0xffffffff
            f = struct.unpack('<f', struct.pack('I', re))[0]
            return f

    def get_acceleration(self, xyz):
        data = [0x28, 0x01, 0x01]
        if(xyz == "X"):
            data[2] = 0x01
        elif(xyz == "Y"):
            data[2] = 0x02
        elif(xyz == "Z"):
            data[2] = 0x03
        self.call.blewrite(data)
        r = self.call.blewait(0x28)
        if(r == None):
            return 0
        else:
            re = r[4] << 24 | r[5] << 16 | r[6] << 8 | r[7]
            re = re & 0xffffffff
            f = struct.unpack('<f', struct.pack('I', re))[0]
            return f

    def get_shaked_strength(self):
        data = [0x28, 0x01, 0x07]
        self.call.blewrite(data)
        r = self.call.blewait(0x28)
        if(r == None):
            return 0
        else:
            re = r[4] << 24 | r[5] << 16 | r[6] << 8 | r[7]
            re = re & 0xffffffff
            f = struct.unpack('<f', struct.pack('I', re))[0]
            return f
