package echo.util;

enum TileShape {
  None;
  Block;
  TopLeft;
  TopRight;
  BottomLeft;
  BottomRight;
}

class TileMap {
  /**
   * Generates an optimized Array of Bodies from an Array of `Int`s representing a TileMap.
   * @param data The Array of `Int`s that make up the TileMap
   * @param tile_width The Width of each Tile in the TileMap
   * @param tile_height The Height of each Tile in the TileMap
   * @param width_in_tiles The Width of the TileMap (Measured in Tiles)
   * @param height_in_tiles The Height of the TileMap (Measured in Tiles)
   * @param offset_x The Offset applied to the X Position of each generated Body
   * @param offset_y The Offset applied to the Y Position of each generated Body
   * @param start_index The Index that designates which tiles are collidable
   * @return Array<Body>
   */
  public static function generate(data:Array<Int>, tile_width:Int, tile_height:Int, width_in_tiles:Int, height_in_tiles:Int, offset_x:Float = 0,
      offset_y:Float = 0, start_index:Int = 0, ?ignore:Array<Int>, ?top_left_slopes:Array<Int>, ?top_right_slopes:Array<Int>, ?bottom_left_slopes:Array<Int>,
      ?bottom_right_slopes:Array<Int>):Array<Body> {
    inline function is_ignored(index:Int) {
      return ignore != null && ignore.indexOf(index) > -1;
    }
    function get_shape(index:Int):TileShape {
      if (is_ignored(index)) return None;
      if (top_left_slopes != null && top_left_slopes.indexOf(index) > -1) return TopLeft;
      if (top_right_slopes != null && top_right_slopes.indexOf(index) > -1) return TopRight;
      if (bottom_left_slopes != null && bottom_left_slopes.indexOf(index) > -1) return BottomLeft;
      if (bottom_right_slopes != null && bottom_right_slopes.indexOf(index) > -1) return BottomRight;
      return Block;
    }
    inline function generate_body(x:Int, y:Int, width:Int, height:Int, data:Array<Array<Int>>, shape:TileShape):Body {
      var yy = y + 1;
      var flag = false;
      while (yy < data.length - 1) {
        if (flag) {
          yy = data.length;
          continue;
        }
        for (j in 0...width) {
          var i = data[yy][j + x];
          if (i <= start_index && get_shape(i) != shape) flag = true;
        }
        if (!flag) {
          for (j in 0...width) {
            data[yy][j + x] = -1;
          }
          height += 1;
        }
        yy += 1;
      }
      return new Body({
        x: x * tile_width + ((tile_width * width) * 0.5) + offset_x,
        y: y * tile_height + (tile_height * height * 0.5) + offset_y,
        mass: 0,
        shape: switch (shape) {
          case Block:
            {
              type: RECT,
              width: tile_width * width,
              height: tile_height * height
            };
          default: null;
        }
      });
    }
    var colliders = [];
    var tmp = new Array<Array<Int>>();
    for (i in 0...data.length) {
      var x = i % width_in_tiles;
      var y = Math.floor(i / width_in_tiles);
      if (tmp[y] == null) tmp[y] = [];
      tmp[y][x] = data[i];
    }
    for (y in 0...tmp.length) {
      var start_x = -1;
      var width = 0;
      var height = 1;
      var shape = None;
      for (x in 0...tmp[y].length) {
        var i = tmp[y][x];
        var i_shape = get_shape(i);
        if (i != -1 && i > start_index && !is_ignored(i) && (shape == None || shape == i_shape)) {
          if (start_x == -1) {
            start_x = x;
            shape = i_shape;
          }
          width += 1;
          tmp[y][x] = -1;
        }
        else {
          if (start_x != -1) {
            colliders.push(generate_body(start_x, y, width, height, tmp, shape));
            start_x = -1;
            width = 0;
            height = 1;
          }
        }
      }
      if (start_x != -1) {
        colliders.push(generate_body(start_x, y, width, height, tmp, shape));
        start_x = -1;
        width = 0;
        height = 1;
      }
    }
    return colliders;
  }
  /**
   * Generates an Array of Bodies from an Array of `Int`s representing a TileMap.
   * @param data The Array of `Int`s that make up the TileMap
   * @param tile_width The Width of each Tile in the TileMap
   * @param tile_height The Height of each Tile in the TileMap
   * @param width_in_tiles The Width of the TileMap (Measured in Tiles)
   * @param height_in_tiles The Height of the TileMap (Measured in Tiles)
   * @param offset_x The Offset applied to the X Position of each generated Body
   * @param offset_y The Offset applied to the Y Position of each generated Body
   * @param start_index The Index that designates which tiles are collidable
   * @return Array<Body>
   */
  public static function generate_grid(data:Array<Int>, tile_width:Int, tile_height:Int, width_in_tiles:Int, height_in_tiles:Int, offset_x:Float = 0,
      offset_y:Float = 0, start_index:Int = 0):Array<Body> {
    var colliders = [];
    for (i in 0...data.length) {
      var index = data[i];
      if (index != -1 && index > start_index) {
        var b = new Body({
          x: (i % width_in_tiles) * tile_width,
          y: Math.floor(i / width_in_tiles) * tile_height,
          mass: 0,
          shape: {
            type: RECT,
            width: tile_width,
            height: tile_height,
            offset_x: tile_width * 0.5 + offset_x,
            offset_y: tile_height * 0.5 + offset_y
          }
        });
        colliders.push(b);
      }
    }
    return colliders;
  }
}
