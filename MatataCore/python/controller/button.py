import sys
import math
import random
import imp


class button:
    def __init__(self, call):
        self.call = call

    def is_play_btn_pressed(self):
        data = [0x20, 0x07, 0x01]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_forward_btn_pressed(self):
        data = [0x20, 0x07, 0x04]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_backward_btn_pressed(self):
        data = [0x20, 0x07, 0x07]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_turnleft_btn_pressed(self):
        data = [0x20, 0x07, 0x05]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_turnright_btn_pressed(self):
        data = [0x20, 0x07, 0x03]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_stop_btn_pressed(self):
        data = [0x20, 0x07, 0x02]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_music_btn_pressed(self):
        data = [0x20, 0x07, 0x06]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False

    def is_delete_btn_pressed(self):
        data = [0x20, 0x07, 0x02]
        self.call.blewrite(data)
        r = self.call.blewait(0x20)
        if(r == None):
            return False
        else:
            if(r[4] > 0):
                return True
            else:
                return False
