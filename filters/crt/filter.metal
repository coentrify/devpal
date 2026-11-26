// CRT: a curved old tube with rounded corners, deep horizontal scan lines,
// a phosphor mask, grain, a soft rolling bar, and now and then a glitch
// that tears a line and splits the colors.
// uv runs from the top left (0, 0) to the bottom right (1, 1), size is in pixels.

static float crt_hash(float n) {
    return fract(sin(n * 91.3458) * 47453.5453);
}

static float crt_noise(float2 p) {
    return fract(sin(dot(p, float2(12.9898, 78.233))) * 43758.5453);
}

float4 devpal_filter(texture2d<float> scene, sampler image, float2 uv, float2 size, float time) {
    float2 centered = uv * 2.0 - 1.0;
    centered *= 1.0 + 0.09 * dot(centered, centered);
    centered /= 1.18;
    float2 point = centered * 0.5 + 0.5;

    float2 corner = max(abs(point * 2.0 - 1.0) - float2(0.94, 0.92), 0.0);
    float border = 1.0 - smoothstep(0.0, 0.012, length(corner) - 0.02);
    if (any(point < 0.0) || any(point > 1.0) || border <= 0.0) {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    float slot = floor(time * 12.0);
    float glitch = step(0.94, crt_hash(slot));
    float band = floor(point.y * 36.0);
    float tear = step(0.75, crt_hash(band + slot * 13.0)) * glitch;
    point.x += (crt_hash(band * 3.7 + slot) - 0.5) * 0.08 * tear;
    point.y += glitch * (crt_hash(slot + 5.0) - 0.5) * 0.02;

    float split = 0.0026 + glitch * 0.007;
    float3 color = float3(
        scene.sample(image, point + float2(split, 0.0)).r,
        scene.sample(image, point).g,
        scene.sample(image, point - float2(split, 0.0)).b
    );
    float3 bloom = scene.sample(image, point, level(0)).rgb;
    color += 0.12 * bloom * bloom;

    float scan = 0.4 + 0.6 * pow(0.5 + 0.5 * sin(point.y * size.y * 3.14159 / 2.5), 1.6);
    int column = int(uv.x * size.x) % 3;
    float3 mask = float3(0.78);
    mask[column] = 1.15;
    float grain = (crt_noise(uv * size + fract(time) * 100.0) - 0.5) * 0.07;
    float roll = 0.08 * smoothstep(0.0, 0.1, 0.1 - abs(fract(point.y - time * 0.12) - 0.5));
    float flicker = 0.97 + 0.03 * sin(time * 53.0);
    float vignette = pow(16.0 * point.x * point.y * (1.0 - point.x) * (1.0 - point.y), 0.35);

    color = color * scan * mask * 1.55 * flicker * vignette + roll + grain;
    color *= border;
    return float4(color, 1.0);
}
