# Code for external Widget solution based on OpenVINO™ Toolkit

## Widget.pyw
```c
import time
from threading import Timer
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import json
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import matplotlib as mpl
import matplotlib.pyplot as plt
import numpy as np
import plotly.plotly as py
import tkinter as tk
from tkinter import *
from threading import Thread

connections = [0]
presentations = [0]
facecount = [0]
malecount = [0]
femalecount=[0]
unite_timestamp = [0]
ov_temp = [0]
ov_timestamp = [0]
ov_flag = False
unite_flag =False
counter = 0;
flag = False

class Handler(FileSystemEventHandler):

    def invokeWidget(self):
        print(" inside invokeWidget")
        updateWindow()
        Timer(15, self.invokeWidget, ()).start()

    def on_any_event(self,event):
        global unite_flag,ov_flag
        print("Inside  change");
        print(event.src_path);
        if(event.src_path=="C:\\Users\\intel1672\\Desktop\\Retail\\05-OpenVINO\\file.json"):
                 self.jsonRead_OVData(event.src_path)
        elif(event.src_path=="C:\\Users\\intel1672\\Desktop\\Retail\\05-OpenVINO\\UniteData.json"):
                 self.jsonRead_uniteData(event.src_path)
        if unite_flag==True or ov_flag==True:
             unite_flag=False
             ov_flag=False


    def jsonRead_uniteData(self,path):
        global unite_flag
        with open(path) as f2:
            UniteData = json.load(f2)
        if(unite_timestamp[-1]!=UniteData["timestamp"]):
            unite_flag = True
            unite_timestamp.append(UniteData["timestamp"])
            connections.append(UniteData["usersConnected"])
            presentations.append(UniteData["usersPresenting"])


    def jsonRead_OVData(self,path):
        global ov_flag
        OVData=[]
        try:
            with open(path) as f1:
                OVData = json.load(f1)
            if(OVData== None):
                print("no value read from openvino")
            if(ov_timestamp[-1]!=OVData["timestamp"]):
                ov_flag=True
                ov_timestamp.append(OVData["timestamp"])
                facecount.append(OVData["facecount"])
                malecount.append(OVData["malecount"])
                femalecount.append(OVData["femalecount"])
        except:
            print("Unexpected error occured")


class MyThread(Thread):
    def __init__(self):
        ''' Constructor. '''
        Thread.__init__(self)


    def run(self):
        print("in run")
        event_handler=Handler()
        observer = Observer()
        observer.schedule(event_handler, "C:\\Users\\intel1672\\Desktop\\Retail\\05-OpenVINO", recursive=False)
        observer.start()
        observer.join()
        print("leaving run")


def updateWindow():

    global flag
    global counter
    if(len(malecount) and len(femalecount)):
        malemean = sum(malecount)/len(malecount)
        femalemean = sum(femalecount)/len(femalecount)
        del malecount[:]
        del femalecount[:]
    else:
        malemean=0
        femalemean=0


    ov_temp.append(counter)
    counter=counter+1
    plt.clf()
    ax = plt.gca()
    plt.axis('off')
    print (connections[-1])
    temptext="  Intel Unite®  Connections :"+ str(connections[-1])+"\n  Male Count :"+str(int(malemean))+"\n  Female Count :"+str(int(femalemean))
    plt.text(0.0, 0.2, temptext, fontsize=13,transform=plt.gcf().transFigure)
    flag = True
    fig.canvas.draw()
    print("plotted graph");


event_handler = Handler()
Timer(0, event_handler.invokeWidget, ()).start()
myThreadOb1 = MyThread()
myThreadOb1.setName('Thread 1')
myThreadOb1.start()
# This defines the Python GUI backend to use for matplotlib
mpl.use('tkAgg')

# Initialize an instance of Tk
root = tk.Tk()
root.overrideredirect(1)


# Initialize matplotlib figure for graphing purposes
fig = plt.figure(figsize=(3,1), dpi=100)

# Special type of "canvas" to allow for matplotlib graphing
canvas = FigureCanvasTkAgg(fig, master=root)

plot_widget = canvas.get_tk_widget()
males = np.array(malecount)
females = np.array(femalecount)
plot_widget.grid(row=0, column=0)
root.mainloop()
```
