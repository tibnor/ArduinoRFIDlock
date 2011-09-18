
#include <NewSoftSerial.h>
#include <Servo2.h>
#include "IdStorage.h"

Servo myservo;

const int SerInToArdu=2; //Defines pin data passes to Arduino over from RFID reader
const int SerOutFrmArdu=3; //Not used, but
//"fills" a parameter in the set up of
//mySerialPort

NewSoftSerial mySerialPort(SerInToArdu,SerOutFrmArdu);
//  Creates serial port for RFID reader to be attached to.
//  Using pins 0 and 1 is problematic, as they are also
//     connecting the development PC to the Arduino for
//     programming, and for the output sent to the serial
//     monitor.

byte id[ID_SIZE];
int bytePos = 0;
int incomingByte=0;
IdStorage theStorage;

#define STATE_ADD_USER 0
#define STATE_DOOR_LOCK 1
byte state = STATE_ADD_USER;

void setup()
{
  Serial.begin(9600);//For access to serial monitor channel
  Serial.println("Bring an RFID tag near the reader...");
  mySerialPort.begin(9600);
  theStorage = IdStorage();
  myservo.attach(9);
  myservo.write(90);

};

void loop()
{
  while (mySerialPort.available() > 0) {
    // read the incoming byte from the serial buffer
    incomingByte = mySerialPort.read();

    if(incomingByte != 2 && incomingByte != 3) {
      id[bytePos] = incomingByte;
      bytePos = bytePos + 1;
    }
    if (incomingByte==3) {
      bytePos = 0;

      int userType = theStorage.typeOfUser(id);
      Serial.print("Type of user: ");
      switch (userType) {
        case (USER):
        Serial.println("USER");
        break;
        case (ADMIN):
        Serial.println("ADMIN");
        break;
        case (UNKNOWN):
        Serial.println("UNKNOWN");
        break;
      }

      if (state == STATE_ADD_USER){
        if (userType == UNKNOWN)
          theStorage.storeId(id);
        else if (userType == ADMIN){
          state = STATE_DOOR_LOCK;
          Serial.println("State: door lock");
        }

        theStorage.printIds();
      } 
      else {
        switch (userType) {
          case (USER):
          toggleDoorLock();
          break;
          case (ADMIN):
          state = STATE_ADD_USER;
          Serial.println("State: add user");
          break;
          case (UNKNOWN):
          Serial.println("Access denied!");
          break;
        }
      }

    }
  }
  delay(10);
}

void toggleDoorLock() {
  static boolean doorIsOpen = true;
  if (doorIsOpen) {
    Serial.println("Locking door");
    //myservo.write(5);
    turnCW(600);
  } 
  else {
    Serial.println("Opening door");
    turnCCW(600);
    //myservo.write(175);
  }

  doorIsOpen = !doorIsOpen;
}

void turnCW(int waitTime) {
  //myservo.attach(9);
  //myservo.writeMicroseconds(2000);
  myservo.write(180);
  delay(waitTime);
  //myservo.writeMicroseconds(1500);
  myservo.write(90);
  //myservo.detach();
}

void turnCCW(int waitTime) {
  //myservo.attach(9);
  //myservo.writeMicroseconds(1000);
  myservo.write(0);
  delay(waitTime);
  //myservo.writeMicroseconds(1500);
  myservo.write(90);
  //myservo.detach();
}












