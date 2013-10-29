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

int count = 0;
Serial myPort;
byte[] inBuffer = new byte[256];
String inString;

float[] raw = new float[MY_WIDTH+1];
float[] raw2 = new float[MY_WIDTH+1];
float[] eased = new float[MY_WIDTH+1];
float[] eased2 = new float[MY_WIDTH+1];
int value = 0;
int value2 = 0;
int x = 0;

float easing = 0.5;
float easedValue;
float easedValue2;

import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress myRemoteLocation;

float threshold, thresholdY;

void setup() 
{
  size(MY_WIDTH,360);
  threshold = height*3/4;

  myPort = new Serial(this, "/dev/tty.usbserial-AD026BCW", 115200);
  myPort.bufferUntil(0x7e);

  oscP5 = new OscP5(this,3333);
  myRemoteLocation = new NetAddress("127.0.0.1",4321);
  for(int index=0; index<raw.length; index++){
    raw[index]=eased[index]=0;
    raw2[index]=eased2[index]=0;
  }
}

void draw()
{
  easedValue += (value - easedValue) * easing;
  eased[x] = easedValue;
  raw[x] = value;

  easedValue2 += (value2 - easedValue2) * easing;
  eased2[x] = easedValue2;
  raw2[x] = value2;
  
  background(0);

  // draw values
  for(int index=0; index<raw.length; index++){
    float y  = map(eased[index], 0, 1023, 0, height);
    float y2  = map(eased2[index], 0, 1023, 0, height);
    stroke(127,0,0);
    line(index,height,index,height-y);
    stroke(0,0,127);
    line(index,height,index,height-y2);
  }

  // threshold
  stroke(255,0,255);
  threshold = map(thresholdY, height, 0, 0, 1024);
  line(0,thresholdY,width,thresholdY);

  // current value line
  stroke(0,255,0);
  line(x,0,x,height);

  // draw value
  text(value,5,36+5);
  text(value2,5,66+5);
  
  // draw threshold
  text(threshold,width-100,36+5);
  
  float first = eased[mod(x,eased.length)];
  float previous = eased[mod(x-1,eased.length)];
  float current = eased[mod(x-2,eased.length)];

  if(current < previous && previous > first){
    if(previous - threshold > 64) {
      println("hit " + ++count + ", strength " + (previous-threshold));
      OscMessage m = new OscMessage("/pad");
      m.add(value);
      oscP5.send(m,myRemoteLocation);
    }
  }
  
  float first2 = eased2[mod(x,eased2.length)];
  float previous2 = eased2[mod(x-1,eased2.length)];
  float current2 = eased2[mod(x-2,eased2.length)];

  if(current2 < previous2 && previous2 > first2){
    if(previous2 - threshold > 64) {
      println("hit " + ++count + ", strength " + (previous2-threshold));
      OscMessage m = new OscMessage("/pad");
      m.add(value);
      oscP5.send(m,myRemoteLocation);
    }
  }

  x++;
  if(x>width){x=0;}
}

int mod(int val, int mod) {
  return ((val % mod) + mod) % mod; 
}

void serialEvent(Serial myPort) { 
  myPort.readBytesUntil(0x7e,inBuffer);
  if (inBuffer != null){
    value = (inBuffer[12] * 256) + inBuffer[11];
    value2 = (inBuffer[14] * 256) + inBuffer[13];
    
    /*
    for(int i=0; i<16; i++){
      print(hex(inBuffer[i])+" ");
    }
    println();
    */
  }
}

void mouseDragged() 
{
  thresholdY = constrain(mouseY,height/2,height);
}
