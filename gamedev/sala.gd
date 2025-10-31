extends Node2D

# Definindo variáveis como tamanho da tela, grossura da parede e cores das paredes e do chão
@export var tamanho_tela: Vector2 = Vector2(1920, 1080)
@export var grossura_parede: float = 32.0
@export var cor_parede: Color = Color("#8B4513")
@export var cor_chao: Color = Color("#2F4F4F")

func _ready() -> void:
	# Criando o chão e as paredes (o chão vem primeiro para não ficar acima das paredes durante a exibição)
	criar_chao()
	criar_parede("ParedeSuperior", Vector2(0, -tamanho_tela.y / 2)) 
	criar_parede("ParedeInferior", Vector2(0, tamanho_tela.y / 2))
	criar_parede("ParedeEsquerda", Vector2(-tamanho_tela.x / 2, 0), true)
	criar_parede("ParedeDireita", Vector2(tamanho_tela.x / 2, 0), true) 

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
	parede.collision_layer = 2
	parede.collision_mask = 1

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
