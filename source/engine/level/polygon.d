/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.engine.level.polygon;

import std.algorithm, std.typecons : Tuple, Nullable;

import poly2trid.shapes : P2TPoint = Point, P2TTriangle = Triangle;
import poly2trid.cdt;

import clipped;

import janus.engine.level, janus.engine.tileset, janus.engine.sizeable;
import janus.globals : assets;

import dsfml.graphics;

version(Editor)
{
	import janus.editor.gui.draggable;
}

class LevelPolygon : Sizeable
{
public:
	struct RenderOptions
	{
		Nullable!Color fillColor, outlineColor;
		version(Editor) 
		{
			Nullable!Color triangleColor, boundingBoxColor, hilightColor;
		}
		bool useShader;
		
		void reset()
		{
			fillColor = Color.White;
			outlineColor.nullify();
			useShader = true;
			version(Editor)
			{
				triangleColor.nullify();
				boundingBoxColor.nullify();
				hilightColor.nullify();
			}
		}
	}

	class Hole
	{
		LevelVertex[] vertices;
		/// Center of the bounding box for this polygon
		Vector2f position;

		@property
		{
			FloatRect bounds()
			{
				auto rect = LevelPolygon.calculateBounds(vertices);
				rect.left = rect.left + position.x;
				rect.top = rect.top + position.y;
				return rect;
			}
		}

		this(LevelVertex[] p_vertices)
		{
			// set the position and create a new list of vertices based on average pos
			vertices = LevelPolygon.getShifted(p_vertices, -LevelPolygon.getCenter(p_vertices));
		}

		this(LevelVertex[] p_vertices, Vector2f p_position)
		{
			vertices = p_vertices;
			position = p_position;
		}

		/// offsets every vertex by (p_dx, p_dy)
		void move(float p_dx, float p_dy)
		{
			_position = _position + Vector2f(p_dx, p_dy);
		}

		bool isPointInside(float p_x, float p_y)
		{
			return LevelPolygon.isPointInside(vertices, p_x - position.x, p_y - position.y);
		}
	}
	
	RenderOptions renderOptions;
	version(Editor) bool isCastrated = false;

protected:
	Vector2f _position;
	LevelVertex[] _edgePoints;
	Hole[] _holes;
	LevelEdge[] _edges;
	uint _id;
	
	/// triangle cache
	const(Vertex)[] _cache;
	/// bounding box cache
	FloatRect _boundingBoxCache;
	
	/// Poly2Tri sweep context
	CDT _cdt;
	
	version(Editor) GuiDraggable[LevelVertex] _draggables;
	version(Editor) GuiDraggable _selector;

public:
	@property
	{
		/// The actual vertex references. <b>Don't edit unless you know what you're doing</b>
		LevelVertex[] vertices() { return _edgePoints; }
		/// The actual vertex references. <b>Don't edit unless you know what you're doing</b>
		Hole[] holes() { return _holes; }
		/// The actual edge references. <b>Don't edit unless you know what you're doing</b>
		LevelEdge[] edges() { return _edges; }
		
		FloatRect bounds() { return _boundingBoxCache; }
		
		/// Center of the bounding box for this polygon
		Vector2f position() { return _position; }
		/// ditto
		void position(Vector2f p_position) { _position = p_position; _boundingBoxCache = calculateBounds(); }

		const uint id() { return _id; }
	}
	
	this()
	{
		renderOptions.reset();
		static uint polyId = 0;
		_id = polyId++;
	}

	this(Vector2f p_position, LevelVertex[] p_vertices)
	{
		_position = p_position;
		set(p_vertices);
		this();
	}

	this(LevelVertex[] p_vertices)
	{
		_position = getCenter(p_vertices);
		set(getShifted(p_vertices, -_position));
		this();
	}

	bool isPointInside(float p_x, float p_y)
	{
		foreach(hole; _holes)
			if (hole.isPointInside(p_x, p_y)) 
				return false;

		return isPointInside(_edgePoints, p_x - _position.x, p_y - _position.y);
	}

	/// Recalculate edges and vertices. Do this as infrequently as possible!
	void think()
	{
		assert(_edgePoints, "You need to set points before you can triangulate!");
		_edges = constructEdges(_edgePoints);
		set(_edgePoints); // reset the CDT edge point context
		foreach(hole; _holes) // reset all the holes
			_cdt.AddHole(convert!(LevelVertex, P2TPoint)(getShifted(hole.vertices, hole.position)));
		_cache = cast(const(Vertex)[])triangulate();
		_boundingBoxCache = calculateBounds();
	}

	/// Adds a hole to the polygon. These holes cannot intersect, and they can't touch or go outside the edges!
	Hole addHole(LevelVertex[] p_vertices)
	{
		_holes ~= new Hole(p_vertices.dup);
		return _holes[$ - 1];
	}

	/// Adds a hole to the polygon. These holes cannot intersect, and they can't touch or go outside the edges!
	Hole addHole(LevelVertex[] p_vertices, Vector2f p_position)
	{
		_holes ~= new Hole(p_vertices.dup, p_position);
		return _holes[$ - 1];
	}

	/// Adds a hole to the polygon. These holes cannot intersect, and they can't touch or go outside the edges!
	Hole addHole(Hole p_hole)
	{
		import std.algorithm : canFind;
		if (!_holes.canFind(p_hole))
			_holes ~= p_hole;
		return p_hole;
	}

	void removeHole(Hole p_hole)
	{
		import std.algorithm : countUntil;
		int ind = _holes.countUntil!"a == b"(p_hole);
		if (ind < 0) return;
		
		_holes = _holes[0 .. ind] ~ _holes[ind + 1 .. $];
	}

	/// Resets all holes and edges, setting the edge vertex list to p_vertices
	/// p_vertices should not be shifted - it should be local to the position of the polygon
	void set(LevelVertex[] p_vertices)
	{
		_edgePoints = p_vertices.dup;
		_cdt = new CDT(convert!(LevelVertex, P2TPoint)(p_vertices));
	}

	/// offsets every vertex by (p_dx, p_dy)
	void move(float p_dx, float p_dy)
	{
		_position = _position + Vector2f(p_dx, p_dy);
		foreach(hole; _holes)
			hole.move(p_dx, p_dy);
	}

	void render(RenderTarget p_canvas)
	{
		static Shader s;
		if (renderOptions.useShader)
		{
			import janus.globals;
			s = assets.get!Shader("level_poly");
			Tileset t = assets.get!Tileset("highlands");
			s.setParameter("texture", t.texture);
			s.setParameter("texSize", t.texSize);
			s.setParameter("texFrameSize", t.frameSize);
			s.setParameter("texFrameOffset", Vector2f(48, 48));
			s.setParameter("globalOffset", editor.cam.center - _position);
			if (!renderOptions.hilightColor.isNull())
				s.setParameter("addColor", renderOptions.hilightColor);
			else
				s.setParameter("addColor", Color(0, 0, 0));
		}
		// draw the main body of the polygon
		if (!renderOptions.fillColor.isNull)
		{
			auto rs = renderOptions.useShader ? RenderStates(s) : RenderStates.Default();
			rs.transform.translate(_position.x, _position.y);
			p_canvas.draw(_cache, PrimitiveType.Triangles, rs);
		}
		// draw triangles
		//TODO: triangles
		if (!renderOptions.outlineColor.isNull)
			drawOutlines(p_canvas, RenderStates.Default(), renderOptions.outlineColor.get());
		if (!renderOptions.boundingBoxColor.isNull)
			drawBoundingBox(p_canvas, RenderStates.Default(), renderOptions.boundingBoxColor.get());
	}

	/// returns the average position of p_vertices
	static Vector2f getAveragePos(LevelVertex[] p_vertices)
	{
		float x = 0, y = 0;
		foreach(vert; p_vertices)
		{
			x += vert.x;
			y += vert.y;
		}
		return Vector2f(x / p_vertices.length, y / p_vertices.length);
	}

	/// returns the center of the rectangle bounding box formed by p_vertices
	static Vector2f getCenter(LevelVertex[] p_vertices)
	{
		auto bounds = calculateBounds(p_vertices);
		return Vector2f(bounds.left + bounds.width / 2, bounds.top + bounds.height / 2);
	}

	static FloatRect calculateBounds(LevelVertex[] p_vertices)
	{
		Vector2f min = p_vertices[0].point, max = p_vertices[0].point;
		foreach(vertex; p_vertices)
		{
			if (vertex.x < min.x)
				min.x = vertex.x;
			if (vertex.x > max.x)
				max.x = vertex.x;

			if (vertex.y < min.y)
				min.y = vertex.y;
			if (vertex.y > max.y)
				max.y = vertex.y;
		}
		return FloatRect(min, max - min);
	}

	version(Editor)
	/// check edge intersections to verify that the poly is simple and not complex
	/// returns false if the verification fails (poly is complex)
	/// <b>Editor only</b>
	bool verify()
	{
		// make sure all the polygons (edge + holes) are simple (no edges collide)
		bool simplePolyCheck = isPolySimple(constructEdges(_edgePoints));
		foreach(hole; _holes)
			simplePolyCheck &= isPolySimple(constructEdges(hole.vertices));
		if (!simplePolyCheck) return false;

		// make sure the holes are inside the poly
		foreach(hole; _holes)
			foreach(vertex; getShifted(hole.vertices, _position + hole.position))
				if (!isPointInside(getShifted(_edgePoints, _position), vertex.x, vertex.y))
					return false;

		// make sure holes don't intersect
		LevelEdge[][] holeEdges = []; // construct an edge cache based on holes
		foreach(hole; _holes)
			holeEdges ~= constructEdges(getShifted(hole.vertices, _position + hole.position));
		foreach(i; 0 .. holeEdges.length) // compare edge cache to itself
			foreach(j; (i + 1) .. holeEdges.length) // no two edge lists are compared twice
				if (doEdgesIntersect(holeEdges[i], holeEdges[j]))
				    return false;

		// make sure holes don't contain other holes' points
		foreach(hole; 0 .. _holes.length) // loop through all holes
		{
			foreach(point; 0 .. _holes[hole].vertices.length) // loop through each point
			{
				foreach(otherHole; 0 .. _holes.length) // loop through all the other holes
				{
					if (hole == otherHole) continue; // false collisions against itself
					// shift the vertices so collisions can be tested out in the wild
					LevelVertex[] hVerts = getShifted(_holes[hole].vertices, _holes[hole].position);
					LevelVertex[] oVerts = getShifted(_holes[otherHole].vertices, _holes[otherHole].position);
					if (isPointInside(oVerts, hVerts[point].x, hVerts[point].y)) // test
						return false; // return false if the point is in any other hole
				}
			}
		}

		return true;
	}
	
	version(Editor)
	/// Checks a poly's verification and castrates it accordingly
	/// Returns true if inspection passed
	/// <b>Editor only</b>
	bool inspect()
	{
		if (verify())
		{
			unCastrate();
			return true;
		}
		else
		{
			castrate(false, Color.Red);
			return false;
		}
	}
	version(Editor)
	/// Makes a polygon only show the outlines.
	/// It means the poly can be complex or incorrect and still render what it is able
	/// <b>Editor only</b>
	void castrate(bool p_drawBody, Color p_outlineColor = Color.White)
	{
		isCastrated = true;
		if (p_drawBody)
			renderOptions.fillColor = Color.White;
		else
			renderOptions.fillColor.nullify();
		renderOptions.useShader = p_drawBody;
		renderOptions.outlineColor = p_outlineColor;
	}
	version(Editor)
	/// Means the polygon is not too complex and can be fully rendered
	/// <b>Editor only</b>
	void unCastrate()
	{
		isCastrated = false;
		renderOptions.fillColor = Color.White;
		renderOptions.outlineColor.nullify();
		renderOptions.useShader = true;
		think();
	}
protected:
	void drawBoundingBox(RenderTarget p_canvas, RenderStates p_rs, Color p_col)
	{
		FloatRect r = _boundingBoxCache;
		Vertex[] dat = [
			Vertex(Vector2f(r.left, r.top), p_col),
			Vertex(Vector2f(r.left + r.width, r.top), p_col),
			Vertex(Vector2f(r.left + r.width, r.top + r.height), p_col),
			Vertex(Vector2f(r.left, r.top + r.height), p_col)
		];
		p_canvas.draw(cast(const(Vertex)[])dat ~ dat[0], PrimitiveType.LinesStrip, p_rs);
	}

	void drawOutlines(RenderTarget p_canvas, RenderStates p_rs, Color p_col)
	{
		drawLineStrip(p_canvas, p_rs, getShifted(_edgePoints, _position), p_col);
		foreach(hole; _holes)
			drawLineStrip(p_canvas, p_rs, getShifted(hole.vertices, _position + hole.position), p_col + Color(75, 75, 75));
	}

	/// vertices should be pre-shifted
	void drawLineStrip(RenderTarget p_canvas, RenderStates p_rs, LevelVertex[] p_vertices, Color p_col)
	{
		Vertex[] lines = convert!(LevelVertex, Vertex)(p_vertices);
		for(int i = 0; i < lines.length; i++)
			lines[i].color = p_col;
		p_canvas.draw(cast(const(Vertex)[])(lines ~ lines[0]), PrimitiveType.LinesStrip, p_rs);
	}

	/// Triangulate the polygon 
	/// <b>Returns:</b> a list of render indices and the vertices which they refer to
	Vertex[] triangulate()
	{
		// triangulate and get the triangles
		_cdt.Triangulate();
		P2TTriangle[] tris = _cdt.GetTriangles();

		P2TPoint[] pointList = []; // Let's make a frame of reference for the indices

		// construct the point list from the triangles.
		int count = 0;
		foreach(tri; tris)
			for(int i = 0; i < 3; i++) // Loop through the three points to the tri
				pointList ~= tri.GetPoint(i);

		auto ret = convert!(P2TPoint, Vertex)(pointList);
		foreach(vert; ret)
			vert.color = Color.Black;
		return ret;
	}

	/// returns true if the polygon <b>edges</b> intersect
	static bool doEdgesIntersect(LevelEdge[] p_edge1, LevelEdge[] p_edge2)
	{
		for(int i = 0; i < p_edge1.length; i++)
			for(int j = 0; j < p_edge2.length; j++)
				if (p_edge1[i].intersects(p_edge2[j]))
					return true;
		return false;
	}

	/// returns true if the polygon does not self intersect
	static bool isPolySimple(LevelEdge[] p_edges)
	{
		if (p_edges.length == 3) return true; // triangles can't intersect themselves
		
		//import std.stdio, std.conv;
		for(int i = 0; i < p_edges.length; i++) // loop through edges
		{
			for(int j = 0; j < p_edges.length; j++) // loop through edges again
			{
				if (   p_edges[i] != p_edges[j] 
					&& p_edges[(i + 1) % p_edges.length] != p_edges[j]  
					&& p_edges[i == 0 ? (p_edges.length - 1) : i - 1] != p_edges[j]  
					&& p_edges[i].intersects(p_edges[j]))
				{
					//writeln(text("verification false", i, " ", j));
					return false;
				}
			}
		}
		//writeln("verification true");
		return true;
	}

	static bool isPointInside(LevelVertex[] p_vertices, float x, float y)
	{
		// http://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
		int i, j;
		bool c = false;
		for (i = 0, j = p_vertices.length - 1; i < p_vertices.length; j = i++) {
			if (((p_vertices[i].y > y) != (p_vertices[j].y > y)) &&
			    (x < (p_vertices[j].x - p_vertices[i].x) * (y - p_vertices[i].y) / (p_vertices[j].y - p_vertices[i].y) + p_vertices[i].x))
				c = !c;
		}
		return c;
	}

	/// returns a duplicated array of p_vertices whose positions have been shifted by p_offset
	static LevelVertex[] getShifted(LevelVertex[] p_vertices, Vector2f p_offset)
	{
		LevelVertex[] ret;
		foreach(vert; p_vertices)
			ret ~= vert.dup;
		foreach(pt; ret)
		{
			pt.x = pt.x + p_offset.x;
			pt.y = pt.y + p_offset.y;
		}
		return ret;
	}

	LevelEdge[] constructEdges(LevelVertex[] p_vertices)
	{
		LevelEdge[] ret = []; // reset edge list
		for(int i = 0; i < p_vertices.length; i++)
		{
			// link each point to the next one, and wrap the last point to the first
			ret ~= new LevelEdge(p_vertices[i], p_vertices[(i + 1) % p_vertices.length]);
		}
		return ret;
	}

	FloatRect calculateBounds()
	{
		return calculateBounds(getShifted(_edgePoints, _position));
	}

	/// Convert an array from one library to an array of another
	static R[] convert(T, R)(T[] p_dat)
	{
		R[] ret = [];
		foreach(t; p_dat)
		{
			ret ~= convert!(T, R)(t);
		}
		return ret;
	}

	/// Convert class data from one library to another. Hardcoded, unfortunately, but templates help.
	static R convert(T, R)(T p_dat)
	{
		static LevelVertex lv;
		static P2TPoint p;
		static Vertex v;

		static if (is(T : LevelVertex) && is(R : P2TPoint))
		{
			// Input = LevelVertex, Output = poly2trid.shapes.Point
			lv = cast(LevelVertex)p_dat;
			return new P2TPoint(cast(double)lv.x, cast(double)lv.y);
		}
		else static if (is(T : LevelVertex) && is(R : Vertex))
		{
			// Input = LevelVertex, Output = DSFML Vertex
			lv = cast(LevelVertex)p_dat;
			return Vertex(Vector2f(p_dat.x, p_dat.y));
		}
		else static if (is(T : P2TPoint) && is(R : LevelVertex))
		{
			// Input = poly2trid.shapes.Point, Output = LevelVertex
			p = cast(P2TPoint)p_dat;
			return new LevelVertex(cast(float)p.x, cast(float)p.y);
		}
		else static if (is(T : P2TPoint) && is(R : Vertex))
		{
			// Input = poly2trid.shapes.Point, Output = Vertex
			p = cast(P2TPoint)p_dat;
			return Vertex(Vector2f(cast(float)p.x, cast(float)p.y));
		}
		else static if (is(T : Vertex) && is(R : LevelVertex))
		{
			// Input = DSFML Vertex, Output = LevelVertex
			v = cast(Vertex)p_dat;
			return new LevelVertex([v.x, v.y]);
		}
		else
		{
			import std.conv;
			static assert(0, text("Unsupported conversion types: \n\tT:[", typeid(T), "] \n\tR:[", typeid(R), "]"));
		}
	}
}