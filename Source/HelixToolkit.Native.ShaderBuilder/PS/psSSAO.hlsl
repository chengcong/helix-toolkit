//Ref: https://learnopengl.com/Advanced-Lighting/SSAO
//Ref: https://mynameismjp.wordpress.com/2009/03/10/reconstructing-position-from-depth/
#ifndef SSAOEFFECTS
#define SSAOEFFECTS
#define SSAO
#include"..\Common\Common.hlsl"
#pragma pack_matrix( row_major )
struct SSAOPS_INPUT
{
    float4 Pos : SV_POSITION;
    noperspective
    float2 Tex : TEXCOORD0;
    float4 Corner : TEXCOORD1;
};

float4 main(SSAOPS_INPUT input) : SV_Target
{
    float4 value = texSSAOMap.Sample(samplerSurface, input.Tex);
    float3 normal = normalize(value.rgb);
    float depth = value.a;
    if (depth == 1)
    {
        return float4(1, 0, 0, 0);
    }
    float3 position = float3(input.Corner.xy, input.Corner.z * depth) * (1 - isPerspective) + input.Corner.xyz * depth * isPerspective;
    
    float3 randomVec = texSSAONoise.Sample(samplerNoise, input.Tex * noiseScale);

    float3 tangent = normalize(randomVec - normal * dot(randomVec, normal));
    float3 bitangent = cross(normal, tangent);
    float3x3 TBN = float3x3(tangent, bitangent, normal);
    float occlusion = 0;
    const float inv = 1.0 / SSAOKernalSize;

    //float3 sample = mul(float3(0, 0, 1), TBN);
    //sample = mad(sample, radius, position);
    //float4 offset = float4(sample, 1);
    //offset = mul(offset, mProjection); 
    //offset.xy /= offset.w;
    //offset.xy = mad(offset.xy, float2(0.5, -0.5), 0.5f);
    //return texSSAOMap.SampleLevel(samplerSurface, offset.xy, 0);
    [loop]
    for (uint i = 0; i < SSAOKernalSize; ++i)
    {
        float3 sample = mul(kernel[i].xyz, TBN);
        sample = mad(sample, radius, position);
        float4 offset = float4(sample, 1);
        offset = mul(offset, mProjection);
        offset.xy /= offset.w;
        offset.xy = mad(offset.xy, float2(0.5, -0.5), 0.5f);
        float sampleDepth = texSSAOMap.SampleLevel(samplerSurface, offset.xy, 0).a * input.Corner.z;
        float rangeCheck = whenlt(abs(position.z - sampleDepth), radius); //smoothstep(0.0, 1.0, radius / abs(position.z - sampleDepth));
        occlusion += whenle(abs(sampleDepth), abs(sample.z)) * rangeCheck;
    }
    occlusion = 1.0 - occlusion * inv;
    return float4(occlusion, 0, 0, 0);
}
#endif