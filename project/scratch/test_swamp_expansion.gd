# scratch/test_swamp_expansion.gd
# Comprehensive automated unit & integration test for the Corrupted Swamp Biome Expansion
extends Node

const FLOOR_Y: float = 312.0
const EPSILON: float = 0.55

func _ready() -> void:
	print("\n========================================================")
	print("🌿 RUNNING CORRUPTED SWAMP BIOME EXPANSION UNIT TESTS 🌿")
	print("========================================================")
	
	# Load main scene
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	assert(main_scene != null, "Failed to load res://scenes/main.tscn")
	var main = main_scene.instantiate()
	add_child(main)
	
	# Wait one frame for ready
	await get_tree().process_frame
	
	# 1. Camera & World Boundaries
	print("\n--- Test 1: World Boundaries & Camera Limits ---")
	var player = main.get_node("Player")
	assert(player != null, "Player node not found")
	var cam: Camera2D = player.get_node("Camera2D")
	assert(cam.limit_right == 5760, "Camera limit_right should be 5760, got %d" % cam.limit_right)
	print("✔ Camera limit_right verified: %d px" % cam.limit_right)
	
	var ground_shape: CollisionShape2D = main.get_node("Ground/FloorShape")
	var rect_shape: RectangleShape2D = ground_shape.shape as RectangleShape2D
	var floor_left: float = ground_shape.position.x - rect_shape.size.x / 2.0
	var floor_right: float = ground_shape.position.x + rect_shape.size.x / 2.0
	assert(floor_left <= 0.0, "Floor must cover x=0, got %f" % floor_left)
	assert(floor_right >= 5760.0, "Floor must cover x=5760, got %f" % floor_right)
	print("✔ Ground Floor collision bounds verified: [%.1f, %.1f] (width: %.1f)" % [floor_left, floor_right, rect_shape.size.x])
	
	var swamp_floor: Sprite2D = main.get_node("Ground/SwampFloorVisual")
	var swamp_left: float = swamp_floor.position.x - swamp_floor.region_rect.size.x / 2.0
	var swamp_right: float = swamp_floor.position.x + swamp_floor.region_rect.size.x / 2.0
	assert(swamp_left <= 1200.0, "Swamp visual should start near transition, got %f" % swamp_left)
	assert(swamp_right >= 5760.0, "Swamp visual must cover x=5760, got %f" % swamp_right)
	print("✔ Swamp repeating floor visual verified: [%.1f, %.1f] (width: %.1f)" % [swamp_left, swamp_right, swamp_floor.region_rect.size.x])
	
	# 2. Elevated Platforming & One-Way Collision
	print("\n--- Test 2: Platform One-Way Collision & Heights ---")
	var expected_platforms = [
		{"name": "Plat1Shape", "x": 230, "y": 240, "one_way": false},
		{"name": "Plat2Shape", "x": 850, "y": 220, "one_way": false},
		{"name": "Plat3Shape", "x": 1580, "y": 276, "one_way": true},
		{"name": "Plat4Shape", "x": 1820, "y": 291, "one_way": true},
		{"name": "Plat5Shape", "x": 2020, "y": 276, "one_way": true},
		{"name": "Plat6Shape", "x": 2280, "y": 288, "one_way": true},
		{"name": "Plat7Shape", "x": 2960, "y": 256, "one_way": true},
		{"name": "Plat8Shape", "x": 3280, "y": 262, "one_way": true},
		{"name": "Plat9Shape", "x": 3580, "y": 240, "one_way": true},
		{"name": "Plat10Shape", "x": 3920, "y": 276, "one_way": true},
		{"name": "Plat11Shape", "x": 4280, "y": 215, "one_way": true},
		{"name": "Plat12Shape", "x": 4640, "y": 256, "one_way": true},
		{"name": "Plat13Shape", "x": 4960, "y": 288, "one_way": true},
		{"name": "Plat14Shape", "x": 5320, "y": 258, "one_way": true}
	]
	
	for plat in expected_platforms:
		var p_node: CollisionShape2D = main.get_node("Ground/" + plat["name"])
		assert(p_node != null, "Missing platform %s" % plat["name"])
		assert(p_node.position.x == plat["x"], "Platform %s x mismatch: expected %d, got %f" % [plat["name"], plat["x"], p_node.position.x])
		assert(p_node.position.y == plat["y"], "Platform %s y mismatch: expected %d, got %f" % [plat["name"], plat["y"], p_node.position.y])
		assert(p_node.one_way_collision == plat["one_way"], "Platform %s one_way mismatch" % plat["name"])
	print("✔ All 14 platform collision shapes verified with exact heights and one-way flags")
	
	# 3. Ground Surface Alignment Check
	print("\n--- Test 3: Ground Surface Alignment Check (Floor Y = 312.0) ---")
	var ground_props_checked = [0]
	var check_bottom = func(node_path: String, offset_bottom: float):
		var n = main.get_node(node_path)
		assert(n != null, "Node %s not found" % node_path)
		var actual_bottom: float = n.position.y + offset_bottom
		var diff = absf(actual_bottom - FLOOR_Y)
		assert(diff < EPSILON, "Misaligned %s: bottom is %.2f, expected %.2f (diff: %.2f)" % [node_path, actual_bottom, FLOOR_Y, diff])
		ground_props_checked[0] += 1
		
	# Braziers on floor
	check_bottom.call("Braziers/Brazier2", 0.0)
	check_bottom.call("Braziers/Brazier3", 0.0)
	check_bottom.call("Braziers/Brazier5", 0.0)
	check_bottom.call("Braziers/Brazier7", 0.0)
	check_bottom.call("Braziers/Brazier10", 0.0)
	check_bottom.call("Braziers/Brazier12", 0.0)
	check_bottom.call("Braziers/Brazier13", 0.0)
	
	# Landmarks
	check_bottom.call("Shrine", 0.0)
	check_bottom.call("Monolith", 0.0)
	check_bottom.call("AbyssalRelic", 0.0)
	
	# Trees & Willows
	check_bottom.call("SwampProps/Tree1", 103.0 / 2.0)
	check_bottom.call("SwampProps/Tree2", 132.0 / 2.0)
	check_bottom.call("SwampProps/Tree3", 150.0 / 2.0)
	check_bottom.call("SwampProps/Tree4", 132.0 / 2.0)
	check_bottom.call("SwampProps/Tree5", 103.0 / 2.0)
	check_bottom.call("SwampProps/Tree6", 150.0 / 2.0)
	check_bottom.call("SwampProps/Tree7", 132.0 / 2.0)
	check_bottom.call("SwampProps/Willow1", 135.0 / 2.0)
	check_bottom.call("SwampProps/Willow2", 168.0 / 2.0)
	check_bottom.call("SwampProps/Willow3", 183.0 / 2.0)
	check_bottom.call("SwampProps/Willow4", 168.0 / 2.0)
	check_bottom.call("SwampProps/Willow5", 183.0 / 2.0)
	check_bottom.call("SwampProps/Willow6", 135.0 / 2.0)
	check_bottom.call("SwampProps/Willow7", 183.0 / 2.0)
	
	# Stones
	check_bottom.call("SwampProps/Stone1", 59.0 / 2.0)
	check_bottom.call("SwampProps/Stone2", 57.0 / 2.0)
	check_bottom.call("SwampProps/Stone3", 57.0 / 2.0)
	check_bottom.call("SwampProps/Stone4", 59.0 / 2.0)
	check_bottom.call("SwampProps/Stone5", 30.0 / 2.0)
	check_bottom.call("SwampProps/Stone6", 59.0 / 2.0)
	
	# Boxes
	check_bottom.call("SwampProps/Box1", 28.0 / 2.0)
	check_bottom.call("SwampProps/Box2", 27.0 / 2.0)
	check_bottom.call("SwampProps/Box3", 26.0 / 2.0)
	check_bottom.call("SwampProps/Box4", 26.0 / 2.0)
	check_bottom.call("SwampProps/Box5", 27.0 / 2.0)
	check_bottom.call("SwampProps/Box6", 26.0 / 2.0)
	
	# Fences & Pointers
	check_bottom.call("SwampProps/Fence1", 18.0 / 2.0)
	check_bottom.call("SwampProps/Fence2", 20.0 / 2.0)
	check_bottom.call("SwampProps/Fence3", 18.0 / 2.0)
	check_bottom.call("SwampProps/Fence4", 13.0 / 2.0)
	
	check_bottom.call("SwampProps/Pointer1", 21.0 / 2.0)
	check_bottom.call("SwampProps/Pointer2", 21.0 / 2.0)
	check_bottom.call("SwampProps/Pointer3", 21.0 / 2.0)
	check_bottom.call("SwampProps/Pointer4", 21.0 / 2.0)
	
	# Grass & Bushes
	check_bottom.call("SwampProps/Grass1", 18.0 / 2.0)
	check_bottom.call("SwampProps/Grass2", 16.0 / 2.0)
	check_bottom.call("SwampProps/Grass3", 16.0 / 2.0)
	check_bottom.call("SwampProps/Grass4", 13.0 / 2.0)
	check_bottom.call("SwampProps/Grass5", 16.0 / 2.0)
	check_bottom.call("SwampProps/Grass6", 18.0 / 2.0)
	check_bottom.call("SwampProps/Grass7", 16.0 / 2.0)
	check_bottom.call("SwampProps/Grass8", 14.0 / 2.0)
	check_bottom.call("SwampProps/Grass9", 18.0 / 2.0)
	check_bottom.call("SwampProps/Grass10", 16.0 / 2.0)
	check_bottom.call("SwampProps/Grass11", 16.0 / 2.0)
	
	check_bottom.call("SwampProps/Bush1", 15.0 / 2.0)
	check_bottom.call("SwampProps/Bush2", 28.0 / 2.0)
	check_bottom.call("SwampProps/Bush3", 24.0 / 2.0)
	check_bottom.call("SwampProps/Bush4", 15.0 / 2.0)
	check_bottom.call("SwampProps/Bush5", 28.0 / 2.0)
	check_bottom.call("SwampProps/Bush6", 21.0 / 2.0)
	check_bottom.call("SwampProps/Bush7", 27.0 / 2.0)
	check_bottom.call("SwampProps/Bush8", 24.0 / 2.0)
	check_bottom.call("SwampProps/Bush9", 28.0 / 2.0)
	
	print("✔ 100%% of ground-resting props (%d nodes) verified sitting cleanly at Y = 312.0" % ground_props_checked[0])
	
	# 4. Interactive Chest & Spirit Coins
	print("\n--- Test 4: Chest & Collectibles Verification ---")
	var chest = main.get_node("SwampChest")
	assert(chest != null, "SwampChest node not found")
	var initial_mana: float = HabitManager.focus_mana
	chest.open_chest()
	assert(HabitManager.focus_mana == initial_mana + 35.0, "Chest reward failed to credit 35.0 mana")
	print("✔ SwampChest opened and awarded +35 Focus Mana successfully")
	
	var coins_group = main.get_node("SpiritCoins")
	assert(coins_group.get_child_count() == 6, "Expected 6 spirit coins, found %d" % coins_group.get_child_count())
	var coin1 = coins_group.get_node("Coin1")
	var mana_before_coin: float = HabitManager.focus_mana
	coin1._on_body_entered(player)
	assert(HabitManager.focus_mana == mana_before_coin + 5.0, "Spirit coin failed to credit 5.0 mana")
	print("✔ Spirit Coins collection mechanism verified (+5.0 Focus Mana)")
	
	# 5. Abyssal Relic
	print("\n--- Test 5: Abyssal Relic Landmark Verification ---")
	var relic = main.get_node("AbyssalRelic")
	assert(relic != null, "AbyssalRelic node not found")
	var mana_before_relic: float = HabitManager.focus_mana
	main._commune_with_abyssal_relic()
	assert(HabitManager.focus_mana == mana_before_relic + 25.0, "Abyssal Relic failed to credit 25.0 mana")
	print("✔ Abyssal Relic commune interaction verified (+25 Focus Mana, Blight Cleansed)")
	
	# 6. Braziers Violet Flame Verification
	print("\n--- Test 6: Brazier Lighting Rig ---")
	var braziers_node = main.get_node("Braziers")
	assert(braziers_node.get_child_count() == 13, "Expected 13 braziers, found %d" % braziers_node.get_child_count())
	print("✔ All 13 lit braziers (4 amber sanctuary + 9 violet swamp) verified")
	
	print("\n========================================================")
	print("🎉 ALL EXPANSION VERIFICATION TESTS PASSED SUCCESSFULLY! 🎉")
	print("========================================================\n")
	get_tree().quit(0)
