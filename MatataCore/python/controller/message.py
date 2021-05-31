import sys
import math
import random


class message:
    def __init__(self, call):
        self.call = call

    def send(self, msg):
        data = [0x20, 0x06, 0x01, 0x02]
        data[3] = int(msg)
        self.call.blewrite(data)
        self.call.blewait()

    def wait(self, msg):
        if isinstance(msg, str):
            if(msg == "random"):
                msg = random.randint(1, 6)
            else:
                msg = 1
        elif isinstance(msg, int):
            pass
        else:
            msg = 1

        data = [0x20, 0x06, 0x02]
        self.call.blewrite(data)
        r = self.call.blewait_until(0x20)
        if (r == None):
            return False
        else:
            if(r[4] == msg):
                return True
            return False

    def wait_1(self):
        return self.wait(1)

    def wait_2(self):
        return self.wait(2)

    def wait_3(self):
        return self.wait(3)

    def wait_4(self):
        return self.wait(4)

    def wait_5(self):
        return self.wait(5)

    def wait_6(self):
        return self.wait(6)

    def recived(self):
        data = [0x20, 0x06, 0x02]
        self.call.blewrite(data)
        r = self.call.blewait_until(0x20)
        if(r == None):
            return 0
        else:
            if(r[4] != 0xff):
                return r[4]
            else:
                return 0
