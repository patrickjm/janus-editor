/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editormode;

import dsfml.system : Time;
import dsfml.window : Event;
import dsfml.graphics : RenderTarget, Color;

import janus.editor.editor;
import janus.engine.gamemode;
import janus.engine.level : Level;

/// provides an interface to the editor class
class EditorMode : GameMode
{
	this(Level p_level)
	{
		_level = p_level;
		_editor = new Editor(p_level);
		import janus.globals;
		editor = _editor;
	}

	override bool processEvent(const(Event) p_e)
	{
		return _editor.processEvent(p_e);
	}

	override void onSwitch()
	{
//		foreach(poly; _level.polygons)
//		{
//			poly.renderOptions.useShader = true;
//			poly.renderOptions.outlineColor = Color.White;
//			poly.renderOptions.boundingBoxColor.nullify();
//		}
	}

	override void update(Time p_dt)
	{
		
	}

	override void render(Time p_dt, RenderTarget p_rt)
	{
		_editor.render(p_dt, p_rt);
	}

protected:
	Level _level;
	Editor _editor;
}