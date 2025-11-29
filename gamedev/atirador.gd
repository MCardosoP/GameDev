extends CharacterBody2D

@export var velocidade: float = 450.0  # 90% da velocidade do jogador (500 * 0.9)
@export var distancia_minima: float = 150.0  # Distância mínima para fugir
@export var distancia_ataque: float = 2000.0  # Alcance muito grande (cobre toda a sala)
@export var cooldown_tiro: float = 1.0  # Tempo entre tiros
@export var tamanho: Vector2 = Vector2(32, 32)
@export var cena_projetil_inimigo: PackedScene

var jogador: Node = null
var vida: int = 2  # Atirador tem mais vida
var pode_atirar: bool = true
var timer_tiro: float = 0.0

# Estados do atirador
enum Estado {
	ATIRANDO,  # Parado, atirando no jogador
	FUGINDO    # Se afastando do jogador
}

var estado_atual = Estado.ATIRANDO

# Componentes visuais
var corpo_visual: ColorRect

func _ready():
	collision_layer = 0b00000100 # layer 3 (inimigos)
	collision_mask = 0b00000011 # colide apenas com jogador (1) e paredes (2)
	add_to_group("inimigos")

	# ADICIONANDO COLLISION SHAPE
	var colisao = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = tamanho
	colisao.shape = forma
	add_child(colisao)

	# Visual do atirador (verde)
	corpo_visual = ColorRect.new()
	corpo_visual.color = Color(0.2, 0.8, 0.3)  # Verde
	corpo_visual.size = tamanho
	corpo_visual.position = -tamanho / 2
	add_child(corpo_visual)

func _physics_process(delta: float):
	if vida <= 0:
		return
	
	# Tenta encontrar o jogador se ainda não tiver referência
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

	# Atualiza timer de tiro
	if not pode_atirar:
		timer_tiro -= delta
		if timer_tiro <= 0:
			pode_atirar = true
	
	# Calcula distância até o jogador
	var direcao = jogador.global_position - global_position
	var distancia = direcao.length()
	
	# Sempre tenta atirar se estiver no alcance e puder
	if distancia <= distancia_ataque and pode_atirar:
		atirar(direcao.normalized())
		pode_atirar = false
		timer_tiro = cooldown_tiro
	
	# Decide o movimento baseado na distância
	if distancia < distancia_minima:
		# Muito perto! FUGIR
		comportamento_fugir(direcao)
	else:
		# Distância segura, fica parado atirando
		estado_atual = Estado.ATIRANDO
		velocity = Vector2.ZERO

func comportamento_fugir(direcao: Vector2):
	estado_atual = Estado.FUGINDO
	
	# Direção oposta ao jogador
	var direcao_fuga = -direcao.normalized()
	
	# Verifica se há parede próxima na direção de fuga
	var posicao_futura = global_position + direcao_fuga * velocidade * 0.1
	
	# Se detectar que vai colidir com parede, tenta direções alternativas
	var teste_movimento = PhysicsTestMotionParameters2D.new()
	teste_movimento.from = global_transform
	teste_movimento.motion = direcao_fuga * velocidade * 0.1
	
	var resultado = PhysicsTestMotionResult2D.new()
	if PhysicsServer2D.body_test_motion(get_rid(), teste_movimento, resultado):
		# Vai colidir! Tenta fugir lateralmente
		direcao_fuga = calcular_direcao_alternativa(direcao)
	
	velocity = direcao_fuga * velocidade
	move_and_slide()

func calcular_direcao_alternativa(direcao_jogador: Vector2) -> Vector2:
	# Tenta fugir para os lados ao invés de diretamente para trás
	var perpendicular1 = Vector2(-direcao_jogador.y, direcao_jogador.x).normalized()
	var perpendicular2 = Vector2(direcao_jogador.y, -direcao_jogador.x).normalized()
	
	# Testa qual direção lateral está mais livre
	var teste1 = testar_direcao(perpendicular1)
	var teste2 = testar_direcao(perpendicular2)
	
	if teste1 and not teste2:
		return perpendicular1
	elif teste2 and not teste1:
		return perpendicular2
	elif teste1 and teste2:
		# Ambas livres, escolhe aleatoriamente
		return perpendicular1 if randf() > 0.5 else perpendicular2
	else:
		# Ambas bloqueadas, tenta diagonal
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
	
	# Define a direção do projétil
	if projetil.has_method("set_direcao"):
		projetil.set_direcao(direcao)
	elif "direcao" in projetil:
		projetil.direcao = direcao

func receber_dano(dano: int):
	vida -= dano
	
	# Feedback visual de dano (pisca branco)
	criar_efeito_dano()
	
	if vida <= 0:
		criar_efeito_morte()
		queue_free()

func criar_efeito_dano():
	# Flash branco ao tomar dano
	var cor_original = corpo_visual.color
	corpo_visual.color = Color(1, 1, 1)  # Branco
	
	# Volta à cor original após 0.1 segundos
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func():
		if is_instance_valid(corpo_visual):
			corpo_visual.color = cor_original
	)

func criar_efeito_morte():
	var efeito = ColorRect.new()
	efeito.color = Color(0.2, 0.8, 0.3, 0.5)  # Verde semi-transparente
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
