/** \file
 *  \brief The code for the Blend Arduino that will be uploaded to the board on the NMES machine.
 *  
 *  The Arduino script was written by the SEED team and named as MasterV1 for the actual prototype that they created. 
 *  It has then been modified by Chia-Chun Chao, Yifan Zhang, and Xavier Stevens beyond that. 
 *  Arduino.ino now tracks time, has clearer and more useful BLE usage and can transfer data from the NMES->Blend Board->App, 
 *  fixed the data pull so now there is no need for an off-app button for the sync, 
 *  the intensity values have been completely overhauled, 
 *  and multiple sessions can now be stored within the EEPROM just incase the user doesn't have internet
 *  
 *  The code on Github is [here] (https://github.com/timstevens1/Rehab-Tracker/blob/master/Hardware/Arduino/Arduino.ino).
 */


// EMPI Usage Monitoring
// Blake Hewgill & Javier Bunuel, University of Vermont
// Capstone Design, Spring 2017
// Chia-Chun Chao, Yifan Zhang, and Xavier Stevens, Universiaty of Vermont
boolean testMode = true; ///<If true, print more messages

#include <EEPROMex.h>
#include <SPI.h>
#include <lib_aci.h>
#include <aci_setup.h>
#include <RBL_nRF8001.h>
#include <RBL_services.h>
#include <Wire.h>
#include "RTClib.h"

int sampleNum1 = 0;  ///< Sample number of channel 1
int sampleNum2 = 0;  ///< Sample number of channel 2
long arrayTot1 = 0; ///< A running sum of the intensity of channel 1 to be divided by sampleNum1 for averaging
float arrayAvg1 = 0; ///< A running avg of channel 1
long arrayTot2 = 0; ///< A running sum of the intensity of channel 2 to be divided by sampleNum2 for averaging
float arrayAvg2 = 0; ///< A running avg of channel 2
int sessionCount; ///< Total session count in EEPROM
//sessionCount = EEPROM.write(0, 0x00);

//int sampleArray1[95]; // Should be 90 samples in an hour long session (one each 40 seconds). Extras to be safe.
//int sampleArray2[95]; // Should be 90 samples in an hour long session (one each 40 seconds). Extras to be safe.

float sessionComp = 0; ///< Session compliance
int ant1 = 0; ///< Old value is stored to find the vertex
int next1 = 0; ///< New value is stored to find the vertex
int maxVal1 = 0; ///< Maximum value is stored to find the vertex
int ant2 = 0; ///< Old value is stored to find the vertex
int next2 = 0; ///< New value is stored to find the vertex
int maxVal2 = 0; ///< Maximum value is stored to find the vertex

bool sendFlag = false; ///<If blend has sent data to the app, the sendFlag is set to true
bool startFlag = false; ///<If a session starts, the startFlag is set to true

long startTime; ///< Store the start time before a session starts
long endTime; ///< Store the time when writing data to EEPROM
DateTime now; ///< Current time
RTC_DS1307 rtc; ///< Real time clock

void initialize(); 
void ButtonInterrupt();
void WriteStorage();
void ArrayAdd(float intensityValue, int channel);
float IntensityMap(int sensorValue);


/**\brief Initialize and set the initial values
 * 
 * Every Arduino program contains a setup function and a loop function.
 * The setup() function is called when a sketch starts. Use it to initialize variables, pin modes, start using libraries, etc. 
 * The setup() function will only run once, after each powerup or reset of the Arduino board.
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

  
  // Set real time clock
  if (! rtc.begin()) {
    Serial.println("Couldn't find RTC");
    //while (1);
  }
  /*
  if (! rtc.isrunning()) {
    Serial.println("RTC is NOT running");
    // following line sets the RTC to the date & time this sketch was compiled
    rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
  }
  */

  //RT is the name of this blend. We can use this name for the app to only recognize this blend
  ble_set_name("RT");
  ble_begin(); //ble_begin starts the BLE stack and broadcasting the advertising packet  
}


/**\brief Loop consecutively, allowing the program to change and respond
 * 
 * Every program contains a setup function and a loop function
 * After creating a setup() function, which initializes and sets the initial values, 
 * the loop() function does precisely what its name suggests, and loops consecutively, 
 * allowing your program to change and respond. Use it to actively control the Arduino board.
*/
void loop()
{   
  //EEPROM.updateInt(0, 0); //Initialize session count
  //rtc.adjust(DateTime(F(__DATE__), F(__TIME__))); //Adjust RTC time

  if (! rtc.isrunning()) {
    Serial.println("RTC is NOT running");
  }

  now = rtc.now();
  Serial.print(now.year());
  Serial.print('/');
  Serial.print(now.month());
  Serial.print('/');
  Serial.print(now.day());
  Serial.print(' ');
  Serial.print(now.hour());
  Serial.print(':');
  Serial.print(now.minute());
  Serial.print(':');
  Serial.println(now.second());

  //Print current session count for debugging
  Serial.print("sc: ");
  Serial.println(EEPROM.readInt(0));
  
  int sensorPin1 = A0;    // select the input pin for channel 1
  int sensorPin2 = A1;    // select the input pin for channel 2
  long i = 0; //i is used as a timer

  //*****************Not running******************

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

  //******************Start counting******************
  
  //Store the start time before a session starts
  if (sampleNum1 == 0 && sampleNum2 == 0) {
    now = rtc.now();
    startTime = now.unixtime();
  }

  ButtonInterrupt(); //Frequently check if user has pressed the sync button

  if (testMode) {
    Serial.println(F("TEST MODE"));
  }

  //******************Find the vertex******************
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

  //******************Find the vertex******************
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


/**\brief Initialize all global variables related to a session
 * 
 * This function is called when a session has finished or a session has been dumped. All global variables related to a session are initialized.
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


/**\brief Send data to the app via BLE
 * 
 * This function is called by ButtonInterrupt() when BLE is connected and user has pressed the sync button in the app. 
 * The data in EEPROM are read and transformed to a format that can be passed to ble_write_bytes().
 * The sent data include an 'x' in the end to inform the app that all data have been sent
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


/**\brief Check if BLE is connected
 * 
 * Check if BLE is connected. If true, call outputtingToApp() and send data to the app.
 * After sending data, disconnect BLE to make sure the next successful connection.
 * This function is frequently called to check if a user has pressed the sync button
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


/**\brief Write data to EEPROM. 
 * 
 * When session count is 9, 19, 29, ..., 89, store data in EEPROM. The data include sessionCount, arrayAvg1, arrayAvg2, sessionComp, startTime, and endTime.
 */
void WriteStorage() {
  int currentAddress;
  
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


/**\brief Sum up all intensities, calculate the average intensity, and calculate the session compliance
 * 
 * This function is called when a vertex of input intensity data is found
 * 
 * \param intensityValue The intensity value of a vertex
 * \param channel The channel number
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


/**\brief Calculate the intensity based on the sensor value and return the intensity
 * 
 * This function is called when a vertex is found. The value of intensity is about one tenth of a sensor value
 * 
 * \param sensorValue The voltage value from a sensor
 * \return Return the intensity value mapping to the input sensor value
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
