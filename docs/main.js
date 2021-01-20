var files = [
  "formwork_cornice_I0518_00175_MAIN.jpg",
  "formwork_mortar_I0518_00700_MAIN.jpg",
  "formwork_rebar_I0518_00500_MAIN.jpg",
  "scaffold_cornice_I0519_00175_MAIN.jpg",
  "scaffold_mortar_I0519_00700_MAIN.jpg",
  "scaffold_rebar_I0519_00500_MAIN.jpg",
  "transverse_cornice_I0520_00175_MAIN.jpg",
  "transverse_mortar_I0520_00700_MAIN.jpg",
  "transverse_rebar_I0520_00500_MAIN.jpg",
];

var Pattern = {
  MONOLITHIC: 0,
  BRICK: 1,
  ASHLAR: 2,

  COUNT: 3,
};

var Tile_strategy = {
  FIXED_TILE_0: 0,
  FIXED_TILE_1: 1,
  FIXED_TILE_2: 2,
  SEQUENTIAL_ROW: 3,
  SEQUENTIAL_COL: 4,
  SEQUENTIAL_ROW_COL: 5,
  SEQUENTIAL_ROW_RANDOM: 6,
  RANDOM: 7,

  COUNT: 8,
};

var Rotation_strategy = {
  FIXED_0: 0,
  FIXED_90: 1,
  ALTERNATING_90: 2,
  ROTATING_90: 3,
  RANDOM_180: 4,
  RANDOM: 5,

  COUNT: 6,
};

var all_tiles = [];
var rnd_generator;
randomSeed(0);

function Config()
{
  this.enabled = [];
  this.random_seed = 0;
  this.pattern = Pattern.MONOLITHIC;
  this.tile_strategy = Tile_strategy.FIXED_TILE_0;
  this.rotation_strategy = Rotation_strategy.FIXED_0;
  this.pattern_offset_ratio = 2;
  this.rotation_glitch = 5;

  this.adjust_pattern = function (delta) {
    this.pattern = (this.pattern + delta + Pattern.COUNT) % Pattern.COUNT;
  }

  this.adjust_tile_strategy = function (delta) {
    this.tile_strategy = (this.tile_strategy + delta + Tile_strategy.COUNT) % Tile_strategy.COUNT;
  }

  this.adjust_rotation_strategy = function (delta) {
    this.rotation_strategy = (this.rotation_strategy + delta + Rotation_strategy.COUNT) % Rotation_strategy.COUNT;
  }
}

var config = new Config();

function getPath(filename) {
  return "tiles/" + filename;
}

function addTileButton(name, path) {
  var div_element = document.getElementById("tiles");

  var element = document.createElement("img");
  element.src = path
  element.id = name;
  element.width = 100;
  element.height = 100;
  element.className = "selected";
  element.textContent = all_tiles[i];
  element.onclick = function() {
    config.enabled[this.id] = !config.enabled[this.id];
    this.className = config.enabled[this.id] ? "selected" : "unselected";
    need_update = true;
  }
  div_element.appendChild(element);
}

function Tile(name, path)
{
  this.name = name;
  this.path = path;
  var canvas = document.createElement("canvas");
  this.canvas = canvas;
  canvas.width = tile_width;
  canvas.height = tile_height;

  var img = new Image();
  this.img = img;
  img.alt = name;
  img.src = path;
  img.addEventListener('load', function() {
    var img_ctx = canvas.getContext("2d");
    img_ctx.drawImage(img, 0, 0, image_width, image_height, 0, 0,
                      canvas.width, canvas.height);
    need_update = true;
  }, false);

  return this;
}

function addButton(container, name, value) {
  var element = document.createElement("button");
  element.value = value;
  element.textContent = name;
  element.onclick = function() {
    config[container] = parseInt(this.value);
    need_update = true;
  }

  var div_element = document.getElementById(container);
  div_element.appendChild(element);
}

function addButtons() {
  addButton("pattern", "Monolithic", Pattern.MONOLITHIC);
  addButton("pattern", "Brick", Pattern.BRICK);
  addButton("pattern", "Ashlar", Pattern.ASHLAR);

  addButton("tile_strategy", "Fixed Tile 0", Tile_strategy.FIXED_TILE_0);
  addButton("tile_strategy", "Fixed Tile 1", Tile_strategy.FIXED_TILE_1);
  addButton("tile_strategy", "Fixed Tile 2", Tile_strategy.FIXED_TILE_2);
  addButton("tile_strategy", "Sequential Row", Tile_strategy.SEQUENTIAL_ROW);
  addButton("tile_strategy", "Sequential Column", Tile_strategy.SEQUENTIAL_COL);
  addButton("tile_strategy", "Sequential Row Colum", Tile_strategy.SEQUENTIAL_ROW_COL);
  addButton("tile_strategy", "Sequential Row Random", Tile_strategy.SEQUENTIAL_ROW_RANDOM);
  addButton("tile_strategy", "Random", Tile_strategy.RANDOM);

  addButton("rotation_strategy", "Fixed 0", Rotation_strategy.FIXED_0);
  addButton("rotation_strategy", "Fixed 90", Rotation_strategy.FIXED_90);
  addButton("rotation_strategy", "Alternating 90", Rotation_strategy.ALTERNATING_90);
  addButton("rotation_strategy", "Rotating 90", Rotation_strategy.ROTATING_90);
  addButton("rotation_strategy", "Random 180", Rotation_strategy.RANDOM_180);
  addButton("rotation_strategy", "Random", Rotation_strategy.RANDOM);

}

function xmur3(str) {
    for(var i = 0, h = 1779033703 ^ str.length; i < str.length; i++)
        h = Math.imul(h ^ str.charCodeAt(i), 3432918353),
        h = h << 13 | h >>> 19;
    return function() {
        h = Math.imul(h ^ h >>> 16, 2246822507);
        h = Math.imul(h ^ h >>> 13, 3266489909);
        return (h ^= h >>> 16) >>> 0;
    }
}

function randomSeed(value) {
  rnd_generator = xmur3(value.toString());
}

function random(max_value) {
  return rnd_generator() % max_value;
}

const image_width = 1700;
const image_height = 1700;
const tile_width = 200;
const tile_height = 200;

console.log("hello");

var c = document.getElementById("canvas");
var ctx = c.getContext("2d");

const tile_cols = (c.width / tile_width) + 1;
const tile_rows = (c.height / tile_height) + 1;

var need_update = true;

for (i = 0; i < files.length; ++i) {
  var name = files[i];
  var path = getPath(files[i]);
  all_tiles.push(new Tile(name, path));
  config.enabled[name] = true;
  addTileButton(name, path);
}

for (i = 0; i < all_tiles.length; ++i) {
  console.log("loaded " + all_tiles[i].name);
}

addButtons();

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function radians(degrees) {
  return degrees * Math.PI / 180.0;
}

function render()
{
  // TODO: Racey.
  if (!need_update) {
    return;
  }
  need_update = false;

  randomSeed(config.random_seed);

  var tiles = [];
  var tile_count = 0;
  for (i = 0; i < all_tiles.length; ++i) {
    var file = all_tiles[i].name;
    if (config.enabled[file]) {
      tiles[tile_count] = all_tiles[i].canvas;
      ++tile_count;
    }
  }
  if (tile_count == 0) {
    tiles[0] = all_tiles[0].canvas;
    tile_count = 1;
  }

  var per_row_random = [];
  for (i = 0; i < tile_rows * 2; ++i) {
    per_row_random.push(random(tile_count));
  }

  ctx.clearRect(0, 0, c.width, c.height);

  for (y = 0; y < tile_rows * 2; ++y) {
    for (x = 0; x < tile_cols * 2; ++x) {
      var tile_x = x * tile_width;
      var tile_y = y * tile_height;
      var tile_num = 0;
      var rot = 0;

      var pattern_offset = tile_width / config.pattern_offset_ratio;
      switch (config.pattern) {
        case Pattern.MONOLITHIC:
          tile_x = x * tile_width;
          tile_y = y * tile_height;
          break;
        case Pattern.ASHLAR:
          // Offset is in reverse to ensure valid data for the entire row.
          tile_x = x * tile_width - y * pattern_offset;
          tile_y = y * tile_height;
          break;
        case Pattern.BRICK:
          // Offset is in reverse to ensure valid data for the entire col.
          tile_x = x * tile_width;
          tile_y = y * tile_height - x * pattern_offset;
          break;
      }

      var tile_random = random(tile_count);
      switch (config.tile_strategy) {
        case Tile_strategy.FIXED_TILE_0:
          tile_num = 0;
          break;
        case Tile_strategy.FIXED_TILE_1:
          tile_num = 1;
          break;
        case Tile_strategy.FIXED_TILE_2:
          tile_num = 2;
          break;
        case Tile_strategy.SEQUENTIAL_ROW:
          tile_num = x % tile_count;
          break;
        case Tile_strategy.SEQUENTIAL_COL:
          tile_num = y % tile_count;
          break;
        case Tile_strategy.SEQUENTIAL_ROW_COL:
          tile_num = (x + y) % tile_count;
          break;
        case Tile_strategy.SEQUENTIAL_ROW_RANDOM:
          tile_num = (x + per_row_random[y]) % tile_count;
          break;
        case Tile_strategy.RANDOM:
          tile_num = tile_random;
          break;
      }

      // Always calculate random value to have the same number of random()
      // calls for each mode.
      var rotation_random = random(4);
      switch (config.rotation_strategy) {
        case Rotation_strategy.FIXED_0:
          rot = 0;
          break;
        case Rotation_strategy.FIXED_90:
          rot = 90;
          break;
	case Rotation_strategy.ALTERNATING_90:
	  // aka Quarter Turned.
	  rot = (x + y) % 2 * 90;
	  break;
	case Rotation_strategy.ROTATING_90:
	  // aka Quarter Turned.
	  rot = (x + y) % 4 * 90;
	  break;
        case Rotation_strategy.RANDOM:
          rot = rotation_random * 90;
          break;
        case Rotation_strategy.RANDOM_180:
          rot = (rotation_random % 2) * 180;
          break;
      }

      // Calculate random_rot first so that the same number of random() calls
      // happen which will result in additional tiles being made glitched.
      var random_rot = 90 + random(2) * 180;
      if (random(100) < config.rotation_glitch) {
        rot += random_rot;
      }

      var tile = tiles[tile_num];
      ctx.save();
      ctx.translate(tile_x, tile_y);
      ctx.translate(tile_width / 2, tile_height / 2);
      ctx.rotate(radians(rot));
      ctx.translate(-tile_width / 2 , -tile_height / 2);
      ctx.drawImage(tile, 0, 0);
      ctx.restore();
    }
  }
}

async function main() {
  while (true) {
    render();
    await sleep(100);
  }
}

main();

