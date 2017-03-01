module janus.editor.polyvertexobject;

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

class PolyVertexObject : EditorObject
{
private:
	LevelPolygon _poly;
	LevelVertex _vertex;
public:
	@property LevelPolygon poly() { return _poly; }
	@property LevelVertex vertex() { return _vertex; }
	@property override float width() { return 10; }
	@property override float height() { return 10; }
	
	this(LevelPolygon p_poly, LevelVertex p_vert)
	{
		_poly = p_poly;
		_vertex = p_vert;
		import std.conv : text;
		static int id = 0;
		super(text("Vertex", _poly.id, ":", id++), mixin(EditorSettings.Main.DraggablePolyColor) + Color(40, 40, 40));
	}
	
	override void pushLocation() 
	{
		import dsfml.system.vector2;
		_vertex.x = _x - _poly.position.x;
		_vertex.y = _y - _poly.position.y;
		_poly.inspect();
		if (parent !is null)
			parent.apply();
	}
	
	override void pull() 
	{
		_x = _vertex.x + _poly.position.x;
		_y = _vertex.y + _poly.position.y;
		super.pull();
	}
}