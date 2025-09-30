shader_type canvas_item;

uniform bool upper_half = true; // true = mostra sopra la diagonale, false = sotto
uniform float thickness = 0.02; // bordo sfumato

void fragment() {
    vec2 uv = UV;

    // linea diagonale y = x
    float line = uv.y - uv.x;

    // maschera per sopra/sotto la diagonale
    float mask = upper_half ? step(0.0, line) : step(line, 0.0);

    // bordo sfumato (facoltativo)
    mask = smoothstep(-thickness, thickness, mask);

    vec4 tex = texture(TEXTURE, uv);
    COLOR = tex * mask;
}
