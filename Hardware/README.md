# Arduino

The Ardiuno script is for the NMES machine.

The original scripts, MasterV1 and RehabTracker, were written by Sean Kates for testing the BLE connection. Currently, RehabTracker was removed and MasterV1 was renamed as Arduino. Both original scripts can be found in the previous Github.

The Arduino script has then been modified by Chia-Chun Chao, Yifan Zhang, and Xavier Stevens beyond that. It now tracks time, has clearer and more useful BLE usage and can transfer data from the NMES->Blend Board->App. The data pull has been fixed so now there is no need for an off-app button for the sync. The intensity values have been completely overhauled, and multiple sessions can now be stored within the EEPROM just incase the user doesn't have internet.

