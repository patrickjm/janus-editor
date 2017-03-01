/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.engine.settings;

import ctini.ctini;

public
{
	enum EngineSettings = IniConfig!"engine.ini";
}