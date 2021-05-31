import sys
import math
import random
import imp
from java import jclass
from controller.leds import leds
from controller.message import message
from controller.sensor import sensor
from controller.motion_sensor import motion_sensor
from controller.button import button
from controller.color_sensor import color_sensor
from controller.infrared_sensor import infrared_sensor
from controller.sound_sensor import sound_sensor
from controller.timer import timer


class controller:
    call = None
    leds = None
    message = None
    sensor = None
    motion_sensor = None
    button = None
    color_sensor = None
    infrared_sensor = None
    sound_sensor = None
    timer = None

    def __init__(self):
        self.call = None
        self.leds = leds(self.call)
        self.message = message(self.call)
        self.sensor = sensor(self.call)
        self.motion_sensor = motion_sensor(self.call)
        self.button = button(self.call)
        self.color_sensor = color_sensor(self.call)
        self.infrared_sensor = infrared_sensor(self.call)
        self.sound_sensor = sound_sensor(self.call)
        self.timer = timer(self.call)
        #data = [0x7e,0x02,0x02,0x00,0x00]
        #print("控制器 设置为新协议")
        # self.call.blewrite(data)
        # self.call.blewait()

    def test(self):
        data = [0x39, 0x04]
        self.call.blewrite(data)
        self.call.blewait()
