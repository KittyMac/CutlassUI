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
    packed_float4 color;
};

struct VertexOut {
    float4 computedPosition [[position]];
    float4 color;
};

vertex VertexOut flat_vertex(
  const device VertexIn* vertex_array [[ buffer(0) ]],
  const device SceneMatrices& scene_matrices [[ buffer(1) ]],
  const device GlobalUniforms& global_uniforms [[ buffer(2) ]],

  unsigned int vid [[ vertex_id ]]) {
    float4x4 viewModelMatrix = scene_matrices.viewModelMatrix;
    float4x4 projectionMatrix = scene_matrices.projectionMatrix;
    
    VertexIn v = vertex_array[vid];

    VertexOut outVertex = VertexOut();
    outVertex.computedPosition = projectionMatrix * viewModelMatrix * float4(v.position, 1.0);
    outVertex.color = v.color * global_uniforms.globalColor;
    return outVertex;
}

fragment float4 flat_fragment(VertexOut interpolated [[stage_in]]) {
  return float4(interpolated.color);
}
