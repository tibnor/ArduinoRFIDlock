# coding:UTF-8

from mobile import Mobile
import random
import os


m = Mobile()
m.create()
m.name = raw_input('Name of device: ')
m.secret = str(random.randint(0,10**30))
m.save()
m.qrcode('http://a1027.no-ip.org/mobile.py/')
