/**
 * A string with physical motion.
 */
public class KineticString extends KineticObject {
  String string;  //the string
  int group;      //group id

  //constructor  
  public KineticString(String s) {
    super();
    
    string = s;
    group = -1;
  }
}
