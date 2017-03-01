/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.editor.settings;

import ctini.ctini;

public
{
	enum EditorSettings = IniConfig!"editor.ini";
}