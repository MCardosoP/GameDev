extends Node

# Singleton para gerenciar high scores
const CAMINHO_ARQUIVO = "user://highscores.save"
const MAX_HIGHSCORES = 5

var highscores: Array = []

func _ready():
	carregar_highscores()

func adicionar_score(pontos: int, sala: int):
	var novo_score = {
		"pontos": pontos,
		"sala": sala,
		"data": Time.get_datetime_string_from_system()
	}
	
	highscores.append(novo_score)
	
	# Ordena por pontos (maior para menor)
	highscores.sort_custom(func(a, b): return a["pontos"] > b["pontos"])
	
	# Mantém apenas os top 5
	if highscores.size() > MAX_HIGHSCORES:
		highscores.resize(MAX_HIGHSCORES)
	
	salvar_highscores()

func obter_highscores() -> Array:
	return highscores

func eh_novo_highscore(pontos: int) -> bool:
	if highscores.size() < MAX_HIGHSCORES:
		return true
	
	# Verifica se é maior que o menor score da lista
	return pontos > highscores[highscores.size() - 1]["pontos"]

func salvar_highscores():
	var arquivo = FileAccess.open(CAMINHO_ARQUIVO, FileAccess.WRITE)
	if arquivo:
		arquivo.store_var(highscores)
		arquivo.close()
		print("High scores salvos com sucesso!")
	else:
		print("ERRO: Não foi possível salvar high scores")

func carregar_highscores():
	if FileAccess.file_exists(CAMINHO_ARQUIVO):
		var arquivo = FileAccess.open(CAMINHO_ARQUIVO, FileAccess.READ)
		if arquivo:
			highscores = arquivo.get_var()
			arquivo.close()
			print("High scores carregados: ", highscores.size(), " entradas")
		else:
			print("ERRO: Não foi possível carregar high scores")
			highscores = []
	else:
		print("Arquivo de high scores não existe ainda")
		highscores = []

func limpar_highscores():
	highscores = []
	salvar_highscores()
