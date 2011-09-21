#include "TestIdStorage.h"

#include "IdStorage.h"

IdStorage theStorageTest;

IdStorageTest::IdStorageTest() {
     ATS_begin("Arduino", "Test of EEPROM storage");
     testSaveUserLoad();
     testSaveAdminLoad();
     ATS_end();
  }
  
void IdStorageTest::testSaveUserLoad() {
  byte admin[12] = {0x50,0x50,0x50,0x50,0x50,0x50,0x50,0x50,0x50,0x50,0x50,0x50};
  byte user[12] = {0x51,0x51,0x51,0x51,0x51,0x51,0x51,0x51,0x51,0x51,0x51,0x51};

  theStorageTest.storeId(admin);
  theStorageTest.storeId(user);
  //theStorageTest.storeEEPROM();
    theStorageTest.clear();
  theStorageTest.loadEEPROM();
  byte typeUser = theStorageTest.typeOfUser(user);
  ATS_PrintTestStatus("test save/load user", typeUser == 1);
};

void IdStorageTest::testSaveAdminLoad() {
  byte admin[12] = {0x50,0x50,0x50,0x50,0x50,0x50,0x50,0x50,0x50,0x50,0x50,0x50};
  byte user[12] = {0x51,0x51,0x51,0x51,0x51,0x51,0x51,0x51,0x51,0x51,0x51,0x51};
  theStorageTest.storeId(admin);
  theStorageTest.storeId(user);

  //theStorageTest.storeEEPROM();
  theStorageTest.clear();
  theStorageTest.loadEEPROM();
  byte typeUser = theStorageTest.typeOfUser(admin);
  ATS_PrintTestStatus("test save/load admin", typeUser == 2);
};
