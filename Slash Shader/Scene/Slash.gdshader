shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_schlick_ggx, unshaded;

// --- Main parameters ---
uniform vec2 offset;
uniform float speed;
uniform float duration;
uniform sampler2D Slash_Texture : repeat_disable;
uniform float intensity;
uniform float flicker_speed;
uniform float flicker_strength;
uniform float fade_start;
uniform float fade_end;

// --- Noise control ---
uniform sampler2D noise : repeat_enable;
uniform float noise_flow = 1.0;
uniform float noise_strength = 0.1;
uniform float Dissovle; // keeping same spelling as original for compatibility

// --- Gradient colors ---
uniform vec3 Bright_Color : source_color = vec3(1.0, 0.8, 0.3); // bright start (yellow)
uniform vec3 Mid_Color    : source_color = vec3(1.0, 0.3, 0.0); // mid (orange/red)
uniform vec3 Dark_Color   : source_color = vec3(0.0, 0.0, 0.0); // end (black)
uniform float Gradient_Sharpness = 1.0; // 0.5=soft, 2.0=sharp

void fragment() {
// --- Base setup ---
float progress = clamp(speed / duration, 0.0, 1.0);

// --- Flicker intensity ---  
float flicker = sin(TIME * flicker_speed) * flicker_strength + 1.0;  
float combined_intensity = intensity * flicker;  

// --- Fade control ---  
float fade = 1.0 - smoothstep(fade_start, fade_end, progress);  

// --- Seamless noise UV (prevents line artifacts) ---  
vec2 noise_uv = fract(UV + vec2(TIME * noise_flow * 0.1, TIME * noise_flow * 0.07));  
vec2 noise_val = texture(noise, noise_uv).rg * 2.0 - 1.0; // range [-1, 1]  

// --- Distorted UV using noise ---  
vec2 distorted_uv = UV + offset * progress + noise_val * noise_strength * 0.5;  

// --- Sample slash texture using distorted UV ---  
vec4 slash_tex = texture(Slash_Texture, distorted_uv);  
float slash_alpha = slash_tex.a;  

// --- Gradient color across UV.x (can change to UV.y for vertical fade) ---  
float gradient_t = pow(UV.x, Gradient_Sharpness);  
vec3 gradient_color = mix(  
    mix(Bright_Color, Mid_Color, gradient_t * 1.5),  
    Dark_Color,  
    smoothstep(0.5, 1.0, gradient_t)  
);  

// --- Noise dissolve ---  
float dissolve_val = texture(noise, noise_uv).r * Dissovle;  
float dissolve_mask = smoothstep(0.2, 0.8, dissolve_val);  

// --- Final outputs ---  
vec3 final_color = gradient_color * slash_tex.rgb * combined_intensity;  
float final_alpha = slash_alpha * fade * dissolve_mask;  

ALBEDO = final_color;  
ALPHA = final_alpha;

}