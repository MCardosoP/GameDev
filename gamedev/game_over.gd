extends CanvasLayer

var painel: ColorRect
var label_titulo: Label
var botao_reiniciar: Button

func _ready() -> void:
	add_to_group("game_over")
	
	painel = ColorRect.new()
	painel.name = "Painel"
	painel.color = Color(0, 0, 0, 0.8)
	painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel.visible = false
	add_child(painel)
	
	var container = VBoxContainer.new()
	container.name = "Container"
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.position = Vector2(-200, -100)
	container.custom_minimum_size = Vector2(400, 200)
	container.add_theme_constant_override("separation", 30)
	painel.add_child(container)
	
	label_titulo = Label.new()
	label_titulo.name = "Titulo"
	label_titulo.text = "VOCÊ PERDEU!"
	label_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_titulo.add_theme_font_size_override("font_size", 48)
	label_titulo.add_theme_color_override("font_color", Color(1, 0, 0))
	container.add_child(label_titulo)
	
	botao_reiniciar = Button.new()
	botao_reiniciar.name = "BotaoReiniciar"
	botao_reiniciar.text = "Recomeçar"
	botao_reiniciar.custom_minimum_size = Vector2(200, 60)
	botao_reiniciar.add_theme_font_size_override("font_size", 24)
	
	var botao_container = CenterContainer.new()
	botao_container.add_child(botao_reiniciar)
	container.add_child(botao_container)
	
	botao_reiniciar.pressed.connect(_on_botao_reiniciar_pressed)

func mostrar() -> void:
	painel.visible = true
	get_tree().paused = true

func _on_botao_reiniciar_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
