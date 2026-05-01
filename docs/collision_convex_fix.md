# Solusi Collision Concave Error

## Problem:
Error "Convex decomposing failed!" terjadi karena Godot tidak bisa pakai collision shape yang concave (cekung).

## Solusi 1: Gunakan StaticBody2D dengan Multiple Convex Shapes

```gdscript
# Buat multiple collision shapes untuk representasi concave
extends StaticBody2D

func _ready():
    # Contoh: Buat 2-3 box collision untuk bentuk concave
    var shape1 = CollisionShape2D.new()
    shape1.position = Vector2(0, 0)
    var rect1 = RectangleShape2D.new()
    rect1.size = Vector2(100, 50)
    shape1.shape = rect1
    add_child(shape1)
    
    var shape2 = CollisionShape2D.new()
    shape2.position = Vector2(25, 50)
    var rect2 = RectangleShape2D.new()
    rect2.size = Vector2(50, 100)
    shape2.shape = rect2
    add_child(shape2)
```

## Solusi 2: Gunakan CollisionPolygon2D dengan Convex Decomposition

```gdscript
extends StaticBody2D

@export var concave_points: PackedVector2Array

func _ready():
    var polygon = CollisionPolygon2D.new()
    polygon.polygon = concave_points
    
    # Godot 4 akan otomatis coba decompose, tapi jika gagal:
    # Manual convex decomposition
    var decomposed = Geometry2D.decompose_polygon_in_convex(concave_points)
    
    for convex_poly in decomposed:
        var shape = CollisionPolygon2D.new()
        shape.polygon = convex_poly
        add_child(shape)
```

## Solusi 3: Gunakan TileMap Collision (Recommended)

Tambahkan collision di TileSet, bukan node terpisah:

1. Buka TileSet
2. Pilih tile yang mau dikasih collision
3. Di inspector, tambah Physics Layer
4. Gambar collision shape yang simpel (box/circle)

## Solusi 4: Simplify Polygon

Pastikan polygon Anda convex (tidak ada sudut dalam):

```gdscript
# Contoh polygon convex (benar - bentuk Cembung)
var convex_polygon = PackedVector2Array([
    Vector2(-50, -50),
    Vector2(50, -50),
    Vector2(50, 50),
    Vector2(-50, 50)
])

# Contoh polygon concave (salah - bentuk Cekung)
var concave_polygon = PackedVector2Array([
    Vector2(-50, -50),
    Vector2(0, 0),      # Titik ini bikin cekung!
    Vector2(50, -50),
    Vector2(50, 50),
    Vector2(-50, 50)
])
```

## Quick Fix: Gunakan RectangleShape2D atau CircleShape2D

Collision paling aman yang tidak pernah error:

```gdscript
extends StaticBody2D

func _ready():
    var collision = CollisionShape2D.new()
    
    # Pilih salah satu:
    collision.shape = RectangleShape2D.new()
    collision.shape.size = Vector2(100, 100)
    
    # atau
    # collision.shape = CircleShape2D.new()
    # collision.shape.radius = 50
    
    add_child(collision)
```

## Tips:
- Hindari bentuk L, U, T untuk single collision
- Pecah jadi beberapa collision shape kecil
- Gunakan "Visible Collision Shapes" debug untuk cek
- Test dengan simple shape dulu, baru kompleks
