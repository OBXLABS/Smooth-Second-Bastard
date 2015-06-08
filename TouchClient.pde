/**
 * Touchscreen client.
 */
public class TouchClient extends PQMTClient {
   
  // Create the listener list
  protected TouchDelegate delegate = null; 

  /**
   * Constructor.
   */
  public TouchClient() {
    try {
      init();
    } catch (Exception e) {
      println("Exception thrown during touch client initialization: " + e.getMessage());
    }
  }

  /**
   * Connect to server and setup client request type
   **/
  public int init() throws Exception {
    int err_code = PQMTClientConstant.PQ_MT_SUCESS;
    try{
      if((err_code = ConnectServer()) != PQMTClientConstant.PQ_MT_SUCESS)
      {
        JOptionPane.showMessageDialog(null, "connect server fail, socket error code:"+err_code);
        return err_code;
      }
    } catch(ConnectException ex){
      JOptionPane.showMessageDialog(null, "Please Run the PQLabs MultiTouch Platform(Server) first.");
      return err_code;
    }
  		
    TouchClientRequest clientRequest = new TouchClientRequest();
    clientRequest.app_id = GetTrialAppID();
  	
    try {
      clientRequest.type = PQMTClientConstant.RQST_RAWDATA_ALL/* | PQMTClientConstant.RQST_GESTURE_ALL*/;
      if((err_code = SendRequest(clientRequest)) != PQMTClientConstant.PQ_MT_SUCESS)
      {
        JOptionPane.showMessageDialog(null, "send request  fail,  error code:"+err_code);
        return err_code;
      }
      if((err_code=GetServerResolution()) != PQMTClientConstant.PQ_MT_SUCESS)
      {
        JOptionPane.showMessageDialog(null, "get server resolution fail,  error code:"+err_code);
        return err_code;
      }
      System.out.println("connected, start receive:"+err_code);
    } catch(Exception ex){
      JOptionPane.showMessageDialog(null, ex.getMessage());
    }
    return err_code;
  }
  
  public int OnTouchFrame(int frame_id, int time_stamp, Vector/*<TouchPoint>*/ point_list) {
    if (delegate != null)
      return delegate.OnTouchFrame(frame_id, time_stamp, point_list);
      
    return PQMTClientConstant.PQ_MT_SUCESS;  
  }
  
  /** Set the delegate. */
  public void setDelegate(TouchDelegate tg) {
    delegate = tg;
  }
}
