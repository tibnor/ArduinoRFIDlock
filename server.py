import serial
import anydbm
import re
import os
import time
import sqlite3

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
                ser = serial.Serial('/dev/'+d, 9600,timeout=0.1)
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

def getMobileOpen(dbMobile):
    while 1:
        try:
            cursor = dbMobile.execute('select value from commands where command = "mobileOpen"')
            res = cursor.fetchone()
            cursor.close()
            return res[0]
        except sqlite3.OperationalError:
            pass    


ser = connectToArduino()
dbMobile = sqlite3.connect('/var/www/users', check_same_thread = False)
lastMobileOpen = getMobileOpen(dbMobile)

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
        if (incomming != ""):
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
    

    if (lastMobileOpen < getMobileOpen(dbMobile)):
        print 'Toggling door lock for: mobile'
        ser.write('1')
        lastMobileOpen = getMobileOpen(dbMobile)
    time.sleep(.1)
