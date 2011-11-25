from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app
from google.appengine.ext import db
import random
import hashlib
from password import Password


class Mobile(db.Model):
    Key = db.StringProperty()
    word = db.IntegerProperty()
    
    def updateKey(self):  
        key = random.randint(0,4611686018427387904)      
        m = hashlib.sha1(str(Password.mobileServerPass)+str(key));
        self.Key = m.hexdigest()    
        self.put()  
        return key  
    
    def getKey(self):
        return self.Key
    
    def updateWord(self):
        word = random.randint(0,4611686018427387904)      
        self.word = word
        self.put()
        return word
    
    def getWord(self):
        return self.word
    
class RequestKey(webapp.RequestHandler):
    def get(self):
        self.response.headers['Content-Type'] = 'text/plain'
        mobile = Mobile()
        key = mobile.updateKey()
        id = mobile.key().id()
        self.response.out.write("{\"status\":200,\"id\":"+str(id)+",\"word\":"+str(key)+"}")
    
class RequestWord(webapp.RequestHandler):
    def get(self):
        id = int(self.request.get("id"))
        self.response.headers['Content-Type'] = 'text/plain'
        mobile = Mobile.get_by_id(id)
        if (mobile is None):
            self.response.out.write("{\"status\":400}")
        else:
            word = mobile.updateWord()
            self.response.out.write("{\"status\":200,\"word\":"+str(word)+"}")
            

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
            m = hashlib.sha1( str(mobile.getKey())+str(mobile.getWord()));
            hashServer = m.hexdigest()          
            #self.response.out.write("Server hashServer:"+str(hashServer))
            if (hashInput == hashServer):
                self.response.out.write("\"status\":200,\"word\":"+str(mobile.updateWord()))
            else:
                self.response.out.write("\"status\":401")
                
        self.response.out.write("}")
        

application = webapp.WSGIApplication([('/requestkey',RequestKey),('/requestword', RequestWord),('/toggledoor',ToggleDoor)], debug=True)


def main():
    run_wsgi_app(application)

if __name__ == "__main__":
    main()
    

