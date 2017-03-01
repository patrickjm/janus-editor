module janus.editor.editorobject;

import janus.globals;
import janus.engine.eventprocessor;
import janus.editor.action;
import janus.editor.settings;
import janus.editor.gui.draggable;

import dsfml.graphics : Color, RenderTarget;
import dsfml.window : Mouse;
import dsfml.system : Time, Vector2f;

static class EditorObjectTypeList
{
	import janus.editor;
	private static immutable(TypeInfo_Class[]) _sortList;
	private static immutable(int[TypeInfo_Class]) _sortMap;
	private static immutable(TypeInfo_Class[][Editor.EM]) _approvedTypes;

	@property public static typeof(_sortList) list() { return _sortList; }
	@property public static typeof(_sortMap) map() { return _sortMap; }
	@property public static typeof(_approvedTypes) approvedTypes() { return _approvedTypes; }

	static this()
	{
		_sortList = cast(typeof(_sortList))[
			typeid(DummyEditorObj),
			typeid(PolyVertexObject),
			typeid(PolyHoleObject),
			typeid(PolygonObject),
		];

		// generate the map
		int[immutable(TypeInfo_Class)] m;
		foreach(i, member; _sortList)
			m[member] = i;
		_sortMap = cast(typeof(_sortMap))m;

		// create the list of approved types per mode
		_approvedTypes = cast(typeof(_approvedTypes)) [
			Editor.EM.Draw : [
				typeid(DummyEditorObj),
				typeid(PolyHoleObject),
				typeid(PolygonObject)
			],
			Editor.EM.Edit : [
				typeid(DummyEditorObj),
				typeid(PolyVertexObject)
			]
		];
	}
}

abstract class EditorObject : EventProcessor
{
private:
	bool _selected;
	bool _alive = true;
protected:
	GuiDraggable _selector;
	float _x, _y;
	typeof(this)[] _children;
	typeof(this) _parent;
public:
	@property
	{
		GuiDraggable selector() { return _selector; }
		float x() { return _x; }
		float y() { return _y; }
		void scaleWithZoom(bool p_swz) { _selector.useEditorViewZoom = p_swz; }
		void moveWithPan(bool p_mwp) { _selector.useEditorViewPos = p_mwp; }
		abstract float width();
		abstract float height();

		typeof(this)[] children() { return _children.dup; }
		typeof(this) parent() { return _parent; }
		typeof(this) parent(typeof(this) p_parent) { _parent = p_parent; return _parent; }

		bool selected() { return _selected; }
		bool isAlive() { return _alive; }
	}
	
	this(string p_label, Color p_color)
	{
		this(p_label);
		_selector.baseColor = p_color;
	}
	
	this(string label)
	{
		_selector = new GuiDraggable(label, cast(int)_x, cast(int)_y, cast(int)width, cast(int)width);
		_selector.onClick += &onSelectorGrab;
		_selector.onDragged += &onSelectorMove;
		_selector.onReleased += &onSelectorRelease;
		_selector.overrideIsMouseInside = (drag, meta) {
			auto mouse = editor.mouseViewLoc();
			return isPointInside(mouse.x, mouse.y);
		};
		pull();
		_renderX = _x;
		_renderY = _y;
		scaleWithZoom = true;
		moveWithPan = true;
		_selector.meta = this;
	}

	bool processEvent(const(Event) p_e)
	{
		foreach(child; _children)
			if (child.processEvent(p_e))
				return true;
		return false;
	}

	/// adds p_o to the list of children and sets p_o.parent to this object
	/// Returns: p_o if not already in the list, null if p_o was already there
	typeof(this) add(typeof(this) p_o)
	{
		import std.algorithm : canFind;
		if (!_children.canFind(p_o))
		{
			p_o.parent = this;
			_children ~= p_o;
			selector.add(p_o.selector);
			p_o.onActivate();
			return p_o;
		}
		return null;
	}

	/// removes p_o from the list of children and sets p_o.parent to null
	/// Returns: p_o if object was removed, null if it was not found in the list
	typeof(this) remove(typeof(this) p_o)
	{
		import std.algorithm : countUntil;
		int num;
		if ((num = _children.countUntil(p_o)) >= 0)
		{
			_children = _children[0 .. num] ~ _children[num + 1 .. $];
			p_o.parent = null;
			return p_o;
		}
		return null;
	}
	
	/// hides the gui draggable selector
	void hide()
	{
		_alive = false;
		_selector.setAlive(false);
		foreach(child; _children)
			child.show();
	}
	
	/// shows the gui draggable selector
	void show()
	{
		_alive = true;
		_selector.setAlive(true);
		foreach(child; _children)
			child.show();
	}
	
	void render(Time p_dt, RenderTarget p_rt)
	{
		import std.math : abs;
		import dsfml.graphics.rectangleshape;
		
		// this does nothing but tween moved values
		if (_doTween && (_renderX != _x || _renderX != _y))
		{
			_renderX = (_x + _renderX) / 2;
			_renderY = (_y + _renderY) / 2;
			if (abs(_renderX - _x) <= 1f)
				_renderX = _x;
			if (abs(_renderY - _y) <= 1f)
				_renderY = _y;
		}
		else
		{
			_renderX = _x;
			_renderY = _y;
		}
		// the size might have changed
		applySize();
		// draw the selection rectangle
		if (_selected)
		{
			static RectangleShape rect;
			if (!rect)
				rect = new RectangleShape;
			rect.size = Vector2f(width, height);
			rect.position = Vector2f(_x, _y) - rect.size / 2;
			rect.fillColor = Color(100, 149, 237, 25);
			rect.outlineColor = Color.Transparent;
			p_rt.draw(rect);
		}
		// render children
		foreach(child; _children)
			child.render(p_dt, p_rt);
	}

	/// pulls for this object and all recursive children
	void nestedPull()
	{
		pull();
		foreach(child; _children)
			child.nestedPull();
	}
	
	/// pushes location information from the draggable to the user object
	void pushLocation();
	
	/// pulls information from the user object and updates the draggable accordingly
	abstract void pull()
	{
		apply();
		foreach(child; _children)
			child.apply();
	}
	
	/// checks if the point is inside the user object
	bool isPointInside(float p_x, float p_y)
	{
		return _selector.isInside(cast(int)p_x, cast(int)p_y);
	}

	void onActivate() 
	{ 
		_selector.revive();
		foreach(child; _children)
			child.onActivate();
	}

	void onDeactivate() 
	{
		deselect();
		_selector.kill();
		foreach(child; _children)
			child.onDeactivate();
	}

	/// applies the pulled information to the draggable without touching its children
	void apply()
	{
		_selector.overrideSet(cast(int)_x, cast(int)_y);
		applySize();
	}

	/// applies the pulled information to the draggable without touching its children
	void applySize()
	{
		_selector.sizeX = cast(int)width;
		_selector.sizeY = cast(int)height;
	}

	/// selects this editor object
	void select()
	{
		// no point in running selection code if we're already selected
		if (_selected) 
			return;
		_selected = true;
		selector.select();

		// no point in adding this to the editor if we're already there.
		// this also stops a feedback loop, since the editor selectObject references this method
		import std.algorithm : canFind;
		if (editor.selectedObjects.canFind(this)) 
			return;
		else
			editor.selectObject(this);
	}

	/// deselects this editor object
	void deselect()
	{
		// no point in running deselection code if we're already deselected
		if (!_selected) 
			return;
		_selected = false;
		selector.deselect();
		
		// no point in removing this from the editor if we're not even there.
		// this also stops a feedback loop, since the editor deselectObject references this method
		import std.algorithm : canFind;
		if (!editor.selectedObjects.canFind(this)) 
			editor.selectObject(this);
	}
protected:
	float _renderX, _renderY; /// used for silly tweening
	bool _doTween = true; /// ditto
	DraggableMovedArgs _curDragActionArgs; /// current draggable action args. cached to update the redo position
	Action _potentialDragAction; /// action to be used if a draggable is moved, discarded if only clicked
	
private:
	void onSelectorGrab(GuiDraggable p_drag, int p_x, int p_y)
	{
		// add the action so that moving this draggable can be undone
		import std.conv : text;
		_curDragActionArgs = new DraggableMovedArgs(p_drag);
		
		// action to be used IF they actually move the selector and don't just click it
		_potentialDragAction = new Action(text(p_drag.label, "(", p_x, ", ", p_y, ")"), (ActionArgs p_args) {
			// undo delegate
			DraggableMovedArgs args = cast(DraggableMovedArgs)p_args;
			args.draggable.overrideSet(args.undoX, args.undoY); // move the draggable
			_x = args.undoX;
			_y = args.undoY;
			pushLocation; // move the user object
			nestedPull;
		}, (ActionArgs p_args) {
			// redo delegate
			DraggableMovedArgs args = cast(DraggableMovedArgs)p_args;
			args.draggable.overrideSet(args.redoX, args.redoY); // move the draggable
			_x = args.redoX;
			_y = args.redoY;
			pushLocation; // move the user object
			nestedPull;
		}, _curDragActionArgs);
	}
	
	void onSelectorMove(GuiDraggable p_drag, int p_x, int p_y)
	{
		_x = p_x;
		_y = p_y;

		pushLocation();
		foreach(child; _children)
			child.pull();
		
		// update the redo position on the draggable, but only if this is a manual move and not an undo/redo
		if (_curDragActionArgs !is null)
		{
			if (_curDragActionArgs.draggable == p_drag)
			{
				_curDragActionArgs.redoX = p_drag.x;
				_curDragActionArgs.redoY = p_drag.y;
				import std.conv : text;
				_curDragActionArgs.info = text(" => (", p_drag.x, ", ", p_drag.y, ")"); 
			}
			else
				_curDragActionArgs = null;
		}
	}
	
	void onSelectorRelease(GuiDraggable p_drag, int p_x, int p_y)
	{
		if (_potentialDragAction !is null)
		{
			// if this is the first move in an action, push it. Otherwise, just update the values
			if (_curDragActionArgs.undoX != _curDragActionArgs.redoX
			    || _curDragActionArgs.undoY != _curDragActionArgs.redoY)
			{
				editor.queue.push(_potentialDragAction);
			}
		}

		_potentialDragAction = null;
		_curDragActionArgs = null;
	}
}

class DummyEditorObj : EditorObject
{
private:
	import dsfml.graphics : Sprite, Texture;
	Sprite _drawer;
	Texture _tex;
public:
	@property override float width() { return _tex.getSize.x * _drawer.scale.x; }
	@property override float height() { return _tex.getSize.y * _drawer.scale.y; }

	this(int p_x, int p_y)
	{
		_x = p_x;
		_y = p_y;
		import janus.globals;
		_tex = assets.get!Texture("llama");
		_drawer = new Sprite();
		import dsfml.system.vector2;
		_drawer.scale = Vector2f(2, 2);
		_drawer.position = Vector2f(_x, _y);
		_drawer.origin = Vector2f(width / 4, height / 4);
		_drawer.setTexture(_tex, true);
		super("Dummy", Color.Green);
	}

	override void pushLocation() 
	{
		import dsfml.system.vector2;
		_drawer.position = Vector2f(_selector.x, _selector.y);
	}

	override void pull() 
	{
		_x = _drawer.position.x;
		_y = _drawer.position.y;
		super.pull();
	}

	override void render(Time p_dt, RenderTarget p_rt) 
	{
		super.render(p_dt, p_rt);
		import dsfml.system.vector2;
		if (_doTween && (_x != _renderX || _y != _renderY))
		{
			_drawer.position = Vector2f(_renderX, _renderY);
			//_poly.think();
		}
		else
			pushLocation();
		
		p_rt.draw(_drawer);
	}
}