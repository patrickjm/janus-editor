/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.engine.eventprocessor;

public
{
	import dsfml.window.event;
}

/// Processes input events (keyboard, mouse, etc..)
interface EventProcessor
{
	/// Returns true if the event is processed, false if it was not
	bool processEvent(const(Event) e);
}