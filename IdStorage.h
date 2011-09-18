#ifndef IdStorage_h
#define IdStorage_h

#include "WProgram.h"
#define UNKNOWN 0
#define USER 1
#define ADMIN 2
#define ID_SIZE 12

class IdStorage {
  public:
    IdStorage();
    boolean storeId(byte id[ID_SIZE]);
    boolean matches(byte id[ID_SIZE]);
    boolean TagMatch(byte sFirst[ID_SIZE],byte sSecond[ID_SIZE]);
    void printIds();
    byte typeOfUser(byte tag[ID_SIZE]);
  private:
    int idPos;
    byte ids[20][ID_SIZE];
    byte idAdmin[ID_SIZE];
    void storeEEPROM();
    void loadEEPROM();
};

#endif
