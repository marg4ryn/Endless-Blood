extends Resource
class_name HeroData

@export var hero_name: String = ""
@export var death_sound: AudioStream
@export var hurt_sounds: Array[AudioStream]
@export var icon: Texture2D
@export var sprite_frames: SpriteFrames
@export var max_health: int = 0
@export var speed: int = 0
@export var luck: int = 0
