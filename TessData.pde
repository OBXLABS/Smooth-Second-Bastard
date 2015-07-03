/**
 * Tesselation data for one polygon
 
  Copyright (C) <2015>  <Jason Lewis>
  
    This program is free software: you can redistribute it and/or modify
    it under the terms of the BSD 3 clause with added Attribution clause license.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   BSD 3 clause with added Attribution clause License for more details.
 */
public class TessData { 
  int[] types;        //types of tesselated shape
  int[] ends;         //index of end vertices
  float[][] vertices; //array of vertices
  color stroke;       //stroke color
  color fill;         //fill color
  
  /** Default constructor. */
  public TessData() {}
  
  /** Constructor. */
  public TessData(ArrayList t, ArrayList e, ArrayList v) {
    //copy types
    types = new int[t.size()];
    for(int i = 0; i < t.size(); i++)
      types[i] = ((Integer)t.get(i)).intValue();

    //copy ends
    ends = new int[e.size()];
    for(int i = 0; i < e.size(); i++)
      ends[i] = ((Integer)e.get(i)).intValue();

    //copy vertices
    vertices = new float[v.size()][3];
    for(int i = 0; i < v.size(); i++) {
      double[] d = (double[])v.get(i);
      vertices[i][0] = (float)d[0];
      vertices[i][1] = (float)d[1];
      vertices[i][2] = (float)d[2];
    }
  }
  
  /** Clone. */
  public TessData clone() {
    TessData clone = new TessData();
    clone.types = new int[this.types.length];
    for(int i = 0; i < clone.types.length; i++)
      clone.types[i] = this.types[i];

    clone.ends = new int[this.ends.length];
    for(int i = 0; i < clone.ends.length; i++)
      clone.ends[i] = this.ends[i];

    clone.vertices = new float[this.vertices.length][3];
    for(int i = 0; i < clone.vertices.length; i++) {
      clone.vertices[i][0] = this.vertices[i][0];   
      clone.vertices[i][1] = this.vertices[i][1];   
      clone.vertices[i][2] = this.vertices[i][2];   
    }
    
    clone.stroke = this.stroke;
    clone.fill = this.fill;
    
    return clone;
  }
  
  /** Translate. */
  public void translate(PVector offset) {
    for(int i = 0; i < vertices.length; i++) {
      vertices[i][0] += offset.x;
      vertices[i][1] += offset.y;
      vertices[i][2] += offset.z;
    }
  }
}

