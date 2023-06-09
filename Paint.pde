import processing.serial.*;
Serial myPort;
static byte[] sendDataStatus = new byte[1];
final byte REQUEST_DATA = 1;
final byte REQUEST_CONNECT = 2;

PShape BORDER;
PShape TOOLBAR;
PShape RIGHTPANEL;
// khong the de cac PShape nay la static va tao cac phuong thuc static (goi ham shape()) o day de goi o class khac, vay phai lam sao de chay trong inteliJ

static int check = 0;
int canvasStepGather = 3;
int realStepGather = 25;

static float canvasToRealRatio = 0.07;

public static int mode = 0;
public static int modeWaiting = 0;
public static int modeSelected = 1;
public static int modeRNM = 2; // mode resize and move
public static int modeResizeLeft = 3;
public static int modeResizeDown = 4;
public static int modeResizeDownLeft = 5;
public static int modeMove = 6;
public static int modePencil = 20;
public static int modeSending = 21;

public static int xInit = 0;
public static int yInit = 0;

public static int xClick = 0;
public static int yClick = 0;

static boolean init_bluetooth = true;

Canvas canvas = new Canvas(this);

ArrayList<Shape> shape = new ArrayList<>();
static Shape tempShape; // can't create an instance of an abstract class

ArrayList<Pencil> pencil = new ArrayList<>();
Pencil tempPencil = new Pencil(this);

Fuction f = new Fuction(5000, 6000, -2000, 2000);

//whether tempShape is inside working area
public boolean insideWorkingArea() {
    if(canvas.xWorkingAreaStart < mouseX + tempShape.getWidth()/2.0
            && mouseX - tempShape.getHeight()/2.0 < canvas.xWorkingAreaEnd) {
        return canvas.yWorkingAreaStart < mouseY + tempShape.getHeight() / 2.0
                && mouseY - tempShape.getHeight() / 2.0 < canvas.yWorkingAreaEnd;
    }
    return false;
}

public void checkMode() {
    // dua doan code nay vao file Canvas

    int temp = mode;
    mode = Paint.modeSelected;
    if(canvas.rectangle.isInsideButton()) {
        canvas.rectangle.buttonActive();
        tempShape = new Rectangle(this);
    } else if(canvas.ring.isInsideButton()) {        
        canvas.ring.buttonActive();
        tempShape = new Ring(this);
    } else if(canvas.pencil.isInsideButton()) {
        canvas.pencil.buttonActive();
        canvas.pencil.setMode();
    } else if(canvas.sendPoint.isInsideButton()) {
        canvas.sendPoint.buttonActive();
        canvas.sendPoint.setMode();  
    } else {
        mode = temp;
    }
}

public void mouseClicked() {
    if(mode == Paint.modeWaiting) {
        checkMode();
    } else if(mode == Paint.modeSelected) {
        // ousite of working area
        if(mouseX > 1095 | mouseY < 105) {
            checkMode();
        } else {
            tempShape.setX0(mouseX);
            tempShape.setY0(mouseY);
            xInit = tempShape.getXInit();
            yInit = tempShape.getYInit();
            mode = Paint.modeRNM;
        }
    } else if(mode == Paint.modeRNM) {
        if(tempShape.isInLeftBorder()) {
            mode = Paint.modeResizeLeft;
        } else if(tempShape.isInDownBorder()) {
            mode = Paint.modeResizeDown;
        } else if (tempShape.isInDownRightCorner()) {
            mode = Paint.modeResizeDownLeft;
        } else if (tempShape.isInside()) {
            mode = Paint.modeMove;
        } else {
            shape.add(tempShape.copy());
            tempShape.refresh();
            mode = Paint.modeSelected;
        }
    } else if(mode <= Paint.modeMove) {
        mode = Paint.modeRNM;
    } else if(mode == Paint.modePencil) {
        if(mouseX > 1095 | mouseY < 105) {
              checkMode();
          }
    } else if(mode == Paint.modeSending) {
        noLoop();
        SendPoint send_point = new SendPoint();
        if(pencil.size() > 0) {
            Pencil p = pencil.get(0);
            send_point.setRealPointList(p.getRealPointList());
            ArrayList<Point> check = send_point.getRealPointList();
            for (Point k: check) {
                println(k);
            }
            send_point.sendData();
        }
        loop();
    }
}

public void mouseDragged() {
    if(mode == Paint.modePencil) {
        tempPencil.addPoint(new Point(mouseX, mouseY));
        tempPencil.show();
    }
}

public void mouseReleased() {
    if(mode == Paint.modePencil) {
        int temp = tempPencil.getPointList().size();
        if (temp > 1) {
            pencil.add(tempPencil.copy());
        }
        if(temp > 0) {
            tempPencil.getPointList().clear();
        }
    }
}

void serialEvent(Serial myPort){ 
  sendDataStatus = myPort.readBytes(1);
  println("received data " + sendDataStatus[0]);
  //if(sendDataStatus[0] == REQUEST_CONNECT) {
  //  myPort.write(REQUEST_CONNECT);
  //}
}

public void settings() {
    size(1920, 1000);
}

public void setup() {
    //myPort = new Serial(this, "COM10", 115200);
    sendDataStatus[0] = 0;
    strokeWeight(1);
    surface.setLocation(0, 0);
    rectMode(CENTER);
    BORDER = loadShape("./svg/Border.svg");
    TOOLBAR = loadShape("./svg/Toolbar.svg");
    RIGHTPANEL = loadShape("./svg/RightPanel.svg");
}

public void draw() {
    canvas.workingAreaInit();

    for(Shape s: shape) {
        s.show();
    }

    for(Pencil p: pencil) {
        p.show();
        
    }
    if(check == 0) {
      f.show();
      //check++;
    }
    
    canvas.canvasRefine();
    
    if(mode == Paint.modeSelected) {
        // if part of shape inside working area
        if(mouseX < 1095 && mouseY > 105) {
            tempShape.setX0(mouseX);
            tempShape.setY0(mouseY);
            tempShape.show();
        }
    } else if (mode == Paint.modeRNM) {
        tempShape.init();
        if(tempShape.isInLeftBorder()) {
            cursor(CROSS);
        } else if(tempShape.isInDownBorder()) {
            cursor(CROSS);
        } else if (tempShape.isInDownRightCorner()) {
            cursor(MOVE);
        } else {
            cursor(ARROW);
        }
    } else if (mode == Paint.modeResizeLeft) {
        //right
        if(mouseX > xInit) {
            tempShape.setX0((int)((mouseX + xInit)/2)); // (int) is redundant because int/int return int
            tempShape.setWidth(mouseX - xInit);
        }
        tempShape.init();
    } else if(mode == Paint.modeResizeDown) {
        //down
        if(mouseY > yInit) {
            tempShape.setY0((int)((mouseY + yInit)/2));
            tempShape.setHeight(mouseY - yInit);
        }
        tempShape.init();
    } else if(mode == Paint.modeResizeDownLeft) {
        //rightdown corner
        if(mouseX > xInit && mouseY > yInit) {
            tempShape.setX0((int)((mouseX + xInit)/2));
            tempShape.setWidth(mouseX - xInit);
            tempShape.setY0((int)((mouseY + yInit)/2));
            tempShape.setHeight(mouseY - yInit);
        }
        tempShape.init();
    } else if(mode == Paint.modeMove) {
        //inner shape
        if(insideWorkingArea()) {
            tempShape.setX0(mouseX);
            tempShape.setY0(mouseY);
        }
        tempShape.init();
    } else {}

}
