# Rehab-Tracker
The overarching goal of the project was to create a mobile application/wireless-enabled NMES device to improve rehabilitation compliance of patients with ACL tears through increased monitoring and novel patient-provider interactions. The iOS app connects to the NMES electrotherapy device through bluetooth, and recieves data on the rehabilitation session. This data is saved in a database and is viewable to the physician on the physician-portal website. Copyright © University of Vermont.

Check ***Documentation/html_doxygen/index.html*** after cloning the project to read the documentation.

**Folder Directory:**

- **Documentation:**
    - The text documents, configuration files, images, and HTML files.
- **Hardware:**
    - The code for the Blend Arduino that will be uploaded to the board on the NMES machine. There is only one file, Arduino.ino, in this directory.
- **RTIT:**
    - The code for web services including physician web portal and backend database web services.
    - **Restful:** All of the scripts that involve RESTful communication, PUSH notifications, and compliance scripts as well as database architecture.
    - **PhysicianPortal:** The code for the online portal which clinicians can use to add/manage users as well as track compliance and patient sessions.
- **Rehab Tracker:**
    - The code for the mobile application(iOS) where patients upload their session information which writes to the database. The documentation of the app is written with Jazzy.


Current authors:
- Tim Stevens timothy.stevens@uvm.edu
- Chia-Chun Chao chia-chun.chao@uvm.edu
- Xavier Stevens Xavier.Stevens@uvm.edu

Advisors:
- Christian Skalka Christian.Skalka@uvm.edu
- Michael Toth michael.toth@med.uvm.edu

Previous authors:
- Brian Colombini bcolombi@uvm.edu
- Luke Trinity ltrinity@uvm.edu
- Yifan Zhang yifan.zhang.1@uvm.edu
- Sean Kates sean.kates@uvm.edu
- Brandon Goodwin brandon.goodwin@uvm.edu
- Meaghan Winter meaghan.winter@uvm.edu


