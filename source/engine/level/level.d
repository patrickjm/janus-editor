/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.engine.level.level;

import dsfml.graphics : FloatRect, RenderTarget;

import janus.engine.level;

class Level
{
	this()
	{

	}

	void addPolygon(LevelPolygon p_poly)
	{
		_polygons[p_poly.bounds] = p_poly;
	}

	void removePolygon(LevelPolygon p_poly)
	{
		foreach(poly; _polygons.byKey())
		{
			if (_polygons[poly] == p_poly)
			{
				_polygons.remove(poly);
				return;
			}
		}
	}

	@disable
	LevelPolygon[] getIntersections(FloatRect rect)
	{
		return null;
	}

	version(Editor)
	void castrate()
	{
	}

	version(Editor)
	void unCastrate()
	{
	}

	void render(RenderTarget p_rt)
	{
		foreach(poly; _polygons.values)
			poly.render(p_rt);
	}

	@property
	{
		LevelPolygon[] polygons() { return _polygons.values.dup; }
	}

protected:
	/// spacial hashmap of the polygons
	LevelPolygon[FloatRect] _polygons;
}