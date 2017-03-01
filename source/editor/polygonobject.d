module janus.editor.polygonobject;

import janus.globals;
import janus.engine.eventprocessor;
import janus.editor.action;
import janus.editor.settings;
public import janus.editor.editorobject;
import janus.editor.gui.draggable;
import janus.engine.level : LevelPolygon, LevelVertex;

import dsfml.graphics : Color, RenderTarget;
import dsfml.window : Mouse;
import dsfml.system : Time;

class PolygonObject : EditorObject
{
private:
	LevelPolygon _poly;
public:
	@property LevelPolygon poly() { return _poly; }
	@property override float width() { return _poly.bounds.width; }
	@property override float height() { return _poly.bounds.height; }
	
	this(LevelPolygon p_polygon)
	{
		_poly = p_polygon;
		import std.conv : to;
		super("Poly" ~ to!string(_poly.id), mixin(EditorSettings.Main.DraggablePolyColor));

		selector.overrideRenderBounds = (p_drag, p_meta) => _poly.bounds;
	}
	
	override void pushLocation() 
	{
		import dsfml.system.vector2;
		_poly.position = Vector2f(_x, _y);
		//_poly.inspect();
	}
	
	override void pull() 
	{
		_x = _poly.position.x;
		_y = _poly.position.y;
		super.pull();
	}
	
	override bool isPointInside(float p_x, float p_y)
	{
		return _poly.isPointInside(p_x, p_y);
	}

	override void render(Time p_dt, RenderTarget p_rt) 
	{
		super.render(p_dt, p_rt);
		import dsfml.system.vector2;
		if (_doTween && (_x != _renderX || _y != _renderY))
		{
			_poly.position = Vector2f(_renderX, _renderY);
			//_poly.think();
		}
		else
			pushLocation();

		// mouse over additive effects on the polygon
		if (selector.isMouseOver)
			_poly.renderOptions.hilightColor = Color(8, 8, 8);
		else
			_poly.renderOptions.hilightColor.nullify();
		// render the poly
		_poly.render(p_rt);
	}

	override void onActivate() 
	{
		super.onActivate();
		// make sure we inspect when things are added back
		_poly.inspect();
	}
}

class PolyHoleObject : EditorObject
{
private:
	LevelPolygon _poly;
	LevelPolygon.Hole _hole;
public:
	@property LevelPolygon poly() { return _poly; }
	@property LevelPolygon.Hole hole() { return _hole; }
	@property override float width() { return _hole.bounds.width; }
	@property override float height() { return _hole.bounds.height; }

	this(LevelPolygon p_poly, LevelPolygon.Hole p_hole)
	{
		_poly = p_poly;
		_hole = p_hole;
		import std.conv : text;
		static int id = 0;
		super(text("Hole", _poly.id, ":", id++), mixin(EditorSettings.Main.DraggablePolyColor) + Color(20, 20, 20));

		selector.overrideRenderBounds = (p_drag, p_meta) {
			auto bounds = _hole.bounds;
			bounds.left = bounds.left + _poly.position.x;
			bounds.top = bounds.top + _poly.position.y;
			return bounds;
		};
	}
	
	override void pushLocation() 
	{
		import dsfml.system.vector2;
		_hole.position = Vector2f(_x, _y);
		if (parent !is null)
			parent.apply();
		_poly.inspect();
	}
	
	override void pull() 
	{
		_x = _hole.position.x;
		_y = _hole.position.y;
		super.pull();
	}
	
	override bool isPointInside(float p_x, float p_y)
	{
		return _hole.isPointInside(p_x - _poly.position.x, p_y - _poly.position.y);
	}

	override void render(Time p_dt, RenderTarget p_rt) 
	{
		super.render(p_dt, p_rt);
		import dsfml.system.vector2;
		if (_doTween && (_x != _renderX || _y != _renderY))
		{
			_hole.position = Vector2f(_renderX, _renderY);
			_poly.think();
		}
	}

	override void onActivate() 
	{
		super.onActivate();
		// add the hole to the poly on activation
		_poly.addHole(_hole);
		_poly.inspect();
	}

	override void onDeactivate() 
	{
		super.onDeactivate();
		// remove the hole from the poly on deactivation
		_poly.removeHole(_hole);
		_poly.inspect();
	}
}