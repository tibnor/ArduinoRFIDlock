# coding:UTF-8

import sqlite3
import pyqrcode
import random
import hashlib

db = sqlite3.connect('/var/www/users', check_same_thread = False)

def getWord(req,_id):
    m = Mobile()
    m.getMobile(int(_id))
    return """{"word":"%s"}""" % m.newWord()
    
def openDoor(req,_id,token):
    m = Mobile()
    m.getMobile(int(_id))
    if (m.word is not None):
        t = hashlib.sha1(str(m.secret)+str(m.word)).hexdigest()
        if (t == token):
            m.resetWord()
            d = Door()
            d.toggleDoor()
            return """{"status":200,"open":1}"""
    return """{"status":403}"""

#def toggleDoor():
#    d = Door()
#    d.toggleDoor()
#    return 1


class Door():
    def toggleDoor(self):
        cursor = db.execute('select value from commands where command = "mobileOpen"')
        res = cursor.fetchone()
        cursor.execute('UPDATE commands SET value=? WHERE command = "mobileOpen"',(int(res[0])+1,))
        cursor.close();
        db.commit();
        return int(res[0])+1

class Mobile():
    _id = None
    name = None
    secret = None
    word = None


    def create(self):
        cursor = db.execute('insert into users (name, secret, word) values (?,?,?)',(self.name,self.secret,self.word))
        self._id = cursor.lastrowid
        db.commit()    

    def newWord(self):
        self.word = str(random.randint(0,10**30))
        cursor = db.execute('update users set word=? where _id=?',(self.word,self._id))
        db.commit()   
        return self.word

    def resetWord(self):
        self.word = None
        cursor = db.execute('update users set word=? where _id=?',(self.word,self._id))
        db.commit()  
        return self.word

    def save(self):
        cursor = db.execute('update users set name=?,secret=?,word=? where _id=?',(self.name,self.secret,self.word,self._id))
        db.commit()   

    def getMobile(self,_id):
        cursor = db.execute('select * from users where _id = %d' % (_id))
        res = cursor.fetchone()
        self._id = res[0];
        self.name = res[1] if res[1] != 'None' else None
        self.secret = res[2] if res[2] != 'None' else None
        self.word = res[3] if res[3] != 'None' else None
        cursor.close()
    
    def qrcode(self,ip):
        qr_image = pyqrcode.MakeQRImage("""{"id":"%d","name":"%s","secret":"%s","url":"%s"}""" % (self._id,self.name,self.secret,ip))
        qr_image.show()

