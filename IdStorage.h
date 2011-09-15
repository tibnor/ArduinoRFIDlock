#ifndef IdStorage_h
#define IdStorage_h

#include "WProgram.h"

class IdStorage {
  public:
    IdStorage();
    boolean storeId(byte id[12]);
    boolean matches(byte id[12]);
    void printIds();
  private:
    int idPos;
    byte ids[20][12];
    void storeEPROM();
};

#endif
