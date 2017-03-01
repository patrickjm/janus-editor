/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editor.gui.draggable;

import std.typecons : Nullable;
import std.conv;

import dsfml.system.time;
import dsfml.graphics;

import janus.editor.settings;
import janus.editor.gui;


class GuiDraggable : GuiComponent
{
protected:
	RectangleShape _rect;
	/// Where, <b>relative to (x, y)</b>, was this component clicked?
	/// isNull() means that this component is not being dragged
	Nullable!Vector2f _clickPosition;
	/// Used to store useful info in this node
	Object _meta;

	bool _mouseOver = false;
	bool _moved = false;
	
	bool _useEditorViewPos;
	bool _useEditorViewZoom;
	
	bool _overridden = false; /// Used for keeping track of when the dragging is interrupted (like an undo event)
	bool _selected = false;
	
	Color _currentColor, _defaultColor = mixin(EditorSettings.Main.DraggableDefaultColor);
	
	bool delegate(GuiDraggable, Object) _overrideMouseDetect;
	FloatRect delegate(GuiDraggable, Object) _overrideRenderBounds;

public:
	GuiEvent!(GuiDraggable, int, int) onClick, onDragged, onReleased, onStaticReleased;

	@property
	{
		Object meta() { return _meta; }
		Object meta(Object p_meta) { _meta = p_meta; return _meta; }
		
		/// can only set to false if zoom is also false
		void useEditorViewPos(bool p_euv) { _useEditorViewPos = p_euv || _useEditorViewZoom; }
		/// sets both useEditorViewZoom AND useEditorViewPos
		void useEditorViewZoom(bool p_euv) 
		{ 
			_useEditorViewZoom = _useEditorViewPos = p_euv;
		}
		void baseColor(Color p_col) { _defaultColor = p_col; }
		
		void overrideIsMouseInside(bool delegate(GuiDraggable, Object) p_func) { _overrideMouseDetect = p_func; }
		void overrideRenderBounds(FloatRect delegate(GuiDraggable, Object) p_func) { _overrideRenderBounds = p_func; }

		bool isMouseOver() { return _mouseOver; }
		bool isSelected() { return _selected; }
		bool isSelected(bool p_isSelected) { _selected = p_isSelected; return _selected; }
	}
	
	this(string p_label, int p_x, int p_y, int p_sizeX = 10, int p_sizeY = 10)
	{
		x = p_x;
		y = p_y;
		sizeX = p_sizeX;
		sizeY = p_sizeY;
		label = p_label;
		
		onClick = new GuiEvent!(GuiDraggable, int, int)();
		onDragged = new GuiEvent!(GuiDraggable, int, int)();
		onReleased = new GuiEvent!(GuiDraggable, int, int)();
		onStaticReleased = new GuiEvent!(GuiDraggable, int, int)();
		
		_rect = new RectangleShape(Vector2f(p_sizeX, p_sizeY));

		_currentColor = _defaultColor;
	}
	
	this(int p_x, int p_y, int p_sizeX = 10, int p_sizeY = 10)
	{
		static int draggableCount = 0;
		this("Draggable" ~ to!string(draggableCount++), p_x, p_y, p_sizeX, p_sizeY);
	}
	
	override
	{
		void render(Time p_dt, RenderTarget p_canvas)
		{
			if (!isAlive)
				return;

			import janus.globals;
			// processEvent can turn _mouseOver on and off, but render can turn it off.
			// this is to make sure that _mouseOver is turned off if another object captures the event.
			if(_clickPosition.isNull && !isMouseInside(editor.cam))
				_mouseOver = false;

			Vector2f mousePos = _useEditorViewPos ? editor.mouseViewLoc() : Vector2f(Mouse.getPosition(window).x, Mouse.getPosition(window).y);
			alias _mouseOver mouseInside;
			float scaleUp = mouseInside ? 4 : 1;
			if (mouseInside && Mouse.isButtonPressed(Mouse.Button.Left) && _moved)
				scaleUp -= 1;
			Color col = mouseInside ? Color.White : _currentColor;
			if (_selected)
				col = col + Color(20, 20, 20);

			FloatRect r; // render rectangle

			// built in rectangle generation
			if (_overrideRenderBounds is null)
			{
				// if we need to move the center point with the camera
				float rx = clientX, ry = clientY;
				if (_useEditorViewPos)
				{
					auto pt = editor.cam2Win(Vector2f(rx, ry));
					rx = pt.x;
					ry = pt.y;
				}

				// if we need to resize the edges with the camera
				float rSizeX = sizeX, rSizeY = sizeY;
				if (_useEditorViewZoom)
				{
					rSizeX /= editor.zoomFactor;
					rSizeY /= editor.zoomFactor;
				}
				rx -= rSizeX / 2f;
				ry -= rSizeY / 2f;

				r = FloatRect(rx, ry, rSizeX, rSizeY);
			}
			else // parent object wants us to use a special function
			{
				r = _overrideRenderBounds(this, meta);
				if (_useEditorViewPos)
				{
					auto pt = editor.cam2Win(Vector2f(r.left, r.top));
					r.left = pt.x;
					r.top = pt.y;
				}

				if (_useEditorViewZoom)
				{
					r.width = r.width / editor.zoomFactor;
					r.height = r.height / editor.zoomFactor;
				}
			}

			// draw the rectangle:
			static RectangleShape rect;
			if (!rect)
				rect = new RectangleShape;
			rect.size = Vector2f(r.width + scaleUp * 2, r.height + scaleUp * 2);
			rect.position = Vector2f(r.left - scaleUp, r.top - scaleUp);
			rect.fillColor = Color.Transparent;
			rect.outlineColor = col;
			rect.outlineThickness = _selected ? 2 : 1;
			p_canvas.draw(rect);

			super.render(p_dt, p_canvas);
		}

		bool processEvent(const(Event) p_e)
		{
			if (!isAlive)
				return false;
			if (super.processEvent(p_e))
				return true;
			
			import janus.globals;
			Vector2f mousePos = _useEditorViewPos ? editor.mouseViewLoc() : Vector2f(Mouse.getPosition(window).x, Mouse.getPosition(window).y);
			int mouseX = cast(int)mousePos.x;
			int mouseY = cast(int)mousePos.y;
			
			if (p_e.type == Event.EventType.MouseButtonPressed && p_e.mouseButton.button == Mouse.Button.Left) // Check for clicks and set the relative _clickPosition
			{
				import janus.globals;
				if (_mouseOver)
				{
					_overridden = false;
					moveToFront();
					_clickPosition = mousePos - Vector2f(x, y);
					onClick.broadcast(this, x, y);
					//select();
					return true;
				}
			}
			else if (p_e.type == Event.EventType.MouseMoved) // Drag this component as the mouse moves
			{
				if (!_clickPosition.isNull())
				{
					if (_overridden) return true;
					_moved = true;
					_mouseOver = true;
					
					x = mouseX - cast(int)_clickPosition.x;
					y = mouseY - cast(int)_clickPosition.y;
					onDragged.broadcast(this, x, y);
					return true;
				}
				if ((_mouseOver = isMouseInside(editor.cam)) == true)
					return true;
			}
			else if (p_e.type == Event.EventType.MouseButtonReleased && p_e.mouseButton.button == Mouse.Button.Left)
			{
				if (!_clickPosition.isNull())
				{
					_overridden = false;
					
					x = mouseX - cast(int)_clickPosition.x;
					y = mouseY - cast(int)_clickPosition.y;
					_clickPosition.nullify();
					onReleased.broadcast(this, x, y);
					_moved = false;
					//deselect();
					return true;
				}
			}
			
			return false;
		}
	}

	void overrideSet(int p_x, int p_y)
	{
		x = p_x;
		y = p_y;
		_overridden = true;
	}

	override public bool isMouseInside(View p_cam) 
	{
		if (_overrideMouseDetect !is null)
			return _overrideMouseDetect(this, meta);
		return super.isMouseInside(p_cam);
	}

	override public bool isInside(int p_x, int p_y, bool p_useGlobalCoordinates = true) 
	{
		return super.isInside(p_x + sizeX / 2, p_y + sizeY / 2, p_useGlobalCoordinates);
	}

	void select()
	{
		_selected = true;
	}
	void deselect()
	{
		_selected = false;
	}
}