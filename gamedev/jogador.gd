extends CharacterBody2D

@export var velocidade: float = 500.0
@export var espera_ataque: float = 0.4
@export var cena_projetil: PackedScene
@export var vida: int = 5
@export var municao: int = 100
@export var tamanho: Vector2 = Vector2(32, 32)

var hud = null
var pode_atacar: bool = true
var corpo_visual: ColorRect  # Referência ao visual do jogador

func _ready():
	collision_layer = 0b00000001 # jogador na layer 1
	collision_mask = 0b00000110  # colide com paredes (2) e inimigos (3)
	
	# Adiciona ao grupo para facilitar busca
	add_to_group("jogador")
	
	# Busca o HUD
	hud = get_tree().current_scene.get_node_or_null("HUD")
	if not hud:
		# Busca em qualquer lugar da árvore
		var huds = get_tree().get_nodes_in_group("hud")
		if huds.size() > 0:
			hud = huds[0]
	
	# ADICIONANDO COLLISION SHAPE (isso estava faltando!)
	var colisao = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = tamanho
	colisao.shape = forma
	add_child(colisao)
	
	# Visual do jogador
	var visual = ColorRect.new()
	visual.color = Color(0, 0, 1) # Azul
	visual.size = tamanho
	visual.position = -tamanho / 2
	add_child(visual)
	corpo_visual = visual  # Salva referência para efeitos visuais

func _physics_process(delta: float):
	mover_jogador()
	atacar_distancia()
	atacar_corpo()

func mover_jogador():
	var direcao = Vector2.ZERO
	if Input.is_action_pressed("mov_direita"): direcao.x += 1
	if Input.is_action_pressed("mov_esquerda"): direcao.x -= 1
	if Input.is_action_pressed("mov_baixo"): direcao.y += 1
	if Input.is_action_pressed("mov_cima"): direcao.y -= 1

	direcao = direcao.normalized()
	velocity = direcao * velocidade
	move_and_slide()

func atacar_distancia():
	# Tenta buscar o HUD se ainda não tiver
	if not hud:
		hud = get_tree().current_scene.get_node_or_null("HUD")
		if not hud:
			var huds = get_tree().get_nodes_in_group("hud")
			if huds.size() > 0:
				hud = huds[0]
	
	var direcao_tiro = Vector2.ZERO
	if Input.is_action_just_pressed("proj_direita"): direcao_tiro = Vector2.RIGHT
	elif Input.is_action_just_pressed("proj_esquerda"): direcao_tiro = Vector2.LEFT
	elif Input.is_action_just_pressed("proj_baixo"): direcao_tiro = Vector2.DOWN
	elif Input.is_action_just_pressed("proj_cima"): direcao_tiro = Vector2.UP

	if direcao_tiro != Vector2.ZERO and municao > 0 and pode_atacar:
		pode_atacar = false
		if not cena_projetil: return

		var projetil = cena_projetil.instantiate()
		var cena = get_tree().current_scene
		if not cena: cena = get_tree().get_root()
		cena.add_child(projetil)
		projetil.global_position = global_position
		projetil.direcao = direcao_tiro.normalized()

		municao -= 1
		if hud and hud.has_method("atualizar_hud"):
			hud.atualizar_hud(vida, municao)
		await get_tree().create_timer(espera_ataque).timeout
		pode_atacar = true

func atacar_corpo():
	if not Input.is_action_just_pressed("ataque_corpo") or not pode_atacar:
		return

	pode_atacar = false

	var area_ataque = Area2D.new()
	area_ataque.position = Vector2.ZERO
	area_ataque.monitoring = true
	area_ataque.collision_layer = 0b00010000 # layer 5
	area_ataque.collision_mask = 0b00000100 # colide com inimigos (layer 3)

	var colisao = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(128, 128)
	colisao.shape = forma
	colisao.position = Vector2.ZERO
	area_ataque.add_child(colisao)
	add_child(area_ataque)

	# Aguarda um frame para o Area2D processar overlaps
	await get_tree().process_frame
	
	# Verifica inimigos na área
	for corpo in area_ataque.get_overlapping_bodies():
		if corpo.is_in_group("inimigos"):
			corpo.receber_dano(1)

	# Mantém sinal para novos inimigos que entrarem
	area_ataque.body_entered.connect(func(corpo):
		if corpo.is_in_group("inimigos"):
			corpo.receber_dano(1)
	)

	# Efeito visual do ataque
	var efeito = ColorRect.new()
	efeito.color = Color(1, 0, 0, 0.3)
	efeito.size = forma.size
	efeito.position = -efeito.size / 2
	area_ataque.add_child(efeito)

	await get_tree().create_timer(0.5).timeout

	if is_instance_valid(area_ataque):
		area_ataque.queue_free()

	await get_tree().create_timer(espera_ataque).timeout
	pode_atacar = true

func receber_dano(dano: int):
	vida -= dano
	if hud and hud.has_method("atualizar_hud"):
		hud.atualizar_hud(vida, municao)
	
	# Feedback visual de dano (pisca vermelho)
	criar_efeito_dano()
	
	if vida <= 0:
		print("Jogador morreu!")
		# Chama o Game Over
		var game_over = get_tree().current_scene.get_node_or_null("GameOver")
		if not game_over:
			var game_overs = get_tree().get_nodes_in_group("game_over")
			if game_overs.size() > 0:
				game_over = game_overs[0]
		
		if game_over and game_over.has_method("mostrar"):
			game_over.mostrar()
		queue_free()

func criar_efeito_dano():
	# Flash vermelho ao tomar dano
	if corpo_visual:
		var cor_original = corpo_visual.color
		corpo_visual.color = Color(1, 0, 0)  # Vermelho
		
		# Volta à cor original após 0.15 segundos
		var timer = get_tree().create_timer(0.15)
		timer.timeout.connect(func():
			if is_instance_valid(corpo_visual):
				corpo_visual.color = cor_original
		)
