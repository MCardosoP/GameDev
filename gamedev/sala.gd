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
@export var cena_porta: PackedScene
@export var distancia_minima_jogador: float = 100.0

var jogador: Node = null
var porta: Node = null
var inimigos_vivos: int = 0

func _ready() -> void:
	# Criando o chão e as paredes (o chão vem primeiro para não ficar acima das paredes durante a exibição)
	criar_chao()
	criar_parede("ParedeSuperior", Vector2(0, -tamanho_tela.y / 2)) 
	criar_parede("ParedeInferior", Vector2(0, tamanho_tela.y / 2))
	criar_parede("ParedeEsquerda", Vector2(-tamanho_tela.x / 2, 0), true)
	criar_parede("ParedeDireita", Vector2(tamanho_tela.x / 2, 0), true)
	
	# Instancia o jogador no centro da sala
	instanciar_jogador()
	
	# Instancia a porta (fechada inicialmente)
	instanciar_porta()
	
	# Instancia os inimigos baseado na onda atual
	var config = GerenciadorOndas.get_config_onda_atual()
	print("=== DEBUG SALA ===")
	print("Onda atual: ", GerenciadorOndas.onda_atual)
	print("Config: ", config)
	print("Inimigos a spawnar: ", config["inimigos"])
	print("Fantasmas a spawnar: ", config["fantasmas"])
	print("Atiradores a spawnar: ", config["atiradores"])
	
	instanciar_inimigos(config["inimigos"])
	instanciar_fantasmas(config["fantasmas"])
	instanciar_atiradores(config["atiradores"])
	
	print("Total de inimigos vivos: ", inimigos_vivos)
	print("==================")

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
	
	# Posiciona no centro visual da sala
	jogador.global_position = global_position + Vector2.ZERO

func instanciar_porta():
	if not cena_porta:
		print("ERRO: Cena da porta não foi definida!")
		return
	
	porta = cena_porta.instantiate()
	porta.name = "Porta"
	add_child(porta)
	
	# Posiciona a porta na parede direita
	var pos_x = (tamanho_tela.x / 2) - grossura_parede - 50
	porta.global_position = global_position + Vector2(pos_x, 0)
	
	# Conecta sinal da porta
	porta.jogador_entrou.connect(_on_porta_jogador_entrou)

func _on_porta_jogador_entrou():
	# Jogador passou pela porta, vai para próxima onda
	GerenciadorOndas.proxima_onda()
	get_tree().reload_current_scene()

func inimigo_morreu():
	# Verifica se a sala ainda existe (evita erro ao voltar ao menu)
	if not is_inside_tree():
		return
	
	inimigos_vivos -= 1
	GerenciadorOndas.inimigo_eliminado()
	GerenciadorOndas.adicionar_pontos(10)  # 10 pontos por inimigo
	
	if inimigos_vivos <= 0:
		# Todos os inimigos foram eliminados, abre a porta
		if porta and is_instance_valid(porta) and porta.has_method("abrir"):
			porta.abrir()

func instanciar_inimigos(quantidade: int):
	if not cena_inimigo:
		print("ERRO: Cena do inimigo não foi definida!")
		return
	
	if not jogador:
		print("ERRO: Jogador não foi instanciado!")
		return
	
	# Calcula os limites reais da área jogável (dentro das paredes)
	var margem = grossura_parede + 50
	var limite_x_min = -tamanho_tela.x / 2 + margem
	var limite_x_max = tamanho_tela.x / 2 - margem
	var limite_y_min = -tamanho_tela.y / 2 + margem
	var limite_y_max = tamanho_tela.y / 2 - margem
	
	for i in range(quantidade):
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
		inimigos_vivos += 1
		
		# Conecta sinal de morte
		inimigo.tree_exited.connect(inimigo_morreu)

func instanciar_fantasmas(quantidade: int):
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
	
	for i in range(quantidade):
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
		inimigos_vivos += 1
		
		# Conecta sinal de morte
		fantasma.tree_exited.connect(inimigo_morreu)

func instanciar_atiradores(quantidade: int):
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
	
	for i in range(quantidade):
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
		inimigos_vivos += 1
		
		# Conecta sinal de morte
		atirador.tree_exited.connect(inimigo_morreu)
