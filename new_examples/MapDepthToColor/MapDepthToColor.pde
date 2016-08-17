/*
Based on the work of Thomas Sanchez Lengeling, sort of.
Color to depth
*/
import KinectPV2.*;
import KinectProjectorToolkit.*;


KinectPV2 kinect;
KinectProjectorToolkit kpc;
PVector[] depthMap;
int [] depthZero;
int cx, cy, cwidth;
int maxDepth;

//BUFFER ARRAY TO CLEAN DE PIXLES
PImage depthToColorImg;

void setup() {
  fullScreen(P2D, 2);
  //size(1920, 1080, P2D);

  kinect = new KinectPV2(this);
  kpc = new KinectProjectorToolkit(this, KinectPV2.WIDTHDepth, KinectPV2.HEIGHTDepth);
  kpc.loadCalibration("calibration.txt");
  
  kinect.enableDepthImg(true);
  kinect.enableColorImg(true);
  kinect.enablePointCloud(true);

  kinect.init();
  
  depthMap = new PVector[KinectPV2.WIDTHDepth*KinectPV2.HEIGHTDepth];
  //loadCalibration("calibration.txt");
}

void draw() {
  //frame.setLocation(0,0);
  background(0);
  int[] rawDepth = kinect.getRawDepthData();
  //println(rawDepth);
  maxDepth = max(rawDepth);
//  println("max: ", maxDepth);
//  println("min: ", min(rawDepth));
  colorMode(HSB, 3000, 100, 100);
  //colorMode(HSB, 10000, 100, 100);
  depthMap = depthMapRealWorld();
  kpc.setDepthMapRealWorld(depthMap);

  for (int y = 0; y < KinectPV2.HEIGHTDepth; y++) {
    for (int x = 0; x < KinectPV2.WIDTHDepth; x++) {
      int offset = x + y * KinectPV2.WIDTHDepth;
      PVector realWorldPoint = depthMap[offset];  //fxn
 
      PVector projectorPoint = kpc.convertKinectToProjector(realWorldPoint);      //used to be kpc.
      noStroke();
      
      if ((realWorldPoint.z < 2000) && (realWorldPoint.z > 1000))
      {
        fill(realWorldPoint.z, 100, 100);   // fixme, z is all the same, y looks similar.... x kind of works?
        //println(projectorPoint);
        ellipse(projectorPoint.x, projectorPoint.y, 5, 5);
      }
    }
  }
  //text("fps: "+frameRate, 50, 50);
}


//@ADD ALL BELOW
PVector[] depthMapRealWorld()
{
  int[] depth = kinect.getRawDepthData();
  int skip = 1;
  for (int y = 0; y < kinect.HEIGHTDepth; y+=skip) {
    for (int x = 0; x < kinect.WIDTHDepth; x+=skip) {
        int offset = x + y * kinect.WIDTHDepth;
        //calculate the x, y, z camera position based on the depth information
        PVector point = depthToPointCloudPos(x, y, depth[offset]);
        depthMap[kinect.WIDTHDepth * y + x] = point;
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