#!/usr/bin/env python
import time
from apns import APNs, Frame, Payload

apns = APNs(use_sandbox=True, cert_file='../../rehabcer.pem', key_file='../../rehabkey.pem')

# Send an iOS 10 compatible notification
token_hex = 'ee0c362a5b1903ec29155f5f180265e31a4c5165af61d9f7a586f9d8849a9ee8'
payload = Payload(alert="Hello World!", sound="default", badge=1)
apns.gateway_server.send_notification(token_hex, payload)
