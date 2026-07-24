class_name Juice extends RefCounted
# Shared motion helpers (DESIGN.md §4). Honors a global reduce-motion flag.

static var reduce_motion := false

static func squash_pop(node: Control, dur: float = 0.14) -> void:
    if reduce_motion or node == null:
        return
    node.pivot_offset = node.size / 2.0
    node.scale = Vector2(0.85, 0.85)
    var tw := node.create_tween()
    tw.tween_property(node, "scale", Vector2(1.12, 1.12), dur * 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.tween_property(node, "scale", Vector2(1, 1), dur * 0.45)

static func stamp_thunk(node: Control, dur: float = 0.14) -> void:
    if node == null:
        return
    node.pivot_offset = node.size / 2.0
    node.rotation = deg_to_rad(-14.0)
    if reduce_motion:
        node.scale = Vector2.ONE
        node.modulate.a = 0.0
        node.create_tween().tween_property(node, "modulate:a", 1.0, 0.06)
        return
    node.scale = Vector2(1.4, 1.4)
    var tw := node.create_tween()
    tw.tween_property(node, "scale", Vector2.ONE, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func odometer(label: Label, from_i: int, to_i: int, prefix: String, dur: float = 0.22) -> void:
    if label == null:
        return
    if from_i == to_i:
        label.text = "%s %d" % [prefix, to_i]
        return
    var d := 0.12 if reduce_motion else dur
    var setter := func(v): label.text = "%s %d" % [prefix, int(round(v))]
    label.create_tween().tween_method(setter, float(from_i), float(to_i), d).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

static func shake(node: Control, amount: float = 8.0, dur: float = 0.15) -> void:
    if reduce_motion or node == null:
        return
    var base := node.position
    var tw := node.create_tween()
    var steps := 6
    for i in steps:
        var dir := 1.0 if i % 2 == 0 else -1.0
        var dx := amount * (1.0 - float(i) / float(steps)) * dir
        tw.tween_property(node, "position:x", base.x + dx, dur / float(steps))
    tw.tween_property(node, "position", base, dur / float(steps))
