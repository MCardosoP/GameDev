extends CharacterBody2D

@export var velocidade: float = 800.0
@export var tamanho: Vector2 = Vector2(16, 16)
var direcao: Vector2 = Vector2.ZERO

func _ready():
	collision_layer = 0b00001000 
	collision_mask = 0b00000110 
	add_to_group("projeteis")
	
	var colisao = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = tamanho
	colisao.shape = forma
	add_child(colisao)
	
	var visual = ColorRect.new()
	visual.color = Color(1, 1, 0)
	visual.size = tamanho
	visual.position = -tamanho / 2
	add_child(visual)

func _physics_process(delta: float):
	var deslocamento = direcao * velocidade * delta
	var colisao = move_and_collide(deslocamento)

	if colisao:
		var corpo = colisao.get_collider()
		if corpo and corpo.is_in_group("parede"):
			criar_efeito_impacto(colisao.get_position())
			queue_free()
		elif corpo and corpo.is_in_group("inimigos"):
			corpo.receber_dano(1)
			queue_free()

func criar_efeito_impacto(ponto: Vector2):
	var efeito = ColorRect.new()
	efeito.color = Color(1, 0, 0, 0.3)
	efeito.size = Vector2(32, 32)
	efeito.position = ponto - efeito.size / 2
	var cena = get_tree().current_scene
	if not cena: cena = get_tree().get_root()
	cena.add_child(efeito)

	var timer = get_tree().create_timer(0.4)
	timer.timeout.connect(func():
		if is_instance_valid(efeito):
			efeito.queue_free()
	)
