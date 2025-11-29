extends CharacterBody2D

@export var velocidade: float = 450.0
@export var distancia_minima: float = 150.0
@export var distancia_ataque: float = 2000.0
@export var cooldown_tiro: float = 1.0
@export var tamanho: Vector2 = Vector2(32, 32)
@export var cena_projetil_inimigo: PackedScene
@export var raio_visao: float = 500.0          # alcance da visão
@export var tempo_troca_patrulha: float = 2.0  # tempo para mudar direção na patrulha

var jogador: Node = null
var vida: int = 2
var pode_atirar: bool = true
var timer_tiro: float = 0.0

# Estados de comportamento
enum EstadoComportamento {
	PATRULHA,
	COMBATE
}
var estado_comportamento = EstadoComportamento.PATRULHA

# Estados internos de combate
enum EstadoCombate {
	ATIRANDO,
	FUGINDO
}
var estado_atual = EstadoCombate.ATIRANDO

# Controle da patrulha
var direcao_patrulha: Vector2 = Vector2.ZERO
var timer_patrulha: float = 0.0

# Componentes visuais
var corpo_visual: ColorRect

func _ready():
	collision_layer = 0b00000100
	collision_mask = 0b00000011
	add_to_group("inimigos")

	var colisao = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = tamanho
	colisao.shape = forma
	add_child(colisao)

	corpo_visual = ColorRect.new()
	corpo_visual.color = Color(0.2, 0.8, 0.3)
	corpo_visual.size = tamanho
	corpo_visual.position = -tamanho / 2
	add_child(corpo_visual)

	_nova_direcao_patrulha()

func _physics_process(delta: float):
	if vida <= 0:
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

	if estado_comportamento == EstadoComportamento.PATRULHA:
		_processar_patrulha(delta)
		_detectar_jogador()
	elif estado_comportamento == EstadoComportamento.COMBATE:
		_processar_combate(delta)

func _processar_patrulha(delta: float):
	timer_patrulha -= delta
	if timer_patrulha <= 0:
		_nova_direcao_patrulha()

	velocity = direcao_patrulha * velocidade * 0.5  # patrulha mais lenta
	move_and_slide()

func _nova_direcao_patrulha():
	direcao_patrulha = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	timer_patrulha = tempo_troca_patrulha

func _detectar_jogador():
	if jogador and jogador.is_inside_tree():
		var distancia = global_position.distance_to(jogador.global_position)
		if distancia <= raio_visao:
			estado_comportamento = EstadoComportamento.COMBATE

func _processar_combate(delta: float):
	# Atualiza cooldown de tiro
	if not pode_atirar:
		timer_tiro -= delta
		if timer_tiro <= 0:
			pode_atirar = true

	var direcao = jogador.global_position - global_position
	var distancia = direcao.length()

	# Atira se estiver no alcance
	if distancia <= distancia_ataque and pode_atirar:
		atirar(direcao.normalized())
		pode_atirar = false
		timer_tiro = cooldown_tiro

	# Decide movimento
	if distancia < distancia_minima:
		comportamento_fugir(direcao)
	else:
		estado_atual = EstadoCombate.ATIRANDO
		velocity = Vector2.ZERO

func comportamento_fugir(direcao: Vector2):
	estado_atual = EstadoCombate.FUGINDO
	var direcao_fuga = -direcao.normalized()

	var teste_movimento = PhysicsTestMotionParameters2D.new()
	teste_movimento.from = global_transform
	teste_movimento.motion = direcao_fuga * velocidade * 0.1

	var resultado = PhysicsTestMotionResult2D.new()
	if PhysicsServer2D.body_test_motion(get_rid(), teste_movimento, resultado):
		direcao_fuga = calcular_direcao_alternativa(direcao)

	velocity = direcao_fuga * velocidade
	move_and_slide()

func calcular_direcao_alternativa(direcao_jogador: Vector2) -> Vector2:
	var perpendicular1 = Vector2(-direcao_jogador.y, direcao_jogador.x).normalized()
	var perpendicular2 = Vector2(direcao_jogador.y, -direcao_jogador.x).normalized()

	var teste1 = testar_direcao(perpendicular1)
	var teste2 = testar_direcao(perpendicular2)

	if teste1 and not teste2:
		return perpendicular1
	elif teste2 and not teste1:
		return perpendicular2
	elif teste1 and teste2:
		return perpendicular1 if randf() > 0.5 else perpendicular2
	else:
		return (-direcao_jogador.normalized() + perpendicular1).normalized()

func testar_direcao(direcao: Vector2) -> bool:
	var teste_movimento = PhysicsTestMotionParameters2D.new()
	teste_movimento.from = global_transform
	teste_movimento.motion = direcao * velocidade * 0.1

	var resultado = PhysicsTestMotionResult2D.new()
	return not PhysicsServer2D.body_test_motion(get_rid(), teste_movimento, resultado)

func atirar(direcao: Vector2):
	if not cena_projetil_inimigo:
		print("AVISO: Cena de projétil do inimigo não definida!")
		return

	var projetil = cena_projetil_inimigo.instantiate()
	var cena = get_tree().current_scene
	if not cena: cena = get_tree().get_root()
	cena.add_child(projetil)
	projetil.global_position = global_position

	if projetil.has_method("set_direcao"):
		projetil.set_direcao(direcao)
	elif "direcao" in projetil:
		projetil.direcao = direcao

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
	var cor_original = corpo_visual.color
	corpo_visual.color = Color(1, 1, 1)
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func():
		if is_instance_valid(corpo_visual):
			corpo_visual.color = cor_original
	)

func criar_efeito_morte():
	var efeito = ColorRect.new()
	efeito.color = Color(0.2, 0.8, 0.3, 0.5)
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
