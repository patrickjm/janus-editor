/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editor.gui.gui;

import janus.editor.gui;
import dsfml.graphics;
import dsfml.system.time;

class Gui : GuiComponent 
{
public:
	this()
	{
		x = 0;
		y = 0;
		sizeX = 0;
		sizeY = 0;
	}


	override
	{
		bool processEvent(const(Event) p_e)
		{
			super.processGlobalEvent(p_e);
			return super.processEvent(p_e);
		}

		void render(Time p_dt, RenderTarget p_canvas)
		{
			if (isAlive)
				renderChildren(p_dt, p_canvas);
		}
	}
	
	@property
	{
		GuiStyle style()
		{
			return _style;
		}
		
		void style(GuiStyle p_gs)
		{
			_style = p_gs;
		}
	}
	
protected:
	GuiStyle _style;
}