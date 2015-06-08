/*
 * Smooth Second Bastard
 * Copyright 2011 Obx Labs / Jason Lewis
 * Developed by Bruno Nadeau
 */

import processing.opengl.*;
import javax.media.opengl.GL;
import javax.media.opengl.glu.GLU;
import javax.media.opengl.glu.GLUtessellator;
import javax.media.opengl.glu.GLUtessellatorCallbackAdapter;

import fullscreen.*;

import net.nexttext.*;
import net.nexttext.behaviour.standard.*;
import net.nexttext.behaviour.control.*;
import net.nexttext.behaviour.dform.*;
import net.nexttext.behaviour.physics.*;
import net.nexttext.behaviour.*;
import net.nexttext.input.*;
import net.nexttext.renderer.*;
import net.nexttext.property.*;

import PQSDKMultiTouch.*;
import javax.swing.JOptionPane;

import java.util.LinkedList;
import java.awt.Color;
import java.awt.geom.Rectangle2D;
import java.awt.Rectangle;
import java.awt.geom.GeneralPath;
import java.awt.geom.AffineTransform;
import java.awt.geom.PathIterator;
import java.awt.Rectangle;
import java.awt.Polygon;
import java.awt.Paint;
import java.awt.RadialGradientPaint;

//constants
boolean FULLSCREEN = true;             //true to start in fullscreen mode, false for window
boolean DEBUG = false;                 //true to turn on debug mode (display extra info)
boolean FRAMERATE = false;              //true to show framerate
boolean FAKE_DUAL_TOUCH = false;       //true to fake dual touch with the mouse
boolean PQLABS_TOUCHSCREEN = true;    //true when using PQLabs touchscreen
boolean CURSOR = !PQLABS_TOUCHSCREEN;  //false to hide cursor

final int FRONT = 1;                   //id for front sentence layer
final int MIDDLE = 2;                  //id for widdle word layer
final int BACK = 3;                    //id for background glyph layer

final int FPS = 30;                    //target frames per second

final int[] PALETTE_FG = { 
  0xFFFFFFFF
};  //foreground color palette
final int[] PALETTE_MG = { 
  0xFFdc6626,    //middle layer color palette
  0xFFad3a25,
  0xFFe5b43d,
  0xFFdf9529
};
final int[] PALETTE_BG = { 
  0xFF231e55,    //background layer color palette
  0xFF671e16,
  0xFF8c191b,
  0xFFc97525
};

//max offsets when getting a color from a palette                           
final int PALETTE_RED_OFFSET = 10;
final int PALETTE_GREEN_OFFSET = 5;
final int PALETTE_BLUE_OFFSET = 5;

//text constants
final String PAGE = "PAGE";                         //NextText book page name
final String FONT_FILE = "Catalogue.ttf";           //font file
final String TEXT_FILE = "SmoothSecondBastard.txt"; //text file
final int TESS_DETAIL_LOW = 3;                      //low tessellation detail
final int TESS_DETAIL_HIGH = 4;                     //high tessellation detail (for middle word)
final int TOUCH_Y_OFFSET = 30;
final long IDLE_TIMEOUT = 20*60*1000;

//tmp
final int[] WORD_INDEXES = {0,4,2,0,1,2,2,3,7,1,0,1,2,5,3,8,4,2,11,0,0,1,1,2,1,1,2,2,1,1};
final int[] GLYPH_INDEXES = {0,2,2,2,0,1,3,4,1,3,0,1,3,1,4,3,1,0,4,3,1,2,0,1,0,1,6,4,7,5};

//property ids to treak with arrow keys
final int PROPERTY_FONT_SIZE = 0;
final int PROPERTY_SENTENCE_OPACITY = 1;
final int PROPERTY_WORD_SCALE = 2;
final int PROPERTY_WORD_SCALE_SPEED = 3;
final int PROPERTY_WORD_SCALE_FRICTION = 4;
final int PROPERTY_WORD_WANDER_SPEED = 5;
final int PROPERTY_WORD_WANDER_RANGE = 6;
final int PROPERTY_WORD_OPACITY = 7;
final int PROPERTY_GLYPH_SCALE = 8;
final int PROPERTY_GLYPH_SCALE_SPEED = 9;
final int PROPERTY_GLYPH_SCALE_FRICTION = 10;
final int PROPERTY_GLYPH_WANDER_SPEED = 11;
final int PROPERYT_GLYPH_WANDER_RANGE = 12;
final int PROPERTY_GLYPH_OPACITY = 13;
final int PROPERTY_TOTAL_BACKGROUND_GLYPHS = 14;
final String[] PROPERTY_NAMES = {
  "Font size", 
  "Sentence opacity", 
  "Word scale", 
  "Word scale speed", 
  "Word scale friction", 
  "Word wander speed", 
  "Word wander reach", 
  "Word opacity", 
  "Glyph scale", 
  "Glyph scale speed", 
  "Glyph scale friction", 
  "Glyph wander speed", 
  "Glyph wander reach", 
  "Glyph opacity", 
  "Total background glyphs"
};

//id of currently tweaked property
int currentProperty = 0;

//tweakable properties
boolean lightsOn = true;                      //true when lights are on
int fontSize = 42;                            //front sentence font size
int frontSentenceOpacity = 240;               //front sentence opacity
float middleWordScale = 2.5f;                 //middle word scale factor
float middleWordScaleSpeed = 0.0002f;         //middle word scale speed
float middleWordScaleFriction = 0.97f;        //middle word scale friction
float middleWordWanderRange = 20;             //middle word wandering range
float middleWordWanderSpeed = 0.01;           //middle word wandering speed
int middleWordOpacity = 180;                  //middle word opacity
float backgroundGlyphScale = 50f;             //background glyph scale factor
float backgroundGlyphScaleSpeed = 0.02f;      //background glyph scale speed
float backgroundGlyphScaleFriction = 0.96f;   //background glyph scale friction
float backgroundGlyphWanderRange = 50;        //background glyph wandering range
float backgroundGlyphWanderSpeed = 0.005;     //background glyph wandering speed
int backgroundGlyphOpacity = 100;             //background glyph opacity
int totalBackgroundGlyphs = 20;               //max background glyphs

//OpenGL
PGraphicsOpenGL pgl;
GL gl;
GLU glu;
TessCallback tessCallback;  //tesselator's callback
GLUtessellator tess;        //tesselator

//Spotlights
Spot[] spotlights;          //all the spotlights
int currentSpot;            //current spotlight tied to the active or next front sentence

//Background
float[] bgColor;            //current background color
float[] bgColorTarget;      //target background color
float[] bgColorSpeed;       //background color fading speed

//text properties
Book book;                  //NextText book
TextPage page;              //book's page
PFont font;                 //the font
String[] textStrings;       //loaded text strings
int stringIndex;            //index of the next string
Rectangle2D.Float bounds;   //bounds of the display to find when words get out

TessSentence tessSentence;  //active front sentence (null if none)
LinkedList doneTessSentences; //the sentences we are done with (exploding)
LinkedList middleWords;     //list of floating middle words
LinkedList doneMiddleWords; //list of done floating middle words
LinkedList bgLetters;       //list of floating letters in the background

//animation time tracking
long lastUpdate = 0;        //last time the sketch was updated
long now = 0;               //current time
long dt;                    //time difference between draw calls
long lastTouch = 0;

//fullscreen manager
SoftFullScreen sfs;         //fullscreen util

//touchscreen
HashMap touches = new HashMap();
TouchClient touchClient = null;              //pqlabs touchscreen client
SmoothTouchDelegate touchDelegate = null;    //touch delegate

void setup() {
  //if we are an applet
  if (online)
    size(900, 600, OPENGL);
  //set size to match PQLabs touchscreen if active
  else if (PQLABS_TOUCHSCREEN && FULLSCREEN)
    size(1920, 1080, OPENGL);
  //or use generic size
  else if (FULLSCREEN)
    size(screenWidth, screenHeight, OPENGL);
  else
    //size(1680, 1050, OPENGL);f
    size(1024, 768, OPENGL);

  //enable 4x anti-aliasing
  hint(DISABLE_OPENGL_2X_SMOOTH);
  hint(ENABLE_OPENGL_4X_SMOOTH);

  frameRate(FPS); //set framerate

  //create bounds
  bounds = new Rectangle2D.Float(0, 0, width, height);

  //init tesselator
  glu = new GLU();
  tess = glu.gluNewTess();
  tessCallback = new TessCallback();
  glu.gluTessCallback(tess, GLU.GLU_TESS_BEGIN, tessCallback); 
  glu.gluTessCallback(tess, GLU.GLU_TESS_END, tessCallback); 
  glu.gluTessCallback(tess, GLU.GLU_TESS_VERTEX, tessCallback); 
  glu.gluTessCallback(tess, GLU.GLU_TESS_COMBINE, tessCallback); 
  glu.gluTessCallback(tess, GLU.GLU_TESS_ERROR, tessCallback); 

  //init lights
  spotlights = new Spot[4];
  spotlights[0] = new Spot(color(0), new PVector(width/2, height/2, 500));
  spotlights[1] = new Spot(color(0), new PVector(width/2, height/2, 500));
  spotlights[2] = new Spot(color(0), new PVector(width/2, height/2, 500));
  spotlights[3] = new Spot(color(0), new PVector(width/2, height/2, 500));
  spotlights[0].friction = spotlights[1].friction = spotlights[2].friction = spotlights[3].friction = 0.8;
  currentSpot = 0;

  //create the fullscreen object
  if (FULLSCREEN) {  
    //create the soft fullscreen
    sfs = new SoftFullScreen(this, 0);
    sfs.enter();
  }  

  //remove the cursor
  if (!CURSOR) noCursor();

  //init background color
  color c = createPaletteColor(255, BACK);
  bgColor = new float[3];
  bgColor[0] = red(c);
  bgColor[1] = green(c);
  bgColor[2] = blue(c);
  bgColorTarget = new float[3];
  bgColorTarget[0] = red(c);
  bgColorTarget[1] = green(c);
  bgColorTarget[2] = blue(c);
  bgColorSpeed = new float[3];
  bgColorSpeed[0] = bgColorSpeed[1] = bgColorSpeed[2] = 0.005;

  //init NextText
  book = new Book(this);
  page = book.addPage(PAGE); 

  //init lists
  tessSentence = null;
  doneTessSentences = new LinkedList();
  middleWords = new LinkedList();
  doneMiddleWords = new LinkedList();
  bgLetters = new LinkedList();

  //load font
  font = createFont(FONT_FILE, fontSize, true);

  //load the text file
  loadText(TEXT_FILE);

  //keep track of time
  now = millis();
  lastUpdate = now;

  //init pqlabs touchscreen
  if (PQLABS_TOUCHSCREEN) {
    touchDelegate = new SmoothTouchDelegate(this);
    touchClient = new TouchClient();
    touchClient.setDelegate(touchDelegate);
  }

  //output default properties
  printProperties();
}

void draw() {  
  //if (frameRate < 26) System.err.out("Warning: framerate is low at " + frameRate);

  //millis since last draw
  dt = now-lastUpdate;

  //clear
  background(color(bgColor[0], bgColor[1], bgColor[2]));

  //disable depth buffer
  hint(DISABLE_DEPTH_TEST);

  //draw the focus layer
  if (lightsOn) {
    //set an ambient light (without it it's too dark)
    ambientLight(128, 128, 128);

    //lighten or darken the current spotlight if we have an active
    //front sentence or not
    if (tessSentence != null) {
      PVector pt = tessSentence.getCenterPt();
      spotlights[currentSpot].approach(pt.x, pt.y, spotlights[currentSpot].pos.z, 5);
      spotlights[currentSpot].lighten(3, 64);
    }
    else {
      spotlights[currentSpot].darken(3, 0);
    }

    //adjust the other spotlights to match the floating words
    Iterator it = middleWords.descendingIterator();
    TessWord tw;
    int wordSpot = currentSpot;
    while (it.hasNext ()) {
      tw = (TessWord)it.next();

      wordSpot--;
      if (wordSpot < 0) wordSpot = spotlights.length-1;   

      spotlights[wordSpot].approach(tw.pos.x, tw.pos.y, spotlights[wordSpot].pos.z, 1);
      spotlights[wordSpot].lighten(3, 64);
    }

    //update all the spotlights and turn them on    
    for(int i = 0; i < spotlights.length; i++) {
      spotlights[i].update(dt);
      spotlights[i].show(new PVector(0, 0, -1), 30, 0);
    }

    //set the light falloff
    lightFalloff(0, 0.1, 0);
  }

  //draw background letters
  drawBgLetters();

  //turn off lights (we only use then for the background)
  noLights();

  //draw middle layer
  drawMiddleWords();

  //draw tess strings
  drawStrings();

  //draw the framerate
  if (FRAMERATE) drawFrameRate();

  //update background color
  updateBackground(dt);

  //update background letters
  updateBgLetters(dt);

  //update middle word
  updateMiddleWords(dt);

  //update strings
  updateStrings(dt);

  //update idle
  updateIdle(dt);

  //keep track of time
  lastUpdate = now;
  now = millis();
}

//draw the framerate
void drawFrameRate() {
  noStroke();
  fill(0, 255, 0);
  textFont(font, 12);
  textAlign(LEFT, BASELINE);
  text(frameRate, 5, 15);
}

//update strings
void updateStrings(long dt) {
  //if we have an active front sentence, update it
  if (tessSentence != null)
    tessSentence.update(dt);

  //keep track the exploding word (if any)
  TessWord explodingWord = null;

  //update non-interactive sentences
  synchronized(doneTessSentences) {
    TessSentence ts;
    ListIterator lit = doneTessSentences.listIterator();
    while (lit.hasNext ()) {
      ts = (TessSentence)lit.next();

      //update sentence
      ts.update(dt);

      //check if we need to clean up after folding
      if (ts.getState() == TessSentence.FOLD && ts.isFolded())
        lit.remove();    

      //check if the sentence is done snapping after releasing it 
      else if (ts.getState() == TessSentence.SNAP && ts.isSnapped()) {

        //if we have enough float words, then blow up the oldest one
        if (middleWords.size() > 2) {
          explodingWord = (TessWord)middleWords.getFirst();
          //int glyphCount = explodingWord.glyphCount();
          //int halfGlyph = glyphCount%2 == 0 ? glyphCount/2-1 : glyphCount/2;
          //int halfGlyph = glyphCount/2;
          TessGlyph tg = explodingWord.extract(explodingWord.extractGlyphIndex());
          //TessGlyph tg = explodingWord.extract(0);
          bgLetters.add(tg);
        }

        //extract the special word
        TessWord tw = ts.extract(ts.extractWordIndex());
        middleWords.add(tw);

        //switch to next state
        ts.setState(TessSentence.EXTRACT);

        //go to next line in the text
        //stringIndex++;
        //if (stringIndex >= textStrings.length) stringIndex = 0;

        //got to the next spotlight
        currentSpot++;
        if (currentSpot >= spotlights.length) currentSpot = 0;
      }  
      //check if the sentence is still in the windows
      else if (ts.isOutside(bounds))
        lit.remove();
    }
  }

  //if we made a floating word explode, now
  //place it in the correct array
  if (explodingWord != null) {
    synchronized(middleWords) {
      middleWords.remove(explodingWord);
    }

    synchronized(doneMiddleWords) {
      doneMiddleWords.add(explodingWord);
    }
  }
}

void updateIdle(long dt) {
  //check if we've been idle for a while
  //if so explode all floating words
  //and reset the poem
  if (middleWords.size() == 0) return;
  if (millis()-lastTouch < IDLE_TIMEOUT) return;
  
  LinkedList explodedWords = new LinkedList();
  
  //go through the floating words and make them wander
  synchronized(middleWords) {
    TessWord tw;
    ListIterator it = middleWords.listIterator();
    while (it.hasNext ()) {
      tw = (TessWord)it.next();
      
      //int glyphCount = tw.glyphCount();
      //int halfGlyph = glyphCount%2 == 0 ? glyphCount/2-1 : glyphCount/2;
      //TessGlyph tg = tw.extract(halfGlyph);
      TessGlyph tg = tw.extract(tw.extractGlyphIndex());
      bgLetters.add(tg);
      
      explodedWords.add(tw);
      it.remove();
    }
  }

  synchronized(doneMiddleWords) {
    doneMiddleWords.addAll(explodedWords);
  }  
  
  stringIndex = 0;
}

//draw strings
void drawStrings() {
  //remove stroke
  noStroke();

  //draw the active sentence if any
  if (tessSentence != null) {
    fill(tessSentence.getColor());
    tessSentence.draw();
    if (DEBUG) tessSentence.drawAbsoluteBounds();
  }

  //loop through and draw the exploding sentence
  synchronized(doneTessSentences) {
    TessSentence ts;
    ListIterator lit = doneTessSentences.listIterator();
    while (lit.hasNext ()) {
      ts = (TessSentence)lit.next();

      fill(ts.getColor());
      ts.draw();

      if (DEBUG) ts.drawAbsoluteBounds();
    }
  }
}    

//update middle layer words
void updateMiddleWords(long dt) {  
  //go through the floating words and make them wander
  TessWord tw;
  ListIterator it = middleWords.listIterator();
  while (it.hasNext ()) {
    tw = (TessWord)it.next();

    tw.wander();    
    tw.update(dt);
  } 

  //go through the exploding words and remove them
  //if they get out of bounds
  it = doneMiddleWords.listIterator();
  while (it.hasNext ()) {
    tw = (TessWord)it.next();

    tw.wander();    
    tw.update(dt);

    //clean up if the word is outside
    if (tw.isOutside(bounds))
      it.remove();
  }
}

//draw middle words
void drawMiddleWords() {
  //set colors
  noStroke();
  fill(255, 150);

  //draw the floating words
  TessWord tw;
  for (int i = 0; i < middleWords.size(); i++) {
    tw = (TessWord)middleWords.get(i);

    if (tw.isColorSet()) fill(tw.getColor());
    tw.draw();
  }

  //draw the exploding words
  for (int i = 0; i < doneMiddleWords.size(); i++) {
    tw = (TessWord)doneMiddleWords.get(i);

    if (tw.isColorSet()) fill(tw.getColor());
    tw.draw();
  }
}

//update background color
void updateBackground(long dt) {
  //if we hit the target, create a new one
  if (bgColor[0] == bgColorTarget[0] &&
    bgColor[1] == bgColorTarget[1] &&
    bgColor[2] == bgColorTarget[2]) {
    color c = createPaletteColor(255, BACK);
    bgColorTarget[0] = red(c);
    bgColorTarget[1] = green(c);
    bgColorTarget[2] = blue(c);
  }

  //fade each color element
  float diff;
  float delta;
  int direction;
  for (int i = 0; i < 3; i++) {
    diff = bgColorTarget[i] - bgColor[i];
    if (diff != 0) {
      delta = bgColorSpeed[i] * dt;
      direction = diff < 0 ? -1 : 1;

      if (diff*direction < delta)
        bgColor[i] = bgColorTarget[i];
      else
        bgColor[i] += delta*direction;
    }
  }
}

//update background letters
void updateBgLetters(long dt) {
  //go through each background glyph and update them
  TessGlyph tg;
  ListIterator it = bgLetters.listIterator();
  int count = 0;
  while (it.hasNext()) {
    tg = (TessGlyph)it.next();

    //wander around
    tg.wander();

    //fade the older letters
    if (count < bgLetters.size()-totalBackgroundGlyphs) {
      color c = tg.getColor();     
      int newAlpha = (int)alpha(c)-1;
      tg.fadeTo(color(red(c), green(c), blue(c), newAlpha > 0 ? newAlpha : 0));
    }

    //update
    tg.update(dt);

    //if the letter is transparent, remove it
    if (alpha(tg.getColor()) <= 0)
      it.remove();

    //next
    count++;
  }
}

//draw background letters
void drawBgLetters() {
  noStroke();
  TessGlyph tg;
  for (int i = 0; i < bgLetters.size(); i++) {
    tg = (TessGlyph)bgLetters.get(i);
    fill(tg.getColor());
    tg.draw();
  }
}

//load text
void loadText(String textFile) {
  //load text file
  print("Loading text file '" + textFile + "'... ");
  textStrings = loadStrings(textFile);

  print("Done (" + textStrings.length + " line");
  if (textStrings.length > 1) print("s");
  println(")");

  //start at first string
  stringIndex = 0;
}

//create a sentence from a line string
TessSentence createSentence(String textLine) { 
  //add text to the book 
  textAlign(CENTER, CENTER);
  textFont(font, fontSize);  

  //add the line to the page
  TextObjectGroup grp = book.addText(textStrings[stringIndex], 0, 0, PAGE);

  //remove spaces
  TextObject child = grp.getLeftMostChild();
  while (child != null) {
    TextObject tmpChild = child;
    child = child.getRightSibling();
    if (tmpChild.toString().equals(" ")) tmpChild.detach();
  } 

  //calculate the offset to make the middle arrive exactly between two glyphs
  int offset = 0;
  int glyphCount = getGlyphCount(grp);
  int halfGlyph = glyphCount%2 == 0 ? glyphCount/2 - 1 : glyphCount/2;
  //int halfGlyph = glyphCount/2;
  TextObjectGlyphIterator it = grp.glyphIterator();
  TextObjectGlyph glyph;
  int count = 0;
  while (it.hasNext ()) {
    glyph = (TextObjectGlyph)it.next();
    if (count == halfGlyph) {
      //println(glyph);
      Rectangle bnds = glyph.getBounds();
      offset = (int)(bnds.getX()+bnds.getWidth());
      break;
    }
    count++;
  }

  //set tessellation data and color
  TessSentence ts = new TessSentence(grp, TESS_DETAIL_LOW, TESS_DETAIL_HIGH);
  ts.setColor(createPaletteColor(frontSentenceOpacity, FRONT));
  ts.setExtractIndexes(WORD_INDEXES[stringIndex], GLYPH_INDEXES[stringIndex]);

  //offset each word so that the center is at the right place
  //(the middle should arrive between two glyphs for a single touch to unfold properly)
  Iterator iterator = ts.words.iterator();
  TessWord tw;
  while (iterator.hasNext ()) {
    tw = (TessWord)iterator.next();
    tw.moveBy(-offset, 0, 0);
  }

  //fold sentence completely (start state)
  ts.fold();

  //flag to unfold right away
  ts.setState(TessSentence.UNFOLD);

  //clear the book (we only use it to easy position text)
  book.clear();
  book.step();

  //return the tess string
  return ts;
}

void keyPressed() {
  switch (key) {
    //turn lights on/off with 'l'
  case 'l':
    lightsOn = !lightsOn;
    break;
    //save the current frame with 's'
  case 's':
    saveFrame("smooth-" + frameCount + ".png");
    break;
    //clear the screen with DELETE
  case DELETE:
    tessSentence = null;
    doneTessSentences.clear();
    middleWords.clear();
    doneMiddleWords.clear();
    bgLetters.clear();
    break;
  }

  //stop here if the key is not coded
  if (key != CODED) { 
    return;
  }

  //adjust the current tweakable property
  switch (keyCode) {
  case ENTER:
    printProperties();
    break;
  case UP:
    print(PROPERTY_NAMES[currentProperty] + ": ");
    switch(currentProperty) {
    case PROPERTY_FONT_SIZE:
      fontSize++;
      println(fontSize);
      break;
    case PROPERTY_SENTENCE_OPACITY:
      frontSentenceOpacity += 1;
      if (frontSentenceOpacity > 255) frontSentenceOpacity = 255;
      println(frontSentenceOpacity);        
      break;
    case PROPERTY_WORD_SCALE:
      middleWordScale += 0.1;
      println(middleWordScale);
      break;
    case PROPERTY_WORD_SCALE_SPEED:
      middleWordScaleSpeed += 0.0001;
      println(middleWordScaleSpeed);
      break;
    case PROPERTY_WORD_SCALE_FRICTION:
      middleWordScaleFriction += 0.01;
      println(middleWordScaleFriction);
      break;
    case PROPERTY_WORD_WANDER_SPEED:
      middleWordWanderSpeed += 0.01;
      println(middleWordWanderSpeed);
      break;
    case PROPERTY_WORD_WANDER_RANGE:
      middleWordWanderRange += 1;
      println(middleWordWanderRange);
      break;
    case PROPERTY_WORD_OPACITY:
      middleWordOpacity += 1;
      if (middleWordOpacity > 255) middleWordOpacity = 255;
      println(middleWordOpacity);
      break;
    case PROPERTY_GLYPH_SCALE:
      backgroundGlyphScale += 1;
      println(backgroundGlyphScale);
      break;
    case PROPERTY_GLYPH_SCALE_SPEED:
      backgroundGlyphScaleSpeed += 0.0001;
      println(backgroundGlyphScaleSpeed);
      break;
    case PROPERTY_GLYPH_SCALE_FRICTION:
      backgroundGlyphScaleFriction += 0.01;
      println(backgroundGlyphScaleFriction);
      break;
    case PROPERTY_GLYPH_WANDER_SPEED:
      backgroundGlyphWanderSpeed += 0.001;
      println(backgroundGlyphWanderSpeed);
      break;
    case PROPERYT_GLYPH_WANDER_RANGE:
      backgroundGlyphWanderRange += 1;
      println(backgroundGlyphWanderRange);
      break;
    case PROPERTY_GLYPH_OPACITY:
      backgroundGlyphOpacity += 1;
      if (backgroundGlyphOpacity > 255) backgroundGlyphOpacity = 255;
      println(backgroundGlyphOpacity);
      break;
    case PROPERTY_TOTAL_BACKGROUND_GLYPHS:
      totalBackgroundGlyphs++;
      println(totalBackgroundGlyphs);
      break;
    }
    break;
  case DOWN:
    print(PROPERTY_NAMES[currentProperty] + ": ");
    switch(currentProperty) {
    case PROPERTY_FONT_SIZE:
      fontSize--;
      if (fontSize < 1) fontSize = 1;
      println(fontSize);
      break;
    case PROPERTY_SENTENCE_OPACITY:
      frontSentenceOpacity -= 1;
      if (frontSentenceOpacity < 0) frontSentenceOpacity = 0;
      println(frontSentenceOpacity);        
      break;          
    case PROPERTY_WORD_SCALE:
      middleWordScale -= 0.1;
      if (middleWordScale < 0) middleWordScale = 0;
      println(middleWordScale);        
      break;
    case PROPERTY_WORD_SCALE_SPEED:
      middleWordScaleSpeed -= 0.0001;
      if (middleWordScaleSpeed < 0) middleWordScaleSpeed = 0;
      println(middleWordScaleSpeed);        
      break;
    case PROPERTY_WORD_SCALE_FRICTION:
      middleWordScaleFriction -= 0.01;
      if (middleWordScaleFriction < 0) middleWordScaleFriction = 0;
      println(middleWordScaleFriction);        
      break;
    case PROPERTY_WORD_WANDER_SPEED:
      middleWordWanderSpeed -= 0.01;
      if (middleWordWanderSpeed < 0) middleWordWanderSpeed = 0;
      println(middleWordWanderSpeed); 
      break;
    case PROPERTY_WORD_WANDER_RANGE:
      middleWordWanderRange -= 1;
      if (middleWordWanderRange < 0) middleWordWanderRange = 0;
      println(middleWordWanderRange);         
      break;
    case PROPERTY_WORD_OPACITY:
      middleWordOpacity -= 1;
      if (middleWordOpacity < 0) middleWordOpacity = 0;
      println(middleWordOpacity);
      break;             
    case PROPERTY_GLYPH_SCALE:
      backgroundGlyphScale -= 1;
      if (backgroundGlyphScale < 0) backgroundGlyphScale = 0;
      println(backgroundGlyphScale);
      break;
    case PROPERTY_GLYPH_SCALE_SPEED:
      backgroundGlyphScaleSpeed -= 0.0001;
      if (backgroundGlyphScaleSpeed < 0) backgroundGlyphScaleSpeed = 0;
      println(backgroundGlyphScaleSpeed);           
      break;
    case PROPERTY_GLYPH_SCALE_FRICTION:
      backgroundGlyphScaleFriction -= 0.01;
      if (backgroundGlyphScaleFriction < 0) backgroundGlyphScaleFriction = 0;
      println(backgroundGlyphScaleFriction);          
      break;
    case PROPERTY_GLYPH_WANDER_SPEED:
      backgroundGlyphWanderSpeed -= 0.001;
      if (backgroundGlyphWanderSpeed < 0) backgroundGlyphWanderSpeed = 0;
      println(backgroundGlyphWanderSpeed);         
      break;
    case PROPERYT_GLYPH_WANDER_RANGE:
      backgroundGlyphWanderRange -= 1;
      if (backgroundGlyphWanderRange < 0) backgroundGlyphWanderRange = 0;
      println(backgroundGlyphWanderRange);                 
      break;
    case PROPERTY_GLYPH_OPACITY:
      backgroundGlyphOpacity -= 1;
      if (backgroundGlyphOpacity < 0) backgroundGlyphOpacity = 0;
      println(backgroundGlyphOpacity);
      break;  
    case PROPERTY_TOTAL_BACKGROUND_GLYPHS:
      totalBackgroundGlyphs--;
      if (totalBackgroundGlyphs < 0) totalBackgroundGlyphs = 0;
      println(totalBackgroundGlyphs);
      break;
    }
    break;
  case LEFT:
    currentProperty--;
    if (currentProperty < 0) currentProperty = PROPERTY_NAMES.length-1;
    println("Tweaking: " + PROPERTY_NAMES[currentProperty]);
    break;
  case RIGHT:
    currentProperty++;
    if (currentProperty >= PROPERTY_NAMES.length) currentProperty = 0;
    println("Tweaking: " + PROPERTY_NAMES[currentProperty]);
    break;
  }
}

//print the tweakable properties
void printProperties() {
  println("Properties: ");
  for (int i = 0; i < PROPERTY_NAMES.length; i++) {
    print("  " + PROPERTY_NAMES[i] + ": ");
    switch(i) {
    case PROPERTY_FONT_SIZE:
      println(fontSize);
      break;
    case PROPERTY_SENTENCE_OPACITY:
      println(frontSentenceOpacity);
      break;
    case PROPERTY_WORD_SCALE:
      println(middleWordScale);        
      break;
    case PROPERTY_WORD_SCALE_SPEED:
      println(middleWordScaleSpeed);        
      break;
    case PROPERTY_WORD_SCALE_FRICTION:
      println(middleWordScaleFriction);        
      break;
    case PROPERTY_WORD_WANDER_SPEED:
      println(middleWordWanderSpeed); 
      break;
    case PROPERTY_WORD_WANDER_RANGE:
      println(middleWordWanderRange);         
      break;
    case PROPERTY_WORD_OPACITY:
      println(middleWordOpacity);         
      break;
    case PROPERTY_GLYPH_SCALE:
      println(backgroundGlyphScale);
      break;
    case PROPERTY_GLYPH_SCALE_SPEED:
      println(backgroundGlyphScaleSpeed);           
      break;
    case PROPERTY_GLYPH_SCALE_FRICTION:
      println(backgroundGlyphScaleFriction);          
      break;
    case PROPERTY_GLYPH_WANDER_SPEED:
      println(backgroundGlyphWanderSpeed);         
      break;
    case PROPERYT_GLYPH_WANDER_RANGE:
      println(backgroundGlyphWanderRange);                 
      break;
    case PROPERTY_GLYPH_OPACITY:
      println(backgroundGlyphOpacity);         
      break;
    case PROPERTY_TOTAL_BACKGROUND_GLYPHS:
      println(totalBackgroundGlyphs);         
      break;
    }
  }
}

//mouse pressed
void mousePressed() {
  //do nothing when using PQLabs (events handled somewhere else)
  if (PQLABS_TOUCHSCREEN) return;

  //if we are faking dual touch, send two points  
  if (FAKE_DUAL_TOUCH) {
    mousePressed(1, mouseX, mouseY);
    mousePressed(2, mouseX+200, mouseY);
  }
  //else process the one point
  else
    mousePressed(1, mouseX, mouseY);
}

void mousePressed(int id, int x, int y) {
  //keep track of touches
  /*Integer iid = new Integer(id);
   PVector pos = new PVector(x, y, 0);  
   synchronized(touches) {
   touches.put(iid, pos);
   }*/

  //keep track of last touch to reset if idle for too long
  lastTouch = millis();
  
  //if there is no active sentence, create a new one
  if (tessSentence == null) {
    TessSentence ts = createSentence(textStrings[0]);
    ts.setCtrlPoint(id, x, y-TOUCH_Y_OFFSET);
    tessSentence = ts;
  } 
  //if we have one and then the control point for this touch
  else {
    tessSentence.setCtrlPoint(id, x, y-TOUCH_Y_OFFSET);
  }

  //print counts
  if (DEBUG) println("Sentences: " + (doneTessSentences.size()+1) + "  " + "Words: " + middleWords.size() + "  " + "Glyphs: " + bgLetters.size());
}

//mouse dragged
void mouseDragged() {
  //do nothing when using PQLabs (events handled somewhere else)
  if (PQLABS_TOUCHSCREEN) return;

  //if we are faking dual touch, send two points 
  if (FAKE_DUAL_TOUCH) {
    mouseDragged(1, mouseX, mouseY);
    mouseDragged(2, mouseX+200, mouseY);
  }
  //else process the one point
  else
    mouseDragged(1, mouseX, mouseY);
}

void mouseDragged(int id, int x, int y) {
  //update position to keep track of touch
  /*PVector v = null;
   Integer iid = new Integer(id);
   synchronized(touches) {
   v = (PVector)touches.get(iid);
   }
   if (v != null) v.set(x, y, 0);*/

  //set the active's sentence control point for this touch
  if (tessSentence != null)
    tessSentence.setCtrlPoint(id, x, y-TOUCH_Y_OFFSET);
}

//mouse released
void mouseReleased() {
  //do nothing when using PQLabs (events handled somewhere else)
  if (PQLABS_TOUCHSCREEN) return;

  //if we are faking dual touch, send two points
  if (FAKE_DUAL_TOUCH) {
    mouseReleased(1, mouseX, mouseY);
    mouseReleased(2, mouseX+200, mouseY);
  }
  //else process the one point 
  else
    mouseReleased(1, mouseX, mouseY);
}

void mouseReleased(int id, int x, int y) {
  //clear touch
  /*Integer iid = new Integer(id);
   synchronized(touches) {   
   touches.remove(iid);
   }*/

  //if there is not active sentences, then nothing to do
  if (tessSentence == null) return;

  //move active sentence to non-interactive list   
  synchronized(doneTessSentences) {
    doneTessSentences.add(tessSentence);
  }

  //if the string is not completely unfolded, then fold it back
  if (!tessSentence.isUnfolded()) {
    tessSentence.setState(TessSentence.FOLD);
  }
  //if it's unfolded then set its state to snap
  else {
    tessSentence.setState(TessSentence.SNAP);

    //go to next line in the text
    stringIndex++;
    if (stringIndex >= textStrings.length) stringIndex = 0;
  }

  //no more active sentence
  tessSentence = null;
}

//generate a color from one of the three palettes
color createPaletteColor(int a, int layer) {
  //get the right palette
  int[] palette = null;
  switch (layer) {
  case FRONT:
    palette = PALETTE_FG;
    break;
  case MIDDLE:
    palette = PALETTE_MG;
    break;
  case BACK:
    palette = PALETTE_BG;
    break;
  }

  //if no palette was found, return black
  if (palette == null) return color(0);

  //get a random color from the palette
  int index = (int)random(0, palette.length);
  int c = palette[index];

  //don't offset front layer
  if (layer == FRONT) return c;

  //offset color so that it's not always the same few
  int r = (int)(red(c) + random(-1, 1)*PALETTE_RED_OFFSET);
  if (r < 0) r = 0;
  else if (r > 255) r = 255;

  int g = (int)(green(c) + random(-1, 1)*PALETTE_GREEN_OFFSET);
  if (g < 0) g = 0;
  else if (g > 255) g = 255;

  int b = (int)(blue(c) + random(-1, 1)*PALETTE_BLUE_OFFSET);
  if (b < 0) b = 0;
  else if (b > 255) b = 255;

  return color(r, g, b, a);
}

//convert color to Color
Color colorToColor(color c) { 
  return new Color(int(red(c)), int(green(c)), int(blue(c)), int(alpha(c)));
}

//convert Color to color
color ColorTocolor(Color c) { 
  return color(c.getRed(), c.getGreen(), c.getBlue(), c.getAlpha());
}

//get number of glyphs in a NextText group
int getGlyphCount(TextObjectGroup root) {
  int count = 0;
  TextObjectGlyphIterator it = root.glyphIterator();
  while (it.hasNext ()) {
    it.next();
    count++;
  }
  return count;
}

