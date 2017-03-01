/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.engine.gamemode;

import janus.engine.eventprocessor;
import dsfml.system : Time;
import dsfml.graphics : RenderTarget;

class GameMode : EventProcessor
{
	abstract bool processEvent(const(Event) e);
	/// Called when this game mode is switched to
	abstract void onSwitch();
	abstract void update(Time p_dt);
	abstract void render(Time p_dt, RenderTarget p_rt);
}