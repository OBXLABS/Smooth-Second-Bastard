package TestPQMTClient;

import java.awt.*;
import java.awt.geom.AffineTransform;
import java.awt.image.AffineTransformOp;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

import javax.imageio.ImageIO;



public class ImageDrawingComponent extends Component {
	BufferedImage img;
	Graphics2D g2;
	public ImageDrawingComponent()
	{
		try {
			isToMove = false;
			location = new Point();
			img=ImageIO.read(new File("test.jpg"));
		} catch (IOException e) {
			e.printStackTrace();
		}
		currentRate=1;
	}
	public void paint(Graphics g)
	{
		g2=(Graphics2D)g;
		
        AffineTransform at = AffineTransform.getScaleInstance(currentRate, currentRate);
          g2.drawImage(img, at, null);
		
	}
	public void resize(double rate)
	{
		currentRate*=rate;
	}
	public void startMove(int x, int y)
	{
		isToMove = true;
		location.x = x;
		location.y = y;
	}
	public void touchmove(int x, int y)
	{
		if(!isToMove) return;
		int dx = x - location.x;
		int dy = y - location.y;
		Point currentLocation = this.getLocation();
		currentLocation.x += dx;
		currentLocation.y += dy;
		this.setLocation(currentLocation);
		location.x = x;
		location.y = y;
	}
	public void stopMove()
	{
		isToMove = false;
	}
	private double currentRate;
	private Point location;
	private boolean isToMove;
}
