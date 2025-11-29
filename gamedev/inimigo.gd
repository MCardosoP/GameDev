extends CharacterBody2D

@export var velocidade: float = 250.0
@export var cooldown_apos_ataque: float = 0.5
@export var distancia_ataque: float = 32.0
@export var tamanho: Vector2 = Vector2(32, 32)

var jogador: Node = null

var vida: int = 1
var pode_mover_e_atacar: bool = true
var corpo_visual: ColorRect  # Referência ao visual

func _ready():
	collision_layer = 0b00000100 # layer 3
	collision_mask = 0b00001011 # colide com jogador (1), paredes (2) e projéteis (4)
	add_to_group("inimigos")

	# ADICIONANDO COLLISION SHAPE
	var colisao = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = tamanho
	colisao.shape = forma
	add_child(colisao)

	# Visual do inimigo
	var cor = ColorRect.new()
	cor.color = Color(1, 0, 0)
	cor.size = tamanho
	cor.position = -tamanho / 2
	add_child(cor)

func _physics_process(delta: float):
	if not pode_mover_e_atacar or vida <= 0:
		return
	
	# Tenta encontrar o jogador se ainda não tiver referência
	if not jogador:
		# Primeiro tenta na cena atual
		jogador = get_tree().current_scene.get_node_or_null("Jogador")
		
		# Se não encontrou, procura no pai (Sala)
		if not jogador and get_parent():
			jogador = get_parent().get_node_or_null("Jogador")
		
		# Se ainda não encontrou, procura em todo o grupo
		if not jogador:
			var jogadores = get_tree().get_nodes_in_group("jogador")
			if jogadores.size() > 0:
				jogador = jogadores[0]
		
		if not jogador:
			return # Ainda não existe, tenta no próximo frame

	var direcao = jogador.global_position - global_position
	var distancia = direcao.length()

	if distancia > distancia_ataque:
		velocity = direcao.normalized() * velocidade
		move_and_slide()
		
		# VERIFICA SE COLIDIU COM O JOGADOR DURANTE O MOVIMENTO
		for i in get_slide_collision_count():
			var colisao = get_slide_collision(i)
			var corpo = colisao.get_collider()
			if corpo == jogador:
				_atacar_jogador()
				break
	else:
		# Está próximo, tenta atacar
		velocity = Vector2.ZERO
		_atacar_jogador()

func _atacar_jogador():
	if not pode_mover_e_atacar:
		return
		
	if jogador and jogador.has_method("receber_dano"):
		jogador.receber_dano(1)

	pode_mover_e_atacar = false
	_iniciar_cooldown()

func _iniciar_cooldown():
	var timer = get_tree().create_timer(cooldown_apos_ataque)
	timer.timeout.connect(func():
		pode_mover_e_atacar = true
	)

func receber_dano(dano: int):
	vida -= dano
	if vida <= 0:
		criar_efeito_morte()
		queue_free()

func criar_efeito_morte():
	# Cria um efeito visual na posição onde o inimigo morreu
	var efeito = ColorRect.new()
	efeito.color = Color(1, 0, 0, 0.5) # Vermelho semi-transparente
	efeito.size = tamanho * 1.5 # Um pouco maior que o inimigo
	efeito.position = global_position - efeito.size / 2
	
	var cena = get_tree().current_scene
	if not cena: cena = get_tree().get_root()
	cena.add_child(efeito)
	
	# Remove o efeito após 0.5 segundos
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(func():
		if is_instance_valid(efeito):
			efeito.queue_free()
	)
