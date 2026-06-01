extends Resource
class_name ItemData

@export var name: String
@export var icon: Texture2D
@export var max_level: int = 3
@export var bonuses: Array[ItemLevelData] = []
