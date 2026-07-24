class_name AbilityData extends Resource

@export_enum("SINGLE", "MULTI", "GUARD") var archetype: String = "SINGLE"
@export var display_name: String = ""
@export var power: int = 0
@export var hit_count: int = 1
@export var guard_amount: int = 0
@export_enum("DEF_BUFF", "PART_RESTORE") var guard_kind: String = "DEF_BUFF"
@export var mana_cost: int = 0
@export var can_target_core: bool = true    # §13.4: false = this move can only hit non-core parts
