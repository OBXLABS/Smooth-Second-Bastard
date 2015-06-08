/**
 * An object that has motion and kinetic properties.
 * It can move around, rotate and scale.
 */
public class KineticObject {
  long age;          //age in millis
  boolean dead;      //true if the object is dead
  
  PVector pos;       //position
  PVector vel;       //velocity
  PVector acc;       //acceleration 
  float friction;    //friction
  PVector target;    //target
  float speed;       //speed

  float angAcc;      //angular acceleration
  float angVel;      //angular velocity
  float ang;         //angle/forward direction
  float angFriction; //angular friction
  
  float sca;         //scale factor
  float scaAcc;      //scale acceleration
  float scaVel;      //scale velocity
  float scaTarget;   //target scale factor
  float scaSpeed;    //scale speed
  float scaFriction; //scale firction
  
  PVector screenPos = new PVector();    //screen position (updated in the draw function)
  
  //constructor
  public KineticObject() {
    age = 0;
    dead = false;
    
    pos = new PVector();
    acc = new PVector();
    vel = new PVector();
    target = new PVector();

    ang = 0;
    angAcc = 0;
    angVel = 0;
    
    scaTarget = sca = 1;
    scaAcc = scaVel = 0;
    scaSpeed = 0;
    scaFriction = 0;
    
    //default to no friction
    friction = 1;
    angFriction = 1;
  }
  
  //update
  public void update(long dt) {
    //grow old
    age += dt;
    
    //apply motion
    updatePosition();
    
    //apply rotation
    updateRotation();
    
    //apply scale
    updateScale();
  }

  //move
  public void updatePosition() {
    //approach target
    if (pos.dist(target) != 0) {
      PVector diff = target.get();
      diff.sub(pos);
      if (diff.mag() > speed) {
        diff.div(diff.mag());
        diff.mult(speed);
        acc.add(diff);
      }
      else {
        //apply friction
        vel.mult(friction);   
        pos.set(target);
      }
    }

    //apply acceleration   
    vel.add(acc);
    acc.set(0, 0, 0);
    
    //apply friction
    vel.mult(friction);   
      
    //apply velocity
    pos.add(vel);   
  }
  
  //rotate
  public void updateRotation() {
    //apply angular acceleration
    angVel += angAcc;
    angAcc = 0;
    
    //apply friction
    angVel *= angFriction; 
    
    //apply angular velocity
    ang += angVel;    
  }
  
  //scale
  public void updateScale() {
    //if we reached the scale target, then do nothing
    if (scaTarget == sca) return;
    
    //scale towards target
    float diff = scaTarget - sca;
    int dir = diff < 0 ? -1 : 1;
    scaAcc = diff/(dir*diff)*scaSpeed;
    scaVel += scaAcc;
    scaAcc = 0;
    
    if (diff*dir < scaSpeed)
      sca = scaTarget;
    else
      sca += scaVel;
      
    //apply friction    
    scaVel *= scaFriction;
  }
  
  //approach a scale factor at a given speed
  public void approachScale(float target, float speed, float friction) {
    scaTarget = target;
    scaSpeed = speed;
    scaFriction = friction;
  }
  
  //set the scale factor
  public void setScale(float s) {
    scaTarget = sca = s;
  }
  
  //get the scale factor
  public float getScale() { return sca; }
  
  //apply force
  public void push(float x, float y, float z) {
    acc.x += x;
    acc.y += y;
    acc.z += z;
    target.set(pos);
  }
  
  //apply force
  public void push(PVector v) {
    acc.x += v.x;
    acc.y += v.y;
    acc.z += v.z;
    target.set(pos);
  }
  
  //apply angular force
  public void spin(float f) {
    angAcc += f;
  }
  
  //set position
  public void setPos(PVector v) {
    pos.set(v.x, v.y, v.z);
    target.set(pos);
  }
  
  //set position
  public void setPos(float x, float y, float z) {
    //pos.x = x; pos.y = y; pos.z = z;
    pos.set(x, y, z);
    target.set(pos);
  }
  
  //translate
  public void moveBy(PVector v) {
    pos.x += v.x; pos.y += v.y; pos.z += v.z;
    target.set(pos);
  }
  
  //translate
  public void moveBy(float x, float y, float z) {
    pos.x += x; pos.y += y; pos.z += z;
    target.set(pos);
  }

  //approach position
  public void approach(float x, float y, float z, float s) {
    target.set(x, y, z);
    speed = s;
  }

  //approach position
  public void approach(float x, float y, float z, float s, float f) {
    approach(x, y, z, s);
    friction = f;
  }
  
  //set friction
  public void setFriction(float f, float af) {
    friction = f;
    angFriction = af;
  }
  
  //get age
  public long age() { return age; }
  
  //kill object
  public void kill() { 
    dead = true;
    angAcc = angVel = 0;
    acc.set(0, 0, 0);
    vel.set(0, 0, 0);
    age = 0;
  }
  
  //check if we're dead
  public boolean isDead() { return dead; } 
}
