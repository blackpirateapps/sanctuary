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
		
	# 4. Scale Reduction Verification (Frog, Dragonfly & Cute Pack)
	print("\n--- Test 4: Size Reductions Verification ---")
	var frog = animals_node.get_node("Fauna_Frog")
	assert(frog.base_scale.x <= 0.65 and frog.base_scale.y <= 0.65, "Frog scale should be reduced (<= 0.65), got %s" % str(frog.base_scale))
	print("  ✔ Frog scale verified reduced: %s" % str(frog.base_scale))
	
	var dragonfly = animals_node.get_node("Fauna_Dragonfly")
	assert(dragonfly.base_scale.x <= 0.4 and dragonfly.base_scale.y <= 0.4, "Dragonfly scale should be reduced (<= 0.4), got %s" % str(dragonfly.base_scale))
	print("  ✔ Dragonfly scale verified reduced: %s" % str(dragonfly.base_scale))
	
	var cute_pack_nodes = [
		"Fauna_Bee", "Fauna_Dragonfly", "Fauna_Bat1", "Fauna_WhiteBat",
		"Spirit_GuardianBear", "Spirit_VoidDrake"
	]
	for c_name in cute_pack_nodes:
		var node = animals_node.get_node(c_name)
		assert(node.base_scale.x < 1.0 and node.base_scale.y < 1.0, "Cute pack animal %s scale should be < 1.0, got %s" % [c_name, str(node.base_scale)])
		print("  ✔ [Cute Pack] %s scale reduced: %s" % [c_name, str(node.base_scale)])
	print("✔ All Cute pack animals and tiny frog verified with reduced proportions")

	# 5. Background & Non-Interactable Fauna Verification (Fox, Deer, Doe, Rabbit)
	print("\n--- Test 5: Background & Non-Interactable Animals Check ---")
	var bg_animals = [
		"Fauna_Rabbit1", "Fauna_Rabbit2", "Fauna_Deer", "Fauna_Doe", "Fauna_Fox", "Spirit_GoldenDoe"
	]
	for bg_name in bg_animals:
		var node = animals_node.get_node(bg_name)
		assert(node.is_background == true, "%s should have is_background = true" % bg_name)
		assert(node.can_pet == false, "%s should be non-interactable (can_pet = false)" % bg_name)
		assert(node.z_index == -1, "%s should have z_index = -1" % bg_name)
		assert(node.prompt_label.visible == false, "%s prompt label should never be visible" % bg_name)
		print("  ✔ %s verified as background (z_index=-1, non-interactable)" % bg_name)
	print("✔ Fox, Deer, Doe, Rabbits are verified non-interactable and placed in background plane")

	# 6. Dragonfly Forward Movement / Facing Direction Verification
	print("\n--- Test 6: Dragonfly Forward Facing Mechanics ---")
	# When moving to the right (dir > 0), sprite should face right (flip_h = true since default faces left)
	dragonfly._target_x = dragonfly.position.x + 50.0
	dragonfly._process_fly_hover(0.016, 0.0)
	var aspr = dragonfly.get_node("AnimatedSprite2D")
	assert(aspr.flip_h == true, "Dragonfly moving right must face right (flip_h = true)")
	print("  ✔ Dragonfly moving right: flip_h == true (facing forward)")
	
	# When moving to the left (dir < 0), sprite should face left (flip_h = false since default faces left)
	dragonfly._target_x = dragonfly.position.x - 50.0
	dragonfly._process_fly_hover(0.016, 0.0)
	assert(aspr.flip_h == false, "Dragonfly moving left must face left (flip_h = false)")
	print("  ✔ Dragonfly moving left: flip_h == false (facing forward)")
	print("✔ Dragonfly verified always moving forward, never backwards")

	# 7. Petting Interaction on Interactable Creature
	print("\n--- Test 7: Petting Interaction Mechanics (Interactable Fauna) ---")
	var owl = animals_node.get_node("Fauna_Owl")
	assert(owl != null, "Fauna_Owl missing")
	assert(owl.can_pet == true, "Fauna_Owl should be interactable")
	var mana_before: float = HabitManager.focus_mana
	owl._perform_pet()
	var mana_after: float = HabitManager.focus_mana
	assert(abs(mana_after - (mana_before + 2.0)) < 0.01, "Expected +2.0 mana, before: %.2f, after: %.2f" % [mana_before, mana_after])
	print("✔ Petting triggered successfully on Owl: awarded +2.0 Focus Mana (%.2f -> %.2f)" % [mana_before, mana_after])
	assert(owl._pet_cooldown > 0.0, "Pet cooldown not set")
	print("✔ Pet cooldown verified: %.1fs" % owl._pet_cooldown)
	assert(owl.feedback_label.visible == true, "Feedback label should be visible on pet")
	print("✔ Feedback label displayed: '%s'" % owl.feedback_label.text)
	
	# 8. Reactive Flee Simulation
	print("\n--- Test 8: Reactive Fleeing on Shy Creature ---")
	var frog_node = animals_node.get_node("Fauna_Frog")
	assert(frog_node != null, "Fauna_Frog missing")
	frog_node._trigger_flee()
	assert(frog_node._is_fleeing == true, "Frog should enter fleeing state")
	assert(frog_node._flee_timer > 0.0, "Frog flee timer should be active")
	print("✔ Reactive flee mechanism verified on Frog (timer: %.1fs)" % frog_node._flee_timer)
	
	# 9. Clean Streak Milestone Spirit Unlocks
	print("\n--- Test 9: Clean Streak Milestone Spirit Unlocks ---")
	var golden_doe = animals_node.get_node("Spirit_GoldenDoe")
	var guardian_bear = animals_node.get_node("Spirit_GuardianBear")
	var void_drake = animals_node.get_node("Spirit_VoidDrake")
	
	assert(golden_doe.unlock_tier == 1, "Golden Spirit Doe should require Tier 1")
	assert(guardian_bear.unlock_tier == 3, "Guardian Bear should require Tier 3")
	assert(void_drake.unlock_tier == 5, "Celestial Drake should require Tier 5")
	print("✔ Milestone unlock tiers verified (Golden Doe: T1, Guardian Bear: T3, Void Drake: T5)")
	
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
	
	# 10. Texture Filter & Pixel Crispness
	print("\n--- Test 10: 2D Lighting & Canvas Filter ---")
	for child in animals_node.get_children():
		var spr: Sprite2D = child.get_node("Sprite2D")
		var anim: AnimatedSprite2D = child.get_node("AnimatedSprite2D")
		assert(spr.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "Sprite2D texture filter not Nearest in %s" % child.name)
		assert(anim.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "AnimatedSprite2D texture filter not Nearest in %s" % child.name)
	print("✔ 100% of animal visual nodes enforce nearest-neighbor pixel texture filtering")

	print("\n========================================================")
	print("🎉 ALL WILDLIFE VERIFICATION TESTS PASSED SUCCESSFULLY! 🎉")
	print("========================================================")
	get_tree().quit(0)
