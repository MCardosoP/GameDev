extends Node2D

@export var tamanho_tela: Vector2 = Vector2(1920, 1080)
@export var grossura_parede: float = 32.0
@export var cor_parede: Color = Color("#8B4513")
@export var cor_chao: Color = Color("#D2B48C")
@export var cena_inimigo: PackedScene
@export var cena_jogador: PackedScene
@export var quantidade_inimigos: int = 3
@export var distancia_minima_jogador: float = 100.0

var jogador: Node = null

func _ready() -> void:
	criar_chao()
	criar_parede("ParedeSuperior", Vector2(0, -tamanho_tela.y / 2)) 
	criar_parede("ParedeInferior", Vector2(0, tamanho_tela.y / 2))
	criar_parede("ParedeEsquerda", Vector2(-tamanho_tela.x / 2, 0), true)
	criar_parede("ParedeDireita", Vector2(tamanho_tela.x / 2, 0), true)
	
	instanciar_jogador()
	instanciar_inimigos()

func criar_chao():
	var chao = ColorRect.new()
	chao.name = "Chao"
	chao.color = cor_chao
	chao.size = tamanho_tela
	chao.position = -chao.size / 2
	add_child(chao)

func criar_parede(nome: String, posicao: Vector2, vertical: bool = false):
	var parede = StaticBody2D.new()
	parede.name = nome
	parede.position = posicao
	parede.add_to_group("parede")
	parede.collision_layer = 0b00000010
	parede.collision_mask = 0b00000101

	var formato = RectangleShape2D.new() 

	var tamanho_formato: Vector2
	if vertical:
		tamanho_formato = Vector2(grossura_parede, tamanho_tela.y + grossura_parede)
	else:
		tamanho_formato = Vector2(tamanho_tela.x + grossura_parede, grossura_parede)

	formato.size = tamanho_formato
	var colisao = CollisionShape2D.new() 
	colisao.shape = formato 
	parede.add_child(colisao) 

	var retangulo = ColorRect.new()
	retangulo.color = cor_parede
	retangulo.size = tamanho_formato
	retangulo.position = -retangulo.size / 2
	parede.add_child(retangulo) 
	add_child(parede) 

func instanciar_jogador():
	if not cena_jogador:
		print("ERRO: Cena do jogador não foi definida!")
		return
	
	jogador = cena_jogador.instantiate()
	jogador.name = "Jogador"
	add_child(jogador)
	
	var centro_x = 0.0
	var centro_y = 0.0
	
	jogador.global_position = global_position + Vector2(centro_x, centro_y)

func instanciar_inimigos():
	if not cena_inimigo:
		print("ERRO: Cena do inimigo não foi definida!")
		return
	
	if not jogador:
		print("ERRO: Jogador não foi instanciado!")
		return
		
	var margem = grossura_parede + 50
	var limite_x_min = -tamanho_tela.x / 2 + margem
	var limite_x_max = tamanho_tela.x / 2 - margem
	var limite_y_min = -tamanho_tela.y / 2 + margem
	var limite_y_max = tamanho_tela.y / 2 - margem
	
	for i in range(quantidade_inimigos):
		var inimigo = cena_inimigo.instantiate()
		var posicao_valida = false
		var tentativas = 0
		var posicao_inimigo = Vector2.ZERO
		
		while not posicao_valida and tentativas < 100:
			posicao_inimigo = Vector2(
				randf_range(limite_x_min, limite_x_max),
				randf_range(limite_y_min, limite_y_max)
			)
			
			var posicao_global = global_position + posicao_inimigo
			
			var distancia = posicao_global.distance_to(jogador.global_position)
			if distancia >= distancia_minima_jogador:
				posicao_valida = true
			
			tentativas += 1
		
		add_child(inimigo)
		inimigo.global_position = global_position + posicao_inimigo
