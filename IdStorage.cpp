#include "IdStorage.h"
#include <EEPROM.h>


IdStorage::IdStorage() {
  //TODO: Read from EPROM
  idPos = 0;
  idAdmin[0] = 0x00;
}

boolean IdStorage::storeId(byte id[ID_SIZE]) {
  //Check if storage is full
  if (idPos >= 19) return false;

  //Check if there is an admin, if not store it
  if (idAdmin[0] == 0x00) {
    for (int i = 0; i < ID_SIZE; i = i + 1){
      idAdmin[i] = id[i];
    }
    return true;
  }

  if(typeOfUser(id)==UNKNOWN){

    //All Ok, store id
    for (int i = 0; i < ID_SIZE; i = i + 1){
      ids[idPos][i] = id[i];
    }
    idPos = idPos + 1;    
    //TODO: Store in EPROM
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
  
  //Read IDs
  int address = 1;
  for (int i = 0; i < idPos; i = i + 1) {  
    for (int j = 0; j < ID_SIZE; j = j + 1) {
      ids[i][j] = EEPROM.read(address);
      address = address + 1;
    }
  }
}

void IdStorage::storeEEPROM() {  
  //Store number of IDs in first byte
  EEPROM.write(0,idPos);
  
  //Store IDs
  int address = 1;
  for (int i = 0; i < idPos; i = i + 1) {  
    for (int j = 0; j < ID_SIZE; j = j + 1) {
      EEPROM.write(address,ids[i][j]);
      address = address + 1;
    }
  }
}


