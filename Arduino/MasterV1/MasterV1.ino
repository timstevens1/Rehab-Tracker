// EMPI Usage Monitoring
// Blake Hewgill & Javier Bunuel, University of Vermont
// Capstone Design, Spring 2017
// Chia-Chun Chao, Yifan Zhang, and Xaview Stevens, Universiaty of Vermont
boolean testMode = true; //If true, print more messages

#include <EEPROMex.h>
#include <SPI.h>
#include <lib_aci.h>
#include <aci_setup.h>
#include <RBL_nRF8001.h>
#include <RBL_services.h>
#include <Wire.h>
#include "RTClib.h"

int sampleNum1 = 0;  // Sample number
int sampleNum2 = 0;  // Sample number
long arrayTot1 = 0; // A running sum of the contents of sampleArray to be divided by sampleNum for averaging
float arrayAvg1 = 0; // A running avg of the above
long arrayTot2 = 0; // A running sum of the contents of sampleArray to be divided by sampleNum for averaging
float arrayAvg2 = 0; // A running avg of the above
int sessionCount; //= EEPROM.write(0, 0x00);

//int sampleArray1[95]; // Should be 90 samples in an hour long session (one each 40 seconds). Extras to be safe.
//int sampleArray2[95]; // Should be 90 samples in an hour long session (one each 40 seconds). Extras to be safe.

float sessionComp = 0;
int ant1 = 0;
int next1 = 0;
int maxVal1 = 0;
int ant2 = 0;
int next2 = 0;
int maxVal2 = 0;

bool sendFlag = false; //If blend has sent data to the app, the sendFlag is set to true
bool startFlag = false; //If a session starts, the startFlag is set to true

long startTime;
long endTime;
DateTime now;
RTC_DS1307 rtc;

void initialize();
void ButtonInterrupt();
void WriteStorage();
void ArrayAdd(float intensityValue, int channel);
float IntensityMap(int sensorValue);

/*
 * Every program contains a setup function and a loop function
 * setup() function initializes and sets the initial values
 * loop() function loops consecutively, allowing your program to change and respond
*/
void setup() {
  
  //Set the maximum number of writes
  //EEPROM.setMaxAllowedWrites(32768);
  EEPROM.setMaxAllowedWrites(EEPROMSizeUno);

  //Set sessionCount
  if (EEPROM.readInt(2) != 1) {//This is the first time using this blend
    EEPROM.updateInt(0, 0);
  }
  sessionCount = EEPROM.readInt(0);  //The first two bytes are used to store an integer of the total session count in EEPROM

  //Start serial monitor
  if (testMode) { //start serial com
    Serial.begin(57600);
    //Serial.print("SessionCount = ");
    //Serial.println(sessionCount);
  }
  Serial.begin(57600); //Use the same rate in serial monitor

  //Set real time clock
  if (! rtc.begin()) {
    //Serial.println("Couldn't find RTC");
    //while (1);
  }
  if (! rtc.isrunning()) {
    //Serial.println("RTC is NOT running");
    // following line sets the RTC to the date & time this sketch was compiled
    rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
    // This line sets the RTC with an explicit date & time, for example to set
    // January 21, 2014 at 3am you would call:
    // rtc.adjust(DateTime(2014, 1, 21, 3, 0, 0));
  }

  //RT is the name of this blend. We can use this name for the app to only recognize this blend
  ble_set_name("RT");
  ble_begin(); //ble_begin starts the BLE stack and broadcasting the advertising packet  
}
//////////////////////////////////////////////////////////////////////////////////////////
/*
 * Every program contains a setup function and a loop function
 * setup() function initializes and sets the initial values
 * loop() function loops consecutively, allowing your program to change and respond
*/
void loop()
{ 
  //loops consecutively, allowing your program to change and respond
  
  //rtc.adjust(DateTime(F(__DATE__), F(__TIME__))); //Adjust RTC time

  //Print current session count for debugging
  Serial.print("sc: ");
  Serial.println(EEPROM.readInt(0));
  
  int sensorPin1 = A0;    // select the input pin for channel 1
  int sensorPin2 = A1;    // select the input pin for channel 2
  long i = 0; //i is used as a timer

  //***********************************Not running***********************************

  //When the input is too low, this blend should not continue computing the intensity
  while ((analogRead(sensorPin1) <= 2 && analogRead(sensorPin2) <= 2)) {
    Serial.println(F("Low input"));
    ButtonInterrupt();
    //If this session has been stored in EEPROM, finish this session
    if (startFlag == true) {
      initialize();
    }
  }

  //When there are already 90 samples, this session has finished
  while (sampleNum1 >= 90 || sampleNum2 >= 90) {
    Serial.println(F("Completed"));
    ButtonInterrupt();
    //Serial.print("While-loop at:");
    //Serial.println(i);
    delay(1);
    i++;
    //When a session has finished after 120 seconds, we initialize all related variables
    if (i == 120000 || (analogRead(sensorPin1) <= 2 && analogRead(sensorPin2) <= 2)) {
      initialize();
    }
  }

  //***********************************Start counting***********************************

  //Store the start time before a session starts
  if (sampleNum1 == 0 && sampleNum2 == 0) {
    now = rtc.now();
    startTime = now.unixtime();
  }

  ButtonInterrupt(); //Frequently check if user has pressed the sync button

  if (testMode) {
    Serial.println(F("TEST MODE"));
  }

  //***********************************Find the vertex***********************************
  delay(1000);

  // Comparison Loop
  // Channel 1
  ant1 = next1;
  next1 = analogRead(sensorPin1);

  Serial.print(F("Pin1: "));
  Serial.println(next1);

  if (ant1 > next1) {
    if (maxVal1 > ant1) {
      //SEND
      Serial.print(F("MaxVolt = "));
      Serial.println(maxVal1);
      //Intensity Map
      ArrayAdd(IntensityMap(maxVal1), 1);
      maxVal1 = 0;
      ButtonInterrupt();
      delay(500);

      //We only store data to EEPROM at 9, 19, 29, ..., 89
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

  //***********************************Find the vertex***********************************
  // Channel 2
  ant2 = next2;
  next2 = analogRead(sensorPin2);

  Serial.print(F("Pin2: "));
  Serial.println(next2);

  if (ant2 > next2) {
    if (maxVal2 > ant2) {
      //SEND
      Serial.print(F("MaxVolt = "));
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

  Serial.print(F("samNum1: "));
  Serial.println(sampleNum1);

  Serial.print(F("samNum2: "));
  Serial.println(sampleNum2);

  Serial.print(F("start: "));
  Serial.println(startTime);

  Serial.print(F("end: "));
  Serial.println(endTime);

  Serial.println(F("------------Loop Complete-------------"));
}
//////////////////////////////////////////////////////////////////////////////////////////
/*
 * Initialize all global variables related to a session
 */

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
  startTime = 0;
  endTime = 0;
  startFlag = false;

  /*
  int i = 0;
  for (i = 0; i < 95; i++) {
    sampleArray1[i] = 0;
    sampleArray2[i] = 0;
  }
  */
}
//////////////////////////////////////////////////////////////////////////////////////////
/*
 * Send data to the app via BLE
 * This function is called by ButtonInterrupt() when BLE is connected and user has pressed the sync button
 */
void outputtingToApp() {
  
  int address = 2;
  unsigned char output_x[1] = {'x'};
  
  for (int i = 0; i < sessionCount; i++) {
    ble_do_events();
    
    char output_array_avg1[6];
    char output_array_avg2[6];
    char output_session_comp[5];
    char output_session_count[2];
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
    dtostrf(aavg1, 5, 2, output_array_avg1); //char * dtostrf (double __val, signed char __width, unsigned char __prec, char *__s)
    address = address + 4;

    aavg2 = EEPROM.readFloat(address);
    dtostrf(aavg2, 5, 2, output_array_avg2);
    address = address + 4;

    scomp = EEPROM.readFloat(address);
    dtostrf(scomp, 4, 2, output_session_comp);
    address = address + 4;

    startT = EEPROM.readLong(address);
    ltoa(startT, output_start_time, 10);
    address = address + 4;

    endT = EEPROM.readLong(address);
    ltoa(endT, output_end_time, 10);
    address = address + 4;


    Serial.print(sc);
    Serial.print("/");
    sc=EEPROM.readInt(0);
    Serial.println(sc);
    Serial.println(startT);

    //Sometimes we need delay() to give data transferred smoothly
    ble_write_bytes((unsigned char * )output_array_avg1, strlen(output_array_avg1));
    ble_write_bytes(output_comma, 1);
    ble_write_bytes((unsigned char * )output_array_avg2, strlen(output_array_avg2));
    ble_write_bytes(output_comma, 1);
    ble_write_bytes((unsigned char * )output_session_comp, strlen(output_session_comp));
    ble_write_bytes(output_comma, 1);
    ble_write_bytes((unsigned char * )output_start_time, strlen(output_start_time));
    ble_write_bytes(output_comma, 1);
    ble_write_bytes((unsigned char * )output_end_time, strlen(output_end_time));
    ble_write_bytes(output_newline, 1);
    delay(5000);
    ble_do_events();
    delay(1000);
  }
  ble_write_bytes(output_x, 1); //Tell the app that all data has been sent successfully

  //Clear all stored sessions or the currently running session
  sessionCount = 0;
  EEPROM.updateInt(0, sessionCount);
  address = 2;
  initialize();
}

////////////Button Inter//////////////////////////////////////////////////////////
/*
 * Check if BLE is connected. If true, call outputtingToApp() and send data to the app.
 * After sending data, disconnect BLE to make sure the next successful connection
 */
void ButtonInterrupt() {

  ble_set_pins(6, 7); //ble_set_pins is to specify the REQN and RDYN pins to the BLE chip, i.e. the jumper on the BLE Shield.

  if (!ble_connected()) { //ble_connected returns 1 if connected by BLE Central or 0 if not.
    Serial.println(F("BLE Not Connected"));
    ble_do_events();//ble_do_events allows the BLE to process its events, if data is pending, it will be sent out.
  }
  
  else if ( ble_connected() ) {
    //Serial.println("BLE Connected");

    //If blend has sent data to the app, the flag is set to true
    if (sendFlag == true) {
      //Serial.println("Done");
      ble_do_events();
      sendFlag = false;
      ble_disconnect();
    }

    //If the app connects to the blend, it will send a value to BLE, so ble_read is not -1
    while (ble_read() != -1) {
      ble_do_events();
      Serial.println(F("Sync!"));
      outputtingToApp();
      ble_do_events();
      delay(5000);
      sendFlag = true;
    }
  }
  ble_do_events();
}
///////////////////////Writing to EEPROM///////////////////////////////////////////////////
/*
 * When session count is 9, 19, 29, ..., 89, store data in EEPROM
 */
void WriteStorage() {
  int currentAddress = 2;
  
  //A session starts only when data is stored in EEPROM at the first time
  if (startFlag == false){
    sessionCount++;
    EEPROM.updateInt(0, sessionCount);
    startFlag = true;
  }

  now = rtc.now();
  endTime = now.unixtime();

  currentAddress = 22 * (sessionCount - 1) + 2;
  EEPROM.updateInt(currentAddress, sessionCount);
  currentAddress = currentAddress + 2;//increase by int
  EEPROM.updateFloat(currentAddress, arrayAvg1);
  currentAddress = currentAddress + 4;//increase by float
  EEPROM.updateFloat(currentAddress, arrayAvg2);
  currentAddress = currentAddress + 4;//increase by float
  EEPROM.updateFloat(currentAddress, sessionComp);
  currentAddress = currentAddress + 4;//increase by float
  EEPROM.updateLong(currentAddress, startTime);
  currentAddress = currentAddress + 4;//increase by int
  EEPROM.updateLong(currentAddress, endTime);
  currentAddress = currentAddress + 4;//increase by int

  if (sampleNum1 > sampleNum2) {
    if (sampleNum1 < 90) { //Not done - these addresses will be rewritten this session
      currentAddress = 2;
    } 
    /*else { //session is done
      EEPROM.updateInt(0, sessionCount);
      sessionCount++;
    }
    */
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
    } 
    /*else { //session is done
      EEPROM.updateInt(0, sessionCount);
      sessionCount++;
    }
    */
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
/*
 * Sum up all intensities, calculate the average intensity, and calculate the session compliance
 */
void ArrayAdd(float intensityValue, int channel) {
  if (intensityValue > 0) {
    if (channel == 1) {
      //sampleArray1[sampleNum1] = intensityValue;
      sampleNum1++;
      arrayTot1 = arrayTot1 + intensityValue;
      arrayAvg1 = arrayTot1 / (sampleNum1 + 1);
      sessionComp = float(sampleNum1) / 90;
      if (testMode) {
        Serial.print(F("ArrayAvg = "));
        Serial.print(arrayAvg1);
        Serial.print(F(" | sessionComp = "));
        Serial.print(sessionComp * 100);
        Serial.println("%");
      }
    } else {
      //sampleArray2[sampleNum2] = intensityValue;
      sampleNum2++;
      arrayTot2 = arrayTot2 + intensityValue;
      arrayAvg2 = arrayTot2 / (sampleNum2 + 1);
      sessionComp = float(sampleNum2) / 90;
      if (testMode) {
        Serial.print(F("ArrayAvg = "));
        Serial.print(arrayAvg2);
        Serial.print(F(" | sessionComp = "));
        Serial.print(sessionComp * 100);
        Serial.println("%");
      }
    }
  }
}
///////////////////////////////////////////////////////////////////////////////////////////
/*
 * Calculate the intensity based on the sensor value and return the intensity
 */
float IntensityMap(int sensorValue) {
  float intensity;

  intensity = (float) sensorValue / 10.0;

  if (testMode) {
    Serial.print(F("Intensity = "));
    Serial.println(intensity);
  }

  return intensity;
}
