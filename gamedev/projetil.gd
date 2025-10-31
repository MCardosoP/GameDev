extends CharacterBody2D

@export var velocidade: float = 800.0 # Velocidade do projétil
var direcao: Vector2 = Vector2.ZERO # Direção do projétil

func _physics_process(delta: float):
	var deslocamento = direcao * velocidade * delta # Calcula deslocamento do projétil a cada frame
	var colisao = move_and_collide(deslocamento) # Move o projétil e trata as colisões

	if colisao: # Se acontecer uma colisão
		var corpo = colisao.get_collider() # Recupera qual foi o objeto colidido
		
		if corpo and corpo.is_in_group("parede"): # Se colidiu com uma parede
			criar_efeito_impacto(colisao.get_position()) # Cria o efeito visual de impacto
			queue_free() # E depois remove o projétil da cena

func criar_efeito_impacto(ponto: Vector2):
	var efeito = ColorRect.new() # Criando o efeito visual do ataque à distância
	efeito.color = Color(1, 0, 0, 0.3)
	efeito.size = Vector2(32, 32)
	efeito.position = ponto - efeito.size / 2
	var cena = get_tree().current_scene 
	
	if not cena:
		cena = get_tree().get_root()
		
	cena.add_child(efeito) # Adiciona o efeito à cena atual
	var timer = get_tree().create_timer(0.5) # Criando um timer para remover o efeito
	
	timer.timeout.connect(func(): # Removendo o efeito da cena
		if is_instance_valid(efeito):
			efeito.queue_free()
	)
