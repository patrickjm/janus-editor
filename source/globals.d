/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.globals;

public
{
	import janus.engine.settings;

	import dsfml.graphics.renderwindow;
	import dsfml.graphics.view;
	RenderWindow window;
	View defaultView() /// returns a new view that fits the viewport of the window
	{
		import dsfml.graphics.rect;
		return new View(FloatRect(0, 0, window.getSize.x, window.getSize.y));
	}

	import janus.engine.assets;
	Assets assets;

	import janus.engine.input;
	Input input;

	import janus.game;
	Game manager;

	version(Editor)
	{
		import janus.editor.editor;
		Editor editor;
	}
}