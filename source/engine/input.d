/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.engine.input;

import janus.globals;
import janus.engine.eventprocessor;
import janus.editor.gui.gui;
import dsfml.graphics;

class Input
{
	this()
	{

	}

	void pull()
	{
		static Event e;
		while(window.pollEvent(e))
		{
			_events ~= e.type;
			_keyCodes ~= e.key.code;
			_mouseButtons ~= e.mouseButton.button;
		}
	}

	void pull(EventProcessor p_ep)
	{
		static Event e;
		while(window.pollEvent(e))
		{
			if (!p_ep.processEvent(e))
			{
				_events ~= e.type;
				_keyCodes ~= e.key.code;
				_mouseButtons ~= e.mouseButton.button;
			}
		}
	}

	void clear()
	{
		_events = [];
		_keyCodes = [];
		_mouseButtons = [];
	}

	bool event(Event.EventType p_event)
	{
		foreach(e; _events)
			if (e is p_event)
				return true;
		return false;
	}

	bool keyPressed(Keyboard.Key p_keyCode)
	{
		if(event(Event.EventType.KeyPressed))
			foreach(keyCode; _keyCodes)
				if(keyCode is cast(int)p_keyCode)
					return true;
		return false;
	}

	bool keyReleased(Keyboard.Key p_keyCode)
	{
		if(event(Event.EventType.KeyReleased))
			foreach(keyCode; _keyCodes)
				if(keyCode is cast(int)p_keyCode)
					return true;
		return false;
	}

	bool mouseButtonPressed(Mouse.Button p_button)
	{
		if(event(Event.EventType.MouseButtonPressed))
			foreach(button; _mouseButtons)
				if(button is cast(int)p_button)
					return true;
		return false;
	}

	bool mouseButtonReleased(Mouse.Button p_button)
	{
		if(event(Event.EventType.MouseButtonReleased))
			foreach(button; _mouseButtons)
				if(button is cast(int)p_button)
					return true;
		return false;
	}

	private
	{
		Event.EventType[] _events;
		int[] _keyCodes;
		int[] _mouseButtons;
	}
}

