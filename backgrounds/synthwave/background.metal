// Synthwave: a neon grid running to a striped setting sun under a starry sky.
// uv runs from the top left (0, 0) to the bottom right (1, 1), size is in pixels.

static float synthwave_hash(float2 p) {
    return fract(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

static float synthwave_line(float v) {
    float distance = abs(fract(v + 0.5) - 0.5);
    return 1.0 - smoothstep(0.0, fwidth(v) * 1.5, distance);
}

float4 devpal_background(float2 uv, float2 size, float time) {
    float aspect = size.x / size.y;
    float horizon = 0.62;
    float3 color;

    if (uv.y < horizon) {
        float height = uv.y / horizon;
        color = mix(float3(0.03, 0.0, 0.09), float3(0.32, 0.02, 0.36), pow(height, 2.2));

        float2 cell = floor(uv * size / 3.0);
        float star = step(0.9975, synthwave_hash(cell)) * (1.0 - height);
        color += star * (0.6 + 0.4 * sin(time * 2.0 + synthwave_hash(cell + 7.0) * 6.28));

        float radius = 0.24;
        float2 sun = float2(0.5, horizon - 0.12);
        float distance = length((uv - sun) * float2(aspect, 1.0));
        float along = saturate((uv.y - (sun.y - radius)) / (2.0 * radius));
        float3 sunColor = mix(float3(1.0, 0.86, 0.3), float3(1.0, 0.16, 0.55), along);
        float stripes = 1.0;
        if (along > 0.45) {
            float period = 0.032;
            float gap = period * (along - 0.45) * 1.4;
            stripes = step(gap, fmod(horizon - uv.y, period));
        }
        float inside = (1.0 - smoothstep(radius - 0.002, radius + 0.002, distance)) * stripes;
        color = mix(color, sunColor, inside);
        color += float3(1.0, 0.2, 0.6) * 0.35 * exp(-max(distance - radius, 0.0) * 9.0) * (1.0 - inside);
    } else {
        float depth = (uv.y - horizon) / (1.0 - horizon);
        float z = 1.0 / max(depth, 0.002);
        float x = (uv.x - 0.5) * aspect * z * 1.6;
        float lines = max(synthwave_line(x), synthwave_line(z * 0.5 + time * 0.35));
        float fade = smoothstep(0.0, 0.25, depth);
        color = mix(float3(0.05, 0.0, 0.1), float3(0.12, 0.0, 0.2), depth);
        color += float3(1.0, 0.18, 0.85) * lines * fade;
        color += float3(1.0, 0.3, 0.7) * 0.5 * exp(-depth * 18.0);
    }
    return float4(color, 1.0);
}
