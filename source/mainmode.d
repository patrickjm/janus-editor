/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.mainmode;

import janus.engine : GameMode;
import dsfml.system : Time, Vector2f;
import dsfml.window : Event;
import dsfml.graphics : RenderTarget, RectangleShape, View;

class MainMode : GameMode
{
	this()
	{
		import janus.globals;
		cam = defaultView;
	}

	override bool processEvent(const(Event) e)
	{
		return false;
	}

	override void onSwitch()
	{

	}
	
	override void update(Time p_dt)
	{
	}

	View cam;

	override void render(Time p_dt, RenderTarget p_rt)
	{
		import dsfml.graphics : Text, RenderStates, Font, Color;
		import janus.globals;

		cam.move(Vector2f(-1, 0));
		window.view = cam;
		static RectangleShape shp;
		if (!shp) shp = new RectangleShape(Vector2f(50, 50));
		shp.position = Vector2f(200, 200);
		shp.fillColor = Color.Red;
		shp.outlineColor = Color.White;
		shp.draw(p_rt, RenderStates.Default);

		window.view = defaultView;
		static Text mode;
		if (!mode) mode = new Text("Game Mode janus.mainmode.MainMode", assets.get!Font("editor_gui"));
		mode.setCharacterSize(14);
		mode.position = Vector2f(5, 20);
		mode.setColor(Color.White);
		mode.draw(p_rt, RenderStates.Default);
	}
}