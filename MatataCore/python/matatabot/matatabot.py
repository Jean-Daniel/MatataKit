import sys
import math
import random
import imp
from java import jclass

from matatabot.motion import motion
from matatabot.music import music
from matatabot.emotion import emotion
from matatabot.speaker import speaker
from matatabot.leds import leds


class matatabot:
    call = None
    music = None
    motion = None
    emotion = None
    speaker = None
    leds = None

    def __init__(self):
        Python2Java = jclass("com.matatalab.matatacode.model.Python2Java")
        self.call = Python2Java("python")
        self.music = music(self.call)
        self.motion = motion(self.call)
        self.emotion = emotion(self.call)
        self.speaker = speaker(self.call)
        self.leds = leds(self.call)

    def start(self):
        data = [0x85]
        self.call.blewrite(data)
        self.call.blewait()
