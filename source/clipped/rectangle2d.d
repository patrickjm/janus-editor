/**
 * 
 */
module clipped.rectangle2d;

import clipped;

/**
 * @author dlegland
 *
 */
public class Rectangle2D {
	
	double x;
	double y;
	double width;
	double height;
	
	public this(double x = 0, double y = 0, double width = 0, double height = 0) {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}
	
	public double getX() {
		return this.x;
	}
	
	public double getY() {
		return this.y;
	}
	
	/**
	 * @return the width
	 */
	public double getWidth() {
		return width;
	}
	
	/**
	 * @return the height
	 */
	public double getHeight() {
		return height;
	}
	
	public double getMinX() {
		return x;
	}
	
	public double getMaxX() {
		return x + width;
	}
	
	public double getMinY() {
		return y;
	}
	
	public double getMaxY() {
		return y + height;
	}
}
