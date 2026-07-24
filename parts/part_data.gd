class_name PartData extends Resource

@export var id: StringName
@export var display_name: String
@export_enum("HEAD", "CORE", "ARM_L", "ARM_R", "LEGS", "BACK") var slot: String

@export_group("Presentation")
@export var mesh: Mesh
@export var socket_offset: Transform3D

@export_group("Stats")
@export var max_hp: int = 1
@export var attack: int = 0
@export var defense: int = 0
@export var speed: int = 0
@export var weight: int = 0
@export var energy: int = 0
@export var carry: int = 0      # CORES ONLY: extra carry capacity ("a stronger soul wakes a heavier body"); inert on body bits

@export_group("Ability")
@export var ability: AbilityData

@export_group("Core / meta")
@export var is_core: bool = false
@export var affinity: StringName = &""
@export_enum("COMMON", "RARE", "EPIC") var rarity: String = "COMMON"
@export var family: String = ""             # style family (for art tinting / grouping)
@export var blueprint_unlockable: bool = true
