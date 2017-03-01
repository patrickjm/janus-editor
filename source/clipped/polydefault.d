/*
 * This license does NOT supersede the original license of GPC.  Please see:
 * http://www.cs.man.ac.uk/~toby/alan/software/#Licensing
 *
 * The SEI Software Open Source License, Version 1.0
 *
 * Copyright (c) 2004, Solution Engineering, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. The end-user documentation included with the redistribution,
 *    if any, must include the following acknowledgment:
 *       "This product includes software developed by the
 *        Solution Engineering, Inc. (http://www.seisw.com/)."
 *    Alternately, this acknowledgment may appear in the software itself,
 *    if and wherever such third-party acknowledgments normally appear.
 *
 * 3. The name "Solution Engineering" must not be used to endorse or
 *    promote products derived from this software without prior
 *    written permission. For written permission, please contact
 *    admin@seisw.com.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL SOLUTION ENGINEERING, INC. OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 * USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * ====================================================================
 */

module clipped.polydefault;

import clipped;

/**
 * <code>PolyDefault</code> is a default <code>Poly</code> implementation.
 * It provides support for both complex and simple polygons.  A <i>complex polygon</i>
 * is a polygon that consists of more than one polygon.  A <i>simple polygon</i> is a
 * more traditional polygon that contains of one inner polygon and is just a
 * collection of points.
 * <p>
 * <b>Implementation Note:</b> If a point is added to an empty <code>PolyDefault</code>
 * object, it will create an inner polygon of type <code>PolySimple</code>.
 *
 * @see PolySimple
 *
 * @author  Dan Bridenbecker, Solution Engineering, Inc.
 */
public class PolyDefault : Poly 
{
	// -----------------
	// --- Constants ---
	// -----------------
	
	// ------------------------
	// --- Member Variables ---
	// ------------------------
	/**
	 * Only applies to the first poly and can only be used with a poly that contains one poly
	 */
	private bool m_IsHole = false;
	protected Poly[] m_List = [];
	
	// --------------------
	// --- Constructors ---
	// --------------------
	/** Creates a new instance of PolyDefault */
	
	public this(bool isHole = false) 
	{
		m_IsHole = isHole;
	}
	
	// ----------------------
	// --- Object Methods ---
	// ----------------------
	/**
	 * Return true if the given object is equal to this one.
	 */
	public bool equals(Object obj) 
	{
		if (typeid(obj) != typeid(PolyDefault)) 
		{
			return false;
		}
		PolyDefault that = cast(PolyDefault)obj;
		
		if (this.m_IsHole != that.m_IsHole) return false;
		if (this.m_List != that.m_List) return false;
		
		return true;
	}
	/**
	 * Return the hashCode of the object.
	 *
	 * @return an integer value that is the same for two objects
	 * whenever their internal representation is the same (equals() is true)
	 **/
//	public override int toHash() 
//	{
//		int result = 17;
//		foreach(i; m_List)
//			result = 37 * result + i.toHash();
//		return result;
//	}
	
	// ----------------------
	// --- Public Methods ---
	// ----------------------
	/**
	 * Remove all of the points.  Creates an empty polygon.
	 */
	public void clear() 
	{
		m_List = [];
	}
	
	/**
	 * Add a point to the first inner polygon.
	 * <p>
	 * <b>Implementation Note:</b> If a point is added to an empty PolyDefault object,
	 * it will create an inner polygon of type <code>PolySimple</code>.
	 */
	public void add(double x, double y) 
	{
		add(new Point2D(x, y));
	}
	
	/**
	 * Add a point to the first inner polygon.
	 * <p>
	 * <b>Implementation Note:</b> If a point is added to an empty PolyDefault object,
	 * it will create an inner polygon of type <code>PolySimple</code>.
	 */
	public void add(Point2D p) 
	{
		if (m_List.length == 0) 
		{
			m_List ~= new PolySimple();
		}
		m_List[0].add(p);
	}
	
	/**
	 * Add an inner polygon to this polygon - assumes that adding polygon does not
	 * have any inner polygons.
	 *
	 * Crashes if the number of inner polygons is greater than
	 * zero and this polygon was designated a hole.  This would break the assumption
	 * that only simple polygons can be holes.
	 */
	public void add(Poly p) 
	{
		if ((m_List.length > 0) && m_IsHole) 
		{
			assert(0, "Cannot add polys to something designated as a hole.");
		}
		m_List ~= p;
	}
	
	/**
	 * Return true if the polygon is empty
	 */
	public bool isEmpty() 
	{
		return m_List.length == 0;
	}
	
	/**
	 * Returns the bounding rectangle of this polygon.
	 * <strong>WARNING</strong> Not supported on complex polygons.
	 */
	public Rectangle2D getBounds() 
	{
		if (m_List.length == 0) 
		{
			return new Rectangle2D();
		} 
		else if (m_List.length == 1) 
		{
			Poly ip = getInnerPoly(0);
			return ip.getBounds();
		} 
		else 
		{
			assert(0, "getBounds not supported on complex poly.");
		}
	}
	
	/**
	 * Returns the polygon at this index.
	 */
	public Poly getInnerPoly(int polyIndex) 
	{
		return m_List[polyIndex];
	}
	
	/**
	 * Returns the number of inner polygons - inner polygons are assumed to return one here.
	 */
	public int getNumInnerPoly() 
	{
		return m_List.length;
	}
	
	/**
	 * Return the number points of the first inner polygon
	 */
	public int getNumPoints() 
	{
		return m_List[0].getNumPoints();
	}
	
	/**
	 * Return the X value of the point at the index in the first inner polygon
	 */
	public double getX(int index) 
	{
		return m_List[0].getX(index);
	}
	
	/**
	 * Return the Y value of the point at the index in the first inner polygon
	 */
	public double getY(int index) 
	{
		return m_List[0].getY(index);
	}
	
	/**
	 * Return true if this polygon is a hole.  Holes are assumed to be inner polygons of
	 * a more complex polygon.
	 *
	 * crashes if called on a complex polygon.
	 */
	public bool isHole() 
	{
		if (m_List.length > 1) 
		{
			assert(0, "Cannot call on a poly made up of more than one poly.");
		}
		return m_IsHole;
	}
	
	/**
	 * Set whether or not this polygon is a hole.  Cannot be called on a complex polygon.
	 *
	 * @throws IllegalStateException if called on a complex polygon.
	 */
	public void setIsHole(bool isHole) 
	{
		if (m_List.length > 1) 
		{
			assert(0, "Cannot call on a poly made up of more than one poly.");
		}
		m_IsHole = isHole;
	}
	
	/**
	 * Return true if the given inner polygon is contributing to the set operation.
	 * This method should NOT be used outside the Clip algorithm.
	 */
	public bool isContributing(int polyIndex) 
	{
		return m_List[polyIndex].isContributing(0);
	}
	
	/**
	 * Set whether or not this inner polygon is constributing to the set operation.
	 * This method should NOT be used outside the Clip algorithm.
	 *
	 * crashes if called on a complex polygon
	 */
	public void setContributing(int polyIndex, bool contributes) 
	{
		if (m_List.length != 1) 
		{
			assert(0, "Only applies to polys of size 1");
		}
		m_List[polyIndex].setContributing(0, contributes);
	}
	
	/**
	 * Return a Poly that is the intersection of this polygon with the given polygon.
	 * The returned polygon could be complex.
	 *
	 * @return the returned Poly will be an instance of PolyDefault.
	 */
	public Poly intersection(Poly p) 
	{
		return Clip.intersection(p, this, typeid(this));
	}
	
	/**
	 * Return a Poly that is the union of this polygon with the given polygon.
	 * The returned polygon could be complex.
	 *
	 * @return the returned Poly will be an instance of PolyDefault.
	 */
	public Poly polyUnion(Poly p) 
	{
		return Clip.polyUnion(p, this, typeid(this));
	}
	
	/**
	 * Return a Poly that is the exclusive-or of this polygon with the given polygon.
	 * The returned polygon could be complex.
	 *
	 * @return the returned Poly will be an instance of PolyDefault.
	 */
	public Poly xor(Poly p) 
	{
		return Clip.xor(p, this, typeid(this));
	}
	
	/**
	 * Return a Poly that is the difference of this polygon with the given polygon.
	 * The returned polygon could be complex.
	 *
	 * @return the returned Poly will be an instance of PolyDefault.
	 */
	public Poly difference(Poly p) 
	{
		return Clip.difference(this, p, typeid(this));
	}
	
	/**
	 * Return the area of the polygon in square units.
	 */
	public double getArea() 
	{
		double area = 0.0;
		for (int i = 0; i < getNumInnerPoly(); i++) 
		{
			Poly p = getInnerPoly(i);
			double tarea = p.getArea() * (p.isHole() ? -1.0 : 1.0);
			area += tarea;
		}
		return area;
	}
	
	// -----------------------
	// --- Package Methods ---
	// -----------------------
	void print() 
	{
		for (int i = 0; i < m_List.length; i++) 
		{
			Poly p = getInnerPoly(i);
			import std.stdio, std.conv;
			writeln(text("InnerPoly(", i, ").hole=", p.isHole()));
			for (int j = 0; j < p.getNumPoints(); j++) 
			{
				writeln(p.getX(j), " ", p.getY(j));
			}
		}
	}
}