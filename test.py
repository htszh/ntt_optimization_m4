#!/usr/bin/env python3

import datetime
import subprocess
import sys

import serial
import numpy as np
from config import Settings
import os.path


def run_test():
    subprocess.check_call(f"make clean", shell=True)
    subprocess.check_call(f"make", shell=True)
    subprocess.check_call(f"make bin", shell=True)
    binary = f"ntt.bin"
    if os.path.isfile(binary) is False:
        print("Binary dose not exist")
        exit()

    try:
        subprocess.check_call(f"st-flash --serial 303636444646343835343530383237 --reset write {binary} 0x8000000", shell=True)
    except:
        print("st-flash failed --> retry")
        return run_test()

    with serial.Serial(Settings.SERIAL_DEVICE, 115200, timeout=10) as dev:
        logs = b""
        log = b""
        device_output = b''
        while device_output != b'#':
            device_output = dev.read()
            # print(device_output)
            if device_output == b'':
                print("timeout --> retry")
                return run_test()
            log += device_output
            if device_output == b'#':
                logs += (log)
                log = b""
    return logs


if __name__ == '__main__':
    logs = run_test()
    print(logs)