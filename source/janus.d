/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.app;

pragma(lib, "lib\\dsfml-window.lib");
pragma(lib, "lib\\dsfml-system.lib");
pragma(lib, "lib\\dsfml-audio.lib");
pragma(lib, "lib\\dsfml-graphics.lib");
pragma(lib, "lib\\dsfml-network.lib");

import janus.game;

void main(string[] args)
{
	Game janusGame = new Game();
	janusGame.start();
}