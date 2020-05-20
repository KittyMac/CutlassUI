//
//  Created by Rocco Bowling on 2/18/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct SceneMatrices {
    float4x4 projectionMatrix;
    float4x4 viewModelMatrix;
};

struct GlobalUniforms {
    float4 globalColor;
};

struct VertexIn {
    packed_float3 position;
    packed_float2 texCoords;
};

struct VertexOut {
    float4 computedPosition [[position]];
    float2 texCoords;
    float4 color;
};

struct SDFUniforms
{
    float edgeDistance;
    float edgeWidth;
};

vertex VertexOut sdf_vertex(
  const device VertexIn* vertex_array [[ buffer(0) ]],
  const device SceneMatrices& scene_matrices [[ buffer(1) ]],
  const device GlobalUniforms& global_uniforms [[ buffer(2) ]],

  unsigned int vid [[ vertex_id ]]) {
    float4x4 viewModelMatrix = scene_matrices.viewModelMatrix;
    float4x4 projectionMatrix = scene_matrices.projectionMatrix;
    
    VertexIn v = vertex_array[vid];

    VertexOut outVertex = VertexOut();
    outVertex.computedPosition = projectionMatrix * viewModelMatrix * float4(v.position, 1.0);
    outVertex.color = global_uniforms.globalColor;
    outVertex.texCoords = v.texCoords;
    return outVertex;
}

fragment float4 sdf_fragment(VertexOut vert [[stage_in]],
                             constant SDFUniforms &uniforms [[buffer(0)]],
                             texture2d<float> texture [[texture(0)]],
                             sampler samplr [[sampler(0)]]) {
  float mask = texture.sample(samplr, vert.texCoords).r;
    
  // Use local automatic gradients to find anti-aliased anisotropic edge width, cf. Gustavson 2012
  float edgeWidth = uniforms.edgeWidth * length(float2(dfdx(mask), dfdy(mask)));
  //float edgeWidth = uniforms.edgeWidth * fwidth(mask);

  float alpha = smoothstep(uniforms.edgeDistance - edgeWidth, uniforms.edgeDistance + edgeWidth, mask);
  return float4(vert.color.rgb, vert.color.a * alpha);
}
