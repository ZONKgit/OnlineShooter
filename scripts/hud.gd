extends Control

@onready var player = $"../.."
@onready var healthBar = $heathBar

func _process(delta):
	healthBar.value = player.health
