from django.utils import simplejson
from google.appengine.ext import db, webapp
from google.appengine.ext.webapp.util import run_wsgi_app
from password import Password
import hashlib
import logging
import random
import sys
import urllib2
from google.appengine.api import urlfetch_errors

class Doorlock(db.Model):
    IP = "http://129.241.143.246:80/"
    open = db.BooleanProperty(default=True)
    word = db.IntegerProperty(default=0)
    
    
    def updateToken(self):  
        word = self.word   
        id = "%010d" % self.word
        m = hashlib.sha1(str(Password.doorlockServerPass) + id); 
        self.put()  
        return m.hexdigest()
       
    def ToggleDoor(self):
        key = self.updateToken()
        word = "%010d" % self.word
        try:
            logging.info("url: "+self.IP+"toggle?id="+word+"&hash="+key)
            response = urllib2.urlopen(self.IP+"toggle?id="+word+"&hash="+key)
        except (urlfetch_errors.DownloadError, urllib2.HTTPError):
            logging.error("Did not find door lock, wrong IP?")
            return 500
        
        
        try:
            result = simplejson.load(response)
        except ValueError:
            logging.error("Can not parse json, wrong IP?")
            return 500
        
        logging.info(response.fp.fp.buf)
        try:
            status = int(result['status'])
        except KeyError:
            logging.error("Json does not include status, wrong IP?")
            return 500
            
        if status == 200:
            self.word = int(result['id'])
            self.open = bool(result['open'])
        elif status == 400:
            self.word = int(result['id'])
        elif status == 403:
            status = 500;
        self.put()
        return status
        
def GetDoorlock():
        doorlock = Doorlock.all();
        if(doorlock.count(1) == 0):
            doorlock = Doorlock();
            doorlock.put();
        else:
            doorlock = doorlock[0]
        return doorlock

    
class Mobile(db.Model):
    Key = db.StringProperty()
    word = db.IntegerProperty()
    name = db.StringProperty()
    
    def updateKey(self):  
        key = random.randint(0, sys.maxint)      
        m = hashlib.sha1(str(Password.mobileServerPass) + str(key));
        self.Key = m.hexdigest()  
        self.word = 0  
        self.put()  
        return key  
    
    def setName(self, name):
        self.name = name;
        self.put()
    
    def getKey(self):
        return self.Key
    
    def updateWord(self):
        word = self.word +1;
        self.word = word
        self.put()
        return word
    
    def getWord(self):
        return self.word
    
class RequestKey(webapp.RequestHandler):
    def get(self):
        self.response.headers['Content-Type'] = 'text/plain'
        mobile = Mobile()
        name = self.request.get("name")
        key = mobile.updateKey()
        id = mobile.key().id()
        mobile.setName(name)
        self.response.out.write("{\"status\":200,\"id\":" + str(id) + ",\"key\":"\
                                 + str(key) + "}")
        
    
class RequestWord(webapp.RequestHandler):
    def get(self):
        id = int(self.request.get("id"))
        self.response.headers['Content-Type'] = 'text/plain'
        mobile = Mobile.get_by_id(id)
        if (mobile is None):
            self.response.out.write("{\"status\":400}")
        else:
            word = mobile.updateWord()
            self.response.out.write("{\"status\":200,\"word\":" + str(word) + "}")
        

    
class IP(webapp.RequestHandler):
    def get(self):
        ip = self.request.get("ip");
        doorlock = Doorlock.all();
        if(doorlock.count(1) == 0):
            doorlock = Doorlock();
            doorlock.put();
        else:
            doorlock = doorlock[0]
        doorlock.ToggleDoor()
        
        
            

class ToggleDoor(webapp.RequestHandler):
    def get(self):
        id = int(self.request.get("id"))
        hashInput = self.request.get("hash")
        mobile = Mobile.get_by_id(id)
        self.response.headers['Content-Type'] = 'text/plain'
        #self.response.out.write("input hashInput:"+str(hashInput)+"\n") 
        self.response.out.write("{")
        if (mobile is None):
            self.response.out.write("\"status\":400")
        else:
            m = hashlib.sha1(str(mobile.getKey()) + str(mobile.getWord()));
            hashServer = m.hexdigest()          
            #self.response.out.write("Server hashServer:"+str(hashServer))
            if (hashInput == hashServer):
                status = GetDoorlock().ToggleDoor()
                self.response.out.write("\"status\":"+str(status)+",\"word\":" + str(mobile.updateWord()))
            else:
                self.response.out.write("\"status\":401")
                
        self.response.out.write("}")
        

application = webapp.WSGIApplication([('/ip', IP), ('/requestkey', RequestKey), ('/requestword', RequestWord), ('/toggledoor', ToggleDoor)], debug=True)


def main():
    run_wsgi_app(application)

if __name__ == "__main__":
    main()
    

