
import platform

class Settings:
    if platform.system() == "Linux":
        SERIAL_DEVICE = "/dev/ttyACM1"
    elif platform.system() == "Darwin":
        SERIAL_DEVICE = "/dev/tty.usbserial-0001"
    else:
        raise Exception("OS not supported")
