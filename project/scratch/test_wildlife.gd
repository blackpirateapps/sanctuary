# scratch/test_wildlife.gd
# Comprehensive automated unit & integration test for the wildlife ecosystem
extends Node

const FLOOR_Y: float = 312.0
const EPSILON: float = 0.5

func _ready() -> void:
	print("\n========================================================")
	print("🐾 RUNNING SANCTUARY & SWAMP WILDLIFE UNIT TESTS 🐾")
	print("========================================================")
	
	# Load main scene
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Failed to load res://scenes/main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	# Wait one frame for ready initialization
	await get_tree().process_frame
	
	var animals_node = main.get_node_or_null("Animals")
	assert(animals_node != null, "Animals container node missing from main scene")
	print("✔ Animals container node verified in main scene")
	
	# 1. Total Wildlife Population & Inventory
	print("\n--- Test 1: Wildlife Population & Node Registration ---")
	var count = animals_node.get_child_count()
	assert(count >= 19, "Expected at least 19 animals, found %d" % count)
	print("✔ Total fauna instances registered: %d" % count)
	
	# 2. Texture & Animation Frame Integrity Check
	print("\n--- Test 2: Asset Integrity & Visual Rig Verification ---")
	for child in animals_node.get_children():
		var animal_id: String = child.get("animal_id")
		var is_anim: bool = child.get("is_animated_pack")
		var d_name: String = child.get("display_name")
		
		if is_anim:
			var anim_node: AnimatedSprite2D = child.get_node("AnimatedSprite2D")
			assert(anim_node != null, "AnimatedSprite2D missing in %s" % child.name)
			assert(anim_node.sprite_frames != null, "SpriteFrames null in %s" % child.name)
			var frame_count = anim_node.sprite_frames.get_frame_count("default")
			assert(frame_count >= 3, "Expected at least 3 animation frames for %s, got %d" % [child.name, frame_count])
			for idx in range(frame_count):
				var tex = anim_node.sprite_frames.get_frame_texture("default", idx)
				assert(tex != null, "Frame texture %d is null in %s" % [idx, child.name])
			print("  ✔ [Animated] %s (%s): %d frames verified" % [child.name, d_name, frame_count])
		else:
			var spr_node: Sprite2D = child.get_node("Sprite2D")
			assert(spr_node != null, "Sprite2D missing in %s" % child.name)
			assert(spr_node.texture != null, "Texture is null in %s" % child.name)
			print("  ✔ [Static 32x32] %s (%s): valid texture '%s'" % [child.name, d_name, spr_node.texture.resource_path.get_file()])
			
	# 3. Ground Surface Alignment (Floor Y = 312.0)
	print("\n--- Test 3: Ground Surface Alignment Check ---")
	var ground_animals = [
		"Fauna_Rabbit1", "Fauna_Rabbit2", "Fauna_Deer", "Fauna_Doe",
		"Fauna_Fox", "Fauna_Hedgehog", "Fauna_Frog", "Fauna_Snail",
		"Spirit_GoldenDoe", "Spirit_GuardianBear"
	]
	for g_name in ground_animals:
		var node = animals_node.get_node_or_null(g_name)
		assert(node != null, "Ground animal %s not found" % g_name)
		assert(abs(node.position.y - FLOOR_Y) < EPSILON,
			"Ground animal %s position.y (%.1f) does not match floor (%.1f)" % [g_name, node.position.y, FLOOR_Y])
		print("  ✔ %s cleanly grounded at Y = %.1f" % [g_name, node.position.y])
		
	# 4. Wander Boundaries & Range Sanity
	print("\n--- Test 4: Wander Boundaries Sanity ---")
	for child in animals_node.get_children():
		var min_x: float = child.get("wander_min_x")
		var max_x: float = child.get("wander_max_x")
		var pos_x: float = child.position.x
		if min_x != 0.0 or max_x != 0.0:
			assert(min_x >= 0.0 and max_x <= 5760.0, "Wander bounds [%.1f, %.1f] out of world bounds [0, 5760] in %s" % [min_x, max_x, child.name])
			assert(min_x <= max_x, "min_x (%.1f) > max_x (%.1f) in %s" % [min_x, max_x, child.name])
			assert(pos_x >= min_x - 50.0 and pos_x <= max_x + 50.0, "Initial position %.1f outside wander bounds [%.1f, %.1f] in %s" % [pos_x, min_x, max_x, child.name])
	print("✔ All wander patrol intervals strictly within valid world coordinates [0..5760]")
	
	# 5. Petting Interaction & Mana Reward
	print("\n--- Test 5: Petting Interaction Mechanics ---")
	var deer = animals_node.get_node("Fauna_Deer")
	assert(deer != null, "Fauna_Deer missing")
	var mana_before: float = HabitManager.focus_mana
	deer._perform_pet()
	var mana_after: float = HabitManager.focus_mana
	assert(abs(mana_after - (mana_before + 2.0)) < 0.01, "Expected +2.0 mana, before: %.2f, after: %.2f" % [mana_before, mana_after])
	print("✔ Petting triggered successfully: awarded +2.0 Focus Mana (%.2f -> %.2f)" % [mana_before, mana_after])
	assert(deer._pet_cooldown > 0.0, "Pet cooldown not set")
	print("✔ Pet cooldown verified: %.1fs" % deer._pet_cooldown)
	assert(deer.feedback_label.visible == true, "Feedback label should be visible on pet")
	print("✔ Feedback label displayed: '%s'" % deer.feedback_label.text)
	
	# 6. Reactive Flee Simulation
	print("\n--- Test 6: Reactive Fleeing ---")
	var rabbit = animals_node.get_node("Fauna_Rabbit1")
	assert(rabbit != null, "Fauna_Rabbit1 missing")
	rabbit._trigger_flee()
	assert(rabbit._is_fleeing == true, "Rabbit should enter fleeing state")
	assert(rabbit._flee_timer > 0.0, "Rabbit flee timer should be active")
	print("✔ Reactive flee mechanism verified (timer: %.1fs)" % rabbit._flee_timer)
	
	# 7. Milestone Unlock Visibility
	print("\n--- Test 7: Clean Streak Milestone Spirit Unlocks ---")
	var golden_doe = animals_node.get_node("Spirit_GoldenDoe")
	var guardian_bear = animals_node.get_node("Spirit_GuardianBear")
	var void_drake = animals_node.get_node("Spirit_VoidDrake")
	
	assert(golden_doe.unlock_tier == 1, "Golden Spirit Doe should require Tier 1")
	assert(guardian_bear.unlock_tier == 3, "Guardian Bear should require Tier 3")
	assert(void_drake.unlock_tier == 5, "Celestial Drake should require Tier 5")
	print("✔ Milestone unlock tiers verified (Golden Doe: T1, Guardian Bear: T3, Void Drake: T5)")
	
	# Check baseline visibility according to current player tier
	var current_tier: int = HabitManager.get_current_tier_index()
	print("  Current player tier index: %d" % current_tier)
	if current_tier < 1:
		assert(golden_doe.visible == false, "Golden Doe should be hidden at Tier 0")
		print("  ✔ Golden Doe locked at Tier 0 foundation")
	else:
		assert(golden_doe.visible == true, "Golden Doe should be visible at Tier >= 1")
		print("  ✔ Golden Spirit Doe unlocked (Tier %d >= 1)" % current_tier)
		
	if current_tier < 3:
		assert(guardian_bear.visible == false, "Guardian Bear should be hidden at Tier < 3")
		print("  ✔ Guardian Spirit Bear locked (requires Tier 3, current is %d)" % current_tier)
	else:
		assert(guardian_bear.visible == true, "Guardian Bear should be visible at Tier >= 3")
		print("  ✔ Guardian Spirit Bear unlocked (Tier %d >= 3)" % current_tier)
		
	if current_tier < 5:
		assert(void_drake.visible == false, "Void Drake should be hidden at Tier < 5")
		print("  ✔ Celestial Void Drake locked (requires Tier 5, current is %d)" % current_tier)
	else:
		assert(void_drake.visible == true, "Void Drake should be visible at Tier >= 5")
		print("  ✔ Celestial Void Drake unlocked (Tier %d >= 5)" % current_tier)
	
	# 8. Brazier & Ambient Lighting Compatibility
	print("\n--- Test 8: 2D Lighting & Canvas Filter ---")
	for child in animals_node.get_children():
		var spr: Sprite2D = child.get_node("Sprite2D")
		var aspr: AnimatedSprite2D = child.get_node("AnimatedSprite2D")
		assert(spr.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Sprite2D texture filter not Nearest in %s" % child.name)
		assert(aspr.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "AnimatedSprite2D texture filter not Nearest in %s" % child.name)
	print("✔ 100% of animal visual nodes enforce nearest-neighbor pixel texture filtering")

	print("\n========================================================")
	print("🎉 ALL WILDLIFE VERIFICATION TESTS PASSED SUCCESSFULLY! 🎉")
	print("========================================================")
	get_tree().quit(0)
