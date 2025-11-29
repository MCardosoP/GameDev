extends CanvasLayer

var painel: ColorRect
var label_titulo: Label
var botao_reiniciar: Button
var botao_menu: Button

@export var cena_menu_principal: String = "res://menu_principal.tscn"  # Caminho do menu

func _ready() -> void:
	# Adiciona ao grupo para facilitar busca
	add_to_group("game_over")
	
	# Cria o painel de fundo semi-transparente
	painel = ColorRect.new()
	painel.name = "Painel"
	painel.color = Color(0, 0, 0, 0.8)
	painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	painel.visible = false
	add_child(painel)
	
	# Cria um container central para organizar os elementos
	var container = VBoxContainer.new()
	container.name = "Container"
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.position = Vector2(-200, -100)
	container.custom_minimum_size = Vector2(400, 200)
	container.add_theme_constant_override("separation", 30)
	painel.add_child(container)
	
	# Título "Você Perdeu!"
	label_titulo = Label.new()
	label_titulo.name = "Titulo"
	label_titulo.text = "VOCÊ PERDEU!"
	label_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_titulo.add_theme_font_size_override("font_size", 48)
	label_titulo.add_theme_color_override("font_color", Color(1, 0, 0))
	container.add_child(label_titulo)
	
	# Botão Recomeçar
	botao_reiniciar = Button.new()
	botao_reiniciar.name = "BotaoReiniciar"
	botao_reiniciar.text = "Recomeçar"
	botao_reiniciar.custom_minimum_size = Vector2(200, 60)
	botao_reiniciar.add_theme_font_size_override("font_size", 24)
	
	# Centraliza o botão no container
	var botao_reiniciar_container = CenterContainer.new()
	botao_reiniciar_container.add_child(botao_reiniciar)
	container.add_child(botao_reiniciar_container)
	
	# Botão Menu Principal
	botao_menu = Button.new()
	botao_menu.name = "BotaoMenu"
	botao_menu.text = "Menu Principal"
	botao_menu.custom_minimum_size = Vector2(200, 60)
	botao_menu.add_theme_font_size_override("font_size", 24)
	
	var botao_menu_container = CenterContainer.new()
	botao_menu_container.add_child(botao_menu)
	container.add_child(botao_menu_container)
	
	# Conecta o sinal do botão
	botao_reiniciar.pressed.connect(_on_botao_reiniciar_pressed)
	botao_menu.pressed.connect(_on_botao_menu_pressed)

func mostrar() -> void:
	painel.visible = true
	# Pausa o jogo quando o Game Over aparece
	get_tree().paused = true
	
	# Salva o high score
	var pontos = GerenciadorOndas.pontuacao
	var sala = GerenciadorOndas.onda_atual
	GerenciadorHighscores.adicionar_score(pontos, sala)
	
	# Verifica se é novo recorde
	if GerenciadorHighscores.eh_novo_highscore(pontos):
		label_titulo.text = "NOVO RECORDE!\nVocê perdeu!"
		label_titulo.add_theme_color_override("font_color", Color(1, 0.84, 0))  # Dourado
	else:
		label_titulo.text = "VOCÊ PERDEU!"
		label_titulo.add_theme_color_override("font_color", Color(1, 0, 0))  # Vermelho

func _on_botao_reiniciar_pressed() -> void:
	# Despausa o jogo
	get_tree().paused = false
	# Reinicia a cena atual
	get_tree().reload_current_scene()

func _on_botao_menu_pressed() -> void:
	# Despausa o jogo
	get_tree().paused = false
	# Volta para o menu principal
	if cena_menu_principal != "":
		get_tree().change_scene_to_file(cena_menu_principal)
	else:
		# Se não definiu o caminho, reinicia o jogo
		get_tree().reload_current_scene()
