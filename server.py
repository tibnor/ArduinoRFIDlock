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
db['1234567890'] = 'user'
db['1234567899'] = 'admin'

adminMode = False;
pattern = re.compile(u'ID: (\d*)')
while 1:
    try:
        res = ser.readline()
        res = pattern.findall(res)
        if (res !=[]):
            id = str(res[0])
            try:
                type = db[id]
                if (type=='admin'):
                    if (adminMode):
                        ser.write('2')
                        adminMode = False
                        print 'Switch to door lock mode mode'
                    else:
                        ser.write('3')
                        adminMode = True
                        print  'Switch to add user mode'
                   
                elif (type=='user'):
                    print 'User: '+id
                    ser.write('1')
                else:
                    ser.write('0')
            except KeyError:
                print "Id not found"
                if(adminMode):
                    db[id] = "user"
                    print 'Added: |'+id+'|'
                    #ser.write('1')
                else:
                    print 'Access denied: |'+id+'|'
                    ser.write('0')
    except serial.serialutil.SerialException:
        ser = connectToArduino()

