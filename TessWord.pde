/**
 * Tessellated word object.
 */
public class TessWord extends KineticObject {
  //constants
  static final float WANDER_THRESHOLD = 1;              //proximity threshold for wander behavior to create a new target
  
  static final float EXTRACT_PUSH_STRENGTH = 4.0f;      //push strenght on glyphs when extracting the middle one
  static final float EXTRACT_PUSH_SPIN_MIN = PI/1024f;  //minimum spin
  static final float EXTRACT_PUSH_SPIN_MAX = PI/512f;   //maximum spin
  static final float EXTRACT_PUSH_ANGLE = PI/12f;       //push angle
  
  static final float BG_LETTER_SCALE_SPEED = 0.0004f;   //scaling speed of background glyphs
  static final float BG_LETTER_SCALE_FRICTION = 0.96f;  //scaling friction of background glyphs
  
  static final float FADE_SPEED = 5000;                 //fading speed when updating color
  
  ArrayList glyphs;      //array of glyphs
  TessSentence parent;   //parent sentence
  
  color clr;             //color
  color clrTarget;       //target color
  int clrRedStep, clrGreenStep, clrBlueStep, clrAlphaStep;  //step for fading color
  
  int extractGlyphIndex;
  
  //constructor
  public TessWord(TessSentence parent, TextObjectGroup root, int accuracy) {
    super();
    this.parent = parent;
    this.glyphs = new ArrayList();
    
    //tesselate the word
    build(root, accuracy);
    
    //set color as unset
    clr = clrTarget = -1;
    
    //set default angular friction
    angFriction = 0.998;
    
    extractGlyphIndex = -1;
  }
  
  //set glyph index for extraction
  public void setExtractIndex(int g) {
    extractGlyphIndex = g;
  }
  
  //get the index of the glyph to extract
  public int extractGlyphIndex() { return extractGlyphIndex; }
  
  //tessellate the word
  public void build(TextObjectGroup root, int accuracy) {
    PVector newPos = root.getCenter();
    newPos.sub(parent.absPos());
    setPos(newPos);

    TextObject to = root.getLeftMostChild();
    while(to != null) {
      if (to instanceof TextObjectGlyph && to.toString().compareTo(" ") != 0) {
        glyphs.add(new TessGlyph(this, (TextObjectGlyph)to, accuracy));
        
      }
      to = to.getRightSibling();
    }
  }
  
  //update
  public void update(long dt) {
    super.update(dt);
    
    //update color
    updateColor(dt);
    
    //update the glyphs
    Iterator it = glyphs.iterator();
    while(it.hasNext()) {
      ((TessGlyph)it.next()).update(dt);
    }     
  }
  
  //update color
  public void updateColor(long dt) {
    if (clr == clrTarget) return;
    
    //fade each color element
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
  
  //set the color
  public void setColor(color c) { clr = c; }
  
  //get the color
  public color getColor() { return clr; }
  
  //check if the color is set
  public boolean isColorSet() { return clr != -1; }
  
  //ask to fade the words to a given color
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

  //draw the word  
  public void draw() {
    pushMatrix();
    
    //transform
    translate(pos.x, pos.y, pos.z);
    rotate(ang);
    scale(sca);
    
    //draw glyphs
    Iterator it = glyphs.iterator();
    TessGlyph tg;
    while(it.hasNext()) {
      tg = (TessGlyph)it.next();
      tg.draw();
    }
    
    popMatrix();
  }
  
  //draw the absolute bounds
  public void drawAbsoluteBounds() {
    Rectangle2D bounds = getAbsoluteBounds();
    rect((float)bounds.getX(), (float)bounds.getY(), (float)bounds.getWidth(), (float)bounds.getHeight());
    
    Iterator it = glyphs.iterator();
    while(it.hasNext()) {
      ((TessGlyph)it.next()).drawAbsoluteBounds();
    }   
  }
  
  //fold the word completely
  public void fold() {
    Iterator it = glyphs.iterator();
    while(it.hasNext()) {
      ((TessGlyph)it.next()).fold();
    }  
  }
  
  //unfold the word
  public void unfold(long dt, float distance, float speed) {
    Iterator it = glyphs.iterator();
    while(it.hasNext()) {
      ((TessGlyph)it.next()).unfold(dt, distance, speed);
    }  
  }

  //fold the word
  public void fold(long dt, float distance, float speed) {
    Iterator it = glyphs.iterator();
    while(it.hasNext()) {
      ((TessGlyph)it.next()).fold(dt, distance, speed);
    }  
  }
  
  //make the word wander around
  public void wander() {
    if (pos.dist(target) < WANDER_THRESHOLD) {
      float angle = random(0, TWO_PI);
      approach(pos.x+cos(angle)*middleWordWanderRange,
               pos.y+sin(angle)*middleWordWanderRange,
               pos.z,
               middleWordWanderSpeed);
    }
  }
  
  //extract the glyph at the specified index and push the rest out
  public TessGlyph extract(int index) {
    //make sure the index is within bounds
    if (index < 0) return null;
    else if (index >= glyphs.size()) return null;
    
    //go over each glyph
    int i = 0;
    Iterator it = glyphs.iterator();
    TessGlyph extractedGlyph = null;
    TessGlyph glyph;
    while(it.hasNext()) {
      glyph = (TessGlyph)it.next();
      
      //if we have the glyph we are looking for, extract it
      if (i == index) {
        it.remove();
        extractedGlyph = glyph;
      }
      //if we are before the glyph, then push to the left
      else if (i < index) {
        float angle = random(PI-EXTRACT_PUSH_ANGLE, PI+EXTRACT_PUSH_ANGLE);
        glyph.push(cos(angle)*EXTRACT_PUSH_STRENGTH, sin(angle)*EXTRACT_PUSH_STRENGTH, -1);
        glyph.spin(random(-EXTRACT_PUSH_SPIN_MAX, -EXTRACT_PUSH_SPIN_MIN));
      }
      //if we are after the glyph, then push to the right
      else if (i > index) {
        float angle = random(-EXTRACT_PUSH_ANGLE, EXTRACT_PUSH_ANGLE);
        glyph.push(cos(angle)*EXTRACT_PUSH_STRENGTH, sin(angle)*EXTRACT_PUSH_STRENGTH, -1);
        glyph.spin(random(EXTRACT_PUSH_SPIN_MIN, -EXTRACT_PUSH_SPIN_MAX));
      }
      i++;
    }
    
    //set the new properties for the extracted glyph
    extractedGlyph.setPos(extractedGlyph.absPos());
    extractedGlyph.setScale(extractedGlyph.absScale());
    extractedGlyph.approachScale(backgroundGlyphScale, backgroundGlyphScaleSpeed, backgroundGlyphScaleFriction);
    extractedGlyph.setColor(getColor());
    extractedGlyph.fadeTo(createPaletteColor(backgroundGlyphOpacity, BACK));
    
    //detach
    extractedGlyph.parent = null;
    
    return extractedGlyph;
  }  
  
  //get glyph count
  public int glyphCount() { return glyphs.size(); }
  
  //check if the word is outside bounds
  public boolean isOutside(Rectangle2D b) {
    Iterator it = glyphs.iterator();
    while(it.hasNext()) {
      if (!((TessGlyph)it.next()).isOutside(b)) return false;
    }
    return true;
  }

  //get the absolute bounds
  public Rectangle2D getAbsoluteBounds() {
    Rectangle2D bnds = null;
    Iterator it = glyphs.iterator();
    TessGlyph tg;
    while(it.hasNext()) {
      tg = (TessGlyph)it.next();
      if (bnds == null) bnds = tg.getAbsoluteBounds();
      else bnds = bnds.createUnion(tg.getAbsoluteBounds()); 
    }
    return bnds;
  }  
}
