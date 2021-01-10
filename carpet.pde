PImage[] all_tiles;
PImage[] tiles;
boolean[] tile_enabled;
int tile_width = 200;
int tile_height = 200;
int tile_cols = 13;
int tile_rows = 12;

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

int random_seed = 0;
Pattern pattern = Pattern.MONOLITHIC;
Tile_strategy tile_strategy = Tile_strategy.RANDOM;
Rotation_strategy rotation_strategy = Rotation_strategy.RANDOM_180;
int rotation_glitch = 0;
int pattern_offset_ratio = 2;
boolean show_tiles = false;
boolean show_help = false;
PFont font;

int status_line;

PImage prepImage(String filename)
{
  PImage orig = loadImage(filename);
  PImage tile = createImage(tile_width, tile_height, RGB);
  tile.copy(orig, 0, 0, 1700, 1700, 0, 0, tile_width, tile_height);
  return tile;
}

void setup() {
  size(2600, 2400);
  all_tiles = new PImage[files.length];
  tiles = new PImage[files.length];
  tile_enabled = new boolean[files.length];
  for (int i = 0; i < files.length; ++i) {
    all_tiles[i] = prepImage(files[i]);
    tile_enabled[i] = true;
  }
  font = createFont("Monaco", 12);
  if (font != null) {
    textFont(font);
  }
}

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

void toggle_tile(int index)
{
  if (index < tile_enabled.length) {
    tile_enabled[index] = !tile_enabled[index];
  }
}

void keyPressed()
{
  switch(key) {
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      toggle_tile(key - '1');
      break;
    case 'A':
    case 'B':
    case 'C':
      toggle_tile((key - 'A') * 3);
      toggle_tile((key - 'A') * 3 + 1);
      toggle_tile((key - 'A') * 3 + 2);
      break;
    case 'D':
    case 'E':
    case 'F':
      toggle_tile((key - 'D'));
      toggle_tile((key - 'D') + 3);
      toggle_tile((key - 'D') + 6);
      break;
    case 'b':
      random_seed = 0;
      pattern = Pattern.MONOLITHIC;
      tile_strategy = Tile_strategy.SEQUENTIAL_ROW;
      rotation_strategy = Rotation_strategy.FIXED_0;
      rotation_glitch = 0;
      pattern_offset_ratio = 2;
      for (int i = 0; i < tile_enabled.length; ++i) {
        tile_enabled[i] = i < 3;
      }
      break;
    case 'g':
      rotation_glitch += 1;
      if (rotation_glitch > 100) {
        rotation_glitch = 100;
      }
      break;
    case 'G':
      rotation_glitch -= 1;
      if (rotation_glitch < 0) {
        rotation_glitch = 0;
      }
      break;
    case '>':
      rotation_glitch += 10;
      if (rotation_glitch > 100) {
        rotation_glitch = 100;
      }
      break;
    case '<':
      rotation_glitch -= 10;
      if (rotation_glitch < 0) {
        rotation_glitch = 0;
      }
      break;
    case 'h':
      show_help = !show_help;
      break;
    case 'o':
      pattern_offset_ratio += 1;
      break;
    case 'O':
      pattern_offset_ratio -= 1;
      if (pattern_offset_ratio < 1) {
        pattern_offset_ratio = 1;
      }
      break;
    case 'p':
      next_pattern(1);
      break;
    case 'P':
      next_pattern(-1);
      break;
    case 'q':
      exit();
      break;
    case 'r':
      next_rotation_strategy(1);
      break;
    case 'R':
      next_rotation_strategy(-1);
      break;
    case 's':
      random_seed = millis();
      break;
    case 't':
      next_tile_strategy(1);
      break;
    case 'T':
      next_tile_strategy(-1);
      break;
    case '?':
      show_tiles = !show_tiles;
      break;
  }
} 

void next_pattern(int inc)
{
  pattern = Pattern.values()[(pattern.ordinal() + inc + Pattern.NUM_PATTERN.ordinal()) % Pattern.NUM_PATTERN.ordinal()];
}

void next_rotation_strategy(int inc)
{
  rotation_strategy = Rotation_strategy.values()[(rotation_strategy.ordinal() + inc + Rotation_strategy.NUM_ROTATION_STRATEGY.ordinal()) % Rotation_strategy.NUM_ROTATION_STRATEGY.ordinal()];
}

void next_tile_strategy(int inc)
{
  tile_strategy = Tile_strategy.values()[(tile_strategy.ordinal() + inc + Tile_strategy.NUM_TILE_STRATEGY.ordinal()) % Tile_strategy.NUM_TILE_STRATEGY.ordinal()];
}

void draw() {
  //image(img[0], 0, 0, img[0].width, img[0].height);
  //image(img[1], 300, 300, img[1].width, img[1].width);
  randomSeed(random_seed);

  // Count how many tiles are enabled.
  int tile_count = 0;
  for (int i = 0; i < tile_enabled.length; ++i) {
    if (tile_enabled[i] && i < all_tiles.length) {
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
      int pattern_offset = tile_width / pattern_offset_ratio;
      switch (pattern) {
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
      switch (tile_strategy) {
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
          tile_num = int(random(tile_count));
          break;
      }
      
      switch (rotation_strategy) {
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
          rot = int(random(4)) * 90;
          break;
        case RANDOM_180:
          rot = int(random(2)) * 180;
          break;
      }
      // Calculate random_rot first so that the same number of random() calls happen which
      // will result in additional tiles being made glitched.
      int random_rot = 90 + int(random(2)) * 180;
      if (int(random(100)) < rotation_glitch) {
        rot += random_rot;
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
  
  status_line = 0;
  status("seed: " + random_seed);
  String s = "tiles: ";
  for (int i = 0; i < tile_enabled.length; ++i) {
    s += tile_enabled[i] ? i + 1 : "_";
  }
  status(s);
  if (show_tiles) {
    for (int i = 0; i < tile_enabled.length; ++i) {
      if (tile_enabled[i]) {
	status("  " + (i + 1) + ": " + files[i]);
      }
    }
  }
  status("pattern: " + pattern.toString());
  status("tile strategy: " + tile_strategy.toString());
  status("rotation strategy: " + rotation_strategy.toString());
  status("rotation glitch percent: " + rotation_glitch);
  status("pattern offset ratio: " + pattern_offset_ratio);
  if (show_help) {
    status("");
    status("commands:");
    status("  1-9   toggle tile");
    status("  ABC   togle tile set");
    status("  DEF   togle tile colour");
    status("  b     basic configuration");
    status("  gG><  adjust rotation glitch percent");
    status("  h     show this message");
    status("  oO    adjust pattern offset ratio");
    status("  pP    adjust pattern");
    status("  q     quit");
    status("  rR    adjust rotation strategy");
    status("  s     new random seed");
    status("  tT    adjust tile strategy");
    status("  ?     show tile names");

    // String[] fontList = PFont.list();
    // for (String i: fontList) {
    //   status(i);
    // }
  }
  delay(20);
}

void status(String s)
{
  ++status_line;
  text(s, 20, status_line * 20);
}
