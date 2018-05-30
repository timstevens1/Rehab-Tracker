# Arduino

These are the two ardiuno scripts for the NMES machine. 

The RehabTracker script was written by Sean Kates for testing the BLE connection, the data is hardcoded into the bytes[] array.

The MasterV1 script was written by the SEED team for the actual prototype that they created. I (Sean Kates) have not verified if it works, but the BLE protocol is the same as the test script, and should work similarly if the data is being created successfully.

The MasterV1 script has then been modified by Chia-Chun Chao, Yifan Zhang, and Xavier Stevens beyond that. MasterV1 now tracks time, has clearer and more useful BLE usage and can transfer data from the NMES->Blend Board->App, fixed the data pull so now there is no need for an off-app button for the sync, the intensity values have been completely overhauled, and multiple sessions can now be stored within the EEPROM just incase the user doesn't have internet

