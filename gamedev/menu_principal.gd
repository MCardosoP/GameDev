extends Control

var painel_fundo: ColorRect
var label_titulo: Label
var botao_jogar: Button
var botao_opcoes: Button
var botao_sair: Button

@export var cena_jogo: String = "res://jogo.tscn"  # Caminho da cena do jogo

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
	container_principal.offset_left = -250
	container_principal.offset_top = -300
	container_principal.offset_right = 250
	container_principal.offset_bottom = 300
	container_principal.grow_horizontal = Control.GROW_DIRECTION_BOTH
	container_principal.grow_vertical = Control.GROW_DIRECTION_BOTH
	container_principal.add_theme_constant_override("separation", 40)
	add_child(container_principal)
	
	# Título do Jogo
	label_titulo = Label.new()
	label_titulo.name = "Titulo"
	label_titulo.text = "VENATOR NOCTIS"
	label_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_titulo.add_theme_font_size_override("font_size", 72)
	label_titulo.add_theme_color_override("font_color", Color(1, 1, 1))
	container_principal.add_child(label_titulo)
	
	# Espaçador
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 50)
	container_principal.add_child(spacer)
	
	# Container para os botões
	var container_botoes = VBoxContainer.new()
	container_botoes.name = "ContainerBotoes"
	container_botoes.add_theme_constant_override("separation", 20)
	container_principal.add_child(container_botoes)
	
	# Botão Jogar
	botao_jogar = criar_botao("Jogar")
	var container_jogar = CenterContainer.new()
	container_jogar.add_child(botao_jogar)
	container_botoes.add_child(container_jogar)
	botao_jogar.pressed.connect(_on_botao_jogar_pressed)
	
	# Botão Sair
	botao_sair = criar_botao("Sair")
	var container_sair = CenterContainer.new()
	container_sair.add_child(botao_sair)
	container_botoes.add_child(container_sair)
	botao_sair.pressed.connect(_on_botao_sair_pressed)
	
	# Informação de controles no rodapé
	var label_controles = Label.new()
	label_controles.text = "Controles: WASD - Mover | Setas - Atirar | Q - Ataque Corpo a Corpo | ESC - Pausar"
	label_controles.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_controles.add_theme_font_size_override("font_size", 16)
	label_controles.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	container_principal.add_child(spacer2)
	container_principal.add_child(label_controles)

func criar_botao(texto: String) -> Button:
	var botao = Button.new()
	botao.text = texto
	botao.custom_minimum_size = Vector2(300, 70)
	botao.add_theme_font_size_override("font_size", 28)
	return botao

func _on_botao_jogar_pressed() -> void:
	# Troca para a cena do jogo
	if cena_jogo != "":
		get_tree().change_scene_to_file(cena_jogo)
	else:
		print("ERRO: Caminho da cena do jogo não foi definido!")

func _on_botao_opcoes_pressed() -> void:
	# Por enquanto, apenas mostra uma mensagem
	print("Opções - A implementar")
	# Aqui você pode criar uma tela de opções depois

func _on_botao_sair_pressed() -> void:
	# Fecha o jogo
	get_tree().quit()
