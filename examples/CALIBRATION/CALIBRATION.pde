//==========================================================
// set resolution of your projector image/second monitor
// and name of your calibration file-to-be
/*@REMOVE
int pWidth = 1024;
int pHeight = 768; 
String calibFilename = "calibration.txt";
*/
//@ADD
int pWidth = 800;
int pHeight = 600; 
String calibFilename = "calibration.txt";


//==========================================================
//==========================================================

import javax.swing.JFrame;
//@REMOVE import SimpleOpenNI.*;
//@ADD START
import org.openkinect.freenect.*;
import org.openkinect.freenect2.*;
import org.openkinect.processing.*;
//@ADD END

import gab.opencv.*;
import controlP5.*;
import Jama.*;

//@REMOVE SimpleOpenNI kinect;
//@ADD
Kinect2 kinect;

OpenCV opencv;
ChessboardFrame frameBoard;
ChessboardApplet ca;
PVector[] depthMap;
ArrayList<PVector> foundPoints = new ArrayList<PVector>();
ArrayList<PVector> projPoints = new ArrayList<PVector>();
ArrayList<PVector> ptsK, ptsP;
PVector testPoint, testPointP;
boolean isSearchingBoard = false;
boolean calibrated = false;
boolean testingMode = false;
int cx, cy, cwidth;

//@ADD
int h, r;
int temp2;
PVector temp;
PImage src;

void setup() 
{
  //@REMOVE size(1200, 768);
  //@ADD
  surface.setSize(1200, 768);
  
  textFont(createFont("Courier", 24));
  frameBoard = new ChessboardFrame();

  // set up kinect 
  /*@REMOVE
  kinect = new SimpleOpenNI(this);
  kinect.setMirror(false); //@TODO libfreenect2 automatically flips, still have to compensate
  kinect.enableDepth();
  //kinect.kinect.enableIR();
  kinect.enableRGB();
  kinect.alternativeViewPointDepthToImage();
  */
  //@ADD
  kinect = new Kinect2(this);
  kinect.initDepth(); 
  kinect.initVideo();
  kinect.initRegistered();
  kinect.initIR();
  kinect.initDevice();
  
  //@REMOVE opencv = new OpenCV(this, kinect.depthWidth(), kinect.depthHeight());
  //@ADD
  opencv = new OpenCV(this, kinect.depthWidth, kinect.depthHeight);

  //@ADD
  depthMap = new PVector[kinect.depthWidth*kinect.depthHeight];

  // matching pairs
  ptsK = new ArrayList<PVector>();
  ptsP = new ArrayList<PVector>();
  testPoint = new PVector();
  testPointP = new PVector();
  setupGui();
}

void draw() 
{
  // draw chessboard onto scene
  projPoints = drawChessboard(cx, cy, cwidth);

  // update kinect and look for chessboard
  //@REMOVE kinect.update();
  //@REMOVE depthMap = kinect.depthMapRealWorld();
  //@ADD
  depthMap = depthMapRealWorld();
  
  //@ADD for flipping
  // ---------------------------------
  for (h = 0; h < kinect.depthHeight; h++)
  {
    for (r = 0; r < kinect.depthWidth / 2; r++)
    {
      temp = depthMap[h*kinect.depthWidth + r];
      depthMap[h*kinect.depthWidth + r] = depthMap[h*kinect.depthWidth + (kinect.depthWidth - r - 1)];
      depthMap[h*kinect.depthWidth + (kinect.depthWidth - r - 1)] = temp;
    }
  }
  // ---------------------------------

  //@REMOVE opencv.loadImage(kinect.rgbImage());
  //@ADD
  src = kinect.getRegisteredImage();
  
  //@ADD for image flip
  // ---------------------------------
  for (h = 0; h < src.height; h++)
  {
    for (r = 0; r < src.width / 2; r++)
    {
      temp2 = src.get(r, h);   //h*src.width + r);
      src.set(r, h, src.get(src.width - r - 1, h));
      src.set(src.width - r - 1, h, temp2);
    }
  }
  // ---------------------------------

  opencv.loadImage(src);
  //opencv.loadImage(kinect.irImage());
  opencv.gray();

  if (isSearchingBoard)
    foundPoints = opencv.findChessboardCorners(4, 3);

  drawGui();
}

void drawGui() 
{
  background(0, 100, 0);

  // draw the RGB image
  pushMatrix();
  translate(30, 120);
  textSize(22);
  fill(255);
  //image(kinect.irImage(), 0, 0);
  //@REMOVE image(kinect.rgbImage(), 0, 0);
  //@ADD
  image(src, 0, 0);
  
  // draw chessboard corners, if found
  if (isSearchingBoard) {
    int numFoundPoints = 0;
    for (PVector p : foundPoints) {
      if (getDepthMapAt((int)p.x, (int)p.y).z > 0) {
        fill(0, 255, 0);
        numFoundPoints += 1;
      }
      else  fill(255, 0, 0);
      ellipse(p.x, p.y, 5, 5);
    }
    if (numFoundPoints == 12)  guiAdd.show();
    else                       guiAdd.hide();
  }
  else  guiAdd.hide();
  if (calibrated && testingMode) {
    fill(255, 0, 0);
    ellipse(testPoint.x, testPoint.y, 10, 10);
  }
  popMatrix();

  // draw GUI
  pushMatrix();
  pushStyle();
  //@REMOVE translate(kinect.depthWidth()+70, 40); // this is black box
  //@ADD
  translate(kinect.depthWidth+70, 40); // this is black box
  fill(0);
  rect(0, 0, 450, 680); // blackbox size
  fill(255);
  text(ptsP.size()+" pairs", 26, guiPos.y+525);
  popStyle();
  popMatrix();
}

ArrayList<PVector> drawChessboard(int x0, int y0, int cwidth) {
  ArrayList<PVector> projPoints = new ArrayList<PVector>();
  /*@REMOVE
  int cheight = (int)(cwidth * 0.8);
  ca.background(255);
  ca.fill(0);
  for (int j=0; j<4; j++) {
    for (int i=0; i<5; i++) {
      int x = int(x0 + map(i, 0, 5, 0, cwidth));
      int y = int(y0 + map(j, 0, 4, 0, cheight));
      if (i>0 && j>0)  projPoints.add(new PVector((float)x/pWidth, (float)y/pHeight));
      if ((i+j)%2==0)  ca.rect(x, y, cwidth/5, cheight/4);
    }
  }  
  ca.fill(0, 255, 0);
  if (calibrated)  
    ca.ellipse(testPointP.x, testPointP.y, 20, 20);  
  */
  
  ca.redraw();
  return projPoints;
}


void addPointPair() {
  if (projPoints.size() == foundPoints.size()) {
    println(getDepthMapAt((int) foundPoints.get(1).x, (int) foundPoints.get(1).y));
    for (int i=0; i<projPoints.size(); i++) {
      ptsP.add( projPoints.get(i) );
      ptsK.add( getDepthMapAt((int) foundPoints.get(i).x, (int) foundPoints.get(i).y) );
      //println(getDepthMapAt((int) foundPoints.get(i).x, (int) foundPoints.get(i).y));
      if ((getDepthMapAt((int) foundPoints.get(i).x, (int) foundPoints.get(i).y)).z == 0)
      {
        println("ARRRRRRRRRRRRRRRRRRRRRRRG");
      }
    }
  }
  guiCalibrate.show();
  guiClear.show();
}

PVector getDepthMapAt(int x, int y) {
  //@REMOVE PVector dm = depthMap[kinect.depthWidth() * y + x];
  //@ADD
  PVector dm = depthMap[kinect.depthWidth * y + x];
  
  return new PVector(dm.x, dm.y, dm.z);
}

void clearPoints() {
  ptsP.clear();
  ptsK.clear();
  guiSave.hide();
}

void saveC() {
  saveCalibration(calibFilename); 
}

void loadC() {
  println("load");
  loadCalibration(calibFilename);
  guiTesting.addItem("Testing Mode", 1);
}

void mousePressed() {
  if (calibrated && testingMode) {
    /*@REMOVE
    testPoint = new PVector(constrain(mouseX-30, 0, kinect.depthWidth()-1), 
                            constrain(mouseY-120, 0, kinect.depthHeight()-1));
    */
    //@ADD
    testPoint = new PVector(constrain(mouseX-30, 0, kinect.depthWidth-1), 
                            constrain(mouseY-120, 0, kinect.depthHeight-1));
    //@REMOVE int idx = kinect.depthWidth() * (int) testPoint.y + (int) testPoint.x;
    //@ADD
    int idx = kinect.depthWidth * (int) testPoint.y + (int) testPoint.x;
    
    testPointP = convertKinectToProjector(depthMap[idx]);
  }
}


//@ADD ALL BELOW
PVector[] depthMapRealWorld()
{
  int[] depth = kinect.getRawDepth();
  int skip = 1;
  for (int y = 0; y < kinect.depthHeight; y+=skip) {
    for (int x = 0; x < kinect.depthWidth; x+=skip) {
        int offset = x + y * kinect.depthWidth;
        //calculate the x, y, z camera position based on the depth information
        PVector point = depthToPointCloudPos(x, y, depth[offset]);
        depthMap[kinect.depthWidth * y + x] = point;
      }
    }
    return depthMap;
}

//calculte the xyz camera position based on the depth data
PVector depthToPointCloudPos(int x, int y, float depthValue) {
  PVector point = new PVector();
  point.z = (depthValue);// / (1.0f); // Convert from mm to meters
  point.x = ((x - CameraParams.cx) * point.z / CameraParams.fx);
  point.y = ((y - CameraParams.cy) * point.z / CameraParams.fy);
  return point;
}

//camera information based on the Kinect v2 hardware
static class CameraParams {
  static float cx = 254.878f;
  static float cy = 205.395f;
  static float fx = 365.456f;
  static float fy = 365.456f;
  static float k1 = 0.0905474;
  static float k2 = -0.26819;
  static float k3 = 0.0950862;
  static float p1 = 0.0;
  static float p2 = 0.0;
}