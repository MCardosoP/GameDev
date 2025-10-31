extends CharacterBody2D

@export var velocidade: float = 500.0 # Velocidade do jogador
@export var espera_ataque: float = 0.5 # Tempo de espera entre ataques
@onready var area_ataque = $AreaAtaque # Referência ao nó usado para detecção de colisões corpo a corpo
@export var cena_projetil: PackedScene # Cena do projétil para ataques à distância

var pode_atacar: bool = true # Controle para saber se o jogador pode atacar

func _physics_process(delta: float):
	mover_jogador() # Sistema de movimentação do jogador
	atacar_distancia() # Sistema de ataque à distância
	atacar_corpo() # Sistema de ataque corpo a corpo

func mover_jogador():
	var direcao = Vector2.ZERO # Vetor para indicar a direção do movimento
	
	# Verificação de quais teclas estão sendo pressionadas
	if Input.is_action_pressed("mov_direita"):
		direcao.x += 1
	if Input.is_action_pressed("mov_esquerda"):
		direcao.x -= 1
	if Input.is_action_pressed("mov_baixo"):
		direcao.y += 1
	if Input.is_action_pressed("mov_cima"):
		direcao.y -= 1
		
	direcao = direcao.normalized() # Normalizando para evitar que o movimento diagonal seja mais rápido
	velocity = direcao * velocidade # Definindo a velocidade do CharacterBody2D
	move_and_slide() # Move o jogador e trata as colisões

func atacar_distancia():
	var direcao_tiro = Vector2.ZERO # Vetor para indicar a direção do projétil
	
	# Detectando a tecla pressionada para determinar a direção do tiro
	if Input.is_action_just_pressed("proj_direita"):
		direcao_tiro.x += 1
	elif Input.is_action_just_pressed("proj_esquerda"):
		direcao_tiro.x -= 1
	elif Input.is_action_just_pressed("proj_baixo"):
		direcao_tiro.y += 1
	elif Input.is_action_just_pressed("proj_cima"):
		direcao_tiro.y -= 1

	if direcao_tiro != Vector2.ZERO: # Se alguma direção foi pressionada, o projétil é criado
		if not cena_projetil:
			return

		var projetil = cena_projetil.instantiate() # Instanciando o projétil
		
		if not projetil:
			return

		var cena = get_tree().current_scene # Adiciona o projétil à cena principal
		
		if not cena:
			cena = get_tree().get_root()
		
		cena.add_child(projetil)
		projetil.global_position = global_position # Posicionando o projétil no centro do jogador
		projetil.direcao = direcao_tiro.normalized()

func atacar_corpo():
	if Input.is_action_just_pressed("ataque_corpo"): # Detecta se a tecla 'Q' foi pressionada
		if not pode_atacar: # Verifica se o cooldown ainda está ativo
			return
		
		pode_atacar = false # Iniciando o cooldown do ataque
		
		# Criando efeito visual para indicar que o ataque foi realizado
		var efeito = ColorRect.new()
		efeito.color = Color(1, 0, 0, 0.3)
		efeito.size = Vector2(128, 128)
		efeito.position = -efeito.size / 2
		add_child(efeito)
		await get_tree().create_timer(0.5).timeout # Mantém o efeito na tela por 0.5 segundos
		
		if is_instance_valid(efeito): # Remove o efeito se ele ainda existir
			efeito.queue_free()
			
		await get_tree().create_timer(espera_ataque).timeout # Espera o cooldown terminar
		pode_atacar = true # Permite que outro ataque seja executado
