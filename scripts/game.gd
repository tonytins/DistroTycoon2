extends Control

@onready var name_distro_win = $NameDistroWin
@onready var intro_win = $IntroWin
@onready var distro_name_input = $NameDistroWin/DistroNameInput
@onready var distro_name_lbl = $DistroBox/DistroBox/DistroLbl

var repository_json = "res://data/repository.json"
# Used during gameplay
var player_json = "res://data/player.json"
# Used when saving and loading the game
var saved_player_json  = "user://data/player.json"

var distro_name: String
var repository_data: Dictionary = {
	"Packages": [
		{
			"Name": "",
			"Bugs": 0,
			"Description": "",
			"NerdCred": 0,
			"Popularity": 0,
			"SizeInMB": 0,
			"Version": 0,
			"isOpenSource": false,
			"SoftwareType": ""
		}
	]
}

var player_data: Dictionary = {
	"Distro": "MyDistro",
	"Version": "1.0",
	"Users": 0,
	"Bugs": 0,
	"Volenteers": 0,
	"Workers": 0,
	"Packages": {}
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_populate_packages()
	if _open_save_game() == true:
		_name_distro(player_data["Distro"])
	else:
		name_distro_win.show()

func _on_name_distro_win_confirmed() -> void:
	_name_distro(distro_name)
	_set_player_info("Distro", distro_name)
	intro_win.show()

func _get_player_info(property: String):
	return player_data[property]

func _set_player_info(property: String, new_val):
	player_data[property] = new_val
	print_debug(player_data)

func _populate_packages():
	var read_file = FileAccess.get_file_as_string(repository_json)
	var parsed_json = JSON.parse_string(read_file)
	if parsed_json:
		repository_data = parsed_json
		print_debug(repository_data)

func _save_game():
	var player_data = JSON.stringify(player_data)
	var file = FileAccess.open(saved_player_json, FileAccess.WRITE)
	file.store_string(player_data)

func _open_save_game() -> bool:
	var read_file = FileAccess.get_file_as_string(saved_player_json)
	if read_file.is_empty():
		return false
	else:
		var parsed_json = JSON.parse_string(read_file)
		if parsed_json["Distro"] != "MyDistro":
			player_data = parsed_json
			return true
		
	return false

func _name_distro(new_name: String) -> void:
	distro_name = new_name
	player_data["Distro"] = distro_name
	distro_name_lbl.text = distro_name
	print_debug(player_data)

func _on_save_btn_pressed() -> void:
	_save_game()
