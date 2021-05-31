import sys
import math
import random


class emotion:
    def __init__(self, call):
        self.call = call

    def look_around(self):
        data = [0x16, 0x01, 0x01]
        self.call.blewrite(data)
        self.call.blewait()

    def smile(self):
        data = [0x16, 0x01, 0x27]
        self.call.blewrite(data)
        self.call.blewait()

    def wow(self):
        data = [0x16, 0x01, 0x2f]
        self.call.blewrite(data)
        self.call.blewait()

    def naughty(self):
        data = [0x16, 0x01, 0x05]
        self.call.blewrite(data)
        self.call.blewait()

    def hello(self):
        data = [0x16, 0x01, 0x21]
        self.call.blewrite(data)
        self.call.blewait()

    def proud(self):
        data = [0x16, 0x01, 0x07]
        self.call.blewrite(data)
        self.call.blewait()

    def yummy(self):
        data = [0x16, 0x01, 0x08]
        self.call.blewrite(data)
        self.call.blewait()

    def uh_oh(self):
        data = [0x16, 0x01, 0x29]
        self.call.blewrite(data)
        self.call.blewait()

    def hurt(self):
        data = [0x16, 0x01, 0x0a]
        self.call.blewrite(data)
        self.call.blewait()

    def shiver(self):
        data = [0x16, 0x01, 0x0b]
        self.call.blewrite(data)
        self.call.blewait()

    def startle(self):
        data = [0x16, 0x01, 0x0c]
        self.call.blewrite(data)
        self.call.blewait()

    def zzz(self):
        data = [0x16, 0x01, 0x24]
        self.call.blewrite(data)
        self.call.blewait()

    def wake_up(self):
        data = [0x16, 0x01, 0x0e]
        self.call.blewrite(data)
        self.call.blewait()

    def sleepy(self):
        data = [0x16, 0x01, 0x26]
        self.call.blewrite(data)
        self.call.blewait()

    def dizzy(self):
        data = [0x16, 0x01, 0x10]
        self.call.blewrite(data)
        self.call.blewait()

    def goodbye(self):
        data = [0x16, 0x01, 0x2e]
        self.call.blewrite(data)
        self.call.blewait()

    def no(self):
        data = [0x16, 0x01, 0x2b]
        self.call.blewrite(data)
        self.call.blewait()

    def yes(self):
        data = [0x16, 0x01, 0x28]
        self.call.blewrite(data)
        self.call.blewait()

    def angry(self):
        data = [0x16, 0x01, 0x29]
        self.call.blewrite(data)
        self.call.blewait()

    def crying(self):
        data = [0x22, 0x01]
        self.call.blewrite(data)
        self.call.blewait()

    def action(self, action_num):
        data = [0x13, 0x01]
        if(action_num == "action1"):
            data[1] = 0x01
        elif(action_num == "action2"):
            data[1] = 0x02
        elif(action_num == "action3"):
            data[1] = 0x03
        elif(action_num == "action4"):
            data[1] = 0x04
        elif(action_num == "action5"):
            data[1] = 0x05
        elif(action_num == "action6"):
            data[1] = 0x06
        elif(action_num == "random"):
            data[1] = random.randint(1, 6)
        self.call.blewrite(data)

    def dance(self, action_num):
        data = [0x12, 0x01]
        if(action_num == "dance1"):
            data[1] = 0x01
        elif(action_num == "dance2"):
            data[1] = 0x02
        elif(action_num == "dance3"):
            data[1] = 0x03
        elif(action_num == "dance4"):
            data[1] = 0x04
        elif(action_num == "dance5"):
            data[1] = 0x05
        elif(action_num == "dance6"):
            data[1] = 0x06
        elif(action_num == "random"):
            data[1] = random.randint(1, 6)
        self.call.blewrite(data)
