
#include <NewSoftSerial.h>
#include "IdStorage.h"


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

byte id[12];
int bytePos = 0;
int incomingByte=0;
IdStorage theStorage;

void setup()
{
  Serial.begin(9600);//For access to serial monitor channel
  Serial.println("Bring an RFID tag near the reader...");
  mySerialPort.begin(9600);
  theStorage = IdStorage();
  
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
      theStorage.storeId(id);
      theStorage.printIds();

    }
  }
  delay(10);
}









