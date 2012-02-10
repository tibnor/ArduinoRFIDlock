#include "IdStorage.h"
#include <EEPROM.h>

IdStorage::IdStorage() {
  loadEEPROM();
  dumpEEPROM();
  //setNumberOfTags(0);
  idAdmin[0] = ((0*16+14)*16+0)*16+0;
  idAdmin[1] = ((15*16+4)*16+1)*16+4;
  idAdmin[2] = ((0*16+13)*16+14)*16+3;
}

boolean IdStorage::storeId(byte id[12]) {
  //Check if storage is full
  if (idPos >= 80) return false;
  
  
  unsigned int idI[ID_SIZE];
  for (int i = 0; i < ID_SIZE; i = i + 1){
      idI[i] = SerialReadToInt(id[i*4],id[i*4+1],id[i*4+2],id[i*4+3]);
  }
  
  if(typeOfUser(idI)==UNKNOWN){
  for (int i = 0; i < ID_SIZE; i = i + 1){
      ids[idPos][i] = idI[i];
  }
    //All Ok, store id

    idPos = idPos + 1; 
    storeEEPROM();
    return true;
  }
  else 
    return false;
}

void IdStorage::printIds() {
  Serial.print("Admin: ");
  for (int j = 0; j < ID_SIZE; j = j + 1) {
    Serial.print(idAdmin[j]);
  }
  Serial.println();

  //Print users
  for (int i = 0; i < idPos; i = i + 1) {  
    Serial.print("Id");
    Serial.print(i);
    Serial.print(": ");
    for (int j = 0; j < ID_SIZE; j = j + 1) {
      Serial.print(ids[i][j]);
    }
    Serial.print(" ");
    Serial.print(SerialReadToInt(ids[i][0],ids[i][1],ids[i][2],ids[i][3]));
    Serial.print(" ");
    Serial.print(SerialReadToInt(ids[i][4],ids[i][5],ids[i][6],ids[i][7]));
    Serial.print(" ");
    Serial.print(SerialReadToInt(ids[i][8],ids[i][9],ids[i][10],ids[i][11]));
    Serial.println(", ");
  }
  Serial.println("Done");
}

boolean IdStorage::TagMatch(unsigned int sFirst[ID_SIZE],unsigned int sSecond[ID_SIZE])
{ 
  for (int i=0; i<ID_SIZE; i++)
  {
    if (sFirst[i]!=sSecond[i])
    {
      return false;
    };
  } 
  return true;
};//end of TagMatch

#define UNKNOWN 0
#define USER 1
#define ADMIN 2
byte IdStorage::typeOfUser(unsigned int tag[ID_SIZE]) {
  Serial.print("id on card: ");
  for (int j = 0; j < ID_SIZE; j = j + 1) {
    Serial.print(tag[j]);
  }
  Serial.println();

  for (byte i = 0; i<idPos;i++){
    if(TagMatch(ids[i],tag))
      return USER;
  }

  if(TagMatch(tag,idAdmin))
    return ADMIN; 
  else
    return UNKNOWN;
};

byte IdStorage::typeOfUser(byte id[12]) {
  unsigned int idI[ID_SIZE];
  for (int i = 0; i < ID_SIZE; i = i + 1){
      idI[i] = SerialReadToInt(id[i*4],id[i*4+1],id[i*4+2],id[i*4+3]);
  }
  return typeOfUser(idI);
};

void IdStorage::dumpEEPROM() {
  Serial.println("Dumping EEPROM\n");
  for (int i = 0; i < 1024; i++) {  
    Serial.print((byte) EEPROM.read(i),BYTE);
  }
    Serial.println("Done");
}

void IdStorage::setNumberOfTags(int n){
    EEPROM.write(0x00,n);
    loadEEPROM();
}

void IdStorage::loadEEPROM() {
  //Read number of IDs in first byte
  idPos = EEPROM.read(0);

  int address = 0x01;
  if(idPos > 0) {
    for (int i = 0; i < idPos; i++) {  
      for (int j = 0; j < ID_SIZE; j = j + 1) {
        ids[i][j] = (unsigned int) EEPROM.read(address);
        address ++;
      }
    }
  }
}

void IdStorage::storeEEPROM() {    
  // Save number of users
  EEPROM.write(0x00,idPos);
  int address = 0x01;

  // Save users
  if (idPos > 0) {
    for (int i = 0; i < idPos; i++) {  
      for (int j = 0; j < ID_SIZE; j = j + 1) {
        EEPROM.write(address,ids[i][j]);
        address ++;
      }
    }
  }


}

void IdStorage::clear() {
  idPos = 0;
}

int IdStorage::SerialReadToInt(byte c)
{
    if (c >= '0' && c <= '9') {
	  return c - '0';
    } else if (c >= 'A' && c <= 'F') {
	  return c - 'A' + 10;
    } else {
        Serial.println('error in convertion of hex to int');
	  return 0;   // getting here is bad: it means the character was invalid
    }
}

unsigned int IdStorage::SerialReadToInt(byte c1, byte c2, byte c3, byte c4)
{
    unsigned int n = SerialReadToInt(c1);
    n *= 16;
    n += SerialReadToInt(c2);
    n *= 16;
    n += SerialReadToInt(c3);
    n *= 16;
    n += SerialReadToInt(c4);
    return n;
}








