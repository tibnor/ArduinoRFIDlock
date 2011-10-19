#include "IdStorage.h"
#include <EEPROM.h>

IdStorage::IdStorage() {
  loadEEPROM();
  idAdmin[0] = '0';
  idAdmin[1] = 'E';
  idAdmin[2] = '0';
  idAdmin[3] = '0';
  idAdmin[4] = 'F';
  idAdmin[5] = '4';
  idAdmin[6] = '1';
  idAdmin[7] = '4';
  idAdmin[8] = '0';
  idAdmin[9] = 'D';
  idAdmin[10] = 'E';
  idAdmin[11] = '3';
}

boolean IdStorage::storeId(byte id[ID_SIZE]) {
  //Check if storage is full
  if (idPos >= 19) return false;

  if(typeOfUser(id)==UNKNOWN){

    //All Ok, store id
    for (int i = 0; i < ID_SIZE; i = i + 1){
      ids[idPos][i] = id[i];
    }
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
    Serial.print(idAdmin[j],BYTE);
  }
  Serial.println();

  //Print users
  for (int i = 0; i < idPos; i = i + 1) {  
    Serial.print("Id");
    Serial.print(i);
    Serial.print(": ");
    for (int j = 0; j < ID_SIZE; j = j + 1) {
      Serial.print(ids[i][j],BYTE);
    }
    Serial.println(", ");
  }
  Serial.println("Done");
}

boolean IdStorage::TagMatch(byte sFirst[ID_SIZE],byte sSecond[ID_SIZE])
{ 
  for (byte bTmp=1; bTmp < 11; bTmp++)
  {
    if (sFirst[bTmp]!=sSecond[bTmp])
    {
      return false;
    };
  } 
  return true;
};//end of TagMatch

#define UNKNOWN 0
#define USER 1
#define ADMIN 2
byte IdStorage::typeOfUser(byte tag[ID_SIZE]) {
  Serial.print("id on card: ");
  for (int j = 0; j < ID_SIZE; j = j + 1) {
    Serial.print(tag[j],BYTE);
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

void IdStorage::loadEEPROM() {
  //Read number of IDs in first byte
  idPos = EEPROM.read(0);
  
  int address = 0x01;
  if(idPos > 0) {
    for (int i = 0; i < idPos; i++) {  
      for (int j = 0; j < ID_SIZE; j = j + 1) {
        ids[i][j] = (byte) EEPROM.read(address);
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






