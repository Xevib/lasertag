  int rangeLow = 20;
  int rangeHigh = 35;
void setup() {
  size(1600, 600, OPENGL);
  
//  jmyron = new JMyron();//make a new instance of the object

//  jmyron.start(cam_width, cam_height);//start a capture at 320x240
//  jmyron.trackColor(0,255,0,color_threshold); //R, G, B, and range of similarity

//  jmyron.minDensity(15); //minimum pixels in the glob required to result in a box
  video = new Capture(this, cam_width,cam_height);
  video.start();
  
  opencv = new OpenCV(this, video.width, video.height);
  
  cam_image = new PImage(cam_width, cam_height);
  
  a_quad[0] = new Point2D.Float(0.0,0.0);
  a_quad[1] = new Point2D.Float(1.0,0.0);
  a_quad[2] = new Point2D.Float(1.0,1.0);
  a_quad[3] = new Point2D.Float(0.0,1.0);
    
  //top left
  coordinates_projector[0][0] = 50;
  coordinates_projector[0][1] = 10;
  //top right
  coordinates_projector[1][0] = cam_width-50;
  coordinates_projector[1][1] = 65;
  //bottom left
  coordinates_projector[2][0] = cam_width-30;
  coordinates_projector[2][1] = cam_height-40;
  //bottom right
  coordinates_projector[3][0] = 5;
  coordinates_projector[3][1] = cam_height-15;
  
  pointer_on_screen = false;
  pointer_is_moving = false;
  
//  PFont f = loadFont("Univers66.vlw.gz");
//  textFont(f, 16);
    
  calibration_point = 4;
  cleararea_calibration_point = 4;

  drips_position = -1;
  current_color = 0;
  change_color(colors[0]);
}


void update_laser_position(){
  if(pointer_on_screen){
    if(pointer_is_moving){
      ((DripsScreen)drips.get(drips_position)).lineTo(pointer[0], pointer[1]);
    }
    else{
      ((DripsScreen)drips.get(drips_position)).moveTo(pointer[0], pointer[1]);
    }
  }
}

void track_laser(){
//jmyron.update();

  opencv.loadImage(video);
  opencv.useColor();
  src = opencv.getSnapshot();
  opencv.useColor(HSB);
  opencv.setGray(opencv.getH().clone());
  opencv.inRange(rangeLow, rangeHigh);
  colorFilteredImage = opencv.getSnapshot();
  contours = opencv.findContours(true, true);
  image(src, 0, 0);
  image(colorFilteredImage, src.width, 0);
  
  
  int brightestX = 0; // X-coordinate of the brightest video pixel
  int brightestY = 0; // Y-coordinate of the brightest video pixel
  
  if(mousePressed && (mouseButton == RIGHT)){
    color c = get(mouseX, mouseY);
    println("r: " + red(c) + " g: " + green(c) + " b: " + blue(c));
   
    int hue = int(map(hue(c), 0, 255, 0, 180));
    println("hue to detect: " + hue);
  
    rangeLow = hue - 5;
    rangeHigh = hue + 5;
    is_color_set = true;
  }
  if(is_color_set){   
    
    brightestX = mouseX;
    brightestY = mouseY;
        
    laser_coordinates[0] = mouseX;
    laser_coordinates[1] = mouseX;
    pointer_camera_coordinates[0] = mouseX;
    pointer_camera_coordinates[1] = mouseX;
    //if (contours.size() > 0) {
        // <9> Get the first contour, which will be the largest one
        Contour biggestContour = contours.get(0);
        
        // <10> Find the bounding box of the largest contour,
        //      and hence our object.
        Rectangle r = biggestContour.getBoundingBox();
        
        // <11> Draw the bounding box of our object
        noFill(); 
        strokeWeight(2); 
        stroke(255, 0, 0);
        rect(r.x, r.y, r.width, r.height);
        
        // <12> Draw a dot in the middle of the bounding box, on the object.
        noStroke(); 
        fill(255, 0, 0);
        ellipse(r.x + r.width/2, r.y + r.height/2, 30, 30);
    //}


    if (pointer_on_screen == true){
      pointer_old[0] = pointer[0];
      pointer_old[1] = pointer[1];
      pointer_is_moving = true;
    }
    else{
      pointer_is_moving = false;
    }
    pointer_on_screen = true;
    pointer[0] = r.x + r.width/2;
    pointer[1] = r.y + r.height/2;
    //pointer[0] = (int)(mouseX);
    //pointer[1] = (int)(mouseY);      

  }
  else{
    pointer_is_visible = false;
    pointer_on_screen = false;
  }
}

void track_mouse_as_laser(){
  //jmyron.update();
  int brightestX = 0; // X-coordinate of the brightest video pixel
  int brightestY = 0; // Y-coordinate of the brightest video pixel

  if(mousePressed && (mouseButton == LEFT)){   
    
    brightestX = mouseX;
    brightestY = mouseY;
        
    laser_coordinates[0] = mouseX;
    laser_coordinates[1] = mouseX;
    pointer_camera_coordinates[0] = mouseX;
    pointer_camera_coordinates[1] = mouseX;

    if (pointer_on_screen == true){
      pointer_old[0] = pointer[0];
      pointer_old[1] = pointer[1];
      pointer_is_moving = true;
    }
    else{
      pointer_is_moving = false;
    }
    pointer_on_screen = true;

    pointer[0] = (int)(mouseX);
    pointer[1] = (int)(mouseY);      
    is_color_set = true;
  }
  else{
    pointer_is_visible = false;
    pointer_on_screen = false;
  }
}