import processing.serial.*;
import processing.sound.*;

Serial serial;
boolean serialActive = false;
String data;
String[] binInput;

SoundFile kick;
SoundFile snare;
SoundFile tempo;

color plr_l;
color plr_r;
color center;
color bgd;
int plr_lHue = 180;
int plr_rHue = 90;
int plrSat;

int initBeat = 0;
int lastBeat = -5000;
int curSec = 0;

int maxPulseSize;
int maxPulseRate = 16;
float tempoPulseRatio;

int plrPulseSize;
int plrPulseRate;
float plrPulseAmp;
int tempoPulseSize;
int tempoPulseRate;
float tempoPulseAmp;

PShape[] leftCache = new PShape[60];
PShape[] rightCache = new PShape[60];
PShape[] centerCache = new PShape[60];

ObjectDynamics objDyn = new ObjectDynamics();
Pulser pulse = new Pulser();

void setup() {
  surface.setTitle("Common Beat");
  surface.setResizable(true);
  frameRate(24);
  size(1280, 720);
  
  background(bgd);
  noFill();
  stroke(bgd);
  strokeWeight(8);
  ellipseMode(RADIUS);
  
  colorMode(HSB, 360, 100, 100);
  plr_l = color(291, 52, 80);
  plr_r = color(255, 78, 80);
  center = color(204, 2, 92);
  bgd = color(0, 0, 16);
  
  maxPulseSize = width + (width / 2);
  
  leftCache = objDyn.nullList(leftCache);
  rightCache = objDyn.nullList(rightCache);
  centerCache = objDyn.nullList(centerCache);
  
  kick = new SoundFile(this, "kick.wav", false);
  snare = new SoundFile(this, "snare.wav", false);
  tempo = new SoundFile(this, "tempo.wav", false);
  
  // Check to see if Serial is availiable
  try {
    serial = new Serial(this, Serial.list()[1], 9600);
    serialActive = true;
  } catch(Exception e) {
    println(e);
  }
}

void draw() {
  // Shift hue for player pulses
  if (frameCount % frameRate <= 12) { 
    plr_lHue = plr_lHue + 4;
    plr_rHue = plr_rHue - 4;
  } else {
    plr_lHue = plr_lHue - 4;
    plr_rHue = plr_rHue + 4;
  }
  plr_l = color(plr_lHue, plrSat, brightness(plr_l));
  plr_r = color(plr_rHue, plrSat, brightness(plr_r));
  
  // If no user input for 5 seconds, reset the sketch 
  if (millis() >= lastBeat + 5000) {
    initBeat = 0;
    background(bgd);
    plrSat = 80;
    plr_lHue = 180;
    plr_rHue = 90;
    
    plrPulseSize = maxPulseSize;
    plrPulseRate = 16;
    plrPulseAmp = 1.0;
    tempoPulseSize = maxPulseSize / 120;
    tempoPulseRate = 2;
    tempoPulseAmp = 0.1;
  }
  
  // After 15 seconds of user interaction...
  if ((initBeat != 0) && (millis() >= initBeat + 15000)) {
    // ...send out tempo pulse
    if (second() != curSec) {
      curSec = second();
      // Decrease the player pulse; increase the tempo pulse
      plrPulseSize = constrain((plrPulseSize - 8), 16, maxPulseSize);
      tempoPulseSize = constrain((tempoPulseSize + 8), 0, maxPulseSize);
      
      tempoPulseRatio = float(tempoPulseSize) / float(maxPulseSize);
      
      tempo.stop();  
      pulse.sizeShift(tempoPulseSize);
      pulse.rateShift(tempoPulseRate);
      stroke(center);
      ellipseMode(CENTER);
      pulse.display(centerCache, (width / 2), (height / 2));
      tempo.amp(tempoPulseAmp);
      tempo.play();
    }
    
    // Set current ripple rate and sound volume
    plrPulseRate = constrain((16 - int(16 * tempoPulseRatio)), 2, 16);
    tempoPulseRate = constrain(int(16 * tempoPulseRatio), 1, 16);
    plrPulseAmp = constrain((1.0 - tempoPulseRatio), 0.1, 1.0);
    tempoPulseAmp = constrain(tempoPulseRatio, 0.1, 1.0);
    plrSat = constrain((100 - int(100.0 * tempoPulseRatio)), 10, 80); 
    println(plrSat);
  }
  
  
  // Clean Serial data for use as input
  if ((serialActive == true) && (serial.available() > 0)) {
    data = serial.readStringUntil('\n');
    if ((data != null) && (data.length() == 5)) {
      binInput = splitTokens(data);
      printArray(binInput);
    }
  }
  
  // binInput[0] = Left, binInput[1] = Right
  if ((data != null) && (data.length() == 5)) {    
    if (binInput[0].equals(str(1))) {
      lastBeat = millis();
      if (initBeat == 0) {
        initBeat = millis();
      }
      
      kick.stop();
      pulse.sizeShift(plrPulseSize);
      pulse.rateShift(plrPulseRate);
      stroke(plr_l);
      ellipseMode(RADIUS);
      pulse.display(leftCache, 0, (height / 2)); 
      kick.amp(plrPulseAmp);
      kick.play();
    }
    if (binInput[1].equals(str(1))) {
      lastBeat = millis();
      if (initBeat == 0) {
        initBeat = millis();
      }
      
      snare.stop();
      pulse.sizeShift(plrPulseSize);
      pulse.rateShift(plrPulseRate);
      stroke(plr_r);
      ellipseMode(RADIUS);
      pulse.display(rightCache, width, (height / 2)); 
      snare.amp(plrPulseAmp);
      snare.play();
    }
  }
  
  if (mousePressed) {
    lastBeat = millis();
    if (initBeat == 0) {
      initBeat = millis();
    }
    
    kick.stop();
    pulse.sizeShift(plrPulseSize);
    pulse.rateShift(plrPulseRate);
    stroke(plr_l);
    ellipseMode(RADIUS);
    pulse.display(leftCache, 0, (height / 2)); 
    kick.amp(plrPulseAmp);
    kick.play();
  }
  if (keyPressed) {
    lastBeat = millis();
    if (initBeat == 0) {
      initBeat = millis();
    }
    
    snare.stop();
    pulse.sizeShift(plrPulseSize);
    pulse.rateShift(plrPulseRate);
    stroke(plr_r);
    ellipseMode(RADIUS);
    pulse.display(rightCache, width, (height / 2)); 
    snare.amp(plrPulseAmp);
    snare.play();
  }
  
  noStroke();
  fill(bgd, 55);
  rect(0, 0, width, height);
  noFill();
  
  // Display centerCache
  shape(centerCache[(centerCache.length - 1)], 0, 0); // We have it render the last position for the ripple effect
  objDyn.arrayShuffle(centerCache, createShape(LINE, width/2, height/2, width/2, height/2));
  
  // Display leftCache
  shape(leftCache[(leftCache.length - 1)], 0, 0); // We have it render the last position for the ripple effect
  objDyn.arrayShuffle(leftCache, createShape(LINE, width/2, height/2, width/2, height/2));
  
  // Display rightCache 
  shape(rightCache[(rightCache.length - 1)], 0, 0);
  objDyn.arrayShuffle(rightCache, createShape(LINE, width/2, height/2, width/2, height/2));
}

/**
 * <h1>ObjectDynamics</h1>
 * Handles core functionality for shape caches, allowing them to work properly.
 */
class ObjectDynamics {
    /**
     * Used in order to prevent crashes in the draw function, as all PShape arrays must be fully filled with data before rendering.
     * @param list PShape list to be altered
     * @return list PShape list written with placeholder data
     */
    PShape[] nullList(PShape[] list) {
        for (int i = 0; i < list.length; ++i) {
             list[i] = createShape(LINE, width/2, height/2, width/2, height/2);
        }
        return list;
    }

    /**
     * Adds a new item to the front of a array, maintaining initialized size.
     * @param data PShape list to be altered
     * @param input New PShape to add to the list
     * @return data PShape list with the new shape added to the front of the list
     */
    PShape[] arrayShuffle(PShape[] data, PShape input) {
        for (int i = data.length - 1 ; i > 0; i--) {
            data[i] = data[i - 1]; 
        }
        data[0] = input; 
        return data;
    }
}

/**
 * <h1>Pulser</h1>
 * Handles settings and events for pulses
 */
class Pulser {
    int type = ELLIPSE;
    int scale = 16;     // Maximum pulse size
    int rate = 1;       // Rate of size increase; bigger is slower

    /**
     * Sends PShape data onto the shape cache
     * @param shape
     * @param x X position of the shape
     * @param y Y position of the shape
     * @return Nothing
     */
    void display(PShape[] shape, int x, int y) {
        for (int i = 0; i < shape.length; ++i) {
            int size = (((-scale) * rate) / (i + rate)) + scale;
            //println(size);
            objDyn.arrayShuffle(shape, createShape(type, x, y, size, size));
        }
    }

    /**
     * Sets the new shape type
     * @param newType New shape primative
     * @return Nothing
     */
    void shapeShift(int newType) {
        type = newType;
    }

    /**
     * Sets the new maximum scale for pulse events
     * @param newScale New maximum size (int)
     * @return Nothing
     */
    void sizeShift(int newScale) {
        scale = newScale;
    }

    /**
     * Sets the new ripple rate for pulse events
     * @param newRate New ripple rate (int)
     * @return Nothing
     */
    void rateShift(int newRate) {
        rate = newRate;
    }

    /**
     * Draws a primative of `type` onto the canvas
     * @param size Size of the center shape (int)
     * @return Nothing
     */
    void centerShape(int size) {
        fill(255);
        shape(createShape(type, width/2, height/2, size, size));
    }
}
