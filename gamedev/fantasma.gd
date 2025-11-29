extends CharacterBody2D

@export var velocidade_base: float = 300.0  # 20% mais rápido que o inimigo normal (250)
@export var cooldown_apos_ataque: float = 0.5
@export var distancia_ataque: float = 32.0
@export var tamanho: Vector2 = Vector2(32, 32)
@export var intervalo_mudanca_estado: float = 3.0

var jogador: Node = null
var vida: int = 1
var pode_mover_e_atacar: bool = true

# Estados do fantasma
enum Estado {
	VULNERAVEL,   # Velocidade normal, pode receber dano
	INVULNERAVEL  # Velocidade reduzida, não recebe dano
}

var estado_atual = Estado.VULNERAVEL
var timer_mudanca_estado: float = 0.0

# Componentes visuais
var corpo_visual: ColorRect
var indicador_invulnerabilidade: ColorRect

func _ready():
	collision_layer = 0b00000100 # layer 3 (inimigos)
	collision_mask = 0b00001011 # colide com jogador (1), paredes (2) e projéteis (4)
	add_to_group("inimigos")

	# ADICIONANDO COLLISION SHAPE
	var colisao = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = tamanho
	colisao.shape = forma
	add_child(colisao)

	# Visual do fantasma (roxo)
	corpo_visual = ColorRect.new()
	corpo_visual.color = Color(0.6, 0.2, 0.8)  # Roxo
	corpo_visual.size = tamanho
	corpo_visual.position = -tamanho / 2
	add_child(corpo_visual)
	
	# Indicador visual de invulnerabilidade (borda branca piscante)
	indicador_invulnerabilidade = ColorRect.new()
	indicador_invulnerabilidade.color = Color(1, 1, 1, 0.5)  # Branco semi-transparente
	indicador_invulnerabilidade.size = tamanho + Vector2(4, 4)
	indicador_invulnerabilidade.position = -(tamanho + Vector2(4, 4)) / 2
	indicador_invulnerabilidade.visible = false
	add_child(indicador_invulnerabilidade)
	
	# Inicia o timer
	timer_mudanca_estado = intervalo_mudanca_estado

func _physics_process(delta: float):
	if not pode_mover_e_atacar or vida <= 0:
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

	# Atualiza o timer de mudança de estado
	atualizar_estado(delta)
	
	# Comportamento de perseguição
	var direcao = jogador.global_position - global_position
	var distancia = direcao.length()

	if distancia > distancia_ataque:
		# Calcula velocidade baseada no estado
		var velocidade_atual = calcular_velocidade()
		velocity = direcao.normalized() * velocidade_atual
		move_and_slide()
		
		# Verifica colisão com o jogador
		for i in get_slide_collision_count():
			var colisao = get_slide_collision(i)
			var corpo = colisao.get_collider()
			if corpo == jogador:
				_atacar_jogador()
				break
	else:
		velocity = Vector2.ZERO
		_atacar_jogador()

func atualizar_estado(delta: float):
	timer_mudanca_estado -= delta
	
	if timer_mudanca_estado <= 0:
		# Alterna o estado
		if estado_atual == Estado.VULNERAVEL:
			mudar_para_invulneravel()
		else:
			mudar_para_vulneravel()
		
		# Reinicia o timer
		timer_mudanca_estado = intervalo_mudanca_estado

func mudar_para_invulneravel():
	estado_atual = Estado.INVULNERAVEL
	indicador_invulnerabilidade.visible = true
	# Torna o fantasma mais transparente quando invulnerável
	corpo_visual.color = Color(0.6, 0.2, 0.8, 0.5)

func mudar_para_vulneravel():
	estado_atual = Estado.VULNERAVEL
	indicador_invulnerabilidade.visible = false
	# Restaura opacidade normal
	corpo_visual.color = Color(0.6, 0.2, 0.8, 1.0)

func calcular_velocidade() -> float:
	if estado_atual == Estado.INVULNERAVEL:
		return velocidade_base * 0.5  # Metade da velocidade
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
	# Só recebe dano se estiver vulnerável
	if estado_atual == Estado.VULNERAVEL:
		vida -= dano
		
		# Feedback visual de dano
		criar_efeito_dano()
		
		if vida <= 0:
			criar_efeito_morte()
			queue_free()
	else:
		# Feedback visual de que está invulnerável
		criar_efeito_bloqueio()

func criar_efeito_dano():
	# Flash branco ao tomar dano
	var cor_original = corpo_visual.color
	corpo_visual.color = Color(1, 1, 1)  # Branco
	
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func():
		if is_instance_valid(corpo_visual):
			corpo_visual.color = cor_original
	)

func criar_efeito_morte():
	var efeito = ColorRect.new()
	efeito.color = Color(0.6, 0.2, 0.8, 0.5)  # Roxo semi-transparente
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
	# Efeito visual quando o ataque é bloqueado (invulnerável)
	var efeito = ColorRect.new()
	efeito.color = Color(1, 1, 1, 0.8)  # Branco brilhante
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
