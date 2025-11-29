extends CharacterBody2D

@export var velocidade: float = 250.0
@export var cooldown_apos_ataque: float = 0.5
@export var distancia_ataque: float = 32.0
@export var tamanho: Vector2 = Vector2(32, 32)
@export var raio_visao: float = 500.0   # distância máxima para detectar jogador
@export var tempo_troca_patrulha: float = 2.0 # tempo para mudar direção na patrulha

var jogador: Node = null
var vida: int = 1
var pode_mover_e_atacar: bool = true
var corpo_visual: ColorRect

# Estados
enum Estado {
	PATRULHA,
	PERSEGUINDO
}
var estado_atual = Estado.PATRULHA

# Controle da patrulha
var direcao_patrulha: Vector2 = Vector2.ZERO
var timer_patrulha: float = 0.0

func _ready():
	collision_layer = 0b00000100 # layer 3
	collision_mask = 0b00001011 # colide com jogador (1), paredes (2) e projéteis (4)
	add_to_group("inimigos")

	var colisao = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = tamanho
	colisao.shape = forma
	add_child(colisao)

	var cor = ColorRect.new()
	cor.color = Color(1, 0, 0)
	cor.size = tamanho
	cor.position = -tamanho / 2
	add_child(cor)
	corpo_visual = cor

	# Inicializa patrulha
	_nova_direcao_patrulha()

func _physics_process(delta: float):
	if not pode_mover_e_atacar or vida <= 0:
		return

	# Tenta encontrar jogador
	if not jogador:
		jogador = get_tree().current_scene.get_node_or_null("Jogador")
		if not jogador and get_parent():
			jogador = get_parent().get_node_or_null("Jogador")
		if not jogador:
			var jogadores = get_tree().get_nodes_in_group("jogador")
			if jogadores.size() > 0:
				jogador = jogadores[0]

	if estado_atual == Estado.PATRULHA:
		_processar_patrulha(delta)
		_detectar_jogador()
	elif estado_atual == Estado.PERSEGUINDO:
		_processar_perseguicao(delta)

func _processar_patrulha(delta: float):
	timer_patrulha -= delta
	if timer_patrulha <= 0:
		_nova_direcao_patrulha()

	velocity = direcao_patrulha * velocidade
	move_and_slide()

func _nova_direcao_patrulha():
	# Direção aleatória
	direcao_patrulha = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	timer_patrulha = tempo_troca_patrulha

func _detectar_jogador():
	if jogador and jogador.is_inside_tree():
		var distancia = global_position.distance_to(jogador.global_position)
		if distancia <= raio_visao:
			estado_atual = Estado.PERSEGUINDO

func _processar_perseguicao(delta: float):
	if not jogador:
		return

	var direcao = jogador.global_position - global_position
	var distancia = direcao.length()

	if distancia > distancia_ataque:
		velocity = direcao.normalized() * velocidade
		move_and_slide()

		for i in get_slide_collision_count():
			var colisao = get_slide_collision(i)
			var corpo = colisao.get_collider()
			if corpo == jogador:
				_atacar_jogador()
				break
	else:
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
	criar_efeito_dano()

	if vida <= 0:
		criar_efeito_morte()
		var sala = get_parent()
		if sala and sala.has_method("inimigo_morreu_com_powerup"):
			sala.inimigo_morreu_com_powerup(global_position)
		queue_free()

func criar_efeito_dano():
	if corpo_visual:
		var cor_original = corpo_visual.color
		corpo_visual.color = Color(1, 1, 1)
		var timer = get_tree().create_timer(0.1)
		timer.timeout.connect(func():
			if is_instance_valid(corpo_visual):
				corpo_visual.color = cor_original
		)

func criar_efeito_morte():
	var efeito = ColorRect.new()
	efeito.color = Color(1, 0, 0, 0.5)
	efeito.size = tamanho * 1.5
	efeito.position = global_position - efeito.size / 2

	var cena = get_tree().current_scene
	if not cena: cena = get_tree().get_root()
	cena.add_child(efeito)

	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(func():
		if is_instance_valid(efeito):
			efeito.queue_free()
	)
