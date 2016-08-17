public class ChessboardFrame extends JFrame {
  public ChessboardFrame() {
    //@REMOVE setBounds(displayWidth,0,pWidth,pHeight);
    ca = new ChessboardApplet();
    //@ADD
    String[] args = {"Chessboard"};
    PApplet.runSketch(args,ca);
    
    //@REMOVE add(ca);
    removeNotify(); 
    setUndecorated(true); 
    setAlwaysOnTop(false); 
    setResizable(false);  
    addNotify();     
    //@REMOVE ca.init();
    show();
  }
}

public class ChessboardApplet extends PApplet {
  public void setup() {
    noLoop();
  }
  //@ADD START
  public void settings() {
    //size(pWidth, pHeight);
    fullScreen(2);
  }
  public void draw() {
    int cheight = (int)(cwidth * 0.8);
    background(255);
    fill(0);
    for (int j=0; j<4; j++) {
      for (int i=0; i<5; i++) {
        /*@REMOVE
        int x = int(x0 + map(i, 0, 5, 0, cwidth));
        int y = int(y0 + map(j, 0, 4, 0, cheight));
        */
        //@ADD
        int x = int(cx + map(i, 0, 5, 0, cwidth));
        int y = int(cy + map(j, 0, 4, 0, cheight));
        
        if (i>0 && j>0)  projPoints.add(new PVector((float)x/pWidth, (float)y/pHeight));
        if ((i+j)%2==0)  rect(x, y, cwidth/5, cheight/4);
      }
    }  
    fill(0, 255, 0);
    if (calibrated)  
      ellipse(testPointP.x, testPointP.y, 20, 20);  
  }
  //@ADD END
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
