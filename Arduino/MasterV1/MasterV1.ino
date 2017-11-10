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
/*
  #include <Wire.h>
  #include "RTClib.h"
*/
#include <EEPROM.h>

int buttonPin = 11; // pin for sync button
int LED2 = 5; // Status lights
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
int dayWithoutSync = 0;
//int startTime;
//int endTime;

void ButtonInterrupt();
void WriteStorage();
void ArrayAdd(float intensityValue, int channel);
float IntensityMap(int sensorValue);

bool flag = false;
// RTC_DS1307 rtc;

void setup() {
  // Initialize what we need in here
  //EEPROM.setMaxAllowedWrites(32768);
  EEPROM.setMaxAllowedWrites(EEPROMSizeUno);

  EEPROM.writeInt(0, 1);
  EEPROM.writeInt(2, 2);
  sessionCount = EEPROM.readInt(0);
  currentAddress = EEPROM.readInt(2);

  // UPLOAD EEPROM SHITE
  pinMode(LED2, OUTPUT);
  if (testMode) { //start serial com
    Serial.begin(57600);
    Serial.print("SessionCount = ");
    Serial.println(sessionCount);
  }


  Serial.begin(57600);
  /*
    if (! rtc.begin()) {
    Serial.println("Couldn't find RTC");
    while (1);
    }
    if (! rtc.isrunning()) {
    Serial.println("RTC is NOT running!");
    // following line sets the RTC to the date & time this sketch was compiled
    rtc.adjust(DateTime(F(__DATE__), F(__TIME__)));
    // This line sets the RTC with an explicit date & time, for example to set
    // January 21, 2014 at 3am you would call:
    // rtc.adjust(DateTime(2014, 1, 21, 3, 0, 0));
    }
  */

  ble_begin(); //ble_begin starts the BLE stack and broadcasting the advertising packet
  delay(5000);
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void loop()
{
  analogWrite(LED2, 10);




  /*
    while(1)
    {
    ButtonInterrupt();
    }
  */
  ButtonInterrupt();

  if (testMode) {
    Serial.println("TEST MODE ACTIVE");
  }
  Serial.print("Pin1: ");
  Serial.print(analogRead(sensorPin1));
  Serial.print(" ; Pin2: ");
  Serial.println(analogRead(sensorPin2));
  /* int beginTime;
    Serial.println("Unix Time, Session 1");
    if (sessionCount == 1) {
      startTime = now.unixtime();
      Serial.print("Start Time: ");
      Serial.println(startTime);
    beginTime = startTime;
    }
    endTime = now.unixtime();*/

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


      if (((sampleNum1 + 1) % 10) == 0) {
        WriteStorage();
        ButtonInterrupt();
      }

      /*
        WriteStorage();
        ButtonInterrupt();
      */
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

      if (((sampleNum2 + 1) % 10) == 0) {
        WriteStorage();
      }

      /*
        WriteStorage();
        ButtonInterrupt();
      */
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
  /*
    Serial.print("Start Time Recorded: ");
    Serial.println(startTime);

    Serial.print("Final Time Recorded: ");
    Serial.println(endTime);
  */
  Serial.println("------------Loop Complete-------------");
}

void outputtingToApp() {
  unsigned char thisThing[13];
  unsigned char val = '0';
  unsigned char output;
  for (int pos = 0; pos < 10; pos++) {
    EEPROM.writeByte(pos, val);
  }
  for (int i = 0; i < 10; i++) {
    output = EEPROM.readByte(i);
    thisThing[i] = output;
    Serial.println(thisThing[i]);
  }
  //= {'W', 'e', ' ', 'C', 'a', 'n', ' ', 'O', 'u', 't', 'p', 'u', 't'};
  ble_write_bytes(thisThing, 10);
}

////////////Button Inter//////////////////////////////////////////////////////////
void ButtonInterrupt() {

  int address = 0;
  unsigned char bytes[255];
  unsigned char value;

  //if (digitalRead(buttonPin)==1 || sampleNum1>90 || sampleNum2>90){

  //********I don't know how to change the conditions of 90 samples because I have changed this buttonInterrupt********
  if (digitalRead(buttonPin) == 0 || sampleNum1 > 90 || sampleNum2 > 90) {
    ble_set_pins(6, 7); //ble_set_pins is to specify the REQN and RDYN pins to the BLE chip, i.e. the jumper on the BLE Shield.

    //********Although we don't know what ble_set_name can do, when it's set to RehabTracker, it shows errors.********
    ble_set_name("RT"); //Call ble_set_name by giving name before calling to ble_begin to set the broadcasting name.
    /*
      while (!ble_connected()){ //ble_connected returns 1 if connected by BLE Central or 0 if not.
      Serial.println("BLE Not Connected");
      ble_do_events(); //ble_do_events allows the BLE to process its events, if data is pending, it will be sent out.
      }
    */

    //********Only check the connection when buttonInterrupt is called********
    if (!ble_connected()) {
      Serial.println("BLE Not Connected");
      ble_do_events();
    }
    else if ( ble_connected() ) {
      Serial.println("BLE Connected");

      //********Maybe we can delete whese two loops********
      while (true) {
        value = EEPROM.readByte(address);
        // Instead of EEPROM.length() we can put the number of bytes of the file if we know the extension
        // avoiding sending many 0 in a row
        while (address < 255) {
          bytes[address] = value;
          Serial.write(value); //Writes binary data to the serial port. This data is sent as a byte or series of bytes
          address = address + 1;
          value = EEPROM.readByte(address);
          //Serial.println(String (value));
        }
        Serial.println("***************");

        //bytes[0]='a';
        //ble_write_bytes(bytes,255); //ble_write_bytes writes an array of bytes in data with length in len.
        //ble_write_bytes(bytes,address); //ble_write_bytes writes an array of bytes in data with length in len.
        //ble_write_bytes(bytes,20);


        //delay(5000);
        /*
          for (int i=0; i<10; i++){
          Serial.println(ble_read());
          }
        */

        //********If blend has sent data to the app, the flap is set to true********
        //********Disconnect BLE if data has been transfered and there's nothing in BLE********
        if (flag == true && ble_read() == -1) {
          Serial.println("Yes!!");
          ble_do_events();
          ble_disconnect();
          flag = false;
        }

        //********If the app connects to the blend, it will send a value to BLE, so ble_read is not -1********
        while (ble_read() != -1) {
          Serial.println("Wait!");
          outputtingToApp();
          flag = true;
        }
        Serial.println("-1");





        /*
          Serial.println(bytes[0]); //original sessionCount
          Serial.println(bytes[1]);
          Serial.println(bytes[2]); //sessionCount
          Serial.println(bytes[3]);
          Serial.println(bytes[4]); //comma
          Serial.println(bytes[5]); //arrayAvg1
          Serial.println(bytes[6]);
          Serial.println(bytes[7]);
          Serial.println(bytes[8]);
          Serial.println(bytes[9]); //comma
          Serial.println(bytes[10]); //arrayAvg2
          Serial.println(bytes[11]);
          Serial.println(bytes[12]);
          Serial.println(bytes[13]);
          Serial.println(bytes[14]); //comma
          Serial.println(bytes[15]); //sessionComp
          Serial.println(bytes[16]);
          Serial.println(bytes[17]);
          Serial.println(bytes[18]);
          Serial.println(bytes[19]); //new line


          ble_write_bytes(bytes,19);
        */

        /*
          Serial.println(bytes[0]); //original sessionCount
          Serial.println();
          Serial.println(bytes[2]); //sessionCount
          Serial.println();
          Serial.println(bytes[4]); //comma
          Serial.println();
          Serial.println(bytes[5]); //arrayAvg1
          Serial.println();
          Serial.println(bytes[9]); //comma
          Serial.println();
          Serial.println(bytes[10]); //arrayAvg2
          Serial.println();
          Serial.println(bytes[14]); //comma
          Serial.println();
          Serial.println(bytes[15]); //sessionComp
          Serial.println();
          Serial.println(bytes[19]); //new line
          Serial.println();
        */

        Serial.println("***************");

        address = 0;
        delay(1000); // We wait for an answer if its true, he has receive it so we go out of the loop, if not, we send it again


        //********I haven't thought of a place to place the break********
        if (ble_read() == -1) { // We may have to change true for the byte that corresponds to true
          //if (true){
          //ble_disconnect(); //ble_read reads a byte from BLE Central, It returns -1 if nothing to be read.
          Serial.println("BLE disconnected.");
          break;
        }
      }
    }
    //}

    ble_do_events();

  }
}
/*
 * Fill The Sending Byte Array from the EEPROM
 * address iterates throught he EEPROM
 * value takes the value from the position in the EEPROM at address
 * dayWithoutSync keeps track of how many of the data arrays need to be stored so that there can be a sync after multiple exercises without a sync
 *      dayWithoutSync isn't stored within any of these methods and is incremented up in the case that 1)Elements are added to resultArray[][] and 2)ble_send_bytes() isn't called
*/
void medArr(unsigned char resultArray[][], int totalBytes, int dayWithoutSync){
 int address;
 int value;
 if(dayWithoutSync > 5){
  arrayOveruse(resultArray);
 }
 for(address = 0; address < totalBytes; address++){
  value = EEPROM.readByte(address,value);
  resultArray[dayWithoutSync][address] = value;
  printf("Byte Array at %d is %d\n",address,byteArr[address]);
 }
}
/*
 * If resultArray[][] gets too full, it shift all the data to the left and then any more data added goes on the end
 */
void arrayOveruse(unsigned char resultArray[][]){
int dayShift;
int valShift;
 for(dayShift = 0; dayShift < 4; dayShift++){
  for(valShift = 0; valShift < 18; valShift++){
   resultArray[dayShift][valShift] = resultArray[dayShift+1][valShift+18];
  }
 }
 dayWithoutSync--;
}
///////////////////////Writing to EEPROM///////////////////////////////////////////////////
void WriteStorage() {
  EEPROM.updateInt(currentAddress, sessionCount); //currentAddress == 2
  currentAddress = currentAddress + 2; //increase by int
  EEPROM.updateByte(currentAddress, comma);
  currentAddress++; //increase by char
  EEPROM.updateFloat(currentAddress, arrayAvg1);
  currentAddress = currentAddress + 4; //increase by float
  EEPROM.updateByte(currentAddress, comma);
  currentAddress++; //increase by char
  EEPROM.updateFloat(currentAddress, arrayAvg2);
  currentAddress = currentAddress + 4; //increase by float
  EEPROM.updateByte(currentAddress, comma);
  currentAddress++; //increase by char
  EEPROM.updateFloat(currentAddress, sessionComp);
  currentAddress = currentAddress + 4;  //increase by float
  EEPROM.updateByte(currentAddress, newline);
  currentAddress++; //increase by char
  if (sampleNum1 > sampleNum2) {
    if (sampleNum1 < 90) { //Not done - these addresses will be rewritten this session
      currentAddress = currentAddress - 18;
    } else { //session is done
      sessionCount++;
      EEPROM.updateInt(0, sessionCount);
    }
    if (testMode) {
      Serial.print(sessionCount);
      Serial.print(',');
      Serial.print(arrayAvg1);
      Serial.print(',');
      Serial.print(arrayAvg2);
      Serial.print(',');
      Serial.print(sessionComp);
      Serial.println(';');
    }
  } else {
    if (sampleNum2 < 90) { //Not done - these addresses will be rewritten this session
      currentAddress = currentAddress - 18;
    } else { //session is done
      sessionCount++;
      EEPROM.updateInt(0, sessionCount);
    }
    if (testMode) {
      Serial.print(sessionCount);
      Serial.print(',');
      Serial.print(arrayAvg1);
      Serial.print(',');
      Serial.print(arrayAvg2);
      Serial.print(',');
      Serial.print(sessionComp);
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

