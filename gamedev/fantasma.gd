extends CharacterBody2D

@export var velocidade_base: float = 300.0
@export var cooldown_apos_ataque: float = 0.5
@export var distancia_ataque: float = 32.0
@export var tamanho: Vector2 = Vector2(32, 32)
@export var intervalo_mudanca_estado: float = 3.0
@export var raio_visao: float = 500.0         # alcance da visão
@export var tempo_troca_patrulha: float = 2.0 # tempo para mudar direção na patrulha

var jogador: Node = null
var vida: int = 1
var pode_mover_e_atacar: bool = true

# Estados de vulnerabilidade
enum EstadoVulnerabilidade {
	VULNERAVEL,
	INVULNERAVEL
}
var estado_vulnerabilidade = EstadoVulnerabilidade.VULNERAVEL
var timer_mudanca_estado: float = 0.0

# Estados de comportamento
enum EstadoComportamento {
	PATRULHA,
	PERSEGUIR
}
var estado_comportamento = EstadoComportamento.PATRULHA

# Controle da patrulha
var direcao_patrulha: Vector2 = Vector2.ZERO
var timer_patrulha: float = 0.0

# Componentes visuais
var corpo_visual: ColorRect
var indicador_invulnerabilidade: ColorRect

func _ready():
	collision_layer = 0b00000100
	collision_mask = 0b00001011
	add_to_group("inimigos")

	var colisao = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = tamanho
	colisao.shape = forma
	add_child(colisao)

	corpo_visual = ColorRect.new()
	corpo_visual.color = Color(0.6, 0.2, 0.8)
	corpo_visual.size = tamanho
	corpo_visual.position = -tamanho / 2
	add_child(corpo_visual)

	indicador_invulnerabilidade = ColorRect.new()
	indicador_invulnerabilidade.color = Color(1, 1, 1, 0.5)
	indicador_invulnerabilidade.size = tamanho + Vector2(4, 4)
	indicador_invulnerabilidade.position = -(tamanho + Vector2(4, 4)) / 2
	indicador_invulnerabilidade.visible = false
	add_child(indicador_invulnerabilidade)

	timer_mudanca_estado = intervalo_mudanca_estado
	_nova_direcao_patrulha()

func _physics_process(delta: float):
	if not pode_mover_e_atacar or vida <= 0:
		return

	if not jogador:
		jogador = get_tree().current_scene.get_node_or_null("Jogador")
		if not jogador and get_parent():
			jogador = get_parent().get_node_or_null("Jogador")
		if not jogador:
			var jogadores = get_tree().get_nodes_in_group("jogador")
			if jogadores.size() > 0:
				jogador = jogadores[0]
		if not jogador:
			return

	atualizar_estado_vulnerabilidade(delta)

	if estado_comportamento == EstadoComportamento.PATRULHA:
		_processar_patrulha(delta)
		_detectar_jogador()
	elif estado_comportamento == EstadoComportamento.PERSEGUIR:
		_processar_perseguicao(delta)

func _processar_patrulha(delta: float):
	timer_patrulha -= delta
	if timer_patrulha <= 0:
		_nova_direcao_patrulha()

	velocity = direcao_patrulha * calcular_velocidade()
	move_and_slide()

func _nova_direcao_patrulha():
	direcao_patrulha = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	timer_patrulha = tempo_troca_patrulha

func _detectar_jogador():
	if jogador and jogador.is_inside_tree():
		var distancia = global_position.distance_to(jogador.global_position)
		if distancia <= raio_visao:
			estado_comportamento = EstadoComportamento.PERSEGUIR

func _processar_perseguicao(delta: float):
	var direcao = jogador.global_position - global_position
	var distancia = direcao.length()

	if distancia > distancia_ataque:
		velocity = direcao.normalized() * calcular_velocidade()
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

func atualizar_estado_vulnerabilidade(delta: float):
	timer_mudanca_estado -= delta
	if timer_mudanca_estado <= 0:
		if estado_vulnerabilidade == EstadoVulnerabilidade.VULNERAVEL:
			mudar_para_invulneravel()
		else:
			mudar_para_vulneravel()
		timer_mudanca_estado = intervalo_mudanca_estado

func mudar_para_invulneravel():
	estado_vulnerabilidade = EstadoVulnerabilidade.INVULNERAVEL
	indicador_invulnerabilidade.visible = true
	corpo_visual.color = Color(0.6, 0.2, 0.8, 0.5)

func mudar_para_vulneravel():
	estado_vulnerabilidade = EstadoVulnerabilidade.VULNERAVEL
	indicador_invulnerabilidade.visible = false
	corpo_visual.color = Color(0.6, 0.2, 0.8, 1.0)

func calcular_velocidade() -> float:
	if estado_vulnerabilidade == EstadoVulnerabilidade.INVULNERAVEL:
		return velocidade_base * 0.5
	else:
		return velocidade_base

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
	if estado_vulnerabilidade == EstadoVulnerabilidade.VULNERAVEL:
		vida -= dano
		criar_efeito_dano()
		if vida <= 0:
			criar_efeito_morte()
			var sala = get_parent()
			if sala and sala.has_method("inimigo_morreu_com_powerup"):
				sala.inimigo_morreu_com_powerup(global_position)
			queue_free()
	else:
		criar_efeito_bloqueio()

func criar_efeito_dano():
	var cor_original = corpo_visual.color
	corpo_visual.color = Color(1, 1, 1)
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func():
		if is_instance_valid(corpo_visual):
			corpo_visual.color = cor_original
	)

func criar_efeito_morte():
	var efeito = ColorRect.new()
	efeito.color = Color(0.6, 0.2, 0.8, 0.5)
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

func criar_efeito_bloqueio():
	var efeito = ColorRect.new()
	efeito.color = Color(1, 1, 1, 0.8)
	efeito.size = tamanho * 1.2
	efeito.position = global_position - efeito.size / 2

	var cena = get_tree().current_scene
	if not cena: cena = get_tree().get_root()
	cena.add_child(efeito)

	var timer = get_tree().create_timer(0.2)
	timer.timeout.connect(func():
		if is_instance_valid(efeito):
			efeito.queue_free()
	)
