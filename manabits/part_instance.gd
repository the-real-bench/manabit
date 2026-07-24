class_name PartInstance extends RefCounted

var data: PartData
var current_hp: int
var disabled: bool = false

func _init(p: PartData) -> void:
    data = p
    current_hp = p.max_hp

func take_damage(amount: int) -> void:
    if disabled:
        return
    current_hp = maxi(0, current_hp - amount)
    if current_hp == 0:
        disabled = true

func restore(amount: int) -> void:
    if disabled:
        return
    current_hp = mini(data.max_hp, current_hp + amount)
