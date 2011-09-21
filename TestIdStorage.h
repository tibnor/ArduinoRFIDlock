#ifndef IdStorageTest_h
#define IdStorageTest_h

//#include "WProgram.h"
//#include "HardwareSerial.h"
#ifndef TEST
#define TEST
#include <ArduinoTestSuite.h>
#endif
class IdStorageTest {
  public:
    IdStorageTest();
  private:
    void testSaveUserLoad();
    void testSaveAdminLoad();
};
#endif
