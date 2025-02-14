extends Node2D

@export var win_chance = 0.2
@export var low_bank_win_mult = 1.25
@export var low_bank_threshold = 300
@export var min_bank_win_mult = 1.5
@export var min_bank_threshold = 150
@export var weights = [8, 5, 4, 2.4, 0.5, 0.1]
@export var winnings = [2, 4, 6, 8, 15, 30]
@export var bet = 50
@export var very_close = 0.2
@export var reward_order = [1,4,2,5,6,3]
@export var two_similar = 0.6
@export var amount = 1000

var win = false
var success_number = 0

var numbers = []

var can_roll = false

@onready var anim_1 = $"1/AnimationPlayer"
@onready var anim_2 = $"2/AnimationPlayer"
@onready var anim_3 = $"3/AnimationPlayer"


func _ready() -> void:
	update_text()
	can_roll = true

func start_roll():
	can_roll = false
	amount -= bet
	update_text()
	determine_roll()

func determine_roll():
	randomize()
	var random_chance = randf()
	if random_chance <= win_chance or (random_chance <= win_chance*low_bank_win_mult and amount <= low_bank_threshold) or (random_chance <= win_chance*min_bank_win_mult and amount <= min_bank_threshold):
		win = true
		var current_value = 0
		var random_number = randi_range(1, 20)
		for i in weights:
			current_value += i
			if random_number <= current_value:
				success_number = weights.find(i)+1
				roll(success_number, success_number, success_number)
				break
	else:
		win = false
		var failure_numbers = []
		if randf() <= very_close:
			var available_numbers = []
			for i in range(len(weights)):
				available_numbers.append(i+1)
			var random_two = available_numbers.pick_random()
			failure_numbers.append(random_two)
			failure_numbers.append(random_two)
			available_numbers.erase(random_two)
			
			random_two = reward_order.find(random_two)+1
			var shift = randi_range(0,1)
			if shift == 1:
				var new_num = random_two%len(weights)
				failure_numbers.append(reward_order[new_num])
			else:
				var new_num = random_two-1
				if new_num == 0:
					new_num = len(weights)
				new_num -= 1
				failure_numbers.append(reward_order[new_num])
		elif randf() <= two_similar:
			var available_numbers = []
			for i in range(len(weights)):
				available_numbers.append(i+1)
			var random_two = available_numbers.pick_random()
			failure_numbers.append(random_two)
			failure_numbers.append(random_two)
			available_numbers.erase(random_two)
			failure_numbers.append(available_numbers.pick_random())
		else:
			var available_numbers = []
			for i in range(len(weights)):
				available_numbers.append(i+1)
			for i in range(3):
				var random_number = available_numbers.pick_random()
				failure_numbers.append(random_number)
				available_numbers.erase(random_number)
		failure_numbers.shuffle()
		roll(failure_numbers[0], failure_numbers[1], failure_numbers[2])

func roll(a: int, b: int, c: int):
	var result = 0
	numbers = [a,b,c]
	
	roll_animation(anim_1, 7, a)
	roll_animation(anim_2, 9, b)
	roll_animation(anim_3, 13, c)
	
	if win == true:
		result = bet*winnings[a-1]
		$Visual/RewardVisual/Label.text = "[wave connected=0 amp=75][shake level=3][rainbow speed=2.5 freq=0.8][center]$"+str(result)
	else:
		pass
	amount += result

func roll_animation(animation_player: AnimationPlayer, length, success):
	animation_player.speed_scale = 5
	animation_player.play("Roll")
	animation_player.seek(0.1*randi_range(0,11), true)
	for i in range(length):
		animation_player.queue("Roll")
	animation_player.queue(str(success))

func update_text():
	$Amount.text = "$"+str(amount)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "Roll" and anim_name != "RESET":
		update_text()
		if win == true:
			if success_number <= 1:
				$Reward.play("Small")
			elif success_number <= 4:
				$Reward.play("Medium")
			else:
				$Reward.play("Large")
			await $Reward.animation_finished
		await get_tree().create_timer(0.1).timeout
		can_roll = true

func _on_button_pressed() -> void:
	if can_roll == true and amount > 0:
		start_roll()
