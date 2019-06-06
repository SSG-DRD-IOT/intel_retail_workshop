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
import tkinter as tk
import pandas as pd
import math
from tkinter import *
from threading import Thread

connections=[0]
presentations=[0]
facecount=[0]
malecount=[0]
femalecount=[0]
attentivecount=[0]
unite_timestamp=[0]
ov_timestamp=[0]
ov_flag=False
unite_flag=False
ov_temp=[0]
counter = 0;
average_males=[0]
average_females=[0]
average_attentivity=[0]
ind = [0]

class Handler(FileSystemEventHandler):

    def invokemethod(self):
        print("in innvoke method")
        plotGraph()
        Timer(60, self.invokemethod, ()).start()

    def on_any_event(self,event):
        global unite_flag,ov_flag
        print("Inside  change");
        print(event.src_path);
        if(event.src_path=="C:\\Users\\intel\\Desktop\\Retail\\OpenVINO\\AttentivityData.json"):
                 self.jsonRead_OVData(event.src_path)
        elif(event.src_path=="C:\\Users\\intel\\Desktop\\Retail\\OpenVINO\\UniteData.json"):
                 self.jsonRead_uniteData(event.src_path)
        if unite_flag==True or ov_flag==True:
            unite_flag=False
            ov_flag=False

    def jsonRead_uniteData(self,path):
        global unite_flag
        with open(path) as f2:
            UniteData = json.load(f2)        
        if(unite_timestamp[-1]!=UniteData["timestamp"]):
            unite_flag=True
            unite_timestamp.append(UniteData["timestamp"])
            connections.append(UniteData["usersConnected"])
            presentations.append(UniteData["usersPresenting"])

    def jsonRead_OVData(self,path):
        global ov_flag
        OVData=[]
        try:
            with open(path) as f1:
                OVData = json.load(f1)
                print("file open is done")
            if(OVData== None):
                print("no value read from openvino")
            if(ov_timestamp[-1]!=OVData["timestamp"]):
                print("value is taken from file")
                ov_flag=True
                ov_timestamp.append(OVData["timestamp"])
                facecount.append(OVData["facecount"])
                malecount.append(OVData["malecount"])
                femalecount.append(OVData["femalecount"])
                attentivecount.append((OVData["attentivityindex"]/OVData["facecount"])*100)
        except:
            print("Unexpected error occured")

class MyThread(Thread):
    def __init__(self):
        Thread.__init__(self)

    def run(self):
        print("in run")
        event_handler=Handler()
        event_handler.jsonRead_OVData("C:\\Users\\intel\\Desktop\\Retail\\OpenVINO\\AttentivityData.json")
        event_handler.jsonRead_uniteData("C:\\Users\\intel\\Desktop\\Retail\\OpenVINO\\UniteData.json")
        observer = Observer()
        observer.schedule(event_handler, "C:\\Users\\intel\\Desktop\\Retail\\OpenVINO", recursive=False)
        observer.start()
        observer.join()
        print("leaving run")


def plotGraph():
    global counter    
    if(len(malecount) and len(femalecount) and len(attentivecount)):
        malemean = math.ceil(sum(malecount)/len(malecount))
        femalemean = math.ceil(sum(femalecount)/len(femalecount))
        attentivityindex  = math.ceil(sum(attentivecount)/len(attentivecount))
    else:
        malemean=0
        femalemean=0
        attentivityindex=0

    average_males.append(malemean)
    average_females.append(femalemean)
    average_attentivity.append(attentivityindex)    
    del malecount[:]
    del femalecount[:]
    del attentivecount[:]

    ov_temp.append(counter)
    counter = counter+1
    males = np.array(average_males)
    females = np.array(average_females)
    attentivityvalue = np.array(average_attentivity)
    ind = [x for x, _ in enumerate(ov_temp)]
    plt.clf()    
    ax = plt.gca()
    ax.set_xbound(-1.0 ,5.0)
    plt.xlim((0, 15))
    plt.ylim((0, 100))

    print(attentivityvalue[-1])
    frequencies = attentivityvalue
    freq_series = pd.Series(frequencies)
    temptext=" \n Intel Unite®  Connections :"+ str(connections[-1])+"\n  Male Count :"+str(int(malemean))+"  Female Count :"+str(int(femalemean))
    plt.title(temptext)
    plt.bar(ov_temp, attentivityvalue, width=0.8, label='Attentivity Index', color='#77b7ff')
    plt.ylabel("Percentage Active",labelpad=0.5)
    plt.xlabel("Time in minutes")
    plt.legend(loc="upper left",prop={'size': 6})
    rects = ax.patches

    # For each bar: Place a label
    for rect in rects:
        # Get X and Y placement of label from rect.

        y_value = rect.get_height()
        x_value = rect.get_x() + rect.get_width() / 2

        # Number of points between bar and label. Change to your liking.
        space = 2
        # Vertical alignment for positive values
        va = 'bottom'
        # Use Y value as label and format number with one decimal place
        label = "{:.1f}".format(y_value)

        # Create annotation
        plt.annotate(
            label,                      # Use `label` as label
            (x_value, y_value),         # Place label at end of the bar
            xytext=(0, space),          # Vertically shift label by `space`
            textcoords="offset points", # Interpret `xytext` as offset in points
            ha='center', fontsize=6,
            color='gray',               # Horizontally center label
            va=va)                      # Vertically align label differently for
                                        # positive and negative values.

    fig.canvas.draw_idle()
    print("Graph")


event_handler = Handler()
Timer(1, event_handler.invokemethod, ()).start()  
myThreadOb1 = MyThread()
myThreadOb1.setName('Widget Thread')
myThreadOb1.start()
# This defines the Python GUI backend to use for matplotlib
mpl.use('tkAgg')

# Initialize an instance of Tk
root = tk.Tk()
root.overrideredirect(1)

# Initialize matplotlib figure for graphing purposes
fig = plt.figure(figsize=(4.5,4.5), dpi=100)

# Special type of "canvas" to allow for matplotlib graphing
canvas = FigureCanvasTkAgg(fig, master=root)
plot_widget = canvas.get_tk_widget()

males = np.array(malecount)
females = np.array(femalecount)
plot_widget.grid(row=0, column=0)
root.mainloop()
```
