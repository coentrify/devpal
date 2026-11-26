// The screen's passes. A background and a filter are layers of their own,
// each a Metal file that defines devpal_background or devpal_filter, and
// they are compiled together with this file when the screen starts.

struct Frame {
    float2 size;
    float time;
    float padding;
    float4 personaRect;
};

struct Varyings {
    float4 position [[position]];
    float2 uv;
};

vertex Varyings fullscreen_vertex(uint id [[vertex_id]]) {
    float2 corner = float2((id << 1) & 2, id & 2);
    Varyings out;
    out.position = float4(corner * 2.0 - 1.0, 0.0, 1.0);
    out.uv = float2(corner.x, 1.0 - corner.y);
    return out;
}

fragment float4 background_fragment(Varyings in [[stage_in]], constant Frame &frame [[buffer(0)]]) {
    return devpal_background(in.uv, frame.size, frame.time);
}

vertex Varyings persona_vertex(uint id [[vertex_id]], constant Frame &frame [[buffer(0)]]) {
    float2 corner = float2(id & 1, (id >> 1) & 1);
    float2 uv = frame.personaRect.xy + corner * frame.personaRect.zw;
    Varyings out;
    out.position = float4(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0, 0.0, 1.0);
    out.uv = corner;
    return out;
}

fragment float4 persona_fragment(Varyings in [[stage_in]], texture2d<float> still [[texture(0)]]) {
    constexpr sampler linear(filter::linear, address::clamp_to_edge);
    return still.sample(linear, in.uv);
}

fragment float4 filter_fragment(Varyings in [[stage_in]], constant Frame &frame [[buffer(0)]], texture2d<float> scene [[texture(0)]]) {
    constexpr sampler linear(filter::linear, address::clamp_to_edge);
    return devpal_filter(scene, linear, in.uv, frame.size, frame.time);
}
