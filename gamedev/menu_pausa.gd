extends CanvasLayer

var painel: ColorRect
var label_titulo: Label
var botao_continuar: Button
var botao_menu: Button
var esta_pausado: bool = false

@export var cena_menu_principal: String = "res://menu_principal.tscn"  # Caminho do menu

func _ready() -> void:
	# Adiciona ao grupo para facilitar busca
	add_to_group("pause_menu")
	
	# Cria o painel de fundo semi-transparente
	painel = ColorRect.new()
	painel.name = "Painel"
	painel.color = Color(0, 0, 0, 0.7)
	painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel.visible = false
	add_child(painel)
	
	# Cria um container central para organizar os elementos
	var container = VBoxContainer.new()
	container.name = "Container"
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.position = Vector2(-200, -150)
	container.custom_minimum_size = Vector2(400, 300)
	container.add_theme_constant_override("separation", 20)
	painel.add_child(container)
	
	# Título "PAUSADO"
	label_titulo = Label.new()
	label_titulo.name = "Titulo"
	label_titulo.text = "JOGO PAUSADO"
	label_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_titulo.add_theme_font_size_override("font_size", 48)
	label_titulo.add_theme_color_override("font_color", Color(1, 1, 1))
	container.add_child(label_titulo)
	
	# Espaçador
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	container.add_child(spacer)
	
	# Botão Continuar
	botao_continuar = Button.new()
	botao_continuar.name = "BotaoContinuar"
	botao_continuar.text = "Continuar"
	botao_continuar.custom_minimum_size = Vector2(250, 60)
	botao_continuar.add_theme_font_size_override("font_size", 24)
	
	var botao_continuar_container = CenterContainer.new()
	botao_continuar_container.add_child(botao_continuar)
	container.add_child(botao_continuar_container)
	
	# Botão Menu Principal (opcional)
	botao_menu = Button.new()
	botao_menu.name = "BotaoMenu"
	botao_menu.text = "Menu Principal"
	botao_menu.custom_minimum_size = Vector2(250, 60)
	botao_menu.add_theme_font_size_override("font_size", 24)
	
	var botao_menu_container = CenterContainer.new()
	botao_menu_container.add_child(botao_menu)
	container.add_child(botao_menu_container)
	
	# Conecta os sinais dos botões
	botao_continuar.pressed.connect(_on_botao_continuar_pressed)
	botao_menu.pressed.connect(_on_botao_menu_pressed)

func _input(event: InputEvent) -> void:
	# Detecta quando ESC é pressionado
	if event.is_action_pressed("ui_cancel"):  # ESC é mapeado como "ui_cancel" por padrão
		alternar_pausa()

func alternar_pausa() -> void:
	if esta_pausado:
		despausar()
	else:
		pausar()

func pausar() -> void:
	esta_pausado = true
	painel.visible = true
	get_tree().paused = true

func despausar() -> void:
	esta_pausado = false
	painel.visible = false
	get_tree().paused = false

func _on_botao_continuar_pressed() -> void:
	despausar()

func _on_botao_menu_pressed() -> void:
	# Despausa antes de trocar de cena
	get_tree().paused = false
	# Volta para o menu principal
	if cena_menu_principal != "":
		get_tree().change_scene_to_file(cena_menu_principal)
	else:
		# Se não definiu o caminho, reinicia o jogo
		get_tree().reload_current_scene()
