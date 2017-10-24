# Arduino

These are the two ardiuno scripts for the NMES machine. 

The RehabTracker script was written by Sean Kates for testing the BLE connection, the data is hardcoded into the bytes[] array.

The MasterV1 script was written by the SEED team for the actual prototype that they created. I (Sean Kates) have not verified if it works, but the BLE protocol is the same as the test script, and should work similarly if the data is being created successfully.

Understanding What's Going On:

1.Turn on Green Light
2.User must press button or have the test already finished
3.If BLE isn't connected, Inform user and dump data
4.If BLE is connected, 
 4a.Fill the bytes array with the first 255 elements in memory
 4b.Writes an Array of bytes in "bytes" with a length of 255
 4c.Resets the address to 0, waits a second, and if there is no answer from the bluetooth, we send it again
 4d.then do some events
 4e.STORE THIS AS: buttonInterrupt
5.The value of each of the 2 channels are printed
6.buttonInterrupt
7.Compare the Old value of the first sensor pin to a new one
8.If the onld one's value is greater than the new one but less than the max
  make the new max equal to that old value. Convert that value using that if/else thing.
8.if that calculated value is > 0, store it in an array and add it to the total of the array
  and calculate the mean. Then set the user Compliance.
9.Set the max value to 0, buttonInterrupt, and wait half a second
10.If the this sample is a multiple of 9, write that to the storage
   'The weird situation here is to find peaks in the intensity. If it keeps climbing, it 
   only matters when it starts to dip'
11.To write to storage the sessionNumber, Averages for both channels, and compliance are
  updated and if this isn't the 90th session it gets prepared to rewrite.
12.buttonInterrupt
13.Output the address your at, and both the sample numbers
