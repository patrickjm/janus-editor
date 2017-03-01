/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editor.polygonbuilder;

import std.typecons : Tuple;

import dsfml.graphics;

import janus.editor.gui.draggable;
import janus.editor;
import janus.globals;
import janus.engine : Tileset, EventProcessor;
import janus.engine.level;

/// An unfinished polygon still being drawn
package class PolygonBuilder : EventProcessor
{
protected:
	LevelVertex[] _pointList; /// List of points
	LevelEdge[] _edgeList; /// List of edges
	Vertex[] _cache; /// Cache for rendering (so that data doesn't need to be converted every frame)
	bool _active;
	LevelPolygon _parent;
	PolygonObject _polyObject;
	LevelPolygon.Hole _hole;
	GuiDraggable _selector;

public:
	@property
	{
		const int size() { return _pointList.length; } /// returns the number of vertices in the polygon builder
		LevelVertex[] points() { return _pointList.dup; }
		bool isActive() { return _active; }
		LevelPolygon parent() { return _parent; }
		PolygonObject polyObject() { return _polyObject; }
		LevelPolygon.Hole hole() { return _hole; }
		GuiDraggable selector() { return _selector; }
	}
	
	this() { }

	bool processEvent(const(Event) p_e)
	{
		if (_selector.processEvent(p_e))
			return true;
		// add new points when they are drawn
		if (p_e.type == Event.EventType.MouseButtonPressed && p_e.mouseButton.button == Mouse.Button.Right
		    && !Mouse.isButtonPressed(Mouse.Button.Left))
		{
			auto mouse = editor.mouseViewLoc;
			if (verifyMouse(mouse.x, mouse.y)) // if the mouse isn't in a bad place (e.g. crossing a line)
				addPoint(new LevelVertex(mouse)); // add the point to the builder! :D
		}
		return _active;
	}

	/// activates and starts the drawing process at a certain point (with an optional parent to make a hole instead of a new poly)
	void startAt(float p_x, float p_y, PolygonObject p_parent = null)
	{
		_polyObject = p_parent;
		startAt(new LevelVertex(p_x, p_y), p_parent is null ? null : p_parent.poly);

		// create the undo/redo event
		auto args = new PointDrawnArgs(_pointList[0]);
		args.parent = p_parent is null ? null : p_parent.poly;
		editor.queue.push(new Action("DrawingPoly[0]", (ActionArgs a) {
			// undo delegate
			_active = false;
			editor.guiSub.remove(_selector);
		}, (ActionArgs a) {
			// redo delegate
			auto pdArgs = cast(PointDrawnArgs)a;
			startAt(pdArgs.point, pdArgs.parent);
		}, args));
	}

	/// Append level vertex to the list
	void addPoint(LevelVertex p_vert)
	{
		add(p_vert);

		// create the undo/redo event
		auto args = new PointDrawnArgs(_pointList[$ - 1]);
		import std.conv : text;
		editor.queue.push(new Action(text("DrawingPoly[", size - 1, "]"), (ActionArgs a) {
			pop(); // undo delegate
		}, (ActionArgs a) {
			add((cast(PointDrawnArgs)a).point); // redo delegate
		}, args));
	}

	/// removes the last created vertex
	void pop()
	{
		_edgeList.length -= 1;
		_pointList.length -= 1;
		_cache.length -= 1;
	}
	
	void render(RenderTarget p_target)
	{
		import janus.globals;
		Vector2f mousePos = editor.mouseViewLoc();
		int mouseX = cast(int)mousePos.x;
		int mouseY = cast(int)mousePos.y;
		auto vertexList = cast(const(Vertex)[])_cache[0 .. $ - 1];
		// draw the point list regularly or with a red tip due to a bad drawing
		if (verifyMouse(mouseX, mouseY))
		{
			vertexList ~= [
				_cache[$ - 1],
				Vertex(Vector2f(mouseX, mouseY), Color(255, 255, 255, 200))
			];
		}
		else
		{
			vertexList ~= [
				Vertex(_cache[$ - 1].position, Color.Red),
				Vertex(Vector2f(mouseX, mouseY), Color.Red)
			];
		}
		// draw the line list
		p_target.draw(vertexList, PrimitiveType.LinesStrip, RenderStates.Default);
		// draw circles on the vertices
		import dsfml.graphics.circleshape;
		static CircleShape shape;
		if (shape is null)
		{
			shape = new CircleShape(3, 10);
			shape.outlineColor = Color.White;
		}
		shape.radius = 3f * editor.zoomFactor;
		shape.origin = Vector2f(shape.radius, shape.radius);
		shape.outlineThickness = editor.zoomFactor;
		// draw the first point a different color
		shape.fillColor = Color.Red;
		shape.position = vertexList[0].position;
		p_target.draw(shape);
		foreach(vert; vertexList[1 .. $])
		{
			shape.fillColor = Color.Yellow;
			shape.position = vert.position;
			p_target.draw(shape);
		}
	}
protected:
	/// Internal - adds the point without changing the action queue
	void add(LevelVertex p_vert)
	{
		foreach(vert; _pointList)
			if (vert.x == p_vert.x && vert.y == p_vert.y)
				return;
		_edgeList ~= new LevelEdge(_pointList[$ - 1], p_vert);
		_pointList ~= p_vert;
		_cache ~= Vertex(Vector2f(p_vert.x, p_vert.y), Color.White);
	}
	/// activates and starts the drawing process at a certain point (with an optional parent to make a hole instead of a new poly)
	/// used internally - does not change the action queue
	void startAt(LevelVertex p_vert, LevelPolygon p_parent = null)
	{
		_active = true;
		_pointList = [ p_vert ];
		_cache = [ Vertex(p_vert.point, Color.White) ];
		_parent = p_parent;
		
		// starting the drawing process
		if (_parent is null // if it isn't a hole, no further checks are needed
		    || (_parent !is null && _parent.verify())) // if this should be a hole, only start it if the parent is verified
		{
			// create the polygon and the draggable
			_selector = new GuiDraggable(cast(int)p_vert.x, cast(int)p_vert.y, 13, 13);
			_selector.useEditorViewPos = true;
			_selector.onClick += &onConstructDraggableClicked;
			_selector.baseColor = mixin(EditorSettings.Main.ButtonClosePolygonColor);
			_selector.meta = this;
			editor.guiSub.add(_selector);
		}
	}
	/// Construct a polygon from the list of vertices
	/// Returns: Either a new polygon or the host polygon of a hole
	LevelPolygon construct()
	{
		// Poly can't be created from less than 3 vertices
		assert(_pointList.length > 2, "Cannot construct an incomplete polygon");
		if (_parent is null) // This is a basic polygon (no parent)
		{
			LevelPolygon ret = new LevelPolygon(_pointList);
			return ret;
		}
		else // this polygon has a parent, so is a hole
		{
			auto list = _pointList.dup;
			auto center = LevelPolygon.getCenter(list);
			foreach(ref vertex; list)
				vertex = vertex - center;
			_hole = parent.addHole(list, center - parent.position);
			return parent;
		}
	}

	/// Returns: true if the line from the last vertex to the mouse doesn't intersect any edges
	bool verifyMouse(float p_mouseX, float p_mouseY)
	{
		if (_pointList.length < 3) return true;
		LevelEdge edge = new LevelEdge(_pointList[$ - 1], new LevelVertex(p_mouseX, p_mouseY));
		for(int i = 0; i < _edgeList.length - 1; i++)
		{
			if (edge.intersects(_edgeList[i]))
				return false;
		}
		return true;
	}

	/// called when a polygon is linked back to its first vertex (when drawing)
	void onConstructDraggableClicked(GuiDraggable p_selector, int p_x, int p_y)
	{
		// you can't create a polygon with less than 3 vertices
		if (size < 3) 
			return;

		scope(exit)
			_active = false; // reset the polyBuilder
		
		const bool isHole = parent !is null;
		
		// construct the poly & remove the linker draggable
		LevelPolygon newPoly = construct();
		newPoly.inspect();
		editor.guiSub.remove(_selector);
		_selector = null;
		
		// create the undo/redo action
		editor.queue.purge("DrawingPoly"); // you can only undo/redo specific verts while you're drawing, not when you're done
		string initStr = "";
		EditorObject obj;
		import std.conv : text;
		if (!isHole) // this is a new poly, not a hole
		{
			// create the object, but don't add it to the editor yet
			obj = new PolygonObject(newPoly);
			initStr = text("Poly[", newPoly.vertices.length, "]");
			// create the vertex editable objects
			foreach(vertex; newPoly.vertices)
				obj.add(new PolyVertexObject(newPoly, vertex));
		}
		else // this is a hole
		{
			// create the hole object and add it to the poly
			obj = _polyObject.add(new PolyHoleObject(newPoly, _hole));
			initStr = text("Poly[", newPoly.vertices.length, "]Hole[", _hole.vertices.length, "]");
			// create the vertex editable objects
			foreach(vertex; _hole.vertices)
				obj.add(new PolyVertexObject(newPoly, vertex));
		}
		// add it to the editor
		editor.addObject(obj);
		editor.deselectObject(obj);
		// undo/redo:
		auto args = new ObjectCreatedArgs(initStr, obj);
		args.draggable = obj.selector;
		editor.queue.push(new Action("Draw", (ActionArgs p_args) {
			ObjectCreatedArgs pda = cast(ObjectCreatedArgs)p_args;
			editor.removeObject(pda.obj);
			editor.guiSub.remove(pda.draggable);
			if (pda.obj.parent !is null)
			{
				pda.parent = obj.parent;
				pda.obj.parent.remove(pda.obj);
			}
		}, (ActionArgs p_args) {
			ObjectCreatedArgs pda = cast(ObjectCreatedArgs)p_args;
			editor.addObject(pda.obj);
			if (pda.obj.parent !is null)
			{
				pda.parent = obj.parent;
				pda.obj.parent.add(pda.obj);
			}
		}, args));
	}
}