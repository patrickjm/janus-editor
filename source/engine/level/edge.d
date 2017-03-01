/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.engine.level.edge;

import janus.engine.level;
import dsfml.graphics;
import std.math;

// Later: Edge types and qualities

// Data storage class for ease of use 
class LevelEdge
{
	this(LevelVertex p_point1, LevelVertex p_point2)
	{
		_point1 = p_point1;
		_point2 = p_point2;
	}

	/// returns a normalized direction vector from one pt to the other
	Vector2f vector() 
	{
		float[] diff = [_point2.x - _point1.x, _point2.y - _point1.y]; // get the regular vector
		float dist = sqrt(pow(diff[0], 2) + pow(diff[1], 2)); // get the distance
		return Vector2f(diff[0], diff[1]) / dist; // normalize and return
	}

	float direction()
	{
		return atan2(deltaY, deltaX);
	}

	float directionDeg()
	{
		return direction() * 180 / PI;
	}
	
	/// Only used in editor for polygon validation, so it doesn't need to be terribly precise or efficient.
	bool intersects(LevelEdge p_e)
	{
		//http://flassari.is/2008/11/line-line-intersection-in-cplusplus/
		float x1 = p1.x, x2 = p2.x, x3 = p_e.p1.x, x4 = p_e.p2.x;
		float y1 = p1.y, y2 = p2.y, y3 = p_e.p1.y, y4 = p_e.p2.y;
		
		float d = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4);
		if (d == 0) return false; // no intersection
		
		// get the x and y
		float pre = (x1 * y2 - y1 * x2), post = (x3 * y4 - y3 * x4);
		float x = (pre * (x3 - x4) - (x1 - x2) * post) / d;
		float y = (pre * (y3 - y4) - (y1 - y2) * post) / d;
		
		// Check if the x and y coordinates are within both lines
		if (x < fmin(x1, x2) || x > fmax(x1, x2) ||
			x < fmin(x3, x4) || x > fmax(x3, x4)) return false;
		if (y < fmin(y1, y2) || y > fmax(y1, y2) ||
			y < fmin(y3, y4) || y > fmax(y3, y4)) return false;
		
		return true;
	}

	//Vector2f normal()
	//{
	//	Vector2f vec = vector();

	//}

	@property
	{
		void point1(LevelVertex p_p1) { _point1 = p_p1; }
		LevelVertex point1() { return _point1; }

		void point2(LevelVertex p_p2) { _point2 = p_p2; }
		LevelVertex point2() { return _point2; }
		
		void p1(LevelVertex p_p1) { _point1 = p_p1; }
		LevelVertex p1() { return _point1; }

		void p2(LevelVertex p_p2) { _point2 = p_p2; }
		LevelVertex p2() { return _point2; }

		void points(LevelVertex[] p_points)
		{
			_point1 = p_points[0];
			_point2 = p_points[1];
		}
		LevelVertex[] points() { return [_point1, _point2]; }

		float deltaX() { return _point2.x - _point1.x; }
		float deltaY() { return _point2.y - _point1.y; }
	}

private:
	LevelVertex _point1, _point2;
}