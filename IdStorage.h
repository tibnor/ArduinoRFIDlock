#ifndef IdStorage_h
#define IdStorage_h

#include "WProgram.h"
#define UNKNOWN 0
#define USER 1
#define ADMIN 2

class IdStorage {
  public:
    IdStorage();
    boolean storeId(byte id[12]);
    boolean matches(byte id[12]);
    boolean TagMatch(byte sFirst[12],byte sSecond[12]);
    void printIds();
    byte typeOfUser(byte tag[12]);
  private:
    int idPos;
    byte ids[20][12];
    byte idAdmin[12];
    void storeEPROM();
};

#endif
