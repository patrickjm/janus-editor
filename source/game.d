/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.game;

import std.stdio, std.conv;

import dsfml.system : Time;
import dsfml.graphics;

version(Editor)
	import janus.editormode;
import janus.globals;
import janus.mainmode;
import janus.engine.eventprocessor;
import janus.engine.gamemode;
import janus.engine.level.level;

enum GameModes
{
	Main,
	Editor
}

/// Top of the heirarchy. Manages game modes and updates them accordingly
class Game : EventProcessor
{
	int framesPerSecond = 0;

	this()
	{
	}

	// Main game initialization and game loop
	void start()
	{
		_restartTriggered = true;
		while(_restartTriggered)
		{
			_restartTriggered = false;
			engineInit();
			gameInit();
			engineLoop();
		}
	}

	void engineInit()
	{
		// Set up window and give OpenGL a context to work with
		auto settings = ContextSettings(24, 8, 4, 3, 0);
		writeln(text("OpenGL Version ", settings.majorVersion, ".", settings.minorVersion));
		window = new RenderWindow(VideoMode(EngineSettings.Render.WinSizeX, EngineSettings.Render.WinSizeY), "Janus", Window.Style.DefaultStyle, settings);
		
		// establish other engine.globals
		input = new Input();
		assets = new Assets();
		assets.load();
		manager = this;
		
		// Cap FPS if necessary
		static if (EngineSettings.Render.CapFps > 0)
			window.setFramerateLimit(cast(uint)EngineSettings.Render.CapFps);
		// VSync if necessary
		window.setVerticalSyncEnabled(EngineSettings.Render.Vsync);
	}

	void gameInit()
	{
		_level = new Level();
		_modes = [ GameModes.Main : new MainMode() ];
		_currentMode = GameModes.Main;
		version(Editor) 
		{
			_modes[GameModes.Editor] = new EditorMode(_level);
			_currentMode = GameModes.Editor;
		}
		manager = this;
	}

	void engineLoop()
	{
		// clocks and timers for FPS purposes
		auto clock = new Clock();
		auto elapsed = new Clock();
		float lastTime = 0;
		int secondTimer = 0;

		// main game loop
		while (window.isOpen())
		{
			// input management
			input.pull(manager);
			if(input.event(Event.EventType.Closed))
				window.close();

			// update clocks and game step
			Time dt = clock.getElapsedTime();
			manager.update(dt);

			// clear screen and render
			window.clear(mixin(EngineSettings.Render.ClearColor));
			manager.render(dt, window);
			window.display();

			// refresh input
			input.clear();
			
			// fps management
			float currentTime = clock.restart().asSeconds();
			if (cast(int)elapsed.getElapsedTime().asSeconds() > secondTimer) // update window title every second
			{
				secondTimer = cast(int)elapsed.getElapsedTime().asSeconds();
				manager.framesPerSecond = cast(int)(1.0 / (currentTime - lastTime));
			}

			if (_restartTriggered)
				window.close();
		}
	}

	/// Updates game step
	void update(Time p_time)
	{
		_modes[_currentMode].update(p_time);
	}

	void render(Time p_time, RenderTarget p_target)
	{
		_modes[_currentMode].render(p_time, p_target);

		// render FPS in top left of screen
		import std.conv;
		import dsfml.graphics : Text, Color, RenderStates;
		static Text fps;
		if (!fps) 
		{
			fps = new Text("", assets.get!Font("editor_gui"));
			fps.setCharacterSize(14);
			fps.position = Vector2f(5, 5);
			fps.setColor(Color.White);
		}
		fps.setString(to!dstring(manager.framesPerSecond));
		fps.draw(p_target, RenderStates.Default);
	}

	bool processEvent(const(Event) p_e)
	{
		return _modes[_currentMode].processEvent(p_e);
	}

	// restarts the program
	void triggerRestart()
	{
		import std.stdio;
		writeln("OK\n\n\n\nOK");
		_restartTriggered = true;
	}

	@property
	{
		GameModes mode() { return _currentMode; }
		GameModes mode(GameModes p_m) 
		{ 
			_currentMode = p_m;
			_modes[p_m].onSwitch();
			return p_m; 
		}
		Level level() { return _level; }
	}

protected:
	Level _level;
	GameModes _currentMode = GameModes.Main;
	GameMode[GameModes] _modes;
	bool _restartTriggered = false;
}

