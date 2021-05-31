import sys
import math
import random


class music:
    def __init__(self, call):
        self.call = call

    def play_treble(self, tone, meter):
        data = [0x71, 0x01, 0x00]
        if(tone == "do"):
            data[1] = 1
        elif(tone == "re"):
            data[1] = 2
        elif(tone == "mi"):
            data[1] = 3
        elif(tone == "fa"):
            data[1] = 4
        elif(tone == "sol"):
            data[1] = 5
        elif(tone == "la"):
            data[1] = 6
        elif(tone == "ti"):
            data[1] = 7
        elif(tone == "random"):
            data[1] = random.randint(1, 7)
        if(meter == "meter1"):
            data[2] = 1
        elif(meter == "meter2"):
            data[2] = 2
        elif(meter == "meter3"):
            data[2] = 3
        elif(meter == "meter4"):
            data[2] = 4
        elif(meter == "meter5"):
            data[2] = 5
        elif(meter == "meter6"):
            data[2] = 6
        elif(tone == "random"):
            data[2] = random.randint(1, 6)
        self.call.blewrite(data)
        self.call.blewait()
