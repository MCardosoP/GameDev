extends CanvasLayer

var label_vida: Label
var label_municao: Label
var label_onda: Label
var label_pontuacao: Label
var jogador: Node

func _ready() -> void:
	# Adiciona ao grupo para facilitar busca
	add_to_group("hud")
	
	# Cria o container horizontal para organizar os labels
	var hbox = HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.position = Vector2(20, 20)
	hbox.add_theme_constant_override("separation", 30)
	add_child(hbox)
	
	# Cria o label de vida
	label_vida = Label.new()
	label_vida.name = "Vida"
	label_vida.text = "Vida: 0"
	label_vida.add_theme_font_size_override("font_size", 24)
	label_vida.add_theme_color_override("font_color", Color(1, 1, 1))
	hbox.add_child(label_vida)
	
	# Cria o label de munição
	label_municao = Label.new()
	label_municao.name = "Municao"
	label_municao.text = "Munição: 0"
	label_municao.add_theme_font_size_override("font_size", 24)
	label_municao.add_theme_color_override("font_color", Color(1, 1, 1))
	hbox.add_child(label_municao)
	
	# Cria o label de onda
	label_onda = Label.new()
	label_onda.name = "Onda"
	label_onda.text = "Sala: 1"
	label_onda.add_theme_font_size_override("font_size", 24)
	label_onda.add_theme_color_override("font_color", Color(1, 1, 0))
	hbox.add_child(label_onda)
	
	# Cria o label de pontuação
	label_pontuacao = Label.new()
	label_pontuacao.name = "Pontuacao"
	label_pontuacao.text = "Pontos: 0"
	label_pontuacao.add_theme_font_size_override("font_size", 24)
	label_pontuacao.add_theme_color_override("font_color", Color(1, 1, 0))
	hbox.add_child(label_pontuacao)
	
	# Aguarda o jogador ser instanciado
	await get_tree().process_frame
	
	jogador = get_tree().current_scene.get_node_or_null("Jogador")
	
	# Se não encontrou na cena, procura na Sala
	if not jogador:
		var sala = get_tree().current_scene.get_node_or_null("Sala")
		if sala:
			jogador = sala.get_node_or_null("Jogador")
	
	# Última tentativa: busca por grupo
	if not jogador:
		await get_tree().create_timer(0.1).timeout
		var jogadores = get_tree().get_nodes_in_group("jogador")
		if jogadores.size() > 0:
			jogador = jogadores[0]
	
	# Atualiza o HUD com os valores iniciais
	if jogador:
		atualizar_hud(jogador.vida, jogador.municao)
	
	# Atualiza onda e pontuação
	atualizar_onda_pontuacao()

func atualizar_hud(vida: int, municao: int) -> void:
	if label_vida:
		label_vida.text = "Vida: %d" % vida
	if label_municao:
		label_municao.text = "Munição: %d" % municao

func atualizar_onda_pontuacao() -> void:
	if label_onda:
		label_onda.text = "Sala: %d" % GerenciadorOndas.onda_atual
	if label_pontuacao:
		label_pontuacao.text = "Pontos: %d" % GerenciadorOndas.pontuacao

func _process(delta: float) -> void:
	# Atualiza pontuação constantemente
	atualizar_onda_pontuacao()
