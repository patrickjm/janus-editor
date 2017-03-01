module clipped.point2d;

/**
 * Simple class for storing 2D coordinates, mimicing the java.awt.Point2D class.
 * @author dlegland
 *
 */
public class Point2D {
	
	double x;
	double y;
	
	public this(double x = 0, double y = 0) {
		this.x = x;
		this.y = y;
	}
	
	public double getX() {
		return this.x;
	}
	
	public double getY() {
		return this.y;
	}
}
