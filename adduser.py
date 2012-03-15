import serial
import anydbm
import re
import os

def connectToArduino():
    print 'Waiting for arduino to connect'
    while 1:
        # Find device
        dev = os.listdir('/dev/')
        pattern = re.compile('ttyACM.*')
        acm = [];
        for d in dev:
            if pattern.match(d):
                acm.append(d)

        # Try to connect
        ser = None
        for d in acm:
            #try:
            ser = serial.Serial('/dev/'+d, 9600)
            #    break
            #except serial.serialutil.SerialException:
            #    pass
    
        # Check if connected
        if ser is not None:
            break

    # Wait for ready signal
    pattern = re.compile('READY')
    print 'Waiting for arduino to be ready'
    while 1:
        #try:
        res = ser.readline()
        if pattern.match(res):
            print 'Arduino is ready'
            break
       # except serial.serialutil.SerialException:
        #    ser = connectToArduino()
    return ser


ser = connectToArduino()


# Open user acount
db = anydbm.open('brukere', 'c')

adminMode = False;
pattern = re.compile(u'ID: ([0-9A-F]*)')
while 1:
    #try:
    res = ser.readline()
    res = pattern.findall(res)
    if (res !=[]):
        id = str(res[0])
        print 'Read id: '+id
        name = raw_input('Write in name of user: ')
        db[id] = name;
        db.sync()
        print db;

    #except serial.serialutil.SerialException:
    #    ser = connectToArduino()
    #except Exception, e:
    #    print str(e)
    #    ser = connectToArduino()

