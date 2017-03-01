/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.engine.level.vertex;

import dsfml.graphics;

// Later: Vertex types and qualities

// Data storage class for ease of use 

class LevelVertex
{
	
	this(float[] p_point)
	{
		_point = [p_point[0], p_point[1]];		
	}

	this(float p_x, float p_y)
	{
		_point = [p_x, p_y];
	}

	this(Vector2f p_point)
	{
		_point = [p_point.x, p_point.y];
	}

	bool equals(LevelVertex other)
	{
		return cast(int)x == cast(int)other.x && cast(int)y == cast(int)other.y;
	}

	@property LevelVertex dup()
	{
		return new LevelVertex(_point.dup);
	}

	LevelVertex opAdd(Vector2f p_other)
	{
		auto d = dup;
		d.x = d.x + p_other.x;
		d.y = d.y + p_other.y;
		return d;
	}

	LevelVertex opSub(Vector2f p_other)
	{
		auto d = dup;
		d.x = d.x - p_other.x;
		d.y = d.y - p_other.y;
		return d;
	}

	// property overkill
	@property
	{
		void x(float p_x) { _point[0] = p_x; }
		float x() { return _point[0]; }

		void y(float p_y) { _point[1] = p_y; }
		float y() { return _point[1]; }

		void point(float[] p_xy) { _point = [p_xy[0], p_xy[1]]; }
		void point(Vector2f p_xy) { _point = [p_xy.x, p_xy.y]; }
		Vector2f point() { return Vector2f(_point[0], _point[1]); }
	}

private:
	float[] _point;
}