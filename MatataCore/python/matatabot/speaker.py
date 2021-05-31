import sys
import math
import random


class speaker:
    def __init__(self, call):
        self.call = call

    def play_melody(self, file_name):
        data = [0x16, 0x01, 0x01]
        if(file_name == "melody1"):
            data[2] = 0x01
        elif(file_name == "melody2"):
            data[2] = 0x02
        elif(file_name == "melody3"):
            data[2] = 0x03
        elif(file_name == "melody4"):
            data[2] = 0x04
        elif(file_name == "melody5"):
            data[2] = 0x05
        elif(file_name == "melody6"):
            data[2] = 0x06
        elif(file_name == "melody7"):
            data[2] = 0x07
        elif(file_name == "melody8"):
            data[2] = 0x08
        elif(file_name == "melody9"):
            data[2] = 0x09
        elif(file_name == "melody10"):
            data[2] = 0x0a
        elif(file_name == "random_melody"):
            data[2] = random.randint(1, 10)
        self.call.blewrite(data)
        self.call.blewait()

    def play_note(self, beat, note_num):
        data = [0x15, 0x00, 0x00, 0x00, 0x00]
        BEATC = [131, 147, 165, 175, 196, 220, 247]
        BEATH = [262, 294, 330, 349, 392, 440, 494, 523]
        fp = 0
        if(beat == "C3"):
            fp = 131
        elif(beat == "D3"):
            fp = 147
        elif(beat == "E3"):
            fp = 165
        elif(beat == "F3"):
            fp = 175
        elif(beat == "G3"):
            fp = 196
        elif(beat == "A3"):
            fp = 220
        elif(beat == "B3"):
            fp = 247
        elif(beat == "C4"):
            fp = 262
        elif(beat == "D4"):
            fp = 294
        elif(beat == "E4"):
            fp = 330
        elif(beat == "F4"):
            fp = 349
        elif(beat == "G4"):
            fp = 392
        elif(beat == "A4"):
            fp = 440
        elif(beat == "B4"):
            fp = 494
        elif(beat == "C5"):
            fp = 523
        elif(beat == "random_alto"):
            fp = BEATC[random.randint(0, len(BEATC)-1)]
        elif(beat == "random_treble"):
            fp = BEATH[random.randint(0, len(BEATH)-1)]
        data[1] = fp//256
        data[2] = fp % 256
        data[3] = note_num//256
        data[4] = note_num % 256
        self.call.blewrite(data)
        self.call.blewait()

    def play_melody_until_done(self, file_name):
        data = [0x16, 0x01, 0x11]
        if(file_name == "music1"):
            data[2] = 0x11
        elif(file_name == "music2"):
            data[2] = 0x12
        elif(file_name == "music3"):
            data[2] = 0x13
        elif(file_name == "music4"):
            data[2] = 0x14
        elif(file_name == "music5"):
            data[2] = 0x15
        elif(file_name == "music6"):
            data[2] = 0x16
        elif(file_name == "random"):
            data[2] = random.randint(0x11, 0x16)
        self.call.blewrite(data)
        self.call.blewait()
