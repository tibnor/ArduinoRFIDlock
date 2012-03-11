
#include <NewSoftSerial.h>
#include <EEPROM.h>
#include <Servo2.h>
/*#ifndef TEST
 #define TEST
 #include <ArduinoTestSuite.h>
 #include "TestIdStorage.h"
 #endif
 */
#include "IdStorage.h"



Servo myservo;

const int SerInToArdu=2; //Defines pin data passes to Arduino over from RFID reader
const int SerOutFrmArdu=4; //Not used, but
//"fills" a parameter in the set up of
//mySerialPort
const int buttonPin = 8; // Digital pin for button
int lastButton = HIGH;
int currentButton = HIGH; 

const int ACCESS_DENIED = 0;
const int TOGGLE_DOORE_LOCK = 1;
const int TOGGLE_ADMIN_MODE = 2;

const int SERVO_PIN = 9;
const int RED_LED_PIN = 6;   
const int GREEN_LED_PIN = 10;
const int BLUE_LED_PIN = 11;
const int INTERNAL_LED = 5;
const int DOOR_BUTTON_PIN = 7;

const int RED_INTENSITY = 100;
const int GREEN_INTENSITY = 100;

boolean doorIsOpen = true;


NewSoftSerial mySerialPort(SerInToArdu,SerOutFrmArdu);
//  Creates serial port for RFID reader to be attached to.
//  Using pins 0 and 1 is problematic, as they are also
//     connecting the development PC to the Arduino for
//     programming, and for the output sent to the serial
//     monitor.

byte id[12];
int bytePos = 0;
int incomingByte=0;
IdStorage theStorage;


#define STATE_ADD_USER 0
#define STATE_DOOR_LOCK 1
byte state = STATE_DOOR_LOCK;

void setup()
{
  Serial.begin(9600);//For access to serial monitor channel
  Serial.println("*******");
  Serial.println("READY");
  delay(1000);
  mySerialPort.begin(9600);
  theStorage = IdStorage();
  myservo.attach(SERVO_PIN);
  myservo.write(90);
  pinMode(buttonPin,INPUT);
  theStorage.clear();
  theStorage.printIds();
  // IdStorageTest test;
  setCorrectLight();


};

void loop()
{
  // Check RFID reader
  while (mySerialPort.available() > 0) {
    // read the incoming byte from the serial buffer
    incomingByte = mySerialPort.read();

    if(incomingByte != 2 && incomingByte != 3) {
      Serial.print(incomingByte);
      id[bytePos] = incomingByte;
      bytePos = bytePos + 1;
    }
    else if (incomingByte==3) {
      bytePos = 0;
      Serial.println();
    }
    else if (incomingByte==2) {
      bytePos = 0;
      Serial.print("ID: ");
    }
  }

  // Check lock button
  currentButton = debounce(lastButton);
  if (lastButton == HIGH && currentButton == LOW) {
    lastButton = currentButton;
    buttonLoop();
  }
  delay(5);
  lastButton = currentButton;

  // Check usb
  while (Serial.available() > 0) {
    switch (Serial.read()) {
    case '0':
      blinkLight(255, 0, 0, 300, 5);
      break;
    case '1':
      toggleDoorLock();
      break;
    case '2':
      setState(STATE_DOOR_LOCK);
      break;
    case '3':
      setState(STATE_ADD_USER);
      break;  

    }
  }
}

void buttonLoop(){
  int ms = 0;
  int cycle = 0;
  int led = 255;
  int blinkPeriod = 500;

  analogWrite(INTERNAL_LED,led);
  changeColor(led,led,0);

  // Waiting for realese of button
  while(isButtonPushed())
    delay(20);

  // Waiting for button to be pushed or door to open
  while( doorIsOpen && (isDoorClosed() || isButtonPushed()) ){
    delay(20);
  }


  while (true){
    ms += 5;
    cycle += 5;
    delay(5);
    //currentButton = debounce(lastButton);
    if (isDoorClosed())//(lastButton == HIGH && currentButton == LOW){
      break;


    if (cycle >= blinkPeriod){
      cycle = 0;

      if(led == 0)
        led = 255;
      else
        led = 0;

      analogWrite(INTERNAL_LED,led);
      changeColor(led,led,0);
    }

  }
  analogWrite(INTERNAL_LED,0);
  changeColor(0,0,0);
  delay(500);
  toggleDoorLock();
}

boolean debounce(boolean last)
{
  boolean current = digitalRead(buttonPin);
  if (last != current) {
    delay(5);
    current = digitalRead(buttonPin);
  }
  return current;
}


void setState(int newState){
  state = newState;
  setCorrectLight();
}

void toggleDoorLock() {

  if (doorIsOpen) {
    Serial.println("Locking door");
    //myservo.write(5);
    turnCW(800);
  } 
  else {
    Serial.println("Opening door");
    turnCCW(800);
    //myservo.write(175);
  }

  doorIsOpen = !doorIsOpen;
  setCorrectLight();
}

void turnCCW(int waitTime) {
  myservo.write(180);
  redToGreen(waitTime);
  myservo.write(90);
}

void turnCW(int waitTime) {
  myservo.write(0);
  greenToRed(waitTime);
  myservo.write(90);
}

boolean isButtonPushed() {
  return digitalRead(buttonPin) == LOW;
}

boolean isDoorClosed() {
  return digitalRead(DOOR_BUTTON_PIN) == LOW;
}

void changeColor(int red, int green, int blue){
  analogWrite(RED_LED_PIN,red);
  analogWrite(GREEN_LED_PIN,green);
  analogWrite(BLUE_LED_PIN,blue);
}

void setCorrectLight(){
  if (state ==  STATE_DOOR_LOCK){
    if(doorIsOpen) {
      analogWrite(INTERNAL_LED,0);
      changeColor(0,GREEN_INTENSITY,0);
    } 
    else {
      changeColor(RED_INTENSITY,0,0);
      analogWrite(INTERNAL_LED,100);
    }
  } 
  else {
    changeColor(0,0,255);
  }
}

void blinkLight(int red, int green, int blue, int period, int cycles) {
  for (int i = 0; i<cycles; i++) {
    changeColor(red,green,blue);
    delay(period/2);
    changeColor(0,0,0);
    delay(period/2);
  }  
}


void redToGreen(int waitTime) {
  int red = RED_INTENSITY;
  int green = 0;
  int waitedTime = 0;
  for (int i = 0; i<RED_INTENSITY; i++) {
    red --; 
    changeColor(red,green,0);
    delay(2);
    waitedTime = waitedTime + 2;
  }  
  for (int i = 0; i<255; i++) {
    green ++;
    changeColor(red,green,0);
    delay(1);
    waitedTime++;
  } 
  delay(waitTime-waitedTime);
}


void greenToRed(int waitTime) {
  int red = 0;
  int green = GREEN_INTENSITY;
  int waitedTime = 0;
  for (int i = 0; i<GREEN_INTENSITY; i++) {
    green --; 
    changeColor(red,green,0);
    delay(2);
    waitedTime = waitedTime + 2;
  }  
  for (int i = 0; i<255; i++) {
    red ++;
    changeColor(red,green,0);
    delay(1);
    waitedTime++;
  }  
  delay(waitTime-waitedTime);
}






