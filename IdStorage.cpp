#include "IdStorage.h"

IdStorage::IdStorage() {
  //TODO: Read from EPROM
  idPos = 0;
}

boolean IdStorage::storeId(byte id[12]) {
  //Check if storage is full
  if (idPos >= 19) return false;
  
  //All Ok, store id
  for (int i = 0; i < 12; i = i + 1){
    ids[idPos][i] = id[i];
  }
  idPos = idPos + 1;    
  //TODO: Store in EPROM
  return true;
}

void IdStorage::printIds() {
  for (int i = 0; i < idPos; i = i + 1) {
    Serial.print("Id");
    Serial.print(i);
    Serial.print(": ");
    for (int j = 0; j < 12; j = j + 1) {
      Serial.print(ids[i][j],BYTE);
     }
     Serial.println(", ");
   }
   Serial.println("Done");
}
