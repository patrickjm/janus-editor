/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editor.gui.window;

import janus.editor.gui, janus.editor.settings, janus.engine.tileset;
import dsfml.graphics;
import core.time;
import std.string, std.conv;

class GuiWindow : GuiComponent
{
public:
	this(string p_label, int p_x, int p_y, int p_sizeX = 100, int p_sizeY = 100)
	{
		x = p_x;
		y = p_y;
		sizeX = p_sizeX;
		sizeY = p_sizeY;
		label = p_label;
	}

	this(int p_x, int p_y, int p_sizeX = 100, int p_sizeY = 100)
	{
		static int windowCount = 0;
		this("Window" ~ to!string(windowCount++), p_x, p_y, p_sizeX, p_sizeY);
	}

	override
	{
		@property
		{
			/// X position bounding children
			int clientX()
			{
				return x + getRoot().style.get!Tileset("col1").frameWidth + EditorSettings.Gui.Window.ClientX;
			}
			
			/// Y position bounding children
			int clientY()
			{
				return y + getRoot().style.get!Tileset("col1").frameHeight + EditorSettings.Gui.Window.ClientY;
			}
		}

		void render(Time p_dt, RenderTarget p_canvas)
		{
			GuiStyle st = getRoot().style;
			
			st.get!Tileset("col2").drawTexturedRect(p_canvas, IntRect(x, y, sizeX, sizeY), [0, 0], st.globalColor + Color(100, 100, 100));

			// draw title
			static Text txt;
			if (txt is null) txt = new Text(to!dstring(label), cast(const)st.get!Font("main"), 8);
			txt.setString(to!dstring(label));
			txt.setColor(Color.White);
			txt.position = Vector2f(x + 9, y + 6);
			p_canvas.draw(txt);

			super.render(p_dt, p_canvas);
		}
	}

protected:
	override
	{
		bool processEvent(const(Event) p_e)
		{
			if (super.processEvent(p_e))
				return true;

			if (p_e.type == Event.EventType.MouseButtonPressed && isMouseInside())
			{
				moveToFront();
				return true;
			}

			return false;
		}
	}
}