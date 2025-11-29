extends CharacterBody2D

@export var velocidade: float = 600.0
@export var tamanho: Vector2 = Vector2(12, 12)
var direcao: Vector2 = Vector2.ZERO

func _ready():
	collision_layer = 0b00100000 # layer 6 (projéteis de inimigos)
	collision_mask = 0b00000011  # colide apenas com jogador (1) e paredes (2)
	add_to_group("projeteis_inimigos")
	
	# ADICIONANDO COLLISION SHAPE
	var colisao = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = tamanho
	colisao.shape = forma
	add_child(colisao)
	
	# Visual do projétil (laranja/vermelho)
	var visual = ColorRect.new()
	visual.color = Color(1, 0.5, 0) # Laranja
	visual.size = tamanho
	visual.position = -tamanho / 2
	add_child(visual)

func set_direcao(nova_direcao: Vector2):
	direcao = nova_direcao.normalized()

func _physics_process(delta: float):
	if direcao == Vector2.ZERO:
		return
		
	var deslocamento = direcao * velocidade * delta
	var colisao = move_and_collide(deslocamento)

	if colisao:
		var corpo = colisao.get_collider()
		if corpo and corpo.is_in_group("parede"):
			criar_efeito_impacto(colisao.get_position())
			queue_free()
		elif corpo and corpo.is_in_group("jogador"):
			# Causa dano no jogador
			if corpo.has_method("receber_dano"):
				corpo.receber_dano(1)
			queue_free()

func criar_efeito_impacto(ponto: Vector2):
	var efeito = ColorRect.new()
	efeito.color = Color(1, 0.5, 0, 0.3) # Laranja semi-transparente
	efeito.size = Vector2(24, 24)
	efeito.position = ponto - efeito.size / 2
	var cena = get_tree().current_scene
	if not cena: cena = get_tree().get_root()
	cena.add_child(efeito)

	var timer = get_tree().create_timer(0.3)
	timer.timeout.connect(func():
		if is_instance_valid(efeito):
			efeito.queue_free()
	)
