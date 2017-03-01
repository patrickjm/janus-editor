/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.engine.sizeable;

import dsfml.graphics.rect;

interface Sizeable
{
	@property FloatRect bounds();
}