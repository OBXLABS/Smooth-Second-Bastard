/**
 * A tesselated glyph.

  Copyright (C) <2015>  <Jason Lewis>
  
    This program is free software: you can redistribute it and/or modify
    it under the terms of the BSD 3 clause with added Attribution clause license.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   BSD 3 clause with added Attribution clause License for more details.
 */
public class TessGlyph extends TessString {
  //constants
  static final float WANDER_THRESHOLD = 5;    //proximity threshold for wander to create a new target
  static final float WANDER_FRICTION = 0.98;  //wandering friction
  static final float FADE_SPEED = 5000;       //color fading speed

  TessData origData;      //tesselated data of the original glyph
  TessData dfrmData;      //tesselated data of the deformed glyph
  TessWord parent;        //parent word

  Rectangle2D.Float bounds;    //local bounds
  Rectangle2D.Float absBounds; //absolute bounds

  color clr;        //color
  color clrTarget;  //target color
  int clrRedStep, clrGreenStep, clrBlueStep, clrAlphaStep;  //fading speed
  
  //constructor
  public TessGlyph(TessWord parent, TextObjectGlyph glyph, int accuracy) {
    super(glyph.toString());
    
    //set parent
    this.parent = parent;
    
    //tesselate the glyph
    build(glyph, accuracy);
    
    //create empty bounds for now
    bounds = new Rectangle2D.Float();
    absBounds = new Rectangle2D.Float();
    
    //set color as unset
    clr = clrTarget = -1;    
  }
  
  //build the tesselated glyph
  public void build(TextObjectGlyph glyph, int accuracy) {
    //get the center of the glyph and use that as positoin
    PVector newPos = glyph.getPositionAbsolute();
    Rectangle gBounds = glyph.getLocalBoundingPolygon().getBounds();
    PVector gCenter = new PVector((float)gBounds.getCenterX(), (float)gBounds.getCenterY(), 0);
    newPos.add(gCenter);
    newPos.sub(parent.absPos());
    setPos(newPos);
    
    //tessalate text in original form
    origData = tesselate(glyph, accuracy);
    
    //offset the vertices so that they are relative to the glyph's position
    for(int j = 0; j < origData.types.length; j++) {
      //go through vertices
      for(int k = j==0?0:origData.ends[j-1]; k < origData.ends[j]; k++) {
        origData.vertices[k][0] -= gCenter.x;
        origData.vertices[k][1] -= gCenter.y;
      }
    }
    
    //clone to deformed data
    dfrmData = origData.clone();
  }
  
  //update the glyph
  public void update(long dt) {
    super.update(dt);
    
    //update color
    updateColor(dt);
  }
  
  //draw the glyph
  public void draw() {
    pushMatrix();
    translate(pos.x, pos.y, pos.z);
    rotate(ang);
    scale(sca);
    
    //keep track of bounding box
    float minX = MAX_FLOAT;
    float maxX = MIN_FLOAT;
    float minY = MAX_FLOAT;
    float maxY = MIN_FLOAT;
    
    //if we have deformed data then draw it
    if (dfrmData != null) {
      TessData data = dfrmData;
    
      //go through contours
      for(int j = 0; j < data.types.length; j++) {
        g.beginShape(data.types[j]);
        //go through vertices
        for(int k = j==0?0:data.ends[j-1]; k < data.ends[j]; k++) {
          if (data.vertices[k][0] < minX) minX = data.vertices[k][0];
          if (data.vertices[k][0] > maxX) maxX = data.vertices[k][0];
          if (data.vertices[k][1] < minY) minY = data.vertices[k][1];
          if (data.vertices[k][1] > maxY) maxY = data.vertices[k][1];
          
          g.vertex(data.vertices[k][0], data.vertices[k][1], data.vertices[k][2]);
        }
        g.endShape();  
      }
    }

    //update the bounds    
    bounds.setRect(minX, minY, maxX-minX, maxY-minY);

    //update the absolute screen bounds
    Polygon poly = new Polygon();
    poly.addPoint((int)screenX(minX, minY, 0), (int)screenY(minX, minY, 0));
    poly.addPoint((int)screenX(minX, maxY, 0), (int)screenY(minX, maxY, 0));
    poly.addPoint((int)screenX(maxX, maxY, 0), (int)screenY(maxX, maxY, 0));
    poly.addPoint((int)screenX(maxX, minY, 0), (int)screenY(maxX, minY, 0));

    absBounds.setRect(poly.getBounds());
    if (absBounds.width < 1) absBounds.width++;
    if (absBounds.height < 1) absBounds.height++;
   
    popMatrix();
  }
  
  //update color
  public void updateColor(long dt) {
    if (clr == clrTarget) return;
    
    //fade to target
    int diff;
    float delta;
    int direction;
    int newr = (int)red(clr);
    int newg = (int)green(clr);
    int newb = (int)blue(clr);
    int newa = (int)alpha(clr);
    
    diff = (int)(red(clrTarget) - red(clr));
    if (diff != 0) {
      delta = clrRedStep * dt;
      if (delta < 1) delta = 1;
      direction = diff < 0 ? -1 : 1;
      
      if (diff*direction < delta)
        newr = (int)red(clrTarget);
      else
        newr += delta*direction;
    }

    diff = (int)(green(clrTarget) - green(clr));
    if (diff != 0) {
      delta = clrGreenStep * dt;
      if (delta < 1) delta = 1;
      direction = diff < 0 ? -1 : 1;
      
      if (diff*direction < delta)
        newg = (int)green(clrTarget);
      else
        newg += delta*direction;
    }

    diff = (int)(blue(clrTarget) - blue(clr));
    if (diff != 0) {
      delta = clrBlueStep * dt;
      if (delta < 1) delta = 1;
      direction = diff < 0 ? -1 : 1;
      
      if (diff*direction < delta)
        newb = (int)blue(clrTarget);
      else
        newb += delta*direction;
    }
    
    diff = (int)(alpha(clrTarget) - alpha(clr));
    if (diff != 0) {
      delta = clrAlphaStep * dt;
      if (delta < 1) delta = 1;
      direction = diff < 0 ? -1 : 1;
      
      if (diff*direction < delta)
        newa = (int)alpha(clrTarget);
      else
        newa += delta*direction;
    }
    
    clr = color(newr, newg, newb, newa);
  }
  
  //set color
  public void setColor(color c) { clr = c; }
  
  //get color
  public color getColor() { return clr; }
  public boolean isColorSet() { return clr != -1; }
  
  //set the color to fade to
  public void fadeTo(color c) {
    if (c == clr) return;
    if (c == -1) { clr = 0; }
    
    clrRedStep = (int)((red(clrTarget) - red(clr)) / FADE_SPEED);
    if (clrRedStep < 0) clrRedStep *= -1;
    clrGreenStep = (int)((green(clrTarget) - green(clr)) / FADE_SPEED);
    if (clrGreenStep < 0) clrGreenStep *= -1;
    clrBlueStep = (int)((blue(clrTarget) - blue(clr)) / FADE_SPEED);
    if (clrBlueStep < 0) clrBlueStep *= -1;
    clrAlphaStep = (int)((alpha(clrTarget) - alpha(clr)) / FADE_SPEED);
    if (clrAlphaStep < 0) clrAlphaStep *= -1;
    clrTarget = c;
  }
  
  //draw the absolute bounds
  public void drawAbsoluteBounds() {
    rect(absBounds.x, absBounds.y, absBounds.width, absBounds.height);
  }
  
  //get the absolute position
  public PVector absPos() {
    if (parent == null) return pos.get();
    
    PVector newPos = pos.get();
    newPos.mult(parent.absScale());
    newPos.add(parent.absPos());
    return newPos;
  }
  
  //get the absolute scale
  public float absScale() {
    if (parent == null) return sca;
    
    return parent.absScale()*sca;
  }

  //fold the glyph so that it's in the middle of the sentence
  public void fold() {
    TessData data = dfrmData;
    
    for(int j = 0; j < data.types.length; j++)
      for(int k = j==0?0:data.ends[j-1]; k < data.ends[j]; k++)
        data.vertices[k][0] = -(parent.pos.x + pos.x);
  }
  
  //fold the glyph towards the middle of the sentence
  public void fold(long dt, float distance, float speed) {
    if (origData != null) {     
      //go through contours
      for(int j = 0; j < origData.types.length; j++) {
        //go through vertices
        for(int k = j==0?0:origData.ends[j-1]; k < origData.ends[j]; k++) {
          //get the distance between the original position and the middle of the sentence          
          float d = parent.pos.x + pos.x + origData.vertices[k][0];
          if (d < 0) d *= -1;
          
          //if the vertex is closer than the threshold distance
          //that affects vertices then attract vertex towards middle         
          if (d < distance) {
            float dx = -(parent.pos.x + pos.x) - dfrmData.vertices[k][0];
            float dy = 0;
            float dd = sqrt(dx*dx+dy*dy);
            
            if (dd < dt*speed) {
              dfrmData.vertices[k][0] += dx;
              dfrmData.vertices[k][1] += dy;
            }
            else {
              dfrmData.vertices[k][0] += dx/dd * dt * speed;
              dfrmData.vertices[k][1] += dy/dd * dt * speed;
            }
          }
        }
      }
    }
  }
  
  //unfold the glyph towards its original state
  public void unfold(long dt, float distance, float speed) {
    if (origData != null) {     
      //go through contours
      for(int j = 0; j < origData.types.length; j++) {
        //go through vertices
        for(int k = j==0?0:origData.ends[j-1]; k < origData.ends[j]; k++) {
          //get the distance between the original position and the middle of the sentence        
          float d = parent.pos.x + pos.x + origData.vertices[k][0];
          if (d < 0) d *= -1;
          
          //if the vertex is further than the threshold distance
          //that affects vertices then attract vertex towards its origin   
          if (d > distance) {              
            float dx = origData.vertices[k][0] - dfrmData.vertices[k][0];
            float dy = origData.vertices[k][1] - dfrmData.vertices[k][1];
            float dd = sqrt(dx*dx+dy*dy);
            
            if (dd < dt*speed) {
              dfrmData.vertices[k][0] += dx;
              dfrmData.vertices[k][1] += dy;
            }
            else {
              dfrmData.vertices[k][0] += dx/dd * dt * speed;
              dfrmData.vertices[k][1] += dy/dd * dt * speed;
            }
          }
        }
      }
    }
  }
  
  //make glyph wander around
  public void wander() {
    if (pos.dist(target) < WANDER_THRESHOLD) {
      float angle = random(0, TWO_PI);
      approach(pos.x+cos(angle)*backgroundGlyphWanderRange,
               height/2+sin(angle)*backgroundGlyphWanderRange,
               pos.z,
               backgroundGlyphWanderSpeed,
               WANDER_FRICTION);
    }
  }

  //check if glyph is outside bounds
  public boolean isOutside(Rectangle2D b) {
    return !b.intersects(absBounds);
  } 
  
  //get local bounds
  public Rectangle2D.Float getBounds() { return bounds; }
  
  //get absolute bounds
  public Rectangle2D.Float getAbsoluteBounds() { return absBounds; }
}
