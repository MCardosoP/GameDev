extends Area2D

@export var quantidade_vida: int = 2  # Quanto de vida recupera
@export var raio: float = 16.0

var corpo_visual: ColorRect
var borda_visual: ColorRect

func _ready():
	collision_layer = 0b10000000  # layer 8 (power-ups)
	collision_mask = 0b00000001   # detecta apenas jogador (layer 1)
	monitoring = true
	add_to_group("powerups")
	
	# Collision shape circular
	var colisao = CollisionShape2D.new()
	var forma = CircleShape2D.new()
	forma.radius = raio
	colisao.shape = forma
	add_child(colisao)
	
	# Borda externa (círculo maior)
	borda_visual = ColorRect.new()
	borda_visual.color = Color(0.8, 0.1, 0.1)  # Vermelho escuro
	borda_visual.size = Vector2(raio * 2 + 6, raio * 2 + 6)
	borda_visual.position = -(borda_visual.size / 2)
	add_child(borda_visual)
	
	# Aplica shader para fazer círculo (borda)
	criar_shader_circular(borda_visual)
	
	# Corpo principal (círculo)
	corpo_visual = ColorRect.new()
	corpo_visual.color = Color(1, 0.3, 0.3)  # Vermelho/Rosa
	corpo_visual.size = Vector2(raio * 2, raio * 2)
	corpo_visual.position = -(corpo_visual.size / 2)
	add_child(corpo_visual)
	
	# Aplica shader para fazer círculo
	criar_shader_circular(corpo_visual)
	
	# Ícone de cruz (símbolo médico)
	criar_icone_cruz()
	
	# Conecta sinal
	body_entered.connect(_on_body_entered)
	
	# Efeito de pulsar
	criar_animacao_pulsar()

func criar_shader_circular(node: ColorRect):
	# Cria shader simples para transformar quadrado em círculo
	var shader_code = """
shader_type canvas_item;

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	if (dist > 0.5) {
		COLOR.a = 0.0;
	}
}
"""
	var shader = Shader.new()
	shader.code = shader_code
	var material = ShaderMaterial.new()
	material.shader = shader
	node.material = material

func criar_icone_cruz():
	# Barra vertical da cruz
	var vertical = ColorRect.new()
	vertical.color = Color(1, 1, 1)
	vertical.size = Vector2(4, 16)
	vertical.position = Vector2(-2, -8)
	corpo_visual.add_child(vertical)
	
	# Barra horizontal da cruz
	var horizontal = ColorRect.new()
	horizontal.color = Color(1, 1, 1)
	horizontal.size = Vector2(16, 4)
	horizontal.position = Vector2(-8, -2)
	corpo_visual.add_child(horizontal)

func criar_animacao_pulsar():
	# Animação de pulsação suave
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.6)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.6)

func _on_body_entered(body):
	if body.is_in_group("jogador"):
		coletar(body)

func coletar(jogador):
	if jogador.has_method("adicionar_vida"):
		jogador.adicionar_vida(quantidade_vida)
		
		# Efeito visual de coleta
		criar_efeito_coleta()
		
		# Remove o power-up
		queue_free()

func criar_efeito_coleta():
	# Partículas ao coletar
	for i in range(8):
		var particula = ColorRect.new()
		particula.color = Color(1, 0.3, 0.3, 0.8)
		particula.size = Vector2(6, 6)
		particula.position = global_position
		
		var cena = get_tree().current_scene
		if not cena: cena = get_tree().get_root()
		cena.add_child(particula)
		
		# Animação de dispersão
		var angulo = (PI * 2 / 8) * i
		var direcao = Vector2(cos(angulo), sin(angulo)) * 50
		
		var tween = create_tween()
		tween.tween_property(particula, "position", particula.position + direcao, 0.5)
		tween.parallel().tween_property(particula, "modulate:a", 0.0, 0.5)
		
		await get_tree().create_timer(0.5).timeout
		if is_instance_valid(particula):
			particula.queue_free()
