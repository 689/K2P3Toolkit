int x0_util;
int y0_util;
int cwidth_util;
boolean calibrated_util;
PVector testPointP_util;

public class ChessboardFrame extends JFrame {
  public ChessboardFrame() {
    setBounds(displayWidth,0,pWidth,pHeight);
    ca = new ChessboardApplet();
    //add(ca);
    String[] args = {"Chessboard"};
    PApplet.runSketch(args,ca);
    
    removeNotify(); 
    setUndecorated(true); 
    setAlwaysOnTop(false); 
    setResizable(false);  
    addNotify();     
    //ca.init();
    show();
  }
}

public class ChessboardApplet extends PApplet {
  public void setup() {
    noLoop();
  }
  public void settings() {
    size(pWidth, pHeight);
  }
  public void draw() {
    int cheight = (int)(cwidth * 0.8);
    background(50, 100, 20);
    fill(0);
    for (int j=0; j<4; j++) {
      for (int i=0; i<5; i++) {
        int x = int(x0_util + map(i, 0, 5, 0, cwidth_util));
        int y = int(y0_util + map(j, 0, 4, 0, cheight));
        if (i>0 && j>0)  projPoints.add(new PVector((float)x/pWidth, (float)y/pHeight));
        if ((i+j)%2==0)  ca.rect(x, y, cwidth/5, cheight/4);
      }
    }  
    fill(255);
    if (calibrated_util)  
      ellipse(testPointP_util.x, testPointP_util.y, 20, 20);
  }
  public void chess(int x0, int y0, int cwidth, boolean calibrated, PVector testPointP) {
    x0_util = x0;
    y0_util = y0;
    cwidth_util = cwidth;
    calibrated_util = calibrated;
    testPointP_util = testPointP;
  }
}

void saveCalibration(String filename) {
  String[] coeffs = getCalibrationString();
  saveStrings(dataPath(filename), coeffs);
}

void loadCalibration(String filename) {
  String[] s = loadStrings(dataPath(filename));
  x = new Jama.Matrix(11, 1);
  for (int i=0; i<s.length; i++)
    x.set(i, 0, Float.parseFloat(s[i]));
  calibrated = true;
  println("done loading");
}