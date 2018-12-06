import requests
import sys
import json
import time

id = sys.argv[1]
facecount = int(sys.argv[2])
malecount = int(sys.argv[3])
femalecount = int(sys.argv[4])
attentivityindex= int(sys.argv[5])

count = {"facecount":facecount, "malecount":malecount, "femalecount":femalecount, "attentivityindex":attentivityindex, "timestamp":time.strftime('%H:%M:%S')}
query = 'id=' + str(id) + '&value=' + str(facecount) +'&malecount=' + str(malecount) +'&femalecount=' + str(femalecount);
with open('/home/intel/Desktop/Retail/OpenVINO/AttentivityData.json', 'w') as file:
     file.write(json.dumps(count))

resp = requests.get('http://192.168.43.156:9002/analytics/face?'+ query);
if resp.status_code != 201:
	print("Unable to submit the data")
else:
    print("Data Submitted for analysis")
