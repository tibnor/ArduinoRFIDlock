#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <sha1.h>
#include <EEPROM.h>

boolean equalHash(uint8_t* hash,String h) {
  boolean equal = true;
  char c;
  for (int i=0; i<20; i++) {
    c = "0123456789abcdef"[hash[i]>>4];
    if (c != h[i*2])
      equal = false;
    c = "0123456789abcdef"[hash[i]&0xf];
    if (c != h[i*2+1])
      equal = false;
  }
  return equal;
}

byte mac[] = { 
  0x00, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };

const char* ip_to_str(const uint8_t*);
static DhcpState prevState = DhcpStateNone;
static unsigned long prevTime = 0;

Server server(80);
String readString = String(30);
boolean doorIsOpen = true;

void setup()
{
  Serial.begin(9600);
  EEPROMWriteInt(0xFE, 0);
  EthernetDHCP.begin(mac, 1);
}

void loop()
{
  dhcpLoop();
  if(serverLoop(doorIsOpen)){
    doorIsOpen = !doorIsOpen; 
  }


}

void dhcpLoop()
{
  DhcpState state = EthernetDHCP.poll();

  if (prevState != state) {
    Serial.println();

    switch (state) {
    case DhcpStateDiscovering:
      Serial.print("Discovering servers.");
      break;
    case DhcpStateRequesting:
      Serial.print("Requesting lease.");
      break;
    case DhcpStateRenewing:
      Serial.print("Renewing lease.");
      break;
    case DhcpStateLeased: 
      {
        Serial.println("Obtained lease!");

        const byte* ipAddr = EthernetDHCP.ipAddress();
        const byte* gatewayAddr = EthernetDHCP.gatewayIpAddress();
        const byte* dnsAddr = EthernetDHCP.dnsIpAddress();

        Serial.print("My IP address is ");
        Serial.println(ip_to_str(ipAddr));

        Serial.print("Gateway IP address is ");
        Serial.println(ip_to_str(gatewayAddr));

        Serial.print("DNS IP address is ");
        Serial.println(ip_to_str(dnsAddr));

        Serial.println();

        Serial.println("Starting server");
        Ethernet.begin(mac, (byte*)ipAddr);
        server.begin();

        break;
      }
    }
  } 
  else if (state != DhcpStateLeased && millis() - prevTime > 300) {
    prevTime = millis();
    Serial.print('.'); 
  }

  prevState = state;
}

boolean serverLoop(boolean doorIsOpen)
{
  boolean toogleDoor = false;
  // listen for incoming clients
  Client client = server.available();
  if (client) {
    // an http request ends with a blank line
    boolean currentLineIsBlank = true;
    String requestString = "";
    boolean parsingRequest = false; 
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        if (readString.length() < 100) {
          //store characters to string
          readString += c;

          if (parsingRequest == true) {
            requestString += c;
          }

          if (readString.endsWith("GET ")) {
            parsingRequest = true;
          }

          if (requestString.endsWith(" ") && parsingRequest == true) {
            parsingRequest = false;
            if(requestString.startsWith("/toggle")){
              String password = "293817605955944458611932855688381892606222593904";

              // Compare id  recived with old id and check if it has been used
              unsigned int oldId = EEPROMReadInt(0xFE);
              String idS=requestString.substring(11,21);
              char buf[11];
              idS.toCharArray(buf,11);
              unsigned int id = atoi(&(buf[0]));
              if(id<oldId){
                Serial.println("old id");
                client.print("{\"id\":\"");
                client.print(oldId);
                client.print("\",\"status\":400}");
              } 
              else {
                
                // Check if hash is correct
                String hash=requestString.substring(27).trim();
                Sha1.init();
                Sha1.print(password+idS);
                if(equalHash(Sha1.result(),hash)){
                  Serial.println("Hash equal");
                  EEPROMWriteInt(0xFE, id+1);
                  // Return new id
                  client.print("{\"id\":\"");
                  client.print(id+1);
                  client.print("\",\"open\":");
                  client.print(!doorIsOpen);
                  client.print(",\"status\":200}");
                }
                else {
                  //Serial.println("Hash not equal");
                  client.print("{\"status\":403}");
                }
              }
              client.println();
            }
            // Serial.print("REQ: ");
            // Serial.println(requestString);
          }       
        }

        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {
          break;
        }
        if (c == '\n') {
          // you're starting a new line
          currentLineIsBlank = true;
        } 
        else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
        }
      }
    }
    // give the web browser time to receive the data
    delay(1);
    readString="";
    // close the connection:
    client.stop();
  }
}

// Just a utility function to nicely format an IP address.
const char* ip_to_str(const uint8_t* ipAddr)
{
  static char buf[16];
  sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  return buf;
}

void EEPROMWriteInt(int p_address, int p_value)
{
  byte lowByte = ((p_value >> 0) & 0xFF);
  byte highByte = ((p_value >> 8) & 0xFF);

  EEPROM.write(p_address, lowByte);
  EEPROM.write(p_address + 1, highByte);
}

//This function will read a 2 byte integer from the eeprom at the specified address and address + 1
unsigned int EEPROMReadInt(int p_address)
{
  byte lowByte = EEPROM.read(p_address);
  byte highByte = EEPROM.read(p_address + 1);
  return ((lowByte << 0) & 0xFF) + ((highByte << 8) & 0xFF00);
}







