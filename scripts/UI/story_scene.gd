extends Control

@onready var story_text: RichTextLabel = $StoryText
@onready var continue_button: Button = $ContinueButton
@onready var skip_button: Button = $SkipButton

var sfx_player: AudioStreamPlayer
var voice_stream: AudioStream

var story_lines = [
	"*heavy sigh*... DUMAAAAAAAAAAAAAA...",
	"",
	"Look at this place. It is a ZOO.",
	"Actually, a zoo is cleaner. Zoos have keepers.",
	"",
	"The roaches have formed a union. They are paying rent now.",
	"MY HUSBAND DOESN'T FLUSH POOPS ARE COMING ALIVE",
	"",
	"And the shame... oh, the shame.",
	"The kids brought home an A-minus.",
	"A. MINUS. They might as well have spit on the ancestors.",
	"",
	"My husband? always beer beer beer beer beer.",
	"The baby is a biological weapon.",
	"And the teenager thinks 'cleaning' is a foreign language.",
	"",
	"I cannot let Mrs. Nguyen see us like this.",
	"",
	"I need you.",
	"",
	"Grab the Slipper of Justice.",
	"",
	"We are EXORCISING this mess.",
	"",
	"Let's show them the true meaning of MOM FURY."
]

var current_line: int = 0
var char_index: int = 0
var text_speed: float = 0.03
var line_delay: float = 0.5

var is_typing: bool = false
var skip_typing: bool = false

func _ready() -> void:
	# --- AUDIO SETUP ---
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	# Load the voice file
	voice_stream = load("res://assets/Sound/Mom/women.mp3") 
	sfx_player.stream = voice_stream
	sfx_player.volume_db = -5.0


	story_text.text = ""
	continue_button.visible = false
	continue_button.pressed.connect(_on_continue_pressed)
	skip_button.pressed.connect(_on_skip_pressed)

	# Start typing after a short delay
	await get_tree().create_timer(0.5).timeout
	_type_next_line()

func _process(delta: float) -> void:
	# Allow clicking anywhere to speed up typing
	if Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		skip_typing = true
		
	# If the audio file is short, this restarts it while we are still typing
	if is_typing and not sfx_player.playing:
		sfx_player.play()


func _type_next_line() -> void:
	if current_line >= story_lines.size():
		is_typing = false
		sfx_player.stop() # Ensure sound stops at end
		continue_button.visible = true
		return

	var line = story_lines[current_line]
	current_line += 1

	if line == "":
		story_text.text += "\n"
		await get_tree().create_timer(line_delay).timeout
		_type_next_line()
		return

	# --- START TYPING ---
	is_typing = true
	skip_typing = false
	
	# Start the voice audio
	if voice_stream:
		sfx_player.play()

	for i in range(line.length()):
		if skip_typing:
			story_text.text += line.substr(i)
			break

		story_text.text += line[i]
		await get_tree().create_timer(text_speed).timeout

	# --- STOP TYPING ---
	is_typing = false
	sfx_player.stop() 
	
	story_text.text += "\n"

	await get_tree().create_timer(line_delay).timeout
	_type_next_line()

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/tutorial.tscn")

func _on_skip_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/tutorial.tscn")
