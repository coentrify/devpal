// CRT: a curved old tube with horizontal scan lines, a soft rolling bar,
// and now and then a glitch that tears a line and splits the colors.
// uv runs from the top left (0, 0) to the bottom right (1, 1), size is in pixels.

static float crt_hash(float n) {
    return fract(sin(n * 91.3458) * 47453.5453);
}

float4 devpal_filter(texture2d<float> scene, sampler image, float2 uv, float2 size, float time) {
    float2 centered = uv * 2.0 - 1.0;
    centered *= 1.0 + 0.045 * dot(centered, centered);
    centered /= 1.09;
    float2 point = centered * 0.5 + 0.5;
    if (any(point < 0.0) || any(point > 1.0)) {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    float slot = floor(time * 12.0);
    float glitch = step(0.94, crt_hash(slot));
    float band = floor(point.y * 36.0);
    float tear = step(0.75, crt_hash(band + slot * 13.0)) * glitch;
    point.x += (crt_hash(band * 3.7 + slot) - 0.5) * 0.06 * tear;

    float split = 0.0012 + glitch * 0.004;
    float3 color = float3(
        scene.sample(image, point + float2(split, 0.0)).r,
        scene.sample(image, point).g,
        scene.sample(image, point - float2(split, 0.0)).b
    );

    float scan = 0.62 + 0.38 * (0.5 + 0.5 * sin(point.y * size.y * 3.14159 / 2.0));
    float roll = 0.06 * smoothstep(0.0, 0.08, 0.08 - abs(fract(point.y - time * 0.12) - 0.5));
    float flicker = 0.985 + 0.015 * sin(time * 53.0);
    float vignette = pow(16.0 * point.x * point.y * (1.0 - point.x) * (1.0 - point.y), 0.22);

    color = color * scan * 1.25 * flicker * vignette + roll;
    return float4(color, 1.0);
}
