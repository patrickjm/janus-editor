/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editor.gui.quickie;

import std.typecons : Nullable;
import std.conv;

import dsfml.system.time;
import dsfml.graphics;

import janus.editor.gui;

/// very extensible, event-based, bare-bones component
class GuiQuickie : GuiComponent
{
public:
	GuiEvent!(GuiQuickie, Time, RenderTarget, float, float) onRender;
	GuiEvent!(GuiQuickie, const(Event)) onProcessEvent;
	/// since events can't return, set this to true if an event is processed
	bool eventProcessed = false;
	
	this(string p_label, int p_x, int p_y, int p_sizeX = 10, int p_sizeY = 10)
	{
		x = p_x - p_sizeX / 2;
		y = p_y - p_sizeY / 2;
		sizeX = p_sizeX;
		sizeY = p_sizeY;
		label = p_label;
		
		onRender = new GuiEvent!(GuiQuickie, Time, RenderTarget, float, float)();
		onProcessEvent = new GuiEvent!(GuiQuickie, const(Event))();
	}
	
	this(int p_x, int p_y, int p_sizeX = 10, int p_sizeY = 10)
	{
		static int quickieCount = 0;
		this("Quickie" ~ to!string(quickieCount++), p_x, p_y, p_sizeX, p_sizeY);
	}

	override void render(Time p_dt, RenderTarget p_canvas)
	{
		if (!isAlive)
			return;
		super.render(p_dt, p_canvas);
		onRender.broadcast(this, p_dt, p_canvas, x, y);
	}

	override bool processEvent(const(Event) p_e)
	{
		if (!isAlive)
			return false;
		eventProcessed = false; // reset
		if (super.processEvent(p_e)) // call parent
			return true;
		onProcessEvent.broadcast(this, p_e); // call event
		bool ret = eventProcessed; // cache eventProcessed for return so it can be cleared first
		eventProcessed = false;
		return ret;
	}
	
	@property
	{
		Object meta() { return _meta; }
		Object meta(Object p_meta) { _meta = p_meta; return _meta; }
	}
	
protected:
	/// Used to store useful info in this node
	Object _meta;
}