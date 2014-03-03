import processing.serial.*;

Serial myPort;        // The serial port
int xPos = 1;         // horizontal position of the graph


float loopCount=0;
float badCount=0;
float[] peak = new float[2];
int[] sigLength = new int[2];
float[] lastPeak = new float[2];
float[] lastLength = new float[2];
int dataCols;
int dataRows;
float[][] data;
color c2 = color(127, 34, 255);
color c1 = color(8, 130, 250);
Star[][] stars;
int signalMax = 30;
float mouseMass = 1000;
PFont f;
boolean paused = false;
boolean debug = false;
boolean vectors = false;
boolean screenSaver = false;
boolean graph;
boolean make;
boolean mouseMode;
float tails = 255;

void setup () {
  
  if (screenSaver) {
    graph = false;
    make = true;
    mouseMode = false;
  }
  else {
    graph = true;
    make = false;
    mouseMode = true;  
  }

  // set the window size:
  size(displayWidth, displayHeight, P2D);
  if (frame != null) {
    frame.setResizable(true);
  }
  f = loadFont("CourierNewPSMT-11.vlw");
  textFont(f);
  smooth();
  // set inital background:
  background(0);
  dataCols = 2;
  dataRows = width;
  data = new float[dataCols][dataRows];

  stars = new Star[2][width];
}

void draw () {
  // background(0);
  if (!paused) {
    fill(0, 0, 0, tails);
    rect(0, 0, width, height);
    
    if (graph) {
      for (int i = 0; i < dataRows; i++) {
        stroke(c1);
        if (data[0][i] >=1) line(i, height/2, i, height/2 - data[0][i]);
        stroke(c2);
        if (data[1][i] >=1) line(i, height/2, i, height/2 + data[1][i]);
      }
    }
    
    if (make) orbit();
    
    for (int h = 0; h < dataCols; h++) {
      for (int i = 0; i < dataRows; i++) {
        if (stars[h][i] != null && stars[h][i].alive) {
          stars[h][i].update();
          //stars[h][i].checkEdges();
          stars[h][i].display();
        }
      }
    }
  }
}

void keyPressed() {
  if (key == ' ') {
    c1=color(int(random(255)), int(random(255)), int(random(255)));
    c2=color(int(random(255)), int(random(255)), int(random(255)));
  }
  if (key == 'c' || key == 'C') {
    for (int i = 0; i < dataCols; i++) {
      for (int j = 0; j < dataRows; j++) {
        if (stars[i][j] != null) stars[i][j].alive=false;
      }
    }
  }
  if (key == 'o' || key == 'O') {
    orbit();
  }
  if (key == 'p' || key == 'P') {
    if (paused) paused=false;
    else paused=true;
  }
  if (key == 'd' || key == 'D') {
    if (debug) debug=false;
    else debug=true;
  }
  if (key == 'g' || key == 'G') {
    if (graph) graph=false;
    else graph=true;
  }
  if (key == 'v' || key == 'V') {
    if (vectors) vectors=false;
    else vectors=true;
  }
  if (key == 'm' || key == 'M') {
    if (make) make=false;
    else make=true;
  }
  if (key == '0') {
    tails = 255;
  }
  if (key == '1') {
    tails = 100;
  }
  if (key == '2') {
    tails = 10;
  }
  if (key == '3') {
    tails = 1;
  }
  if (key == '4') {
    tails = .1;
  }
}

// Testing new orbit code
void orbit(){
  if (xPos >= width) {
      reset();
    }
    int star0 = int(map(montecarlo(),0,1,signalMax,1));
    int star1 = int(map(montecarlo(),0,1,signalMax,1)); 
    PVector s0location = new PVector(abs(montecarlo()-1)*mouseX-1, mouseY);
    float star0rad = abs(s0location.x-mouseX);
    float star0grav = (star0*mouseMass)/sq(star0rad);
    PVector s0velocity = new PVector(0, -(sqrt(star0grav*star0rad)));
    PVector s1location =  new PVector(abs(montecarlo()-1)*mouseX-1, mouseY);
    float star1rad = abs(s1location.x-mouseX);
    float star1grav = (star1*mouseMass)/sq(star1rad);
    PVector s1velocity = new PVector(0, sqrt(star1grav*star1rad));
    data[0][xPos] = star0;
    data[1][xPos] = star1;
    stars[0][xPos] = new Star(c1, star0, star0, star0, s0location, s0velocity);
    stars[1][xPos] = new Star(c2, star1, star1, star1, s1location, s1velocity);
    xPos++;
}

void reset() {
  xPos = 0;
  //background(0);
  c1=color(int(random(255)), int(random(255)), int(random(255)));
  c2=color(int(random(255)), int(random(255)), int(random(255)));
  for (int i = 0; i < dataCols; i++) {
    for (int j = 0; j < dataRows; j++) {
      data[i][j]=0;
    }
  }
}

void serialEvent (Serial myPort) {
  String myString = "";
  String trimmedString = "";
  String[] inString = new String[2];
  float[] inByteA = new float[2];
  float errRatio;
  if (!(mouseButton == RIGHT)) {
    // Signal error ratio.
    /*
  loopCount++;
     if (badCount == 1) {
     errRatio = badCount/loopCount;
     println(badCount+"/"+loopCount);
     println("Error ratio: "+errRatio);
     loopCount=0;
     badCount=0;
     }
     */
    // get the ASCII string:
    myString = myPort.readStringUntil('\n');
    //Trim off white space
    trimmedString = trim(myString);
    //Make sure string conatins only 1-4 digits a comma and then 1-4 digits. Otherwise set to 0.
    if (!trimmedString.matches("\\d{1,4},\\d{1,4}")) {
      trimmedString = "0";
      //Signal error data.
      //println("Bad data detected: "+myString);
      badCount++;
    }
    //Data should be clean at this point or ignored.

    //Split string into an array to handle data from multiple sensors.
    inString = splitTokens(trimmedString, ",");

    //For each sensor, map the value for graphing.
    for (int i = 0; i < inString.length; i++) { 

      // convert to a float and map to the screen height:
      inByteA[i] = map(float(inString[i]), 0, 1023, 0, height);
      //println(map(inByte, 0, 1023, 0, height));   

      //Calculate peak of each sensor and display value as an int.
      if (inByteA[i] > peak[i]) {
        peak[i]=inByteA[i];
      }
      else {
        if (peak[i] >= 1) {
          lastPeak[i]= peak[i];
          peak[i] = 0;
        }
      }

      //Calculate length of signal.
      if (inByteA[i] >= 1) {
        sigLength[i]++;
      }
      else if (sigLength[i] >= 1) {
        lastLength[i] = sigLength[i];
        sigLength[i]=0;
      }
    }
    //Update data arrays.
    if (inByteA[0] >= 1 || inByteA[1] >= 1) {
      data[0][xPos] = inByteA[0];
      data[1][xPos] = inByteA[1];
      stars[0][xPos] = new Star(c1, inByteA[0], inByteA[0], inByteA[0]);
      stars[1][xPos] = new Star(c2, inByteA[1], inByteA[1], inByteA[1]);
      xPos++;
    }

    // at the edge of the screen, go back to the beginning:
    if (xPos >= width) {
      xPos = 0;
      //background(0);
      c1=color(random(255), random(255), random(255));
      c2=color(random(255), random(255), random(255));
      for (int i = 0; i < dataCols; i++) {
        for (int j = 0; j < dataRows; j++) {
          data[i][j]=0;
        }
      }
    }
  }
}

class Star {
  PVector target;
  PVector location;
  PVector velocity;
  PVector acceleration;
  PVector gravity;
  PVector dir;
  float topspeed = 10;
  float starsize;
  float mass;
  boolean alive;
  color clr1;
  /*Star() {
    location = new PVector(width/2, height/2);
    velocity = new PVector(0, 0);
    topspeed = topspeed;
    alive = true;
    clr1 = color(100);
  }*/ /*
  Star(color c) {
    location = new PVector(width/2, height/2);
    velocity = new PVector(0, 0);
    alive = true;
    topspeed = topspeed;
    clr1 = c;
  }*/ /*
  Star(color c, PVector t) {
    location = new PVector(width/2, height/2);
    velocity = new PVector(0, 0);
    target = t;
    alive = true;
    topspeed = topspeed;
    clr1 = c;
  } */
  Star(color c, float s, float sp, float M) {
    location = new PVector(random(width), random(height));
    velocity = new PVector(random(-4, 4), random(-4, 4));
    starsize = s;
    mass = M;
    alive = true;
    topspeed = topspeed-10/sp;
    clr1 = c;
  }
  Star(color c, float s, float sp, float M, PVector loc, PVector vel) {
    location = loc;
    velocity = vel;
    starsize = s;
    mass = M;
    alive = true;
    topspeed = topspeed-10/sp;
    clr1 = c;
  }
  void update() {
    if (alive) {
      if (target == null) target = new PVector(random(width), random(height));
      if (dir == null) dir = PVector.sub(target, location);
      if (mouseMode){
        if (mouseX >10 && mouseY >10) {
          mouseGravity();
          velocity.add(gravity);
        }
        else{
            
        }
      }
      // velocity.limit(topspeed);
      if (vectors) {
        stroke(255);
        line(location.x+mass/2, location.y+mass/2, (location.x+velocity.x)+mass/2, (location.y+velocity.y)+mass/2);
      }
      location.add(velocity);
    }
    else {
      if (vectors) {
        stroke(255);
        line(location.x, location.y, location.x+velocity.x, location.y+velocity.y);
      }
      location.add(velocity);
    }
  }
  void mouseGravity() {
    target = new PVector(mouseX, mouseY);
    float F;
    if ( sq( location.x - target.x ) + sq( location.y - target.y ) != 0 ) {
      F = mass * mouseMass;
      F /= sq( location.x - target.x ) + sq( location.y - target.y );
      dir = PVector.sub(target, location);
      dir.normalize();
      if (!mousePressed)dir.mult(F);
      if (mousePressed)dir.mult(-F);
      gravity = dir;
    }
  }
  void display() {
    if (alive) {
      noStroke();
      fill(clr1);
      ellipse(location.x, location.y, starsize, starsize);
      if (debug) {
        fill(255);
        text("Size: "+starsize+"\n"+
          "x: "+location.x+" y: "+location.y, location.x+starsize/2, location.y+starsize);
      }
    }
  }
  void checkEdges() {

    if (location.x > width+10) {
      alive = false;
    } 
    else if (location.x < -10) {
      alive = false;
    }

    if (location.y > height+10) {
      alive = false;
    }  
    else if (location.y < -10) {
      alive = false;
    }
  }
}

public float montecarlo() {
  // Have we found one yet
  boolean foundone = false;
  int hack = 0;  // let's count just so we don't get stuck in an infinite loop by accident
  while (!foundone && hack < 10000) {
    // Pick two random numbers
    float r1 = (float) random(1);
    float r2 = (float) random(1);
    float y = r1*r1;  // y = x*x (change for different results)
    // If r2 is valid, we'll use this one
    if (r2 < y) {
      foundone = true;
      return r1;
    }
    hack++;
  }
  // Hack in case we run into a problem (need to improve this)
  return 0;
}
