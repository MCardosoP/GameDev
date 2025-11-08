extends CharacterBody2D

@export var velocidade: float = 500.0
@export var espera_ataque: float = 0.4
@export var cena_projetil: PackedScene
@export var vida: int = 5
@export var municao: int = 100
@export var tamanho: Vector2 = Vector2(32, 32)

var hud = null
var pode_atacar: bool = true

func _ready():
	collision_layer = 0b00000001
	collision_mask = 0b00000110
	
	add_to_group("jogador")
	
	hud = get_tree().current_scene.get_node_or_null("HUD")
	if not hud:
		var huds = get_tree().get_nodes_in_group("hud")
		if huds.size() > 0:
			hud = huds[0]
	
	var colisao = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = tamanho
	colisao.shape = forma
	add_child(colisao)
	
	var visual = ColorRect.new()
	visual.color = Color(0, 0, 1)
	visual.size = tamanho
	visual.position = -tamanho / 2
	add_child(visual)

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
	if Input.is_action_just_pressed("proj_direita"): direcao_tiro.x += 1
	elif Input.is_action_just_pressed("proj_esquerda"): direcao_tiro.x -= 1
	elif Input.is_action_just_pressed("proj_baixo"): direcao_tiro.y += 1
	elif Input.is_action_just_pressed("proj_cima"): direcao_tiro.y -= 1

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
	area_ataque.collision_layer = 0b00010000
	area_ataque.collision_mask = 0b00000100 

	var colisao = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = Vector2(128, 128)
	colisao.shape = forma
	colisao.position = Vector2.ZERO
	area_ataque.add_child(colisao)
	add_child(area_ataque)

	await get_tree().process_frame
	
	for corpo in area_ataque.get_overlapping_bodies():
		if corpo.is_in_group("inimigos"):
			corpo.receber_dano(1)

	area_ataque.body_entered.connect(func(corpo):
		if corpo.is_in_group("inimigos"):
			corpo.receber_dano(1)
	)

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
	
	if vida <= 0:
		print("Jogador morreu!")
		var game_over = get_tree().current_scene.get_node_or_null("GameOver")
		if not game_over:
			var game_overs = get_tree().get_nodes_in_group("game_over")
			if game_overs.size() > 0:
				game_over = game_overs[0]
		
		if game_over and game_over.has_method("mostrar"):
			game_over.mostrar()
		queue_free()
