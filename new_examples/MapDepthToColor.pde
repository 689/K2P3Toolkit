/*
Based on the work of Thomas Sanchez Lengeling, sort of.
Color to depth
*/
int pWidth = 800;
int pHeight = 600; 

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
  size(pWidth, pHeight);

  kinect = new KinectPV2(this);
  kpc = new KinectProjectorToolkit(this, KinectPV2.WIDTHDepth, KinectPV2.HEIGHTDepth);
  kpc.loadCalibration("calibration.txt");
  
  kinect.enableDepthImg(true);
  kinect.enableColorImg(true);
  kinect.enablePointCloud(true);
  kinect.activateRawDepth(true);

  kinect.init();
  
  depthMap = new PVector[KinectPV2.WIDTHDepth*KinectPV2.HEIGHTDepth];
  
}

void draw() {
  background(0);
  maxDepth = max(max(kinect.getRawDepthData()), 50);
  print(maxDepth);
  colorMode(HSB, maxDepth, 100, 100);
  
  depthMap = getRealWorldTest();
  kpc.setDepthMapRealWorld(depthMap);

  for (int i = 0; i < KinectPV2.WIDTHDepth; i++) {
    for (int j = 0; j < KinectPV2.HEIGHTDepth; j++) {
      PVector realWorldPoint = depthMap[KinectPV2.WIDTHDepth * i + j];  //fxn
 
      PVector projectorPoint = kpc.convertKinectToProjector(realWorldPoint);
      fill(realWorldPoint.z, 100, 100);
      ellipse(projectorPoint.x, projectorPoint.y, 10, 10);
    }
  }
  text("fps: "+frameRate, 50, 50);
}


PVector[] getRealWorldTest()
{
  PVector[] protoDepthMap = new PVector[KinectPV2.WIDTHDepth*KinectPV2.HEIGHTDepth];
  int[] depth = kinect.getRawDepthData();
  for (int y = 0; y < KinectPV2.HEIGHTDepth; y++) {
      for (int x = 0; x < KinectPV2.WIDTHDepth; x++) {
        int offset = x + y * KinectPV2.WIDTHDepth;
        PVector point = depthToPointCloudPos(x, y, depth[offset]);
        protoDepthMap[offset] = point;
      }
    }
    return protoDepthMap;
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