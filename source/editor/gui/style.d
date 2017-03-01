/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editor.gui.style;

import janus.editor.settings;
import janus.engine.tileset;
import dsfml.graphics;

class GuiStyle
{
public:
	Color globalColor = Color(50, 75, 255);

	this(Tileset[string] p_tilesets, Font[string] p_fonts)
	{
		_tilesets = p_tilesets;
		_fonts = p_fonts;
	}

	/// Get an asset held by this style
	T get (T)(string p_name) 
		if (is(T : Tileset) || is(T : Font))
	{
		static if (is(T : Tileset))
			return _tilesets[p_name];
		else static if (is(T : Font))
			return _fonts[p_name];
	}

protected:
	Tileset[string] _tilesets;
	Font[string] _fonts;
}