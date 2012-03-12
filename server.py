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
            try:
                ser = serial.Serial('/dev/'+d, 9600)
                break
            except serial.serialutil.SerialException:
                pass
    
        # Check if connected
        if ser is not None:
            break

    # Wait for ready signal
    pattern = re.compile('READY')
    print 'Waiting for arduino to be ready'
    while 1:
        try:
            res = ser.readline()
            if pattern.match(res):
                print 'Arduino is ready'
                break
        except serial.serialutil.SerialException:
            ser = connectToArduino()
    return ser


ser = connectToArduino()


# Open user acount
db = anydbm.open('brukere', 'c')

adminMode = False;
getIdPattern = re.compile(u'ID: ([0-9A-F]*)')
getUnlockingPattern = re.compile(u'Opening door')
getLockingPattern = re.compile(u'Locking door')

doorIsLocked = False
while 1:
    try:
        incomming = ser.readline()
        print 'A:'+incomming
        res = getIdPattern.findall(incomming)
        if (res !=[]):
            id = str(res[0])
            if (db.has_key(id)):
                print 'Toggling door lock for: '+db[id]
                ser.write('1')
            else:
                print 'User is not known, id: '+id
                ser.write('0')
        elif (getUnlockingPattern.match(incomming)):
            doorIsLocked = False;
        elif (getLockingPattern.match(incomming)):
            doorIsLocked = True;

    except serial.serialutil.SerialException:
        ser = connectToArduino()
    except Exception, e:
        print str(e)
        ser = connectToArduino()

