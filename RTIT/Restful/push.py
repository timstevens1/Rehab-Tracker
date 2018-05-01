import time
import random
from apns import APNs, Payload, Frame
import mysql.connector

apns = APNs(use_sandbox=False, cert_file='rehabDepCer.pem', key_file='rehabDepKey.pem', enhanced=True)
# Send an iOS 10 compatible notification
try:
	cnx = mysql.connector.connect(user="phys", password="CallingDr.H0w@rd",host="Med65",port=65002,db="rehabtracker")

except mysql.connector.Error as err:
	print(err)
else:
	cursor = cnx.cursor(buffered = True)
	cursor.execute("SELECT pmkPushID, fnkPatientID, fnkMessageID FROM tblPush WHERE fldDelivered != 1");
	notifications = cursor.fetchall()
	frame = Frame()
	for push_ID, patient_ID, message_ID in notifications:
		cursor.execute("SELECT UDID FROM tblPatient WHERE pmkPatientID=%s;",(patient_ID,));
		token_hex = cursor.fetchall()[0][0]
		if token_hex:
			print("{}, {}\n".format(patient_ID, token_hex))
			cursor.execute("SELECT fldMessageString FROM tblNotifications WHERE pmkMessageID=%s;",(message_ID,));
			message = cursor.fetchall()[0][0]
			payload = Payload(alert=message, sound="default", badge=1)
			identifier = random.getrandbits(32)
			priority = 10
			expiry = time.time()+ 86400
			frame.add_item(token_hex, payload, identifier, expiry, priority)
			cursor.execute("UPDATE tblPush SET fldDelivered=1 WHERE pmkPushID=%s",(push_ID,));
			cnx.commit()
	apns.gateway_server.send_notification_multiple(frame)
	cursor.close()
	cnx.close()
