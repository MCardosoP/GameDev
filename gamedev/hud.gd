extends CanvasLayer

var label_vida: Label
var label_municao: Label
var jogador: Node

func _ready() -> void:
	add_to_group("hud")
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.position = Vector2(20, 20)
	hbox.add_theme_constant_override("separation", 30)
	add_child(hbox)
	
	label_vida = Label.new()
	label_vida.name = "Vida"
	label_vida.text = "Vida: 0"
	label_vida.add_theme_font_size_override("font_size", 24)
	label_vida.add_theme_color_override("font_color", Color(1, 1, 1))
	hbox.add_child(label_vida)
	
	label_municao = Label.new()
	label_municao.name = "Municao"
	label_municao.text = "Munição: 0"
	label_municao.add_theme_font_size_override("font_size", 24)
	label_municao.add_theme_color_override("font_color", Color(1, 1, 1))
	hbox.add_child(label_municao)
	
	await get_tree().process_frame
	
	jogador = get_tree().current_scene.get_node_or_null("Jogador")
	
	if not jogador:
		var sala = get_tree().current_scene.get_node_or_null("Sala")
		if sala:
			jogador = sala.get_node_or_null("Jogador")
	
	if not jogador:
		await get_tree().create_timer(0.1).timeout
		var jogadores = get_tree().get_nodes_in_group("jogador")
		if jogadores.size() > 0:
			jogador = jogadores[0]
	
	if jogador:
		atualizar_hud(jogador.vida, jogador.municao)

func atualizar_hud(vida: int, municao: int) -> void:
	if label_vida:
		label_vida.text = "Vida: %d" % vida
	if label_municao:
		label_municao.text = "Munição: %d" % municao
