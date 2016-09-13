/**
 * Laser Marker 2.0
 * Graffiti Research Lab Vienna // Florian Hufsky & Michael Zeltner
 * them@graffitiresearchlab.at
 * http://graffitiresearchlab.at/
 *
 * Java is a pile of crap. Don't use it.
 */

import processing.video.*;
import processing.opengl.*;
import java.awt.geom.*;
import java.awt.Polygon;
//import javax.vecmath.Vector2f;
//import JMyron.*;
import java.util.Iterator;
import gab.opencv.*;
import java.awt.Rectangle;

int color_threshold = 200;
int brush_width = 16-2;
int drip_width = brush_width/3;
int drips_probability = 15;
int zcall = -50;

//JMyron jmyron;
Capture video;
OpenCV opencv;
ArrayList<Contour> contours;
PImage src, colorFilteredImage;

PImage cam_image;
int cam_width = 640;
int cam_height = 480;

int[][] coordinates_projector = new int[4][2];
int[][] coordinates_cleararea = new int[4][2];

int current_color = 0;
int[] colors = {#ffffff, #ff1493, #4682b4, #9370db, #ff4500, #ffff00, #c0c0c0};

boolean pointer_on_screen;
boolean pointer_is_moving;
boolean pointer_is_visible;
int[] pointer = new int[2];
int[] pointer_old = new int[2];
int[] laser_coordinates = new int[2];
int[] pointer_camera_coordinates = new int[2];

//used for the actual drawing
ArrayList drips = new ArrayList();
int drips_position;

//helpers for calibration
int calibration_point; //used for running through the four edges during calibration
int cleararea_calibration_point; //used for running through the four edges during calibration
Point2D[] a_quad = new Point2D[4];

boolean should_draw_menu = true;
boolean should_draw_outline = false;
boolean should_draw_framerate = false;
boolean should_draw_fatmarker = true;
boolean should_draw_drips = true;
boolean should_use_mouse = false;
boolean should_draw_left = false;
boolean is_color_set=false;

//rotation
boolean wannarotate = false;
float crap = 0.0;


Point2D.Double intersection;



void change_color(int new_color) {
  drips.add(new DripsScreen(new_color));
  drips_position += 1;
}

void clear_draw_area() {
  wannarotate = false;
  drips.clear();
  drips.add(new DripsScreen(colors[current_color]));
  drips_position = 0;
}

void draw() {
  background(0);
  ortho(0, width, 0, height, -5000, 5000);
  translate((width/2), (-height/2));
  drip_width = brush_width/3;
  
  smooth();

  //compute tasks
  
  if(should_use_mouse)
    track_mouse_as_laser();
  else
    track_laser();

  update_laser_position();
  handle_cleararea();

    pushMatrix();

    draw_tracking();
    popMatrix();
    
  //draw the lines & drips
  if(wannarotate) {
    crap += 0.01;
    Iterator i = drips.iterator();
    while(i.hasNext()) {
      DripsScreen d = (DripsScreen)i.next();
      d.draw_rotate();
    }
    
  }
  else{
    Iterator i = drips.iterator();
    while(i.hasNext()){
      DripsScreen d = (DripsScreen)i.next();
      d.draw();
    }
  }
  
  if (!should_draw_menu) {
    zcall = 5000;
  } else {
    zcall = -1;
  }
  
  if(should_draw_menu){
    repositionRectangleByMouse();
    noStroke();
    fill(0,0,0,0);
    rect(0,0,width,height);
    draw_menu();
    

  }

  if(calibration_point != 4)
    draw_calibration();
  else if(cleararea_calibration_point != 4)
    draw_cleararea_calibration();
    
  if(should_draw_framerate){
    noStroke();
    fill(255,255,255);
    textAlign(LEFT);
    text(frameRate, 10, 20);
  }
  
  if(should_draw_outline){
    noFill();
    stroke(255,255,255,255);
    strokeWeight(4);
  }
}

void draw_menu(){
  pushMatrix();
  fill(255,255,255);
  noStroke();
  int x = 0;
  int y = 0;
  
  textAlign(LEFT);
  
  y += 735;
  
  ArrayList lines = new ArrayList();
  lines.add("color threshold " + color_threshold + " (./, to in/decrease");
  lines.add("brush weight: " + brush_width + " (+/- to in/decrease)");
  lines.add("drips probability: " + drips_probability +" (h/g to in/decrease - lower = more likely))");
  lines.add("");
  
  Iterator i = lines.iterator();
  String s;
  while(i.hasNext()){
    s = (String)i.next();
    y += -15;
    text(s, x, y);
  }
  
  
  textAlign(RIGHT);
  x = width-20;
  y = 0;
  
  lines = new ArrayList();
  lines.add("r - Start/continue callibration");
  lines.add("x - Start/continue callibration");
  lines.add("l - Turn screen counterclockwise");
  lines.add("m - Toggle menu");
  lines.add("c - Clear screen");
  lines.add("d - Toggle drips");
  lines.add("f - Toggle framerate");
  lines.add("b - Toggle marker");
  lines.add("a - Next colour");
  lines.add("0 (nr) - use mouse mode");
  lines.add("3 - Effin' 3D effect");
    
  i = lines.iterator();
  while(i.hasNext()){
    s = (String)i.next();
    y += 15;
    text(s, x, y);
  }

  popMatrix();
}


void repositionRectangleByMouse(){
  // reposition scan rectangle
  if (should_draw_menu && should_use_mouse && mousePressed == true && mouseX < cam_width && mouseY < cam_height) {
    int nearest_distance = -1;
    int[] nearest = null;
    //find nearest beamer coordinate and set it to new point
    for(int i=0; i<4; i++){
      int[] pt = coordinates_projector[i];
      int distance = (int)(pow(mouseX-pt[0], 2) + pow(mouseY-pt[1], 2)); //need no sqrt, because we're only comparing
      if(distance < nearest_distance || nearest_distance == -1){
        nearest = pt;
        nearest_distance = distance;
      }
    }

    //move nearest point to mouse coordinates
    if(nearest != null){
      nearest[0] = mouseX;
      nearest[1] = mouseY;
    }
  }
}

void draw_calibration(){
  noStroke();
  fill(0,0,0,100);
  rect(0,0,width,height);

  noStroke();
  fill(255,255,255);
  Point2D point = a_quad[calibration_point];
  
  int c_size = width/15; //calibration circle with
  int c_x = (int)(point.getX()*width);
  int c_y = (int)(point.getY()*height);
  
  ellipse(c_x, c_y, c_size, c_size);
  
  if (pointer_is_visible) {
    coordinates_projector[calibration_point][0] = pointer_camera_coordinates[0];
    coordinates_projector[calibration_point][1] = pointer_camera_coordinates[1];
  }
}

void draw_cleararea_calibration(){
  noStroke();
  
  pushMatrix();
  
  scale((float)width/(float)cam_width, (float)height/(float)cam_height);
  draw_tracking();
  
  if(pointer_is_visible){
    coordinates_cleararea[cleararea_calibration_point][0] = pointer_camera_coordinates[0];
    coordinates_cleararea[cleararea_calibration_point][1] = pointer_camera_coordinates[1];
  }
  
  popMatrix();
}

void draw_tracking() {
  //draw the normal image of the camera
//  int[] img = jmyron.image();
/*  cam_image.loadPixels();
  arraycopy(img, cam_image.pixels);
  if (should_draw_menu) {
    cam_image.updatePixels();
  };
  image(cam_image, 0, 0, 320, 240);
*/
  opencv.loadImage(video);
  opencv.useColor();
  src = opencv.getSnapshot();
  opencv.useColor(HSB);
  opencv.setGray(opencv.getH().clone());
  opencv.inRange(110,130);
  colorFilteredImage = opencv.getSnapshot();
  contours = opencv.findContours(true, true);
  image(src, 0, 0);


  // Draw glob Boxes
  // First box is always the red border around the video
//  int[][] b = jmyron.globBoxes();
  noFill();
  stroke(255,0,0);
// jmyron based, PER CANVIAR
//  for(int i=0;i<b.length;i++){
//    rect(b[i][0], b[i][1], b[i][2] , b[i][3] );
//  }
  
  //draw the beamer
  noFill();
  stroke(255, 255, 255);
  strokeWeight(1);
  quad(coordinates_projector[0][0], coordinates_projector[0][1],
       coordinates_projector[1][0], coordinates_projector[1][1],
       coordinates_projector[2][0], coordinates_projector[2][1],
       coordinates_projector[3][0], coordinates_projector[3][1]
       );
  
  //draw the clear area
  stroke(255,0,0, 128);
  quad(coordinates_cleararea[0][0], coordinates_cleararea[0][1],
       coordinates_cleararea[1][0], coordinates_cleararea[1][1],
       coordinates_cleararea[2][0], coordinates_cleararea[2][1],
       coordinates_cleararea[3][0], coordinates_cleararea[3][1]
       );
  
  //draw mah lazer!!!
  if(pointer_is_visible){
    int e_size = cam_width/10;
    noStroke();
    fill(255,0,0,128);
    ellipse(pointer_camera_coordinates[0], pointer_camera_coordinates[1], e_size, e_size);
  }
}


void handle_cleararea(){
  if(pointer_is_visible){
    int[] xpoints = new int[4];
    int[] ypoints = new int[4];
    for(int i=0; i<4; i++){
      xpoints[i] = coordinates_cleararea[i][0];
      ypoints[i] = coordinates_cleararea[i][1];
    }
    Polygon clear_area = new Polygon(xpoints, ypoints, 4); //refactor me to use a polygon all the way
    
    if(clear_area.contains(pointer_camera_coordinates[0], pointer_camera_coordinates[1]))
      clear_draw_area();
  }
}


void keyPressed() {
  if(key == 'l') {
    should_draw_left = !should_draw_left;
  }
  if(key == 'a'){
    current_color += 1;
    if (current_color == colors.length)
      current_color = 0;
    change_color(colors[current_color]);
  }
  if(key == '3'){
    wannarotate = !wannarotate;
    rotateX(0);
    rotateY(0);
    crap = 0.0;
  }
  if(key == 'm')
    should_draw_menu = !should_draw_menu;
  if(key == 'f')
    should_draw_framerate = !should_draw_framerate;
  if(key == 'o')
    should_draw_outline = !should_draw_outline;
  if(key == 'b')
    should_draw_fatmarker = !should_draw_fatmarker;
  if(key == 'd')
    should_draw_drips = !should_draw_drips;
  if(key == '0')
    should_use_mouse = !should_use_mouse;
  if(key == 'c'){
    clear_draw_area();
  }
  if(key == 'r'){
    calibration_point += 1;
    if(calibration_point == 4){
      clear_draw_area(); // Clear drawing area after callibration finished
    }
    if(calibration_point == 5){
      calibration_point = 0;
    }
  }
  if(key == 'x'){
    cleararea_calibration_point += 1;
    if(cleararea_calibration_point == 4){
      clear_draw_area(); // Once calibration is finished, clear drawing area
    }
    if(cleararea_calibration_point == 5){
      cleararea_calibration_point = 0;
    }
  }
  if (key == '-') {
    brush_width -= 1;
  }
  if (key == '+') {
    brush_width += 1;
  }
  if (key == '.') {
    color_threshold += 20;
    //jmyron.trackColor(0,255,0,color_threshold);
  }
  if (key == ',') {
    color_threshold -= 20;
    //jmyron.trackColor(0,255,0,color_threshold);
  }
  if (key == 'h') {
    drips_probability += 5;
  }
  if (key == 'g') {
    drips_probability -= 5;
  }
  if (key == 'y') {
    src.updatePixels();
  }
}