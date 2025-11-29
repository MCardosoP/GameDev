extends Area2D

@export var tamanho: Vector2 = Vector2(80, 120)
@export var cor_fechada: Color = Color(0.5, 0.3, 0.2)  # Marrom escuro
@export var cor_aberta: Color = Color(0.2, 0.8, 0.2)  # Verde brilhante

var esta_aberta: bool = false
var corpo_visual: ColorRect
var label_texto: Label

signal jogador_entrou

func _ready():
	collision_layer = 0b01000000  # layer 7 (porta)
	collision_mask = 0b00000001   # detecta apenas jogador (layer 1)
	monitoring = true
	
	# Collision shape
	var colisao = CollisionShape2D.new()
	var forma = RectangleShape2D.new()
	forma.size = tamanho
	colisao.shape = forma
	add_child(colisao)
	
	# Visual da porta
	corpo_visual = ColorRect.new()
	corpo_visual.color = cor_fechada
	corpo_visual.size = tamanho
	corpo_visual.position = -tamanho / 2
	add_child(corpo_visual)
	
	# Borda da porta
	var borda = ColorRect.new()
	borda.color = Color(0.3, 0.2, 0.1)
	borda.size = tamanho + Vector2(8, 8)
	borda.position = -(tamanho + Vector2(8, 8)) / 2
	borda.z_index = -1
	add_child(borda)
	
	# Conecta sinal de entrada
	body_entered.connect(_on_body_entered)
	
	# Inicia fechada
	fechar()

func abrir():
	esta_aberta = true
	corpo_visual.color = cor_aberta
	
	criar_efeito_abertura()

func fechar():
	esta_aberta = false
	corpo_visual.color = cor_fechada

func _on_body_entered(body):
	if esta_aberta and body.is_in_group("jogador"):
		jogador_entrou.emit()

func criar_efeito_abertura():
	# Partículas/brilho ao abrir
	for i in range(10):
		var particula = ColorRect.new()
		particula.color = Color(1, 1, 0, 0.8)
		particula.size = Vector2(8, 8)
		particula.position = global_position + Vector2(
			randf_range(-tamanho.x/2, tamanho.x/2),
			randf_range(-tamanho.y/2, tamanho.y/2)
		)
		
		# Verifica se a árvore de cena ainda existe
		var cena = get_tree()
		if not cena:
			return
		
		cena = cena.current_scene
		if not cena:
			cena = get_tree().get_root()
		
		if not is_instance_valid(cena):
			return
			
		cena.add_child(particula)
		
		var timer = get_tree().create_timer(0.5)
		timer.timeout.connect(func():
			if is_instance_valid(particula):
				particula.queue_free()
		)
