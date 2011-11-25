from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app
from google.appengine.ext import db
import random
import hashlib
from password import Password

class MainPage(webapp.RequestHandler):
    def get(self):
        id = self.request.get("id")
        self.response.headers['Content-Type'] = 'text/plain'
        mobile = Mobile.get_or_insert(id)
        key = mobile.updateKey()
        self.response.out.write(key)

class ToggleDoor(webapp.RequestHandler):
    def get(self):
        id = self.request.get("id")
        hashInput = self.request.get("hash")
        mobile = Mobile.get_by_key_name(id)
        self.response.headers['Content-Type'] = 'text/plain'
        #self.response.out.write("input hashInput:"+str(hashInput)+"\n") 
        self.response.out.write("{")
        if (mobile is None):
            self.response.out.write("\"status\":400")
        else:
            #self.response.out.write("Key:"+str(mobile.getKey())+"\n")
            m = hashlib.sha1( str(mobile.getKey()+Password.mobileServerPass));
            hashServer = m.hexdigest()          
            #self.response.out.write("Server hashServer:"+str(hashServer))
            if (hashInput == hashServer):
                #self.response.out.write("\nTrue")
                self.response.out.write("\"status\":200,\"key\":"+str(mobile.updateKey()))
            else:
                self.response.out.write("\"status\":401")
                
        self.response.out.write("}")
        

application = webapp.WSGIApplication([('/requestkey', MainPage),('/toggledoor',ToggleDoor)], debug=True)


def main():
    run_wsgi_app(application)

if __name__ == "__main__":
    main()
    
class Mobile(db.Model):
    Key = db.IntegerProperty()
    
    def updateKey(self):  
        key = random.randint(0,4611686018427387904)      
        self.Key = key
        self.put()
        return key
    
    def getKey(self):
        return self.Key
