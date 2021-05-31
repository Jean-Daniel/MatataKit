import sys
import math
import random


class motion:
    def __init__(self, call):
        self.call = call

    def forward_step(self, step):
        data = [0x10, 0x01, 0x00, 0x00]
        mm = 100
        data[2] = mm//256
        data[3] = mm % 256
        for i in range(0, step):
            self.call.blewrite(data)
            self.call.blewait(0x88)

    def forward(self, step):
        data = [0x10, 0x01, 0x00, 0x00]
        mm = None
        if isinstance(step, int):
            mm = round(step)
            mm = mm*10
        elif isinstance(step, float):
            mm = round(step)
            mm = mm*10
        elif isinstance(step, str):
            if(step == "step_1"):
                self.forward_step(1)
                return
            elif(step == "step_2"):
                self.forward_step(2)
                return
            elif(step == "step_3"):
                self.forward_step(3)
                return
            elif(step == "step_4"):
                self.forward_step(4)
                return
            elif(step == "step_5"):
                self.forward_step(5)
                return
            elif(step == "step_6"):
                self.forward_step(6)
                return
            elif(step == "random_step"):
                mm = random.randint(1, 6)
                self.forward_step(mm)
                return
            elif(step == "random"):
                mm = random.randint(1, 6)
                mm = mm*100
        if(mm == None):
            pass
        data[2] = mm//256
        data[3] = mm % 256
        self.call.blewrite(data)
        self.call.blewait(0x88)

    def backward_step(self, step):
        data = [0x10, 0x02, 0x00, 0x00]
        mm = 100
        data[2] = mm//256
        data[3] = mm % 256
        for i in range(0, step):
            self.call.blewrite(data)
            self.call.blewait(0x88)

    def backward(self, step):
        data = [0x10, 0x02, 0x00, 0x00]
        mm = None
        if isinstance(step, int):
            mm = step
            mm = mm*10
        elif isinstance(step, float):
            mm = round(step)
            mm = mm*10
        elif isinstance(step, str):
            if(step == "step_1"):
                self.backward_step(1)
                return
            elif(step == "step_2"):
                self.backward_step(2)
                return
            elif(step == "step_3"):
                self.backward_step(3)
                return
            elif(step == "step_4"):
                self.backward_step(4)
                return
            elif(step == "step_5"):
                self.backward_step(5)
                return
            elif(step == "step_6"):
                self.backward_step(6)
                return
            elif(step == "random_step"):
                mm = random.randint(1, 6)
                self.backward_step(mm)
                return
            elif(step == "random"):
                mm = random.randint(1, 6)
                mm = mm*100
            else:
                mm = 100
        data[2] = mm//256
        data[3] = mm % 256
        self.call.blewrite(data)
        self.call.blewait(0x88)

    def turn_left(self, angle):
        data = [0x10, 0x03, 0x00, 0x00]
        mm = None
        if isinstance(angle, int):
            mm = angle
        elif isinstance(angle, float):
            mm = round(angle)
        elif isinstance(angle, str):
            if(angle == "random"):
                mm = random.randint(30, 180)
            elif(angle == "30degree"):
                mm = 30
            elif(angle == "36degree"):
                mm = 36
            elif(angle == "45degree"):
                mm = 45
            elif(angle == "60degree"):
                mm = 60
            elif(angle == "72degree"):
                mm = 72
            elif(angle == "90degree"):
                mm = 90
            elif(angle == "108degree"):
                mm = 108
            elif(angle == "120degree"):
                mm = 120
            elif(angle == "135degree"):
                mm = 135
            elif(angle == "145degree"):
                mm = 145
            elif(angle == "150degree"):
                mm = 150
            elif(angle == "180degree"):
                mm = 180
            else:
                mm = 30
        data[2] = mm//256
        data[3] = mm % 256
        self.call.blewrite(data)
        self.call.blewait()

    def turn_right(self, angle: int):
        data = [0x10, 0x04, 0x00, 0x00]
        mm = None
        if isinstance(angle, int):
            mm = angle
        elif isinstance(angle, float):
            mm = round(angle)
        elif isinstance(angle, str):
            if(angle == "random"):
                mm = random.randint(30, 180)
            elif(angle == "30degree"):
                mm = 30
            elif(angle == "36degree"):
                mm = 36
            elif(angle == "45degree"):
                mm = 45
            elif(angle == "60degree"):
                mm = 60
            elif(angle == "72degree"):
                mm = 72
            elif(angle == "90degree"):
                mm = 90
            elif(angle == "108degree"):
                mm = 108
            elif(angle == "120degree"):
                mm = 120
            elif(angle == "135degree"):
                mm = 135
            elif(angle == "145degree"):
                mm = 145
            elif(angle == "150degree"):
                mm = 150
            elif(angle == "180degree"):
                mm = 180
            else:
                mm = 30
        data[2] = mm//256
        data[3] = mm % 256
        self.call.blewrite(data)
        self.call.blewait()

    def move_position(self, position):
        # print(str(position))
        if(float(position) > 9999):
            position = 9999
        if(float(position) < -9999):
            position = -9999
        position = position*10
        position = round(position)
        data = [0x10, 0x01, 0x00, 0x00]
        mm = None
        if(position > 0):
            data[1] = 0x01
            if(position > 1000):
                position = 1000
            mm = position
        else:
            data[1] = 0x02
            if(position < -1000):
                position = -1000
            mm = 0-position
        data[2] = mm//256
        data[3] = mm % 256
        self.call.blewrite(data)
        self.call.blewait()

    def move_angle(self, angle):
        if(float(angle) > 9999):
            angle = 9999
        if(float(angle) < -9999):
            angle = -9999
        angle = round(angle)
        data = [0x10, 0x03, 0x00, 0x00]
        mm = None
        if(angle > 0):
            data[1] = 0x04
            if(angle > 360):
                angle = 360
            mm = angle
        else:
            data[1] = 0x03
            if(angle < -360):
                angle = -360
            mm = 0-angle
        data[2] = mm//256
        data[3] = mm % 256
        self.call.blewrite(data)
        self.call.blewait()

    def move_speed(self, left_speed, right_speed):
        left_s = 0
        right_s = 0
        data = [0x11, 0x03, 0x01, 0x00, 0x00, 0x01, 0x00, 0x00]
        if isinstance(left_speed, int):
            left_s = 144*left_speed/9.70
        elif isinstance(left_speed, float):
            left_s = 144*left_speed/9.70
        elif isinstance(left_speed, str):
            if(left_speed == "gear_1"):
                left_s = 70
            elif(left_speed == "gear_2"):
                left_s = 105
            elif(left_speed == "gear_3"):
                left_s = 140
            elif(left_speed == "gear_4"):
                left_s = 175
            elif(left_speed == "gear_5"):
                left_s = 210
            elif(left_speed == "gear_6"):
                left_s = 245
            elif(left_speed == "inf"):
                left_s = 245
            elif(left_speed == "gear_stop"):
                left_s = 0
            elif(left_speed == "gear_random"):
                a = random.randint(0, 5)
                left_s = 70+35*a
            elif(left_speed == "backgear_1"):
                left_s = -70
            elif(left_speed == "backgear_2"):
                left_s = -105
            elif(left_speed == "backgear_3"):
                left_s = -140
            elif(left_speed == "backgear_4"):
                left_s = -175
            elif(left_speed == "backgear_5"):
                left_s = -175
            elif(left_speed == "backgear_6"):
                left_s = -210
            elif(left_speed == "-inf"):
                left_s = -210
            elif(left_speed == "backgear_stop"):
                left_s = 0
            elif(left_speed == "backgear_random"):
                a = random.randint(0, 5)
                left_s = -70-35*a
        if isinstance(right_speed, int):
            right_s = 144*right_speed/9.70
        elif isinstance(right_speed, float):
            right_s = 144*right_speed/9.70
        elif isinstance(right_speed, str):
            if(right_speed == "gear_1"):
                right_s = 70
            elif(right_speed == "gear_2"):
                right_s = 105
            elif(right_speed == "gear_3"):
                right_s = 140
            elif(right_speed == "gear_4"):
                right_s = 175
            elif(right_speed == "gear_5"):
                right_s = 210
            elif(right_speed == "gear_6"):
                right_s = 245
            elif(right_speed == "inf"):
                right_s = 245
            elif(right_speed == "gear_stop"):
                right_s = 0
            elif(right_speed == "gear_random"):
                a = random.randint(0, 5)
                right_s = 70+35*a
            elif(right_speed == "backgear_1"):
                right_s = -70
            elif(right_speed == "backgear_2"):
                right_s = -105
            elif(right_speed == "backgear_3"):
                right_s = -140
            elif(right_speed == "backgear_4"):
                right_s = -175
            elif(right_speed == "backgear_5"):
                right_s = -175
            elif(right_speed == "backgear_6"):
                right_s = -210
            elif(right_speed == "-inf"):
                right_s = -210
            elif(right_speed == "backgear_stop"):
                right_s = 0
            elif(right_speed == "backgear_random"):
                a = random.randint(0, 5)
                right_s = -70-35*a
        if(left_s > 0):
            left_s = left_s
            data[2] = 0x01
        else:
            left_s = 0-left_s
            data[2] = 0x02
        if(right_s > 0):
            right_s = right_s
            data[5] = 0x01
        else:
            right_s = 0-right_s
            data[5] = 0x02
        left_s = round(left_s)
        right_s = round(right_s)
        data[3] = left_s//256
        data[4] = left_s % 256
        data[6] = right_s//256
        data[7] = right_s % 256
        self.call.blewrite(data)

    def move_right_speed(self, right_speed):
        right_s = 0
        data = [0x11, 0x01, 0x01, 0x00, 0x00]
        if isinstance(right_speed, int):
            right_s = 144*right_speed/9.70
        elif isinstance(right_speed, float):
            right_s = 144*right_speed/9.70
        elif isinstance(right_speed, str):
            if(right_speed == "gear_1"):
                right_s = 70
            elif(right_speed == "gear_2"):
                right_s = 105
            elif(right_speed == "gear_3"):
                right_s = 140
            elif(right_speed == "gear_4"):
                right_s = 175
            elif(right_speed == "gear_5"):
                right_s = 210
            elif(right_speed == "gear_6"):
                right_s = 245
            elif(right_speed == "inf"):
                right_s = 245
            elif(right_speed == "gear_stop"):
                right_s = 0
            elif(right_speed == "gear_random"):
                a = random.randint(0, 5)
                right_s = 70+35*a
            elif(right_speed == "backgear_1"):
                right_s = -70
            elif(right_speed == "backgear_2"):
                right_s = -105
            elif(right_speed == "backgear_3"):
                right_s = -140
            elif(right_speed == "backgear_4"):
                right_s = -175
            elif(right_speed == "backgear_5"):
                right_s = -175
            elif(right_speed == "backgear_6"):
                right_s = -210
            elif(right_speed == "-inf"):
                right_s = -210
            elif(right_speed == "backgear_stop"):
                right_s = 0
            elif(right_speed == "backgear_random"):
                a = random.randint(0, 5)
                right_s = -70-35*a
        if(right_s > 0):
            right_s = right_s
            data[2] = 0x01
        else:
            right_s = 0-right_s
            data[2] = 0x02
        right_s = round(right_s)
        data[3] = right_s//256
        data[4] = right_s % 256
        self.call.blewrite(data)

    def move_left_speed(self, left_speed):
        left_s = 0
        data = [0x11, 0x02, 0x01, 0x00, 0x00]
        if isinstance(left_speed, int):
            left_s = 144*left_speed/9.70
        elif isinstance(left_speed, float):
            left_s = 144*left_speed/9.70
        elif isinstance(left_speed, str):
            if(left_speed == "gear_1"):
                left_s = 70
            elif(left_speed == "gear_2"):
                left_s = 105
            elif(left_speed == "gear_3"):
                left_s = 140
            elif(left_speed == "gear_4"):
                left_s = 175
            elif(left_speed == "gear_5"):
                left_s = 210
            elif(left_speed == "gear_6"):
                left_s = 245
            elif(left_speed == "inf"):
                left_s = 245
            elif(left_speed == "gear_stop"):
                left_s = 0
            elif(left_speed == "gear_random"):
                a = random.randint(0, 5)
                left_s = 70+35*a
            elif(left_speed == "backgear_1"):
                left_s = -70
            elif(left_speed == "backgear_2"):
                left_s = -105
            elif(left_speed == "backgear_3"):
                left_s = -140
            elif(left_speed == "backgear_4"):
                left_s = -175
            elif(left_speed == "backgear_5"):
                left_s = -175
            elif(left_speed == "backgear_6"):
                left_s = -210
            elif(left_speed == "-inf"):
                left_s = -210
            elif(left_speed == "backgear_stop"):
                left_s = 0
            elif(left_speed == "backgear_random"):
                a = random.randint(0, 5)
                left_s = -70-35*a
        if(left_s > 0):
            left_s = left_s
            data[2] = 0x01
        else:
            left_s = 0-left_s
            data[2] = 0x02
        left_s = round(left_s)
        data[3] = left_s//256
        data[4] = left_s % 256
        self.call.blewrite(data)

    def stop(self, wheel):
        data = None
        if(wheel == "left"):
            data = [0x11, 0x01, 0x01, 0x00, 0x00]
        elif(wheel == "right"):
            data = [0x11, 0x02, 0x01, 0x00, 0x00]
        elif(wheel == "all"):
            data = [0x11, 0x03, 0x01, 0x00, 0x00, 0x01, 0x00, 0x00]
        else:
            data = [0x11, 0x03, 0x01, 0x00, 0x00, 0x01, 0x00, 0x00]
        self.call.blewrite(data)
