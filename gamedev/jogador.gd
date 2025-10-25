extends CharacterBody2D

const VELOCIDADE = 400.0 # Velocidade base = 1.0 (multiplicada para 200 pixels)

func _physics_process(delta):
	var direcao = Vector2.ZERO # Variável para armazenar o input do jogador
	
	# Verificando se o jogador apertou as teclas WASD
	if Input.is_action_pressed("cima"):
		direcao.y -= 1
	if Input.is_action_pressed("baixo"):
		direcao.y += 1
	if Input.is_action_pressed("esquerda"):
		direcao.x -= 1
	if Input.is_action_pressed("direita"):
		direcao.x += 1
	
	# Normalizando o vetor para que o movimento diagonal não seja mais rápido
	if direcao != Vector2.ZERO:
		direcao = direcao.normalized()
	
	# Calculando o movimento baseado na direção e na velocidade
	velocity = direcao * VELOCIDADE
	
	move_and_slide()
