#if defined(ARDUINO) && ARDUINO > 18
#include <SPI.h>
#endif
#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <sha1.h>
#include <EEPROM.h>

void printHash(uint8_t* hash) {
  int i;
  for (i=0; i<20; i++) {
    Serial.print(byte(hash[i]),BYTE);
  }
  Serial.println();
}

boolean equalHash(uint8_t* hash,String h) {
  boolean equal = true;
  for (int i=0; i<20; i++) {
    if (hash[i] != byte(h[i]))
      equal = false;
  }
  return equal;
}

byte mac[] = { 
  0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };

const char* ip_to_str(const uint8_t*);
static DhcpState prevState = DhcpStateNone;
static unsigned long prevTime = 0;

Server server(80);
String readString = String(30);

void setup()
{
  Serial.begin(9600);
EEPROMWriteInt(0xFE, 0);
  EthernetDHCP.begin(mac, 1);
}

void loop()
{
  dhcpLoop();
  serverLoop();


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

        // Since we're here, it means that we now have a DHCP lease, so we
        // print out some information.
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

void serverLoop()
{
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
            //client.println("HTTP/1.1 200 OK");
            //client.println("Content-Type: text/plain");
            //client.println();
            //client.print("You requested: ");
            //client.print(requestString);
            //client.println("<br />");
            if(requestString.startsWith("/toggle")){
              String password = "293817605955944458611932855688381892606222593904";
              unsigned int oldId = EEPROMReadInt(0xFE);
              String idS=requestString.substring(11,21);
              char buf[11];
              idS.toCharArray(buf,11);
              unsigned int id = atoi(&(buf[0]));
              Serial.println("id: ");
              Serial.println(id);
              Serial.println(oldId);
              if(id<oldId){
                Serial.println("old id");
                client.print("{\"id\":\"");
                client.print(oldId);
                client.print("\",\"error\":403}");
              } else {
              String hash=requestString.substring(27).trim();
              Sha1.init();
              Sha1.print(password+idS);
              if(equalHash(Sha1.result(),hash)){
                Serial.println("Hash equal");
                EEPROMWriteInt(0xFE, id+1);
                client.print("{\"id\":\"");
                client.print(id+1);
                client.print("\",\"open\":1}");
              }
              else {
                Serial.println("Hash not equal");
                Serial.println(password+idS);
                printHash(Sha1.result());
                client.print("{\"error\":403}");
              }
              }
               client.println();
            }
            Serial.print("REQ: ");
            Serial.println(requestString);
 }       
 }
        //Serial.print(c);

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






