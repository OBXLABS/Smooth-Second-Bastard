/**
 * A spotlight with kinetic properties.
 
  Copyright (C) <2015>  <Jason Lewis>
  
    This program is free software: you can redistribute it and/or modify
    it under the terms of the BSD 3 clause with added Attribution clause license.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   BSD 3 clause with added Attribution clause License for more details.
 */
public class Spot extends KineticObject {
  color clr;  //color
  
  //constructor
  public Spot(color c, PVector pos) {
    clr = c;
    setPos(pos);
  }
  
  //lighten the color up to a maximum
  public void lighten(int c, int maximum) {
    int r = (int)(red(clr) + c);
    if (r > maximum) r = maximum;

    int g = (int)(green(clr) + c);
    if (g > maximum) g = maximum;

    int b = (int)(blue(clr) + c);
    if (b > maximum) b = maximum;
    
    clr = color(r, g, b);
  }
  
  //darken the color up to a minimum
  public void darken(int c, int minimum) {
    int r = (int)(red(clr) - c);
    if (r < minimum) r = minimum;

    int g = (int)(green(clr) - c);
    if (g < minimum) g = minimum;

    int b = (int)(blue(clr) - c);
    if (b < minimum) b = minimum;
    
    clr = color(r, g, b);
  }
  
  //show the spotlight
  public void show(PVector dir, float angle, float concentration) {
    spotLight(red(clr), green(clr), blue(clr), pos.x, pos.y, pos.z, dir.x, dir.y, dir.z, angle, concentration);  
    
    if (DEBUG) {
      noFill();
      stroke(0, 255, 0);
      ellipse(pos.x, pos.y, red(clr)+10, red(clr)+10);
    }
  }
}
