// Carpet tiling explorer
// David Riley <driley@moonfall.com>

// Tile data.
PImage[] all_tiles;
PImage[] tiles;
int tile_width = 200;
int tile_height = 200;
int tile_cols = 13;
int tile_rows = 12;

// UI/Display state.
boolean need_update = true;
boolean mouse_processed = false;
boolean shift_pressed = false;
boolean do_save = false;
int favourite;
PFont font;
char last_key = ' ';
boolean show_tiles = false;
boolean show_help = false;
int status_line;

String base_dir = "docs/tiles";
String[] files = {
  "formwork_cornice_I0518_00175_MAIN.jpg",
  "formwork_mortar_I0518_00700_MAIN.jpg",
  "formwork_rebar_I0518_00500_MAIN.jpg",
  "scaffold_cornice_I0519_00175_MAIN.jpg",
  "scaffold_mortar_I0519_00700_MAIN.jpg",
  "scaffold_rebar_I0519_00500_MAIN.jpg",
  "transverse_cornice_I0520_00175_MAIN.jpg",
  "transverse_mortar_I0520_00700_MAIN.jpg",
  "transverse_rebar_I0520_00500_MAIN.jpg",
};

enum Pattern
{
  MONOLITHIC,
  BRICK,
  ASHLAR,

  NUM_PATTERN,
};

enum Tile_strategy {
  FIXED_TILE_0,
  FIXED_TILE_1,
  FIXED_TILE_2,
  SEQUENTIAL_ROW,
  SEQUENTIAL_COL,
  SEQUENTIAL_ROW_COL,
  SEQUENTIAL_ROW_RANDOM,
  RANDOM,
  
  NUM_TILE_STRATEGY,
};

enum Rotation_strategy {
  FIXED_0,
  FIXED_90,
  ALTERNATING_90,
  ROTATING_90,
  RANDOM_180,
  RANDOM,
  
  NUM_ROTATION_STRATEGY,
};

class Modification
{
  int x;
  int y;
  int rotation;
  int tile;

  Modification(int x_, int y_)
  {
    x = x_;
    y = y_;
    rotation = 0;
    tile = 0;
  }

  Modification copy()
  {
    Modification rhs = new Modification(x, y);
    rhs.rotation = rotation;
    rhs.tile = tile;
    return rhs;
  }
};

class Config {
  int random_seed;
  boolean[] tile_enabled;
  Pattern pattern;
  Tile_strategy tile_strategy;
  Rotation_strategy rotation_strategy;
  int rotation_glitch;
  int pattern_offset_ratio;
  ArrayList<Modification> mods;
  int MAX_FAVOURITES = 18;

  Config() {
    initial();
  }

  void initial() {
    random_seed = 0;
    tile_enabled = new boolean[9];
    for (int i = 0; i < tile_enabled.length; ++i) {
      tile_enabled[i] = true;
    }
    pattern = Pattern.MONOLITHIC;
    tile_strategy = Tile_strategy.RANDOM;
    rotation_strategy = Rotation_strategy.RANDOM_180;
    rotation_glitch = 0;
    pattern_offset_ratio = 2;
    mods = new ArrayList<Modification>();
  }

  void basic()
  {
    random_seed = 0;
    for (int i = 0; i < tile_enabled.length; ++i) {
      tile_enabled[i] = i < 3;
    }
    pattern = Pattern.MONOLITHIC;
    tile_strategy = Tile_strategy.SEQUENTIAL_ROW;
    rotation_strategy = Rotation_strategy.FIXED_0;
    rotation_glitch = 0;
    pattern_offset_ratio = 2;
  }

  void favourite(int preset)
  {
    // Blank canvas.
    basic();

    // tiles
    // - 012 - formwork
    // - 345 - scaffold
    // - skip transvere since mortar doesn't have same shadows
    // pattern
    // - brick/ashlar make random look less jarring
    // tile strategy
    // - RANDOM almost always is favourite 
    // - SEQUENTIAL_ROW/SEQUENTIAL_COL only look good with a single
    //   tile with ALTERNATING_90 or ROTATING_90 (maybe RANDOM or RANDOM_90)
    // - SEQUENTIAL_ROW_COL 
    //   - MONOLITHIC && tile_enabled.length == 1
    //   - BRICK/ASHLAR look okay due to rebar being lighter colour

    // Switch between tilesets.
    if (preset % 2 == 1) {
      toggle_tile(0);
      toggle_tile(1);
      toggle_tile(2);
      toggle_tile(3);
      toggle_tile(4);
      toggle_tile(5);
    }
    preset /= 2;

    switch (preset) {
      case 0:
	tile_strategy = Tile_strategy.RANDOM;
	break;
      case 1:
	tile_strategy = Tile_strategy.RANDOM;
	rotation_strategy = Rotation_strategy.RANDOM_180;
	break;
      case 2:
	tile_strategy = Tile_strategy.RANDOM;
	rotation_strategy = Rotation_strategy.ALTERNATING_90;
	break;
      case 3:
	pattern = Pattern.BRICK;
	tile_strategy = Tile_strategy.RANDOM;
	break;
      case 4:
	pattern = Pattern.ASHLAR;
	tile_strategy = Tile_strategy.RANDOM;
	break;
      case 5:
	pattern = Pattern.BRICK;
	tile_strategy = Tile_strategy.SEQUENTIAL_ROW_COL;
	break;
      case 6:
	pattern = Pattern.ASHLAR;
	tile_strategy = Tile_strategy.SEQUENTIAL_ROW_COL;
	break;
      case 7:
	pattern = Pattern.BRICK;
	tile_strategy = Tile_strategy.SEQUENTIAL_ROW_COL;
	rotation_strategy = Rotation_strategy.ALTERNATING_90;
	break;
      case 8:
	pattern = Pattern.ASHLAR;
	tile_strategy = Tile_strategy.SEQUENTIAL_ROW_COL;
	rotation_strategy = Rotation_strategy.ALTERNATING_90;
	break;
    }
  }

  void randomize()
  {
    random_seed = millis() + int(random(Integer.MAX_VALUE));
    randomSeed(random_seed);
    pattern = Pattern.values()[int(random(Pattern.NUM_PATTERN.ordinal()))];
    tile_strategy = Tile_strategy.values()[int(random(Tile_strategy.NUM_TILE_STRATEGY.ordinal()))];
    rotation_strategy = Rotation_strategy.values()[int(random(Rotation_strategy.NUM_ROTATION_STRATEGY.ordinal()))];
    rotation_glitch = int(random(2)) == 0 ? 0 : int(random(100));
    pattern_offset_ratio = int(random(3)) + 1;
  }

  void randomize_tiles()
  {
    for (int i = 0; i < tile_enabled.length; ++i) {
      tile_enabled[i] = int(random(2)) == 0;
    }
  }

  Config copy() {
    Config rhs = new Config();
    rhs.random_seed = random_seed;
    rhs.tile_enabled = new boolean[9];
    for (int i = 0; i < tile_enabled.length; ++i) {
      rhs.tile_enabled[i] = tile_enabled[i];
    }
    rhs.pattern = pattern;
    rhs.tile_strategy = tile_strategy;
    rhs.rotation_strategy = rotation_strategy;
    rhs.rotation_glitch = rotation_glitch;
    rhs.pattern_offset_ratio = pattern_offset_ratio;
    for (Modification mod: mods) {
      rhs.mods.add(mod.copy());
    }
    return rhs;
  }

  void reseed(int seed) {
    random_seed = seed;
  }

  void toggle_tile(int index)
  {
    if (index < tile_enabled.length) {
      tile_enabled[index] = !tile_enabled[index];
    }
  }

  void adjust_pattern(int delta)
  {
    pattern = Pattern.values()[(pattern.ordinal() + delta + Pattern.NUM_PATTERN.ordinal()) % Pattern.NUM_PATTERN.ordinal()];
  }

  void adjust_rotation_strategy(int delta)
  {
    rotation_strategy = Rotation_strategy.values()[(rotation_strategy.ordinal() + delta + Rotation_strategy.NUM_ROTATION_STRATEGY.ordinal()) % Rotation_strategy.NUM_ROTATION_STRATEGY.ordinal()];
  }

  void adjust_tile_strategy(int delta)
  {
    tile_strategy = Tile_strategy.values()[(tile_strategy.ordinal() + delta + Tile_strategy.NUM_TILE_STRATEGY.ordinal()) % Tile_strategy.NUM_TILE_STRATEGY.ordinal()];
  }

  void adjust_glitch(int delta)
  {
    rotation_glitch += delta;
    if (config.rotation_glitch < 0) {
      config.rotation_glitch = 0;
    } else if (config.rotation_glitch > 100) {
      config.rotation_glitch = 100;
    }
  }

  void adjust_offset_ratio(int delta) {
    pattern_offset_ratio += delta;
    if (pattern_offset_ratio < 1) {
      pattern_offset_ratio = 1;
    }
  }

  void clear_modifications()
  {
    mods.clear();
  }

  void remove_modification(int x, int y)
  {
    for (int i = 0; i < mods.size(); ++i) {
      Modification mod = mods.get(i);
      if (mod.x == x && mod.y == y) {
	mods.remove(i);
	return;
      }
    }
  }

  Modification get_modification(int x, int y, boolean add)
  {
    for (Modification mod: mods) {
      if (mod.x == x && mod.y == y) {
	return mod;
      }
    }

    if (add) {
      Modification mod = new Modification(x, y);
      mods.add(mod);
      return mod;
    } else {
      return null;
    }
  }
};

void push_config()
{
  // Remove anything forward from the current undo point.
  old_configs.subList(current_config + 1, old_configs.size()).clear();

  // Add the new config.
  old_configs.add(config.copy());
  current_config = old_configs.size() - 1;
}

Config config = new Config();
Config saved_config = new Config();
ArrayList<Config> old_configs = new ArrayList<Config>();
int current_config = 0;

PImage prepImage(String filename)
{
  PImage orig = loadImage(base_dir + "/" + filename);
  PImage tile = createImage(tile_width, tile_height, RGB);
  tile.copy(orig, 0, 0, 1700, 1700, 0, 0, tile_width, tile_height);
  return tile;
}

void setup() {
  size(2600, 2400);
  all_tiles = new PImage[files.length];
  tiles = new PImage[files.length];
  for (int i = 0; i < files.length; ++i) {
    all_tiles[i] = prepImage(files[i]);
  }

  font = createFont("Monaco", 12);
  if (font != null) {
    textFont(font);
  }

  old_configs.add(config.copy());
}

void keyPressed()
{
  need_update = true;

  char input = key;
  if (key == '.') {
    input = last_key;
  } else if (key == CODED) {
    if (keyCode == SHIFT) {
      shift_pressed = true;
    }
  } else if (key != CODED) {
    last_key = key;
  }

  // Handle input which doesn't modify config and returns before saving
  // the current state.
  switch (input) {
    case 'h':
      show_help = !show_help;
      return;
    case 'q':
      exit();
      break;
    case 'S':
      do_save = true;
    case 'u':
      // Move config back in the undo stack.
      if (current_config > 0) {
	current_config -= 1;
	config = old_configs.get(current_config).copy();
      }
      return;
    case 18: // CTRL-R
    case 'U':
      if (current_config + 1 < old_configs.size()) {
	current_config += 1;
	config = old_configs.get(current_config).copy();
      }
      return;
    case '*':
      saved_config = config.copy();
      status("saved_config seed(): " + saved_config.random_seed);
      return;
    case '?':
      show_tiles = !show_tiles;
      return;
  }

  // Clear modifications in most cases.
  boolean clear_mods = true;

  switch (input) {
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      config.toggle_tile(input - '1');
      break;
    case 'A':
    case 'B':
    case 'C':
      config.toggle_tile((input - 'A') * 3);
      config.toggle_tile((input - 'A') * 3 + 1);
      config.toggle_tile((input - 'A') * 3 + 2);
      break;
    case 'D':
    case 'E':
    case 'F':
      config.toggle_tile((input - 'D'));
      config.toggle_tile((input - 'D') + 3);
      config.toggle_tile((input - 'D') + 6);
      break;
    case 'b':
      config.basic();
      break;
    case 'f':
      favourite = (favourite + 1) % config.MAX_FAVOURITES;
      config.favourite(favourite);
      println("favourite: " + favourite);
      break;
    case 'g':
      config.adjust_glitch(1);
      break;
    case 'G':
      config.adjust_glitch(-1);
      break;
    case '>':
      config.adjust_glitch(10);
      break;
    case '<':
      config.adjust_glitch(-10);
      break;
    case 'i':
      config.basic();
      break;
    case 'm':
      config.clear_modifications();
      break;
    case 'o':
      config.adjust_offset_ratio(1);
      break;
    case 'O':
      config.adjust_offset_ratio(-1);
      break;
    case 'p':
      config.adjust_pattern(1);
      break;
    case 'P':
      config.adjust_pattern(-1);
      break;
    case 'r':
      config.adjust_rotation_strategy(1);
      break;
    case 'R':
      config.adjust_rotation_strategy(-1);
      break;
    case 's':
      config.reseed(millis());
      break;
    case 't':
      config.adjust_tile_strategy(1);
      break;
    case 'T':
      config.adjust_tile_strategy(-1);
      break;
    case 'x':
      config.randomize();
      break;
    case 'X':
      config.randomize();
      config.randomize_tiles();
      break;
    case '!':
      config = saved_config.copy();
      clear_mods = false;
      break;
    case '^':
      Config temp = saved_config;
      saved_config = config;
      config = temp;
      clear_mods = false;
      break;
    default:
      // Ignore unknown key input.
      return;
  }

  if (clear_mods) {
    config.clear_modifications();
  }

  push_config();
}

void keyReleased()
{
  if (key == CODED) {
    if (keyCode == SHIFT) {
      shift_pressed = false;
    }
  }
}

void status(String s)
{
  ++status_line;
  text(s, 20, status_line * 20);
}

void render() {
  if (!need_update) {
    return;
  }
  need_update = false;

  randomSeed(config.random_seed);
  status_line = 0;

  // Count how many tiles are enabled.
  int tile_count = 0;
  for (int i = 0; i < config.tile_enabled.length; ++i) {
    if (config.tile_enabled[i] && i < all_tiles.length) {
      tiles[tile_count] = all_tiles[i];
      ++tile_count;
    }
  }

  if (tile_count == 0) {
    tiles[0] = all_tiles[0];
    tile_count = 1;
  }

  // Calculate an entire double set of rows and columns to handle offsets.
  // The Brick and Ashlar patterns actually offset the tiles by up to half
  // a tile width per row or column, so just start drawing at negative
  // values off the canvas.  To ensure the entire canvas is drawn to,
  // draw twice as much.

  int[] per_row_random = new int[tile_rows * 2];
  for (int i = 0; i < tile_rows * 2; ++i) {
    per_row_random[i] = int(random(tile_count));
  }

  for (int y = 0; y < tile_rows * 2; ++y) {
    for (int x = 0; x < tile_cols * 2; ++x) {
      int tile_x = x * tile_width;
      int tile_y = y * tile_height;
      int tile_num = 0;
      float rot = 0;
      int pattern_offset = tile_width / config.pattern_offset_ratio;
      switch (config.pattern) {
        case MONOLITHIC:
	default:
	  tile_x = x * tile_width;
	  tile_y = y * tile_height;
	  break;
	case BRICK:
	  // Offset is in reverse to ensure valid data for the entire row.
	  tile_x = x * tile_width - y * pattern_offset;
	  tile_y = y * tile_height;
	  break;
	case ASHLAR:
	  // Offset is in reverse to ensure valid data for the entire col.
	  tile_x = x * tile_width;
	  tile_y = y * tile_height - x * pattern_offset;
	  break;
      }

      // All modifications to tile_x and tile_y should be performed by now.
      if (mousePressed && !mouse_processed) {
	if (mouseX >= tile_x && mouseX < tile_x + tile_width &&
	    mouseY >= tile_y && mouseY < tile_y + tile_height) {
	  if (mouseButton == LEFT) {
	    Modification mod = config.get_modification(x, y, true);
	    mod.rotation += shift_pressed ? -90 : 90;
	    push_config();
	  } else if (mouseButton == CENTER) {
	    config.remove_modification(x, y);
	    push_config();
	  } else if (mouseButton == RIGHT) {
	    Modification mod = config.get_modification(x, y, true);
	    mod.tile += shift_pressed ? -1 : 1;
	    push_config();
	  }
	}
      }

      // Always calculate random value to have the same number of random()
      // calls for each mode.
      int tile_random = int(random(tile_count));
      switch (config.tile_strategy) {
        case FIXED_TILE_0:
          tile_num = 0;
          break;
        case FIXED_TILE_1:
          tile_num = 1;
          break;
        case FIXED_TILE_2:
          tile_num = 2;
          break;
        case SEQUENTIAL_ROW:
          tile_num = x % tile_count;
          break;
        case SEQUENTIAL_COL:
          tile_num = y % tile_count;
          break;
        case SEQUENTIAL_ROW_COL:
          tile_num = (x + y) % tile_count;
          break;
        case SEQUENTIAL_ROW_RANDOM:
          tile_num = (x + per_row_random[y]) % tile_count;
          break;
        case RANDOM:
          tile_num = tile_random;
          break;
      }
      
      // Always calculate random value to have the same number of random()
      // calls for each mode.
      int rotation_random = int(random(4));
      switch (config.rotation_strategy) {
        case FIXED_0:
          rot = 0;
          break;
        case FIXED_90:
          rot = 90;
          break;
	case ALTERNATING_90:
	  // aka Quarter Turned.
	  rot = (x + y) % 2 * 90;
	  break;
	case ROTATING_90:
	  // aka Quarter Turned.
	  rot = (x + y) % 4 * 90;
	  break;
        case RANDOM:
          rot = rotation_random * 90;
          break;
        case RANDOM_180:
          rot = (rotation_random % 2) * 180;
          break;
      }

      // Calculate random_rot first so that the same number of random() calls
      // happen which will result in additional tiles being made glitched.
      int random_rot = 90 + int(random(2)) * 180;
      if (int(random(100)) < config.rotation_glitch) {
        rot += random_rot;
      }

      Modification mod = config.get_modification(x, y, false);
      if (mod != null) {
	rot += mod.rotation;
	tile_num = tile_num + mod.tile;
	while (tile_num < 0) {
	  tile_num += tile_count;
	}
	tile_num %= tile_count;
      }

      PImage tile = tiles[tile_num];
      pushMatrix();
      translate(tile_x, tile_y);
      translate(tile_width / 2, tile_height / 2);
      rotate(radians(rot));
      translate(-tile_width / 2 , -tile_height / 2);
      image(tile, 0, 0);
      popMatrix();
    }
  }

  if (do_save) {
    String name = String.format("saved-%02d%02d%02d-%02d%02d%02d.jpg",
			        year(), month(), day(), hour(), minute(),
				second());
    save(name);
    do_save = false;
  }
  
  // status("old_configs: " + old_configs.size());
  // for (int i = 0; i < old_configs.size(); ++i) {
  //   Config old = old_configs.get(i);
  //   status("  seed: " + old.random_seed + "; mods: " + old.mods.size() +
  //          (current_config == i ? "*" : ""));
  // }
  status("seed: " + config.random_seed);
  String s = "tiles: ";
  for (int i = 0; i < config.tile_enabled.length; ++i) {
    s += config.tile_enabled[i] ? i + 1 : "_";
  }
  status(s);
  if (show_tiles) {
    for (int i = 0; i < config.tile_enabled.length; ++i) {
      if (config.tile_enabled[i]) {
	status("  " + (i + 1) + ": " + files[i]);
      }
    }
  }
  status("pattern: " + config.pattern.toString());
  status("tile strategy: " + config.tile_strategy.toString());
  status("rotation strategy: " + config.rotation_strategy.toString());
  status("rotation glitch percent: " + config.rotation_glitch);
  status("pattern offset ratio: " + config.pattern_offset_ratio);
  status("modifications: " + config.mods.size());
  // status("key pressed: " + int(key));
  if (show_help) {
    status("");
    status("commands:");
    status("  1-9   toggle tile");
    status("  ABC   togle tile set");
    status("  DEF   togle tile colour");
    status("  b     basic configuration");
    status("  gG><  adjust rotation glitch percent");
    status("  h     show this message");
    status("  i     initial configuration");
    status("  m     clear modifications");
    status("  oO    adjust pattern offset ratio");
    status("  pP    adjust pattern");
    status("  q     quit");
    status("  rR    adjust rotation strategy");
    status("  s     new random seed");
    status("  S     save image");
    status("  tT    adjust tile strategy");
    status("  u     undo last config change");
    status("  U     redo last config change");
    status("  x     randomize layout");
    status("  X     randomize layout and tile selection");
    status("  *     save config");
    status("  !     load saved config");
    status("  ^     swap with saved config");
    status("  .     repeat last command");
    status("  ?     show tile names");

    // String[] fontList = PFont.list();
    // for (String i: fontList) {
    //   status(i);
    // }
  }

  if (mousePressed) {
    // Avoid repeated mouse updated.
    mouse_processed = true;
  }
}

void draw()
{
  if (mousePressed) {
    need_update = true;
  } else if (mouse_processed) {
    mouse_processed = false;
    need_update = true;
  }
  render();
  delay(5);
}
