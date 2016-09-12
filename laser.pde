void setup() {
  size(800, 600, OPENGL);
  
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
 // jmyron.update(); //update the camera view
/*
  int brightestX = 0; // X-coordinate of the brightest video pixel
  int brightestY = 0; // Y-coordinate of the brightest video pixel

  int[][] blobs = jmyron.globCenters();//get the center points

  if(blobs.length > 1){
    // Draw a large, yellow circle at the brightest pixel
    pointer_is_visible = true;
    
    brightestX = blobs[1][0];
    brightestY = blobs[1][1];
        
    laser_coordinates[0] = brightestX;
    laser_coordinates[1] = brightestY;
    pointer_camera_coordinates[0] = brightestX;
    pointer_camera_coordinates[1] = brightestY;
 
    //if the brightest spot is inside the beamer area
    int[] xpoints = new int[4];
    int[] ypoints = new int[4];
    for(int i=0; i<4; i++){
      xpoints[i] = coordinates_projector[i][0];
      ypoints[i] = coordinates_projector[i][1];
    }
    Polygon beamer_area = new Polygon(xpoints, ypoints, 4); //refactor me to use a polygon all the way

    if(beamer_area.contains(brightestX, brightestY)){
      if (pointer_on_screen == true){
        pointer_old[0] = pointer[0];
        pointer_old[1] = pointer[1];
        pointer_is_moving = true;
      }
      else{
        pointer_is_moving = false;
      }
      pointer_on_screen = true;


      //transform camera coordinates to beamer (screen) coordinates
      
      //coordinates_projector contains the calibrated area of the beamer 
      Point2D.Double a = new Point2D.Double((double)coordinates_projector[0][0], (double)coordinates_projector[0][1]);
      Point2D.Double b = new Point2D.Double((double)coordinates_projector[1][0], (double)coordinates_projector[1][1]);
      Point2D.Double c = new Point2D.Double((double)coordinates_projector[2][0], (double)coordinates_projector[2][1]);
      Point2D.Double d = new Point2D.Double((double)coordinates_projector[3][0], (double)coordinates_projector[3][1]);

      Line2D.Double a_b = new Line2D.Double(a, b);
      Line2D.Double d_c = new Line2D.Double(d, c);
      Line2D.Double d_a = new Line2D.Double(d, a);
      Line2D.Double c_b = new Line2D.Double(c, b);
      
      double l_a_b = line_length(a_b);
      double l_d_a = line_length(d_a);

      Point2D.Double flucht_y = new Point2D.Double();
      Point2D.Double flucht_x = new Point2D.Double();
      getLineLineIntersection(a_b, d_c, flucht_x);
      getLineLineIntersection(d_a, c_b, flucht_y);
      
      Point2D.Double pointer_on_webcam = new Point2D.Double((double)brightestX, (double)brightestY);
      
      Line2D.Double x_p = new Line2D.Double(flucht_x, pointer_on_webcam);
      Line2D.Double y_p = new Line2D.Double(flucht_y, pointer_on_webcam);
      
      Point2D.Double y_on_A = new Point2D.Double();
      Point2D.Double x_on_B = new Point2D.Double();

      getLineLineIntersection(x_p, d_a, y_on_A);
      getLineLineIntersection(y_p, a_b, x_on_B);
      
      double l_a_y_on_A = line_length(new Line2D.Double(a, y_on_A));
      double l_a_x_on_B = line_length(new Line2D.Double(a, x_on_B));
      
      intersection = y_on_A;

      //x coordinate between 0 and 1
      double the_y =  l_a_y_on_A / l_d_a;
      double the_x = l_a_x_on_B / l_a_b;

      pointer[0] = (int)(the_x * width);
      pointer[1] = (int)(the_y * height);      
    }
    else {
      pointer_on_screen = false;
    }
  }
  else{
    pointer_is_visible = false;
    pointer_on_screen = false;
  } */
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

  }
  else{
    pointer_is_visible = false;
    pointer_on_screen = false;
  }
}