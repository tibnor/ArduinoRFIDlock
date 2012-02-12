#ifndef IdStorage_h
#define IdStorage_h

#include "WProgram.h"
#define UNKNOWN 0
#define USER 1
#define ADMIN 2
#define ID_SIZE 6

class IdStorage {
  public:
    IdStorage();
    boolean storeId(byte id[ID_SIZE]);
    boolean matches(unsigned int id[ID_SIZE]);
    boolean TagMatch(unsigned int sFirst[ID_SIZE],unsigned int sSecond[ID_SIZE]);
    void printIds();
    byte typeOfUser(byte tag[12]);
    byte typeOfUser(unsigned int tag[ID_SIZE]);
    void clear();
    void storeEEPROM();
    void loadEEPROM();
  private:
    byte idPos;
    void setNumberOfTags(int n);
    void dumpEEPROM();
    unsigned int ids[80][ID_SIZE];
    unsigned int idAdmin[ID_SIZE];
    unsigned int SerialReadToInt(byte c1, byte c2);
    int SerialReadToInt(byte c);

};

#endif
