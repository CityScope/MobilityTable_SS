#include <SPI.h>

#include <Ethernet.h>

#include <EthernetUdp.h>

#define PIN_SLIDE_A A0
#define PIN_SLIDE_B A1
#define BUTTON_A 2
#define BUTTON_B 3
#define BUTTON_C 4
#define BUTTON_D 5
boolean buttonState_A;
boolean buttonState_B;
boolean buttonState_C;
boolean buttonState_D;
int A, B, C, D;
int AA, BB, CC, DD;
#define DOWN 0

void setup() {

  pinMode(PIN_SLIDE_A, INPUT);
  pinMode(PIN_SLIDE_B, INPUT);
  pinMode(BUTTON_A, INPUT_PULLUP);
  AA = digitalRead(BUTTON_A);
  pinMode(BUTTON_B, INPUT_PULLUP);
  BB = digitalRead(BUTTON_B);
  pinMode(BUTTON_C, INPUT_PULLUP);
  CC = digitalRead(BUTTON_C);
  pinMode(BUTTON_D, INPUT_PULLUP);
  DD = digitalRead(BUTTON_D);
  Serial.begin(9600);
}

void loop() {
    
    Serial.print(",");
    Serial.print("0:");
    Serial.print(int(analogRead(PIN_SLIDE_A)*5.0/1024*3));
    Serial.print(",");
    delay(0);

    Serial.print("1:");
    Serial.print(int(analogRead(PIN_SLIDE_B)*5.0/1024*5));
    Serial.print(",");
    delay(0);

    A = AA;
    AA = digitalRead(BUTTON_A);
    if (A == DOWN && AA != DOWN){
      buttonState_A = !buttonState_A;
    }
    Serial.print("2:");
    Serial.print(buttonState_A);
    Serial.print(",");
    delay(0);

    B = BB;
    BB = digitalRead(BUTTON_B);
    if (B == DOWN && BB != DOWN){
      buttonState_B = !buttonState_B;
    }
    Serial.print("3:");
    Serial.print(buttonState_B);
    Serial.print(",");
    delay(0);

    C = CC;
    CC = digitalRead(BUTTON_C);
    if (C == DOWN && CC != DOWN){
      buttonState_C = !buttonState_C;
    }
    Serial.print("4:");
    Serial.print(buttonState_C);
    Serial.print(",");
    delay(0);

    D = DD;
    DD = digitalRead(BUTTON_D);
    if (D == DOWN && DD != DOWN){
      buttonState_D = !buttonState_D;
    }
    Serial.print("5:");
    Serial.print(buttonState_D);
    Serial.println();
    delay(0);
}