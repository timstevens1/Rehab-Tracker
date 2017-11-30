// EMPI Usage Monitoring
// Blake Hewgill & Javier Bunuel, University of Vermont
// Capstone Design, Spring 2017
boolean testMode = true;

#include <EEPROMex.h>
#include <SPI.h>
#include <lib_aci.h>
#include <aci_setup.h>
#include <RBL_nRF8001.h>
#include <RBL_services.h>

#include <Wire.h>
#include "RTClib.h"

int sensorPin1 = A0;    // select the input pin for channel 1
int sensorPin2 = A1;    // select the input pin for channel 2
int sensorValue = 0;  // variable to store the value coming from the sensor
int sampleNum1 = 0;  // Sample number
int sampleNum2 = 0;  // Sample number
int sampleArray1[100]; // Should be 90 samples in an hour long session (one each 40 seconds). Extras to be safe.
long arrayTot1 = 0; // A running sum of the contents of sampleArray to be divided by sampleNum for averaging
float arrayAvg1 = 0; // A running avg of the above
int sampleArray2[100]; // Should be 90 samples in an hour long session (one each 40 seconds). Extras to be safe.
long arrayTot2 = 0; // A running sum of the contents of sampleArray to be divided by sampleNum for averaging
float arrayAvg2 = 0; // A running avg of the above
int sessionCount; //= EEPROM.write(0, 0x00);
int currentAddress; //= EEPROM.write(1,0x15);

float sessionComp=0;
int ant1 = 0;
int next1 = 0;
int maxVal1 = 0;
int ant2 = 0;
int next2 = 0;
int maxVal2 = 0;

void initialize();
void ButtonInterrupt();
void WriteStorage();
void ArrayAdd(float intensityValue, int channel);
float IntensityMap(int sensorValue);

bool flag = false;

long startTime;
long endTime;
DateTime now;
RTC_DS1307 rtc;

void setup() {
  // Initialize what we need in here
  EEPROM.setMaxAllowedWrites(32768);
  //EEPROM.setMaxAllowedWrites(EEPROMSizeUno);

  EEPROM.updateInt(0, 0);
  EEPROM.writeInt(2, 2);

  //currentAddress = EEPROM.readInt(2);
  currentAddress = 2;
  sessionCount = EEPROM.readInt(0);

  if (testMode) { //start serial com
    Serial.begin(57600);
    Serial.print("SessionCount = ");
    Serial.println(sessionCount);
  }


  Serial.begin(57600);

  if (! rtc.begin()) {
    Serial.println("Couldn't find RTC");
    //while (1);
  }

  if (! rtc.isrunning()) {
    Serial.println("RTC is NOT running!");
    // following line sets the RTC to the date & time this sketch was compiled
    rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
    // This line sets the RTC with an explicit date & time, for example to set
    // January 21, 2014 at 3am you would call:
    // rtc.adjust(DateTime(2014, 1, 21, 3, 0, 0));
  }


  ble_set_name("RT");
  ble_begin(); //ble_begin starts the BLE stack and broadcasting the advertising packet
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void loop()
{
  //analogWrite(LED1, 10);
  long i = 0;
  while ((analogRead(sensorPin1) <= 10 && analogRead(sensorPin2) <= 10) || (sampleNum1 >= 90 || sampleNum2 >= 90)) {
    Serial.println("Not running");
    ButtonInterrupt();
    Serial.print("While-loop at:");
    Serial.println(i);
    delay(1);
    i++;
    if (i == 120000) {
      EEPROM.updateInt(0, sessionCount);
      sessionCount++;
      initialize();
      Serial.println("If Statement Complete!");
    }
  }

  /*
    //EEPROM only stores one session. We will change this later
    while (sampleNum1 > 90 || sampleNum2 > 90) {
    ButtonInterrupt();
    Serial.println("This session has finished.");
    }
  */

  /*
    while(1)
    {
    ButtonInterrupt();
    }
  */
  //Store the start time when a session starts
  if (sampleNum1 == 0 || sampleNum2 == 0) {
    now = rtc.now();
    startTime = now.unixtime();
  }

  //Store the start time when a session starts
  if (sampleNum1 == 0 || sampleNum2 == 0) {
    now = rtc.now();
    startTime = now.unixtime();
  }

  ButtonInterrupt();

  if (testMode) {
    Serial.println("TEST MODE ACTIVE");
  }

  ButtonInterrupt();
  // Comparison Loop
  // Channel 1
  ant1 = next1;
  next1 = analogRead(sensorPin1);
  
  Serial.print("Pin1: ");
  Serial.println(next1);
  
  delay(1000);

  if (ant1 > next1) {
    if (maxVal1 > ant1) {
      //maxVal1 = ant1;
      //SEND
      Serial.print("MaxDigiVoltage = ");
      Serial.println(maxVal1);
      //Intensity Map
      ArrayAdd(IntensityMap(maxVal1), 1);
      maxVal1 = 0;
      ButtonInterrupt();
      delay(500);

      if (((sampleNum1 + 1) % 10) == 0) {
        WriteStorage();
        ButtonInterrupt();
      }

    }
  }
  else {
    maxVal1 = next1;
  }
  ButtonInterrupt();
  // Channel 2
  ant2 = next2;
  next2 = analogRead(sensorPin2);

  Serial.print("Pin2: ");
  Serial.println(next2);
  
  if (ant2 > next2) {
    if (maxVal2 > ant2) {
      //maxVal2 = ant2;
      //SEND
      Serial.print("MaxDigiVoltage = ");
      Serial.println(maxVal2);
      //Intensity Map
      ArrayAdd(IntensityMap(maxVal2), 2);
      maxVal2 = 0;
      delay(500);

      if (((sampleNum2 + 1) % 10) == 0) {
        WriteStorage();
        ButtonInterrupt();
      }

    }
  } else {
    maxVal2 = next2;
  }
  ButtonInterrupt();

  Serial.print("currentAddress = HEX ");
  Serial.println(currentAddress);

  Serial.print("SampleNumber 1 = ");
  Serial.println(sampleNum1);

  Serial.print("SampleNumber 2 = ");
  Serial.println(sampleNum2);

  Serial.print("Start Time Recorded: ");
  Serial.println(startTime);

  Serial.print("Final Time Recorded: ");
  Serial.println(endTime);

  Serial.println("------------Loop Complete-------------");
}


void initialize() {
  sampleNum1 = 0;  // Sample number
  sampleNum2 = 0;  // Sample number
  arrayTot1 = 0; // A running sum of the contents of sampleArray to be divided by sampleNum for averaging
  arrayAvg1 = 0; // A running avg of the above
  arrayTot2 = 0; // A running sum of the contents of sampleArray to be divided by sampleNum for averaging
  arrayAvg2 = 0; // A running avg of the above
  sessionComp = 0;
  ant1 = 0;
  next1 = 0;
  maxVal1 = 0;
  ant2 = 0;
  next2 = 0;
  maxVal2 = 0;

  for (int i=0; i<140; i++){
    sampleArray1[i] = 0;
    sampleArray2[i] = 0;
  }
}


void outputtingToApp() {

  int address = 2;
  for (int i = 0; i <= sessionCount; i++) {

    char output_array_avg1[6];
    char output_array_avg2[6];
    char output_session_comp[5];
    char output_session_count[2];
    //int address = 2;
    int sc = 0;
    float aavg1;
    float aavg2;
    float scomp;
    unsigned char output_comma[1] = {','};
    unsigned char output_newline[1] = {'\n'};
    long startT = 0;
    long endT = 0;
    char output_start_time[11];
    char output_end_time[11];

    sc = EEPROM.readInt(address);
    itoa(sc, output_session_count, 10);
    address = address + 2;

    aavg1 = EEPROM.readFloat(address);
    dtostrf(aavg1, 5, 2, output_array_avg1);
    address = address + 5;

    aavg2 = EEPROM.readFloat(address);
    dtostrf(aavg2, 5, 2, output_array_avg2);
    address = address + 5;

    scomp = EEPROM.readFloat(address);
    dtostrf(scomp, 4, 2, output_session_comp);
    address = address + 5;

    startT = EEPROM.readLong(address);
    ltoa(startT, output_start_time, 10);
    address = address + 5;

    endT = EEPROM.readLong(address);
    ltoa(endT, output_end_time, 10);
    address = address + 5;

    //ble_write_bytes((unsigned char * )output_session_count, strlen(output_session_count));
    //delay(500);
    //ble_write_bytes(output_comma,1);
    //delay(1000);
    ble_write_bytes((unsigned char * )output_array_avg1, strlen(output_array_avg1));
    delay(500);
    ble_write_bytes(output_comma, 1);
    delay(1000);
    ble_write_bytes((unsigned char * )output_array_avg2, strlen(output_array_avg2));
    delay(500);
    ble_write_bytes(output_comma, 1);
    delay(1000);
    ble_write_bytes((unsigned char * )output_session_comp, strlen(output_session_comp));
    delay(500);
    ble_write_bytes(output_comma, 1);
    delay(1000);
    ble_write_bytes((unsigned char * )output_start_time, strlen(output_start_time));

    Serial.println(strlen(output_start_time));
    delay(1000);
    ble_write_bytes(output_comma, 1);
    delay(1000);
    ble_write_bytes((unsigned char * )output_end_time, strlen(output_end_time));
    delay(1000);
    ble_write_bytes(output_newline, 1);

  }
  sessionCount = 0;

  EEPROM.updateInt(0, sessionCount);
  address = 2;
}

////////////Button Inter//////////////////////////////////////////////////////////
void ButtonInterrupt() {
  /*
    int address = 0;
    unsigned char bytes[255];
    unsigned char value;
  */
  //analogWrite(LED2, 150);

  //if (digitalRead(buttonPin)==1 || sampleNum1>90 || sampleNum2>90){

  //********I don't know how to change the conditions of 90 samples because I have changed this buttonInterrupt********
  //if (digitalRead(buttonPin)==0 || sampleNum1>90 || sampleNum2>90){
  if (1) {
    ble_set_pins(6, 7); //ble_set_pins is to specify the REQN and RDYN pins to the BLE chip, i.e. the jumper on the BLE Shield.


    //********Only check the connection when buttonInterrupt is called********
    if (!ble_connected()) { //ble_connected returns 1 if connected by BLE Central or 0 if not.
      Serial.println("BLE Not Connected");
      ble_do_events();//ble_do_events allows the BLE to process its events, if data is pending, it will be sent out.
    }
    else if ( ble_connected() ) {
      //Serial.println("BLE Connected");




      //********If blend has sent data to the app, the flap is set to true********
      //********Disconnect BLE if data has been transfered and there's nothing in BLE********
      if (flag == true) {
        Serial.println("Data has been sent out");
        ble_do_events();
        //ble_disconnect();
        flag = false;
        //analogWrite(LED3, 0);
      }

      //********If the app connects to the blend, it will send a value to BLE, so ble_read is not -1********
      while (ble_read() != -1) {
        Serial.println("Transfering data!!");
        outputtingToApp();

        ble_do_events();
        delay(5000);

        flag = true;
        //analogWrite(LED3, 50);
      }



      //Serial.println("***************");

      //address = 0;
      //delay(1000); // We wait for an answer if its true, he has receive it so we go out of the loop, if not, we send it again

    }
    //}

    ble_do_events();
    //analogWrite(LED2, 0);
  }
}
///////////////////////Writing to EEPROM///////////////////////////////////////////////////
void WriteStorage() {
  char comma = ',';
  char newline = '\n';

  now = rtc.now();
  endTime = now.unixtime();

  Serial.print("********sessionCount = ");
  Serial.println(sessionCount);
  Serial.print("********currentAddress = ");
  Serial.println(currentAddress);

  currentAddress = 27 * sessionCount + currentAddress;
  EEPROM.updateInt(currentAddress, sessionCount);
  currentAddress = currentAddress + 2;//increase by int
  //EEPROM.updateByte(currentAddress,comma);
  //currentAddress = currentAddress + 1;
  EEPROM.updateFloat(currentAddress, arrayAvg1);
  currentAddress = currentAddress + 4;//increase by float
  EEPROM.updateByte(currentAddress, comma);
  currentAddress = currentAddress + 1;
  EEPROM.updateFloat(currentAddress, arrayAvg2);
  currentAddress = currentAddress + 4;//increase by float
  EEPROM.updateByte(currentAddress, comma);
  currentAddress = currentAddress + 1;
  EEPROM.updateFloat(currentAddress, sessionComp);
  currentAddress = currentAddress + 4;//increase by float
  EEPROM.updateByte(currentAddress, comma);
  currentAddress = currentAddress + 1;
  EEPROM.updateLong(currentAddress, startTime);
  currentAddress = currentAddress + 4;//increase by int
  EEPROM.updateByte(currentAddress, comma);
  currentAddress = currentAddress + 1;
  EEPROM.updateLong(currentAddress, endTime);
  currentAddress = currentAddress + 4;//increase by int
  EEPROM.updateByte(currentAddress, newline);
  currentAddress = currentAddress + 1;





  if (sampleNum1 > sampleNum2) {
    if (sampleNum1 < 90) { //Not done - these addresses will be rewritten this session
      currentAddress = 2;
    } else { //session is done
      EEPROM.updateInt(0, sessionCount);
      sessionCount++;
    }
    if (testMode) {
      Serial.print(sessionCount);
      Serial.print(',');
      Serial.print(arrayAvg1);
      Serial.print(',');
      Serial.print(arrayAvg2);
      Serial.print(',');
      Serial.print(sessionComp);
      Serial.print(',');
      Serial.print(startTime);
      Serial.print(',');
      Serial.print(endTime);
      Serial.println(';');
    }
  } else {
    if (sampleNum2 < 90) { //Not done - these addresses will be rewritten this session
      currentAddress = 2;
    } else { //session is done
      EEPROM.updateInt(0, sessionCount);
      sessionCount++;

    }
    if (testMode) {
      Serial.print(sessionCount);
      Serial.print(',');
      Serial.print(arrayAvg1);
      Serial.print(',');
      Serial.print(arrayAvg2);
      Serial.print(',');
      Serial.print(sessionComp);
      Serial.print(',');
      Serial.print(startTime);
      Serial.print(',');
      Serial.print(endTime);
      Serial.println(';');
    }
  }
}
//////////////////////////////////////////////////////////////////////////////////////////
void ArrayAdd(float intensityValue, int channel) {
  if (intensityValue > 0) {
    if (channel == 1) {
      sampleArray1[sampleNum1] = intensityValue;
      sampleNum1++;
      arrayTot1 = arrayTot1 + intensityValue;
      arrayAvg1 = arrayTot1 / (sampleNum1 + 1);
      sessionComp = float(sampleNum1) / 90;
      if (testMode) {
        Serial.print("ArrayAvg = ");
        Serial.print(arrayAvg1);
        Serial.print(" and SessionComplete = ");
        Serial.print(sessionComp * 100);
        Serial.println("%");
      }
    } else {
      sampleArray2[sampleNum2] = intensityValue;
      sampleNum2++;
      arrayTot2 = arrayTot2 + intensityValue;
      arrayAvg2 = arrayTot2 / (sampleNum2 + 1);
      sessionComp = float(sampleNum2) / 90;
      if (testMode) {
        Serial.print("ArrayAvg = ");
        Serial.print(arrayAvg2);
        Serial.print(" and SessionComplete = ");
        Serial.print(sessionComp * 100);
        Serial.println("%");
      }
    }
  }
}
///////////////////////////////////////////////////////////////////////////////////////////
float IntensityMap(int sensorValue) {
  float intensity;

  intensity = (float) sensorValue / 10.0;

  if (testMode) {
    Serial.print("Intensity = ");
    Serial.println(intensity);
  }

  return intensity;
}
