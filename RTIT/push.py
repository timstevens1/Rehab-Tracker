import requests
from apns import APNs, Payload, Frame
import json
import random
import time

r = requests.get('https://rehabtracker.med.uvm.edu/Restful/getPushNotifications.php')
noteList = json.loads(r.text)
apns = APNs(use_sandbox=False, cert_file='rehabDepCer.pem', key_file='rehabDepKey.pem', enhanced=True)
delivered = [];
frame = Frame()
for note in noteList:
	payload = Payload(alert=note['Message'], sound="default", badge=0)
	identifier = random.getrandbits(32)
	priority = 10
	expiry = time.time()+ 86400
	print(note['UDID'])
	frame.add_item(note['UDID'], payload, identifier, expiry, priority)
	delivered.append(note['pmkPushID'])
apns.gateway_server.send_notification_multiple(frame)
postJson = json.dumps({ "pushed" : delivered })
POST = requests.post('https://rehabtracker.med.uvm.edu/Restful/getPushNotifications.php', data = postJson)
print(POST.status_code)
