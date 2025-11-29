extends Node

# Singleton para gerenciar ondas/salas entre cenas
var onda_atual: int = 1
var pontuacao: int = 0
var inimigos_eliminados_total: int = 0

# Persistência de dados do jogador entre salas
var vida_jogador: int = 5
var municao_jogador: int = 100

# Configuração de dificuldade por onda
var config_ondas = {
	1: {"inimigos": 3, "fantasmas": 0, "atiradores": 0},
	2: {"inimigos": 4, "fantasmas": 1, "atiradores": 0},
	3: {"inimigos": 3, "fantasmas": 1, "atiradores": 1},
	4: {"inimigos": 5, "fantasmas": 2, "atiradores": 1},
	5: {"inimigos": 4, "fantasmas": 2, "atiradores": 2},
	6: {"inimigos": 6, "fantasmas": 3, "atiradores": 2},
	7: {"inimigos": 5, "fantasmas": 3, "atiradores": 3},
	8: {"inimigos": 7, "fantasmas": 4, "atiradores": 3},
	9: {"inimigos": 6, "fantasmas": 4, "atiradores": 4},
	10: {"inimigos": 8, "fantasmas": 5, "atiradores": 4}
}

func get_config_onda_atual() -> Dictionary:
	if onda_atual in config_ondas:
		return config_ondas[onda_atual]
	else:
		# Ondas infinitas após a 10: progressão contínua
		var base = 10
		var extra = onda_atual - 10
		return {
			"inimigos": 8 + extra,
			"fantasmas": 5 + extra,
			"atiradores": 4 + (extra / 2)
		}

func proxima_onda():
	onda_atual += 1

func resetar_jogo():
	onda_atual = 1
	pontuacao = 0
	inimigos_eliminados_total = 0
	vida_jogador = 5
	municao_jogador = 100

func salvar_estado_jogador(vida: int, municao: int):
	vida_jogador = vida
	municao_jogador = municao

func obter_vida_jogador() -> int:
	return vida_jogador

func obter_municao_jogador() -> int:
	return municao_jogador

func adicionar_pontos(pontos: int):
	pontuacao += pontos

func inimigo_eliminado():
	inimigos_eliminados_total += 1
