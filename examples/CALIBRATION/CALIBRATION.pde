//==========================================================
// set resolution of your projector image/second monitor
// and name of your calibration file-to-be
int pWidth = 1920;
int pHeight = 1080; 
String calibFilename = "calibration.txt";


//==========================================================
// Nash adds
//import java.nio.*;
import org.openkinect.freenect.*;
import org.openkinect.freenect2.*;
import org.openkinect.processing.*;
//==========================================================

import javax.swing.JFrame;
//import SimpleOpenNI.*;
import gab.opencv.*;
import controlP5.*;
import Jama.*;

Kinect2 kinect;        // used to be SimpleOpenNI
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

float guiScaler = 0.9;
float picScaler = 0.4;
//int screenWidth = 1366;
//int screenHeight = 768;
int guiWidth;
int guiHeight;
int picWidth;
int picHeight;

PImage src;

void setup() 
{
  guiHeight = int(displayHeight*guiScaler);
  guiWidth = int(displayWidth*guiScaler);
  picWidth = int(displayWidth*picScaler);
  picHeight = int(displayHeight*picScaler);
  surface.setSize(guiWidth, guiHeight);  
  textFont(createFont("Courier", 24));
  frameBoard = new ChessboardFrame(); 
  

  // set up kinect
  kinect = new Kinect2(this);
  //kinect.setMirror(false);    fixme, this doesn't exist
  kinect.initDepth();                     // used to be enableDepth
  //kinect.initIR();  //add so we can get depth??
  kinect.initVideo();                      //used to be enableRGB, is this right?
  kinect.initRegistered(); // used to be alternativeViewPointDepthToImage();  //fixme IMPORTANT
  
  
/* Load a test chessboard in
  src = loadImage("test18.jpg");
  opencv = new OpenCV(this, src); //kinect.depthWidth, kinect.depthHeight);    //depthwWidth and height used to be functions
*/
  src = kinect.getVideoImage();
  opencv = new OpenCV(this, src);//kinect.depthWidth, kinect.depthHeight); //kinect.depthWidth(), kinect.depthHeight());
  
  
  
// test again
  depthMap = new PVector[kinect.depthWidth*kinect.depthHeight]; //fixme jank fix
  // matching pairs
  ptsK = new ArrayList<PVector>();
  ptsP = new ArrayList<PVector>();
  testPoint = new PVector();
  testPointP = new PVector();
  kinect.initDevice();
  setupGui();
}

void draw() 
{
  // draw chessboard onto scene
  projPoints = drawChessboard(cx, cy, cwidth);

  // update kinect and look for chessboard
  // kinect.update();                            // not needed
  
  //depthMap = //kinect.depthMapRealWorld(); //fixme, is this right? Imporantt
  depthMap = getRealWorldTest();   // updates depthMap 

// not need if using static image

  src = kinect.getVideoImage();
  opencv.loadImage(src); //rgbImage());
  //opencv.loadImage(kinect.irImage());
  opencv.gray();

  if (isSearchingBoard)
    foundPoints = opencv.findChessboardCorners(4, 3);
 //print(foundPoints);
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
  image(src, 0, 0, picWidth, picHeight);      //used to be.rgbImage(). We resize chessboard here!
  
  // draw chessboard corners, if found
  if (isSearchingBoard) {
    int numFoundPoints = 0;
    for (PVector p : foundPoints) {
      if (getDepthMapAt((int)(p.x/src.width*picWidth), (int)(p.y/src.height*picHeight)).z > 0) {//(int)p.x, (int)p.y).z > 0) {
        fill(0, 255, 0);
        numFoundPoints += 1;
      }
      else  fill(255, 0, 0);
      //ellipse(p.x/src.width*picWidth, p.y/src.height*picHeight, 5, 5); 
      ellipse(p.x/src.width*picWidth, p.y/src.height*picHeight, 5, 5);  // need to figure out right size for this...
      //println(p.x/src.width*);
      //println(src.width);
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
  translate(kinect.depthWidth + 250, 20);    //this is black box
  fill(0);
  rect(0, 0, 450, 680); // blackbox size
  fill(255);
  text(ptsP.size()+" pairs", 26, guiPos.y+525);
  popStyle();
  popMatrix();
}

//fixme add in once calibrating

ArrayList<PVector> drawChessboard(int x0, int y0, int cwidth) {
  ArrayList<PVector> projPoints = new ArrayList<PVector>();
  
  ca.chess(x0, y0, cwidth, calibrated, testPointP);
  ca.redraw();
  
  return projPoints;
}


void addPointPair() {
  if (projPoints.size() == foundPoints.size()) {
    for (int i=0; i<projPoints.size(); i++) {
      ptsP.add( projPoints.get(i) );
      ptsK.add( getDepthMapAt((int) (foundPoints.get(i).x /src.width*picWidth), (int) (foundPoints.get(i).y /src.height*picHeight )) );        // p.x/src.width*picWidth
    }
  }
  guiCalibrate.show();
  guiClear.show();
}

PVector getDepthMapAt(int x, int y) {
//  println(x, "   ", y);
//  println(kinect.depthWidth * y + x);
//  println(depthMap.length);
  PVector dm = depthMap[kinect.depthWidth * y + x];  //fxn
  
  // max is at kinect.depthHeight so much null
  //println("xyz: ", dm.x, "  ", dm.y, "   ", dm.z);
  PVector result = new PVector(dm.x, dm.y, dm.z);
  return result;
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
    testPoint = new PVector(constrain(mouseX-30, 0, kinect.depthWidth-1), 
                            constrain(mouseY-120, 0, kinect.depthHeight-1));
    int idx = kinect.depthWidth * (int) testPoint.y + (int) testPoint.x;    //functions
    testPointP = convertKinectToProjector(depthMap[idx]);
  }
}

PVector[] getRealWorldTest()
{
  int[] depth = kinect.getRawDepth();
  int skip = 1;
  for (int x = 0; x < kinect.depthWidth; x+=skip) {
      for (int y = 0; y < kinect.depthHeight; y+=skip) {
        int offset = x + y * kinect.depthWidth;
        //calculte the x, y, z camera position based on the depth information
        PVector point = depthToPointCloudPos(x, y, depth[offset]);
        depthMap[kinect.depthWidth * y + x] = point;
//        println("depthmap: ", kinect.depthWidth * y + x);
      }
    }
    return depthMap;
}

//calculte the xyz camera position based on the depth data
PVector depthToPointCloudPos(int x, int y, float depthValue) {
  PVector point = new PVector();
  point.z = (depthValue);// / (1.0f); // Convert from mm to meters
  point.x = (x - CameraParams.cx) * point.z / CameraParams.fx;
  point.y = (y - CameraParams.cy) * point.z / CameraParams.fy;
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