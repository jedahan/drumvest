/*
   Reads a packet from an XBee radio and parses it.  The packet
   should be 22 bytes long. It should be made up of the following:
     byte 1:     0x7E, the start byte value
     byte 2-3:   packet size, a 2-byte value  (not used here)
     byte 4:     API identifier value, a code that says what this response is (not used here)
     byte 5-6:   Sender's address
     byte 7:     RSSI, Received Signal Strength Indicator (not used here)
     byte 8:     Broadcast options (not used here)
     byte 9:     Number of samples to follow
     byte 10-11: Active channels indicator (not used here)
     byte 12-21: 5 10-bit values, each ADC samples from the sender
*/
int MY_WIDTH = 400;
boolean DEBUG = true;

import processing.serial.*;
PFont f;

Serial myPort;
byte[] inBuffer = new byte[17];
int[] values = new int[MY_WIDTH+1];
int value;
int x;
int numReadings = 10;
int[] readings = new int[numReadings];

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

int threshold;

void setup() 
{
  size(MY_WIDTH,255);
  x = 0;
  f = createFont("Arial",16,true);
  textFont(f,36);
  String portName = "/dev/tty.usbserial-AD026BCW";
  myPort = new Serial(this, portName, 115200);
  background(127);
  oscP5 = new OscP5(this,3333);
  myRemoteLocation = new NetAddress("192.168.1.255",12000);
  threshold = height/2;
  for(int index=0; index<values.length-1; index++){
        values[index]=0;
  }
}

void draw()
{
  background(127);
  stroke(255,0,255);
  line(0,threshold,width,threshold);
  stroke(0,0,255);
  line(x,0,x,height);
  stroke(0);

  // draw value
  fill(255);
  text(value,5,36+5);
  
  stroke(0,255,255);
  // draw values
  for(int index=0; index<values.length-1; index++){
    line(index,values[index],index+1,values[index+1]);
  }


  //should be the start byte
  if (myPort.available() >= 16) {
    myPort.readBytes(inBuffer);
    if(inBuffer[0] == 0x7E){
      value = (inBuffer[13] * 256) + inBuffer[12];
      x = x % (width);
      values[x++] = value;

      // if we have passed a threshold, send an osc message
      if(value>50){
        OscMessage myMessage = new OscMessage("/pad1");
        myMessage.add(value);
        oscP5.send(myMessage,myRemoteLocation);
      }

      /*
      // print raw packets to console
      if (DEBUG) {
        for(int i=0; i<16; i++){
          print(hex(inBuffer[i])+" ");
        }
        println();
      }
      */
    }
  }
}

void mouseDragged() 
{
  threshold = mouseY;
}
