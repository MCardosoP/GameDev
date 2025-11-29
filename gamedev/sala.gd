extends Node2D

# Definindo variáveis como tamanho da tela, grossura da parede e cores das paredes e do chão
@export var tamanho_tela: Vector2 = Vector2(1920, 1080)
@export var grossura_parede: float = 32.0
@export var cor_parede: Color = Color("#8B4513")
@export var cor_chao: Color = Color("#D2B48C")
@export var cena_inimigo: PackedScene
@export var cena_fantasma: PackedScene
@export var cena_atirador: PackedScene
@export var cena_jogador: PackedScene
@export var quantidade_inimigos: int = 3
@export var quantidade_fantasmas: int = 2
@export var quantidade_atiradores: int = 2
@export var distancia_minima_jogador: float = 100.0

var jogador: Node = null

func _ready() -> void:
	# Criando o chão e as paredes (o chão vem primeiro para não ficar acima das paredes durante a exibição)
	criar_chao()
	criar_parede("ParedeSuperior", Vector2(0, -tamanho_tela.y / 2)) 
	criar_parede("ParedeInferior", Vector2(0, tamanho_tela.y / 2))
	criar_parede("ParedeEsquerda", Vector2(-tamanho_tela.x / 2, 0), true)
	criar_parede("ParedeDireita", Vector2(tamanho_tela.x / 2, 0), true)
	
	# Instancia o jogador no centro da sala
	instanciar_jogador()
	
	# Instancia os inimigos em posições aleatórias
	instanciar_inimigos()
	
	# Instancia os fantasmas em posições aleatórias
	instanciar_fantasmas()
	
	# Instancia os atiradores em posições aleatórias
	instanciar_atiradores()

func criar_chao():
	# Criando o nó ColorRect, definindo suas características e adicionando como nó filho do nó sala
	var chao = ColorRect.new()
	chao.name = "Chao"
	chao.color = cor_chao
	chao.size = tamanho_tela
	chao.position = -chao.size / 2
	add_child(chao)

func criar_parede(nome: String, posicao: Vector2, vertical: bool = false):
	# Criando um nó estático que funcionará como as paredes da sala
	var parede = StaticBody2D.new()
	parede.name = nome
	parede.position = posicao
	parede.add_to_group("parede")
	parede.collision_layer = 0b00000010
	parede.collision_mask = 0b00000101

	var formato = RectangleShape2D.new() # Criando o nó que define o formato da colisão das paredes

	# Definindo qual será o tamanho do retângulo 'formato'
	var tamanho_formato: Vector2
	if vertical:
		tamanho_formato = Vector2(grossura_parede, tamanho_tela.y + grossura_parede)
	else:
		tamanho_formato = Vector2(tamanho_tela.x + grossura_parede, grossura_parede)

	formato.size = tamanho_formato
	var colisao = CollisionShape2D.new() # Criando o nó de colisão
	colisao.shape = formato # Atribuindo o nó retângulo ao nó de colisão
	parede.add_child(colisao) # Adicionando o nó de colisão como filho do nó parede

	# Criando um nó ColorRect para permitir a visualização das paredes no jogo
	var retangulo = ColorRect.new()
	retangulo.color = cor_parede
	retangulo.size = tamanho_formato
	retangulo.position = -retangulo.size / 2
	parede.add_child(retangulo) # Adicionando o nó ColorRect como filho do nó parede
	add_child(parede) # Adicionando o nó parede como filho do nó sala

func instanciar_jogador():
	if not cena_jogador:
		print("ERRO: Cena do jogador não foi definida!")
		return
	
	jogador = cena_jogador.instantiate()
	jogador.name = "Jogador"
	add_child(jogador)
	
	# Calcula o centro real da área jogável entre as paredes
	# Parede Superior está em y = -tamanho_tela.y / 2
	# Parede Inferior está em y = tamanho_tela.y / 2
	# Parede Esquerda está em x = -tamanho_tela.x / 2
	# Parede Direita está em x = tamanho_tela.x / 2
	
	# O centro entre as paredes, considerando a grossura
	var centro_x = 0.0  # Entre -tamanho_tela.x/2 e +tamanho_tela.x/2
	var centro_y = 0.0  # Entre -tamanho_tela.y/2 e +tamanho_tela.y/2
	
	# Como as paredes estão simétricas em relação a (0,0), o centro é (0,0)
	# Mas isso está em coordenadas locais da sala
	# Em coordenadas globais, precisamos somar a posição da sala
	jogador.global_position = global_position + Vector2(centro_x, centro_y)

func instanciar_inimigos():
	if not cena_inimigo:
		print("ERRO: Cena do inimigo não foi definida!")
		return
	
	if not jogador:
		print("ERRO: Jogador não foi instanciado!")
		return
	
	# Calcula os limites reais da área jogável (dentro das paredes)
	# Parede Superior: y = -tamanho_tela.y / 2
	# Parede Inferior: y = tamanho_tela.y / 2
	# Parede Esquerda: x = -tamanho_tela.x / 2
	# Parede Direita: x = tamanho_tela.x / 2
	
	# Adiciona margem para não spawnar colado nas paredes
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
		
		# Tenta encontrar uma posição válida (longe do jogador)
		while not posicao_valida and tentativas < 100:
			# Gera posição aleatória dentro dos limites
			posicao_inimigo = Vector2(
				randf_range(limite_x_min, limite_x_max),
				randf_range(limite_y_min, limite_y_max)
			)
			
			# Converte para posição global considerando a posição da sala
			var posicao_global = global_position + posicao_inimigo
			
			# Verifica se está longe o suficiente do jogador
			var distancia = posicao_global.distance_to(jogador.global_position)
			if distancia >= distancia_minima_jogador:
				posicao_valida = true
			
			tentativas += 1
		
		add_child(inimigo)
		inimigo.global_position = global_position + posicao_inimigo

func instanciar_fantasmas():
	if not cena_fantasma:
		print("AVISO: Cena do fantasma não foi definida!")
		return
	
	if not jogador:
		print("ERRO: Jogador não foi instanciado!")
		return
	
	# Calcula os limites da área jogável (dentro das paredes)
	var margem = grossura_parede + 50
	var limite_x_min = -tamanho_tela.x / 2 + margem
	var limite_x_max = tamanho_tela.x / 2 - margem
	var limite_y_min = -tamanho_tela.y / 2 + margem
	var limite_y_max = tamanho_tela.y / 2 - margem
	
	for i in range(quantidade_fantasmas):
		var fantasma = cena_fantasma.instantiate()
		var posicao_valida = false
		var tentativas = 0
		var posicao_fantasma = Vector2.ZERO
		
		# Tenta encontrar uma posição válida (longe do jogador)
		while not posicao_valida and tentativas < 100:
			# Gera posição aleatória dentro dos limites
			posicao_fantasma = Vector2(
				randf_range(limite_x_min, limite_x_max),
				randf_range(limite_y_min, limite_y_max)
			)
			
			# Converte para posição global considerando a posição da sala
			var posicao_global = global_position + posicao_fantasma
			
			# Verifica se está longe o suficiente do jogador
			var distancia = posicao_global.distance_to(jogador.global_position)
			if distancia >= distancia_minima_jogador:
				posicao_valida = true
			
			tentativas += 1
		
		add_child(fantasma)
		fantasma.global_position = global_position + posicao_fantasma

func instanciar_atiradores():
	if not cena_atirador:
		print("AVISO: Cena do atirador não foi definida!")
		return
	
	if not jogador:
		print("ERRO: Jogador não foi instanciado!")
		return
	
	# Calcula os limites da área jogável (dentro das paredes)
	var margem = grossura_parede + 50
	var limite_x_min = -tamanho_tela.x / 2 + margem
	var limite_x_max = tamanho_tela.x / 2 - margem
	var limite_y_min = -tamanho_tela.y / 2 + margem
	var limite_y_max = tamanho_tela.y / 2 - margem
	
	for i in range(quantidade_atiradores):
		var atirador = cena_atirador.instantiate()
		var posicao_valida = false
		var tentativas = 0
		var posicao_atirador = Vector2.ZERO
		
		# Tenta encontrar uma posição válida (longe do jogador)
		while not posicao_valida and tentativas < 100:
			# Gera posição aleatória dentro dos limites
			posicao_atirador = Vector2(
				randf_range(limite_x_min, limite_x_max),
				randf_range(limite_y_min, limite_y_max)
			)
			
			# Converte para posição global considerando a posição da sala
			var posicao_global = global_position + posicao_atirador
			
			# Verifica se está longe o suficiente do jogador
			var distancia = posicao_global.distance_to(jogador.global_position)
			if distancia >= distancia_minima_jogador:
				posicao_valida = true
			
			tentativas += 1
		
		add_child(atirador)
		atirador.global_position = global_position + posicao_atirador
