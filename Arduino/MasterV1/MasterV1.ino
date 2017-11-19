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
int sampleArray1[140]; // Should be 90 samples in an hour long session (one each 40 seconds). Extras to be safe.
long arrayTot1 = 0; // A running sum of the contents of sampleArray to be divided by sampleNum for averaging
float arrayAvg1 = 0; // A running avg of the above
int sampleArray2[140]; // Should be 90 samples in an hour long session (one each 40 seconds). Extras to be safe.
long arrayTot2 = 0; // A running sum of the contents of sampleArray to be divided by sampleNum for averaging
float arrayAvg2 = 0; // A running avg of the above
int sessionCount; //= EEPROM.write(0, 0x00);
int currentAddress; //= EEPROM.write(1,0x15);
char comma = ',';
char newline = '\n';
float sessionComp;
int ant1 = 0;
int next1 = 0;
int maxVal1 = 0;
int ant2 = 0;
int next2 = 0;
int maxVal2 = 0;
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

  EEPROM.writeInt(0, 0);
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

  int i = 0;
  while (analogRead(sensorPin1) <= 10 && analogRead(sensorPin2) <= 10) {
    Serial.println("Not running");
    ButtonInterrupt();

    delay(1);
    i++;
    if (i == 120000) {
      EEPROM.writeInt(0, sessionCount);
      sessionCount++;
    }


  }

  //EEPROM only stores one session. We will change this later
  while (sampleNum1 > 90 || sampleNum2 > 90) {
    ButtonInterrupt();
    Serial.println("This session has finished.");
  }


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


  /*
    //while(1){
    Serial.println("**********");
    //DateTime now = rtc.now();

    Serial.print(now.year(), DEC);
    Serial.print('/');
    Serial.print(now.month(), DEC);
    Serial.print('/');
    Serial.println(now.day(), DEC);

    Serial.print(now.hour(), DEC);
    Serial.print(':');
    Serial.print(now.minute(), DEC);
    Serial.print(':');
    Serial.print(now.second(), DEC);
    Serial.println();
    Serial.println("**********");
    //}
  */

  ButtonInterrupt();

  if (testMode) {
    Serial.println("TEST MODE ACTIVE");
  }
  Serial.print("Pin1: ");
  Serial.print(analogRead(sensorPin1));
  Serial.print(" ; Pin2: ");
  Serial.println(analogRead(sensorPin2));


  ButtonInterrupt();
  // Comparison Loop
  // Channel 1
  ant1 = next1;
  next1 = analogRead(sensorPin1);
  delay(1000);

  if (ant1 > next1) {
    if (maxVal1 > ant1) {
      maxVal1 = ant1;
      //SEND
      Serial.print("MaxDigiVoltage = ");
      Serial.println(maxVal1);
      //Intensity Map
      ArrayAdd(IntensityMap(maxVal1), 1);
      maxVal1 = 0;
      ButtonInterrupt();
      delay(500);


      if (((sampleNum1+1) % 10) == 0){
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
  if (ant2 > next2) {
    if (maxVal2 > ant2) {
      maxVal2 = ant2;
      //SEND
      Serial.print("MaxDigiVoltage = ");
      Serial.println(maxVal2);
      //Intensity Map
      ArrayAdd(IntensityMap(maxVal2), 2);
      maxVal2 = 0;
      delay(500);

      if (((sampleNum2+1) % 10) == 0){
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

void outputtingToApp() {

  int address = 2;
  for (int i = 0; i < sessionCount; i++) {

    char output_array_avg1[10];
    char output_array_avg2[10];
    char output_session_comp[10];
    char output_session_count[10];
    //int address = 2;
    int sc = 0;
    float aavg1;
    float aavg2;
    float scomp;
    unsigned char output_comma[1] = {','};
    unsigned char output_newline[1] = {'\n'};
    int startT=0;
    int endT=0;
    char output_start_time[10];
    char output_end_time[10];


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
    dtostrf(scomp, 5, 2, output_session_comp);
    address = address + 5;

    startT = EEPROM.readLong(address);
    itoa(sc, output_start_time, 10);
    address = address + 5;

    endT = EEPROM.readLong(address);
    itoa(sc, output_end_time, 10);
    address = 2;

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
    delay(500);
    ble_write_bytes(output_comma, 1);
    delay(1000);
    ble_write_bytes((unsigned char * )output_end_time, strlen(output_end_time));
    delay(500); 
    ble_write_bytes(output_newline, 1);

  }
  sessionCount = 0;
  EEPROM.writeInt(0, sessionCount);

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
        ble_do_events();
        outputtingToApp();
        delay(5000);
        ble_do_events();
        outputtingToApp();
        delay(5000);
        ble_do_events();
        outputtingToApp();

        flag = true;
        //analogWrite(LED3, 50);
      }



      //Serial.println("***************");

      //address = 0;
      delay(1000); // We wait for an answer if its true, he has receive it so we go out of the loop, if not, we send it again

    }
    //}

    ble_do_events();
    //analogWrite(LED2, 0);
  }
}
///////////////////////Writing to EEPROM///////////////////////////////////////////////////
void WriteStorage() {
  now = rtc.now();
  endTime = now.unixtime();

  Serial.print("********sessionCount = ");
  Serial.println(sessionCount);
  Serial.print("********currentAddress = ");
  Serial.println(currentAddress);
  EEPROM.writeInt(27 * sessionCount + currentAddress, sessionCount);
  currentAddress = currentAddress + 2;//increase by int
  //EEPROM.updateByte(currentAddress,comma);
  //currentAddress = currentAddress + 1;
  EEPROM.writeFloat(currentAddress, arrayAvg1);
  currentAddress = currentAddress + 4;//increase by float
  EEPROM.updateByte(currentAddress, comma);
  currentAddress = currentAddress + 1;
  EEPROM.writeFloat(currentAddress, arrayAvg2);
  currentAddress = currentAddress + 4;//increase by float
  EEPROM.updateByte(currentAddress, comma);
  currentAddress = currentAddress + 1;
  EEPROM.writeFloat(currentAddress, sessionComp);
  currentAddress = currentAddress + 4;//increase by float
  EEPROM.updateByte(currentAddress, comma);
  currentAddress = currentAddress + 1;
  EEPROM.writeLong(currentAddress, startTime);
  currentAddress = currentAddress + 4;//increase by int
  EEPROM.updateByte(currentAddress, comma);
  currentAddress = currentAddress + 1;
  EEPROM.writeLong(currentAddress, endTime);
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
  // Nested if’s/elseif reduce processor load and speed up the cycle time
  if (sensorValue < 683)
  {
    if (sensorValue < 393)
    {
      if (sensorValue < 203)
      {
        if (sensorValue < 101)
        {
          if (sensorValue < 50)
          {
            intensity = .0;
          }
          else if (sensorValue >= 50)
          {
            intensity = 1.0;
          }
        }
        else if (sensorValue >= 101)
        {
          if (sensorValue < 151)
          {
            intensity = 1.5;
          }
          else if (sensorValue >= 151)
          {
            intensity = 2.0;
          }
        }
      }
      else if (sensorValue >= 203)
      {
        if (sensorValue < 299)
        {
          if (sensorValue < 251)
          {
            intensity = 2.5;
          }
          else if (sensorValue >= 251)
          {
            intensity = 3.0;
          }
        }
        else if (sensorValue >= 299)
        {
          if (sensorValue < 345)
          {
            intensity = 3.5;
          }
          else if (sensorValue >= 345)
          {
            intensity = 4.0;
          }
        }
      }
    }
    else if (sensorValue >= 393)
    {
      if (sensorValue < 594)
      {
        if (sensorValue < 479)
        {
          if (sensorValue < 438)
          {
            intensity = 4.5;
          }
          else if (sensorValue >= 438)
          {
            intensity = 5.0;
          }
        }
        else if (sensorValue >= 479)
        {
          if (sensorValue < 538)
          {
            intensity = 5.5;
          }
          else if (sensorValue >= 538)
          {
            intensity = 6.0;
          }

        }
      }
      else if (sensorValue >= 594)
      {
        if (sensorValue < 658)
        {
          if (sensorValue < 627)
          {
            intensity = 6.5;
          }
          else if (sensorValue >= 627)
          {
            intensity = 7.0;
          }
        }
        else if (sensorValue >= 658)
        {
          intensity = 7.5;
        }
      }
    }
  }
  else if (sensorValue >= 683)
  {
    if (sensorValue < 876)
    {
      if (sensorValue < 786)
      {
        if (sensorValue < 737)
        {
          if (sensorValue < 706)
          {
            intensity = 8.0;
          }
          else if (sensorValue >= 706)
          {
            if (sensorValue < 724)
            {
              intensity = 8.5;
            }
            else if (sensorValue >= 724)
            {
              intensity = 9.0;
            }
          }
        }
        else if (sensorValue >= 737)
        {
          if (sensorValue < 758)
          {
            intensity = 9.5;
          }
          else if (sensorValue >= 758)
          {
            intensity = 10.0;
          }
        }
      }
      else if (sensorValue >= 786)
      {
        if (sensorValue < 816)
        {
          intensity = 11.0;
        }
        else if (sensorValue >= 816)
        {
          if (sensorValue < 847)
          {
            intensity = 12.0;
          }
          else if (sensorValue >= 847)
          {
            intensity = 13.0;
          }
        }
      }
    }
    else if (sensorValue >= 876)
    {
      if (sensorValue < 961)
      {
        if (sensorValue < 933)
        {
          if (sensorValue < 905)
          {
            intensity = 14.0;
          }
          else if (sensorValue >= 905)
          {
            intensity = 15.0;
          }
        }
        else if (sensorValue >= 933)
        {
          intensity = 16.0;
        }
      }
      else if (sensorValue >= 961)
      {
        if (sensorValue < 1010)
        {
          if (sensorValue < 989)
          {
            intensity = 17.0;
          }
          else if (sensorValue >= 989)
          {
            intensity = 18.0;
          }
        }
        else if (sensorValue >= 1010)
        {
          if (sensorValue < 1020)
          {
            intensity = 19.0;
          }
          else if (sensorValue >= 1020)
          {
            intensity = 20.0;
          }
        }
      }

    }
  }
  intensity = (intensity * 2);
  if (testMode) {
    Serial.print("Intensity = ");
    Serial.println(intensity);
  }
  return intensity;
}

