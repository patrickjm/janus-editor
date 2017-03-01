/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editor.gui.button;

import janus.editor.gui;
import janus.engine.tileset;
import dsfml.graphics;
import core.time;
import std.string, std.conv;

class GuiButton : GuiComponent
{
public:
	GuiEvent!(GuiButton, int) onClick;

	this(string p_label, int p_x, int p_y, int p_sizeX = 55, int p_sizeY = 26)	
	{
		this.x = p_x;
		this.y = p_y;
		this.sizeX = p_sizeX;
		this.sizeY = p_sizeY;
		label = p_label;
		
		onClick = new GuiEvent!(GuiButton, int)();
		_blend = selectAesthetic();
	}

	this(int p_x, int p_y, int p_sizeX = 60, int p_sizeY = 22)
	{
		static int buttonCount = 0;
		this("Button" ~ to!string(buttonCount++), p_x, p_y, p_sizeX, p_sizeY);
	}

	override void render(Time p_t, RenderTarget p_canvas)
	{
		// set up some variables and settings for rendering
		int[2] globalpos = globalPosition;
		int xx = globalpos[0], yy = globalpos[1];
		GuiStyle st = getRoot().style;

		// select a few things before we draw
		_drawCoords = _state == GraphicState.Down ? [6, 0] : [3, 0];
		Vector2f buttonOffset = _state == GraphicState.Down ? Vector2f(0, 4) : Vector2f(0, 0);

		// draw the button
		st.get!Tileset("col1").drawTexturedRect(p_canvas, IntRect(xx, yy, sizeX, sizeY), _drawCoords, _blend);
		st.get!Tileset("col2").drawTexturedRect(p_canvas, IntRect(xx, yy, sizeX, sizeY), _drawCoords, st.globalColor);

		// draw the label
		static Text txt;
		if (txt is null) txt = new Text(to!dstring(label), cast(const)st.get!Font("main"), 8);
		txt.position = Vector2f(xx + 10, yy + 4) + buttonOffset;
		txt.setColor(Color.Black);
		p_canvas.draw(txt);

		super.render(p_t, p_canvas);
	}
protected:
	enum GraphicState
	{
		Normal,
		Hover,
		Down
	}
	GraphicState _state = GraphicState.Normal;
	Color _blend = Color(255, 255, 255);
	int[] _drawCoords = [3, 0];

	/// Select the right color based on the graphics state
	Color selectAesthetic()
	{
		switch(_state)
		{
			case GraphicState.Normal:
				return Color(225, 225, 225);
			case GraphicState.Hover:
				return Color(255, 255, 255);
			case GraphicState.Down:
				return Color(100, 100, 100);
			default: 
				return Color(255, 255, 255);
		}
	}

	@property 
	{
		GraphicState state() { return _state; };
		void state(GraphicState p_state)
		{
			if (_state != p_state)
			{
				_state = p_state;
			}
		}
	}
	
	/// Get the right state based on mouseDown + mousePosition
	bool refresh()
	{
		if (isMouseInside())
		{
			if (Mouse.isButtonPressed(Mouse.Button.Left))
				state = GraphicState.Down;
			else
				state = GraphicState.Hover;
			return true;
		}
		else
			state = GraphicState.Normal;
		return false;
	}

	override
	{
		bool processEvent(const(Event) p_e)
		{
			if(super.processEvent(p_e)) return true;

			if (p_e.type == Event.EventType.MouseButtonPressed) // Mouse press
			{
				if (refresh())
					focus();
				_blend = selectAesthetic();
			}

			return false;
		}

		void processGlobalEvent(const Event p_e)
		{
			if (p_e.type == Event.EventType.MouseMoved)
			{
				refresh();
				_blend = selectAesthetic();
			}
			else if (p_e.type == Event.EventType.MouseButtonReleased) // mouse release
			{
				refresh();
				
				if (_state == GraphicState.Down)
				{
					onClick.broadcast(this, p_e.mouseButton.button);
					state = GraphicState.Hover;
				}
				_blend = selectAesthetic();
			}

			super.processGlobalEvent(p_e);
		}
	}
}