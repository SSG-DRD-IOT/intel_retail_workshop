import numpy as np
import cv2


cv2.namedWindow('frame')
cv2.namedWindow('dist')

# the classifier that will be used in the cascade
faceCascade = cv2.CascadeClassifier('haar_face.xml')

#capture video stream from camera source. 0 refers to first camera, 1 referes to 2nd and so on. 
cap = cv2.VideoCapture(0)


triggered = False
sdThresh = 10
font = cv2.FONT_HERSHEY_SIMPLEX

def distMap(frame1, frame2):
    """outputs pythagorean distance between two frames"""
    frame1_32 = np.float32(frame1)
    frame2_32 = np.float32(frame2)
    diff32 = frame1_32 - frame2_32
    norm32 = np.sqrt(diff32[:,:,0]**2 + diff32[:,:,1]**2 + diff32[:,:,2]**2)/np.sqrt(255**2 + 255**2 + 255**2)
    dist = np.uint8(norm32*255)
    return dist

_, frame1 = cap.read()
_, frame2 = cap.read()

while(True):
    _, frame3 = cap.read()
    rows, cols, _ = np.shape(frame3)
    cv2.imshow('dist', frame3)
    dist = distMap(frame1, frame3)

    frame1 = frame2
    frame2 = frame3

    # apply Gaussian smoothing
    mod = cv2.GaussianBlur(dist, (9,9), 0)

    # apply thresholding
    _, thresh = cv2.threshold(mod, 100, 255, 0)

    # calculate st dev test
    _, stDev = cv2.meanStdDev(mod)

    cv2.imshow('dist', mod)
    cv2.putText(frame2, "Standard Deviation - {}".format(round(stDev[0][0],0)), (70, 70), font, 1, (255, 0, 255), 1, cv2.LINE_AA)

    
    if stDev > sdThresh:
            # the cascade is implemented in grayscale mode
            gray = cv2.cvtColor(frame2, cv2.COLOR_BGR2GRAY)

            # begin face cascade
            faces = faceCascade.detectMultiScale(
                gray,
                scaleFactor=2,
                minSize=(20, 20)
            )
            facecount = 0
            # draw a rectangle over detected faces
            for (x, y, w, h) in faces:
                facecount = facecount + 1 
                cv2.rectangle(frame2, (x, y), (x+w, y+h), (0, 255, 0), 1)
            cv2.putText(frame2, "No of faces {}".format(facecount), (50, 50), font, 1, (0, 0, 255), 1, cv2.LINE_AA)
                            
    cv2.imshow('frame', frame2)

    if cv2.waitKey(1) & 0xFF == 27:
        break

cap.release()
cv2.destroyAllWindows()
