extends Control

var painel_fundo: ColorRect
var label_titulo: Label
var container_scores: VBoxContainer
var botao_voltar: Button

func _ready() -> void:
	# Garante que o Control raiz ocupe a tela toda
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Cria o fundo
	painel_fundo = ColorRect.new()
	painel_fundo.name = "Fundo"
	painel_fundo.color = Color(0.1, 0.1, 0.15)  # Azul escuro
	painel_fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(painel_fundo)
	
	# Container principal centralizado
	var container_principal = VBoxContainer.new()
	container_principal.name = "ContainerPrincipal"
	container_principal.anchor_left = 0.5
	container_principal.anchor_top = 0.5
	container_principal.anchor_right = 0.5
	container_principal.anchor_bottom = 0.5
	container_principal.offset_left = -400
	container_principal.offset_top = -300
	container_principal.offset_right = 400
	container_principal.offset_bottom = 300
	container_principal.add_theme_constant_override("separation", 30)
	add_child(container_principal)
	
	# Título
	label_titulo = Label.new()
	label_titulo.name = "Titulo"
	label_titulo.text = "MELHORES PONTUAÇÕES"
	label_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_titulo.add_theme_font_size_override("font_size", 48)
	label_titulo.add_theme_color_override("font_color", Color(1, 1, 0))
	container_principal.add_child(label_titulo)
	
	# Container para os scores
	container_scores = VBoxContainer.new()
	container_scores.name = "ContainerScores"
	container_scores.add_theme_constant_override("separation", 15)
	container_principal.add_child(container_scores)
	
	# Carrega e exibe os high scores
	exibir_highscores()
	
	# Espaçador
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	container_principal.add_child(spacer)
	
	# Botão Voltar
	botao_voltar = Button.new()
	botao_voltar.name = "BotaoVoltar"
	botao_voltar.text = "Voltar ao Menu"
	botao_voltar.custom_minimum_size = Vector2(300, 60)
	botao_voltar.add_theme_font_size_override("font_size", 24)
	
	var botao_container = CenterContainer.new()
	botao_container.add_child(botao_voltar)
	container_principal.add_child(botao_container)
	
	botao_voltar.pressed.connect(_on_botao_voltar_pressed)

func exibir_highscores():
	# Limpa scores anteriores
	for child in container_scores.get_children():
		child.queue_free()
	
	var scores = GerenciadorHighscores.obter_highscores()
	
	if scores.size() == 0:
		# Nenhum score ainda
		var label_vazio = Label.new()
		label_vazio.text = "Nenhuma pontuação registrada ainda.\nJogue para aparecer aqui!"
		label_vazio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_vazio.add_theme_font_size_override("font_size", 24)
		label_vazio.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		container_scores.add_child(label_vazio)
	else:
		# Exibe cada score
		for i in range(scores.size()):
			var score = scores[i]
			
			# Container horizontal para cada entrada
			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 20)
			
			# Posição (1º, 2º, 3º...)
			var label_posicao = Label.new()
			label_posicao.text = "%d." % (i + 1)
			label_posicao.custom_minimum_size = Vector2(50, 0)
			label_posicao.add_theme_font_size_override("font_size", 28)
			label_posicao.add_theme_color_override("font_color", obter_cor_posicao(i))
			hbox.add_child(label_posicao)
			
			# Pontos
			var label_pontos = Label.new()
			label_pontos.text = "%d pontos" % score["pontos"]
			label_pontos.custom_minimum_size = Vector2(200, 0)
			label_pontos.add_theme_font_size_override("font_size", 28)
			label_pontos.add_theme_color_override("font_color", Color(1, 1, 1))
			hbox.add_child(label_pontos)
			
			# Sala alcançada
			var label_sala = Label.new()
			label_sala.text = "Sala %d" % score["sala"]
			label_sala.custom_minimum_size = Vector2(150, 0)
			label_sala.add_theme_font_size_override("font_size", 24)
			label_sala.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			hbox.add_child(label_sala)
			
			container_scores.add_child(hbox)

func obter_cor_posicao(posicao: int) -> Color:
	match posicao:
		0: return Color(1, 0.84, 0)      # Ouro
		1: return Color(0.75, 0.75, 0.75) # Prata
		2: return Color(0.8, 0.5, 0.2)   # Bronze
		_: return Color(1, 1, 1)         # Branco

func _on_botao_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://menu_principal.tscn")
