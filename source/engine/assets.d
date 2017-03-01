/+
 + This source file is part of proprietary software.
 + © 2014 Patrick Moriarty and Ryan Goodman.
 + All rights reserved.
+/
module janus.engine.assets;

import std.file, std.json, std.conv, std.stdio, std.string;
import dsfml.graphics.texture, dsfml.graphics.font, dsfml.graphics.shader;

import janus.engine.tileset;

class Assets
{

	this()
	{

	}

	T get(T) (string p_name)
	{
		static if (is(T : Texture))
			return _textures[p_name];
		else static if (is(T : Font))
			return _fonts[p_name];
		else static if (is(T : Shader))
			return _shaders[p_name];
		else static if (is(T : Tileset))
			return _tilesets[p_name];
		else
			return null;
	}

	void load()
	{
		// totally inconspicuous welcome message
		writeln(readText(_basePath ~ "m.txt"));

		auto content = to!string(read(_settingsFile)); // load file text

		JSONValue[string] document = parseJSON(content).object;

		loadTextures(document["textures"]);
		loadFonts(document["fonts"]);
		loadShaders(document["shaders"]);
		loadTilesets(document["tilesets"]);
	}

	private
	{
		static const string _basePath = "assets/";
		static const string _settingsFile = _basePath ~ "assets.json";

		Texture[string] _textures;
		Font[string] _fonts;
		Shader[string] _shaders;
		Tileset[string] _tilesets;

		// reads the json file
		void loadTextures(JSONValue p_textureTree)
		{
			JSONValue[] textures = p_textureTree.array;
			foreach(textureJson; textures)
			{
				JSONValue[string] texture = textureJson.object;
				string name = texture["name"].str;
				string path = texture["path"].str;

				Texture t = new Texture();
				t.loadFromFile(_basePath ~ path);
				_textures[name] = t;

				writefln("Texture [%s] loaded from [%s]", name, path);
			}
		}

		void loadFonts(JSONValue p_fontTree)
		{
			JSONValue[] fonts = p_fontTree.array;
			foreach(fontJson; fonts)
			{
				JSONValue[string] font = fontJson.object;
				string name = font["name"].str;
				string path = font["path"].str;

				Font f = new Font();
				f.loadFromFile(_basePath ~ path);
				_fonts[name] = f;

				writefln("Font [%s] loaded from [%s]", name, path);
			}
		}

		void loadShaders(JSONValue p_shaderTree)
		{
			JSONValue[] shaders = p_shaderTree.array;
			foreach(shaderJson; shaders)
			{
				JSONValue[string] shader = shaderJson.object;
				string name = shader["name"].str;
				string path = shader["path"].str;
				string type = shader["type"].str;

				Shader.Type[string] map = [
					"fragment" : Shader.Type.Fragment,
					"vertex"   : Shader.Type.Vertex
				];
				
				Shader s = new Shader();
				if (!s.loadFromFile(_basePath ~ path, map[type.toLower]))
					assert(0, text("Unable to load ", type, " shader ", name, ". Looks like you're shit out of luck!"));
				_shaders[name] = s;
				
				writefln("%s Shader [%s] loaded from [%s]", type.capitalize, name, path);
			}
		}

		void loadTilesets(JSONValue p_tilesetTree)
		{
			JSONValue[] tilesets = p_tilesetTree.array;
			foreach(tilesetJson; tilesets)
			{
				JSONValue[string] tileset = tilesetJson.object;
				string name = tileset["name"].str;
				string texture = tileset["texture"].str;
				int tileWidth = cast(int)tileset["tileWidth"].integer;
				int tileHeight = cast(int)tileset["tileHeight"].integer;

				Texture t = get!Texture(texture);
				Tileset s = new Tileset(t, tileWidth, tileHeight);
				_tilesets[name] = s;
				
				writefln("Tileset [%s](%d, %d) registered with texture [%s]", name, tileWidth, tileHeight, texture);
			}
		}
	}
};



