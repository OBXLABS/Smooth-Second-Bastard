/**
 * A tesselated sentence.
 */
public class TessSentence extends KineticObject { 
  //constants
  static final float APPROACH_SPEED = 3f;              //speed to approach to touch
  static final int APPROACH_THRESHOLD = 20;            //approach threshold distance (hit distance)  
  static final float UNFOLD_REPEAT = 8;                //number of times the unfold method is called per frame
  static final float UNFOLD_SPEED_DECAY = 1;//0.975f;      //speed decay of unfolding behaviour
  static final float FOLD_REPEAT = 8;                  //number of times the fold method is called per frame
  static final float FOLD_SPEED_DECAY = 1;//0.99f;         //speed decay of folding behaviour
  
  static final float EXTRACT_PUSH_STRENGTH = 5.0f;     //push strength on words when extracting the middle one
  static final float EXTRACT_PUSH_SPIN_MIN = PI/512f;  //minimum spin push
  static final float EXTRACT_PUSH_SPIN_MAX = PI/256f;  //maximum spin push
  static final float EXTRACT_PUSH_ANGLE = PI/8f;       //maximum push angle
  
  static final float CTRL_PT_FRICTION = 0.8;           //friction of control points
  static final float CTRL_PT_SPEED = 8;                //speed of control points
  
  static final float SNAP_FRICTION = 0.75;             //friction of control points when snapping
  static final float SNAP_SPEED = 6;                   //speed of snapping control points

  //sentence states  
  static final int IDLE = 0;                           //idle state, nothing to do
  static final int FOLD = 1;                           //folding
  static final int UNFOLD = 2;                         //unfolding
  static final int SNAP = 3;                           //snapping
  static final int EXTRACT = 4;                        //extracting
  
  int state = IDLE;                 //default state

  ArrayList words;                  //array of words
  color clr;                        //sentence color
  
  //unfolding attributes
  float unfoldSpeed = 125/1000f; //px/ms
  float unfoldFriction = 0.98f;
  
  //folding attributes
  float foldSpeed = 125/1000f; //px/ms
  float foldFriction = 0.98f;

  //folding/unfolding threshold
  float foldWidth = MAX_INT;
  float origFoldWidth = MAX_INT;

  //string attributes
  float stringWidth = MAX_INT;
  float stringHeight = MAX_INT;
  
  //control points
  HashMap ctrlPts = new HashMap();
  int middleGlyph = 0;  //index of the middle glyph (set when setting control point)
  
  int extractWordIndex;
  
  //constructor
  public TessSentence(TextObjectGroup root, int accuracyLow, int accuracyHigh) {
    super();
    words = new ArrayList();
    clr = color(0);

    //build tesselated sentence
    build(root, accuracyLow, accuracyHigh);
    
    //set defaults
    stringHeight = (float)root.getBounds().getHeight();
    stringWidth = (float)root.getBounds().getWidth();
    origFoldWidth = stringWidth/2 + 50;
    foldWidth = origFoldWidth;
    unfoldSpeed = 0.5f;//(foldWidth * 2) / 1000f;
    foldSpeed = unfoldSpeed * 2;    
    friction = 0.80;    
    
    extractWordIndex = -1;
  }
  
  //set the word and glyph index for extraction
  public void setExtractIndexes(int w, int g) {
    extractWordIndex = w;
    ((TessWord)words.get(w)).setExtractIndex(g);
  }
  
  //set a control point
  public void setCtrlPoint(int id, int x, int y) {
    Integer iid = new Integer(id);
    KineticObject pt = (KineticObject)ctrlPts.get(iid);
    
    //if there is no control point for this touch id
    //then we need to create one
    if (pt == null) {
      
      //if we already have two control points then do nothing
      if (ctrlPts.size() >= 2) return;
      
      KineticObject ko = new KineticObject();
      ko.friction = CTRL_PT_FRICTION;

      //if it's the first control point then
      //we can set it at the touch location
      if (ctrlPts.size() == 0) {      
        ko.setPos(x, y, 0);
      }     
      //but if it's not the first, then it needs to
      //be set at the location of the first and approach
      //the touch location
      else {
        KineticObject ctrlPt1 = null;
        synchronized(ctrlPts) {
          Iterator ids = ctrlPts.keySet().iterator();
          ctrlPt1 = (KineticObject)ctrlPts.get((Integer)ids.next());
        }
        ko.setPos(ctrlPt1.pos);
        ko.approach(x, y, 0, CTRL_PT_SPEED);
        
        //set the middle glyph to know where to split when drawing
        middleGlyph = glyphCount()/2;
      }
      
      //add it to the list
      synchronized(ctrlPts) {
        ctrlPts.put(iid, ko);
      }
      
    }
    else {
      pt.approach(x, y, 0, CTRL_PT_SPEED);
    }
  }
  
  //update sentence
  public void update(long dt) {
    super.update(dt);

    //unfold, fold, or snap based on state 
    switch(state) {
      case UNFOLD:
        unfold(1000/60);
        updateCtrlPts();
        break;
      case FOLD:
        fold(1000/60);
        updateCtrlPts();
        break;
      case SNAP:
        snap(dt);
        updateCtrlPts();
        break;
    }
    
    //update words
    Iterator it = words.iterator();
    while(it.hasNext()) {
      ((TessWord)it.next()).update(dt);
    }     
  }  
  
  //udpate control points
  public void updateCtrlPts() {
    synchronized(ctrlPts) {
      Iterator ids = ctrlPts.keySet().iterator();
      while(ids.hasNext())
        ((KineticObject)ctrlPts.get((Integer)ids.next())).update(dt);
    }
  }
  
  //set color
  public void setColor(color c) { clr = c; }
  
  //get color
  public color getColor() { return clr; }
  
  //set state
  public void setState(int s) { state = s; }
  
  //get state
  public int getState() { return state; }
  
  //get word count
  public int wordCount() { return words.size(); }
  
  //get glyph count
  public int glyphCount() {
    int total = 0;
    Iterator it = words.iterator();
    while(it.hasNext()) {
      total += ((TessWord)it.next()).glyphCount();
    }
    return total;
  }
  
  //extract the sentence's middle word
  public TessWord extract(int index) {
    //make sure the index is within bounds
    if (index < 0) return null;
    else if (index >= words.size()) return null;
    
    //go through the words
    int i = 0;
    Iterator it = words.iterator();
    TessWord extractedWord = null;
    TessWord word;
    while(it.hasNext()) {
      word = (TessWord)it.next();
      //if we reached the word to extract, then extract it
      if (i == index) {
        it.remove();
        word.parent = null;
        extractedWord = word;
      }
      //if we are before the word we are looking for, push to the left
      else if (i < index) {
        float angle = random(PI-EXTRACT_PUSH_ANGLE, PI+EXTRACT_PUSH_ANGLE);
        word.push(cos(angle)*EXTRACT_PUSH_STRENGTH, sin(angle)*EXTRACT_PUSH_STRENGTH, 0);
        word.spin(random(-EXTRACT_PUSH_SPIN_MAX, -EXTRACT_PUSH_SPIN_MIN));
      }
      //if after, push to the right
      else if (i > index) {
        float angle = random(-EXTRACT_PUSH_ANGLE, EXTRACT_PUSH_ANGLE);
        word.push(cos(angle)*EXTRACT_PUSH_STRENGTH, sin(angle)*EXTRACT_PUSH_STRENGTH, 0);
        word.spin(random(EXTRACT_PUSH_SPIN_MIN, -EXTRACT_PUSH_SPIN_MAX));
      }
      i++;
    }

    //set the sentences position where the control points snapped
    Iterator ids = null;
    KineticObject ctrlPt1 = null;
    synchronized(ctrlPts) {
      ids = ctrlPts.keySet().iterator();
      ctrlPt1 = (KineticObject)ctrlPts.get((Integer)ids.next());
      ctrlPt1.acc.set(0, 0, 0);
      ctrlPt1.vel.set(0, 0, 0);
    }
    
    //remove the second control point
    if (ids.hasNext()) {
      ids.next();
      ids.remove();
    }

    //set the new properties for the extracted word
    extractedWord.moveBy(pos.x + ctrlPt1.pos.x, pos.y + ctrlPt1.pos.y, pos.z + ctrlPt1.pos.z);
    extractedWord.push(0, -0.5, 0);
    extractedWord.approachScale(middleWordScale, middleWordScaleSpeed, middleWordScaleFriction);
    extractedWord.setColor(getColor());
    extractedWord.fadeTo(createPaletteColor(middleWordOpacity, MIDDLE));
    return extractedWord;
  }
  
  //decrease the folding radius
  void decFoldRadius(long dt) {
    if (foldWidth == 0) return;
    
    foldWidth -= dt * unfoldSpeed/UNFOLD_REPEAT;
    if (foldWidth < 0) foldWidth = 0;
  }
 
  //increase the folding radius
  void incFoldRadius(long dt) {
    if (foldWidth == origFoldWidth) return;
    
    foldWidth += dt * foldSpeed/FOLD_REPEAT;
    if (foldWidth > origFoldWidth) foldWidth = origFoldWidth;
  }

  //approach towards x,y point
  void approach(float x, float y) {
    //calculate distance to point                           
    float dx = x - screenPos.x;
    float dy = y - screenPos.y;   
    float d = sqrt(dx*dx + dy*dy);
    
    if (d > APPROACH_THRESHOLD) {
      acc.x += dx/d * APPROACH_SPEED;
      acc.y += dy/d * APPROACH_SPEED;
    }
  } 
  
  //check if the sentence is done unfolding
  public boolean isUnfolded() { return foldWidth == 0; }
  
  //check if the sentence is done folding
  public boolean isFolded() { return foldWidth == origFoldWidth; }
  
  //check if the sentence is done snapping
  public boolean isSnapped() { 
    if (ctrlPts.size() < 2) return true;
    
    KineticObject ctrlPt1 = null;
    KineticObject ctrlPt2 = null;
    synchronized(ctrlPts) {
      Iterator ids = ctrlPts.keySet().iterator();
      ctrlPt1 = (KineticObject)ctrlPts.get((Integer)ids.next());
      ctrlPt2 = (KineticObject)ctrlPts.get((Integer)ids.next());
    }
      
    return (ctrlPt1.pos.dist(ctrlPt2.pos) < 4);
  }

  //unfold the sentence
  public  void unfold(long dt) {
    for(int i = 0; i < UNFOLD_REPEAT; i++) {
      Iterator it = words.iterator();
      TessWord word;
      while(it.hasNext()) {
        word = (TessWord)it.next();
        word.unfold(dt, foldWidth, unfoldSpeed/UNFOLD_REPEAT);
      } 
      decFoldRadius(dt);
    }

    if (unfoldSpeed/UNFOLD_REPEAT > 2/1000f)
      unfoldSpeed *= UNFOLD_SPEED_DECAY;
  }

  //fold sentence complete 
  public void fold() {
     Iterator it = words.iterator();
     while(it.hasNext()) {
       ((TessWord)it.next()).fold();
     }  
   }
 
  //fold sentence
  public void fold(long dt) {
    for(int i = 0; i < FOLD_REPEAT; i++) {
      Iterator it = words.iterator();
      TessWord word;
      while(it.hasNext()) {
        word = (TessWord)it.next();
        word.fold(dt, foldWidth, foldSpeed/FOLD_REPEAT);
      } 
      incFoldRadius(dt);
    }

    if (foldSpeed/FOLD_REPEAT > 2/1000f)
      foldSpeed *= FOLD_SPEED_DECAY;
  }
 
  //get the sentence's center point (middle of two control point)
  public PVector getCenterPt() {
    if (ctrlPts.size() == 0) return pos.get();
    else if (ctrlPts.size() == 1) {
      KineticObject ctrlPt1 = null;
      synchronized(ctrlPts) {
        Iterator ids = ctrlPts.keySet().iterator();
        ctrlPt1 = (KineticObject)ctrlPts.get((Integer)ids.next());
      }
      return ctrlPt1.pos.get();
    }
    else if (ctrlPts.size() == 2) {
      KineticObject ctrlPt1 = null;
      KineticObject ctrlPt2 = null;
      synchronized(ctrlPts) {
        Iterator ids = ctrlPts.keySet().iterator();
        ctrlPt1 = (KineticObject)ctrlPts.get((Integer)ids.next());
        ctrlPt2 = (KineticObject)ctrlPts.get((Integer)ids.next());
      }
      return new PVector((ctrlPt1.pos.x + ctrlPt2.pos.x)/2, (ctrlPt1.pos.y + ctrlPt2.pos.y)/2, 0);
    }
    
    return null;
  }
 
  //snap sentence (bring control points together)
  public void snap(long dt) { 
    if (ctrlPts.size() < 2) return; 
    
    //get control points
    KineticObject ctrlPt1 = null;
    KineticObject ctrlPt2 = null;
    synchronized(ctrlPts) {
      Iterator ids = ctrlPts.keySet().iterator();
      ctrlPt1 = (KineticObject)ctrlPts.get((Integer)ids.next());
      ctrlPt2 = (KineticObject)ctrlPts.get((Integer)ids.next());
    }
      
    //if the control points are already really close, then we're done
    if (ctrlPt1.pos.dist(ctrlPt2.pos) < 4) return;
      
    //bring them closer
    PVector target = new PVector((ctrlPt1.pos.x + ctrlPt2.pos.x)/2, (ctrlPt1.pos.y + ctrlPt2.pos.y)/2, 0);
    ctrlPt1.friction = ctrlPt2.friction = SNAP_FRICTION;
    ctrlPt1.approach(target.x, target.y, target.z, SNAP_SPEED);
    ctrlPt2.approach(target.x, target.y, target.z, SNAP_SPEED);
  }
 
  //get the absolute position
  public PVector absPos() { return pos.get(); }
  
  //get the absolute scale
  public float absScale() { return sca; }
   
  //draw
  void draw() {
    //we need at least one control point to draw
    if (ctrlPts.size() == 0) return;
    
    //if there is less than 2 control points,
    //then we are drawing the whole sentence in one place
    if (ctrlPts.size() < 2) {
      //get the control point
      KineticObject ctrlPt1 = null;
      synchronized(ctrlPts) {
        Iterator ids = ctrlPts.keySet().iterator();
        ctrlPt1 = (KineticObject)ctrlPts.get((Integer)ids.next());
      }

      //transform
      pushMatrix();
      translate(pos.x, pos.y, pos.z);
      translate(ctrlPt1.pos.x, ctrlPt1.pos.y, ctrlPt1.pos.z);
      rotate(ang);
      
      //track screen position
      screenPos.x = screenX(0, 0, 0);
      screenPos.y = screenY(0, 0, 0);
      
      //draw words
      Iterator it = words.iterator();
      TessWord tw;
      while(it.hasNext()) {
        tw = (TessWord)it.next();
        if (tw.isColorSet()) fill(tw.getColor());
        tw.draw();
      }
      
      //debug
      if (DEBUG) {
        if (foldWidth < MAX_INT) {
          noFill();
          stroke(0, 255, 0);
          line(foldWidth, -stringHeight/2, foldWidth, stringHeight/2);
          line(-foldWidth, -stringHeight/2, -foldWidth, stringHeight/2);
        }
      }
  
      popMatrix();    
    }
    //if we are two control points, then draw the halves separately
    else {
      //get the control points
      KineticObject ctrlPt1 = null;
      KineticObject ctrlPt2 = null;
      synchronized(ctrlPts) {
        Iterator ids = ctrlPts.keySet().iterator();
        ctrlPt1 = (KineticObject)ctrlPts.get((Integer)ids.next());
        ctrlPt2 = (KineticObject)ctrlPts.get((Integer)ids.next());
      }
      
      //tranform      
      pushMatrix();
      translate(pos.x, pos.y, pos.z);
      rotate(ang);
      
      //draw the words
      Iterator it = words.iterator();
      TessWord tw;
      int count = 0;
      while(it.hasNext()) {
        tw = (TessWord)it.next();
        if (tw.isColorSet()) fill(tw.getColor());
          
        //tw.draw();
        pushMatrix();
    
        translate(tw.pos.x, tw.pos.y, tw.pos.z);
        rotate(tw.ang);
        scale(tw.sca);
        
        Iterator git = tw.glyphs.iterator();
        TessGlyph tg;

        //if we are in the first half, use the first control point
        while(git.hasNext() && count <= middleGlyph) {
          tg = (TessGlyph)git.next();
          
          pushMatrix();    
          translate(ctrlPt1.pos.x, ctrlPt1.pos.y, ctrlPt1.pos.z);            
          tg.draw();
          popMatrix();
          
          count++;
        }
        
        //in the second half, use the second control point
        while(git.hasNext()) {
          tg = (TessGlyph)git.next();
          pushMatrix();    
          translate(ctrlPt2.pos.x, ctrlPt2.pos.y, ctrlPt2.pos.z);            
          tg.draw();
          popMatrix();
        }
        
        popMatrix();
      }
      popMatrix();
    }
  } 
  
  //build the tesselated sentence
  public void build(TextObjectGroup root, int accuracyLow, int accuracyHigh) {
    pos.set(root.getCenter());
    
    //count how many glyphs there are in this group
    TextObjectGlyphIterator it = root.glyphIterator();
    TextObjectGlyph glyph;
    int totalCount = 0;
    while(it.hasNext()) {
      glyph = (TextObjectGlyph)it.next();
      totalCount++;
    }
    
    //find the point of the word that contains the middle glyph
    it = root.glyphIterator();
    TextObjectGroup middleWord = null;
    int count = 0;
    while(it.hasNext()) {
      glyph = (TextObjectGlyph)it.next();
      if (count > totalCount/2) {
        middleWord = glyph.getParent();
        break;
      }
      count++;
    }

    //build the sentence, and assign a higher tesselation detail to the middle word    
    TextObject to = root.getLeftMostChild();
    while(to != null) {
      if (to instanceof TextObjectGroup && to.toString().compareTo(" ") != 0)
        if (to == middleWord)
          words.add(new TessWord(this, (TextObjectGroup)to, accuracyHigh));
        else
          words.add(new TessWord(this, (TextObjectGroup)to, accuracyLow));
          
      to = to.getRightSibling();      
    }
  }

  //check if the sentence is outside bounds
  public boolean isOutside(Rectangle2D b) {
    Iterator it = words.iterator();
    while(it.hasNext()) {
      if (!((TessWord)it.next()).isOutside(b)) return false;
    }
    return true;
  }  

  //draw the absolute bounds
  public void drawAbsoluteBounds() {
    Rectangle2D bounds = getAbsoluteBounds();
    rect((float)bounds.getX(), (float)bounds.getY(), (float)bounds.getWidth(), (float)bounds.getHeight());
    
    Iterator it = words.iterator();
    while(it.hasNext()) {
      ((TessWord)it.next()).drawAbsoluteBounds();
    }    
  }

  //get absolute bounds
  public Rectangle2D getAbsoluteBounds() {
    Rectangle2D bnds = null;
    Iterator it = words.iterator();
    TessWord tw;
    while(it.hasNext()) {
      tw = (TessWord)it.next();
      if (bnds == null) bnds = tw.getAbsoluteBounds();
      else bnds = bnds.createUnion(tw.getAbsoluteBounds());
    }
    return bnds;
  }
  
  //get the index of the word with the middle glyph
  public int extractWordIndex() {
    /*int glyphCount = glyphCount();
    int halfTotal = glyphCount%2 == 0 ? glyphCount/2-1 : glyphCount/2;
    //int halfTotal = glyphCount()/2;
    int count = 0;
    int index = 0;
    
    Iterator it = words.iterator();
    while(it.hasNext()) {
      count += ((TessWord)it.next()).glyphCount();
      if (count > halfTotal) return index;
      index++;
    }

    return wordCount()-1;
    */
    return extractWordIndex;
  }
}
