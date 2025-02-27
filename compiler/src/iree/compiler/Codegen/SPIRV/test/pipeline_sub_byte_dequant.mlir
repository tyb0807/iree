// RUN: iree-opt --split-input-file --pass-pipeline='builtin.module(hal.executable(hal.executable.variant(iree-codegen-linalg-to-spirv-pipeline)))' %s | FileCheck %s

#pipeline_layout = #hal.pipeline.layout<push_constants = 0, sets = [
  #hal.descriptor_set.layout<0, bindings = [
    #hal.descriptor_set.binding<0, storage_buffer>,
    #hal.descriptor_set.binding<1, storage_buffer>,
    #hal.descriptor_set.binding<2, storage_buffer>,
    #hal.descriptor_set.binding<3, storage_buffer>
  ]>
]>
hal.executable @i4_dequant {
  hal.executable.variant @vulkan_spirv_fb, target = <"vulkan-spirv", "vulkan-spirv-fb", {
      spirv.target_env = #spirv.target_env<#spirv.vce<v1.4, [Shader], []>, Unknown:IntegratedGPU, #spirv.resource_limits<
        max_compute_shared_memory_size = 32768,
        max_compute_workgroup_invocations = 512,
        max_compute_workgroup_size = [512, 512, 512],
        subgroup_size = 64>>
    }> {
    hal.executable.export @i4_dequant layout(#pipeline_layout) {
    ^bb0(%arg0: !hal.device):
      %x, %y, %z = flow.dispatch.workgroup_count_from_slice
      hal.return %x, %y, %z : index, index, index
    }
    builtin.module {
      func.func @i4_dequant() {
        %c0 = arith.constant 0 : index
        %0 = hal.interface.binding.subspan set(0) binding(0) type(storage_buffer) alignment(64) offset(%c0) flags(ReadOnly) : !flow.dispatch.tensor<readonly:tensor<131072x128xi4>>
        %1 = hal.interface.binding.subspan set(0) binding(1) type(storage_buffer) alignment(64) offset(%c0) flags(ReadOnly) : !flow.dispatch.tensor<readonly:tensor<131072xf32>>
        %2 = hal.interface.binding.subspan set(0) binding(2) type(storage_buffer) alignment(64) offset(%c0) flags(ReadOnly) : !flow.dispatch.tensor<readonly:tensor<131072xf32>>
        %3 = hal.interface.binding.subspan set(0) binding(3) type(storage_buffer) alignment(64) offset(%c0) : !flow.dispatch.tensor<writeonly:tensor<131072x128xf32>>
        %4 = flow.dispatch.tensor.load %0, offsets = [0, 0], sizes = [131072, 128], strides = [1, 1] : !flow.dispatch.tensor<readonly:tensor<131072x128xi4>> -> tensor<131072x128xi4>
        %5 = flow.dispatch.tensor.load %1, offsets = [0], sizes = [131072], strides = [1] : !flow.dispatch.tensor<readonly:tensor<131072xf32>> -> tensor<131072xf32>
        %6 = flow.dispatch.tensor.load %2, offsets = [0], sizes = [131072], strides = [1] : !flow.dispatch.tensor<readonly:tensor<131072xf32>> -> tensor<131072xf32>
        %7 = tensor.empty() : tensor<131072x128xf32>
        %8 = linalg.generic {
               indexing_maps = [affine_map<(d0, d1) -> (d0, d1)>, affine_map<(d0, d1) -> (d0)>, affine_map<(d0, d1) -> (d0)>, affine_map<(d0, d1) -> (d0, d1)>],
               iterator_types = ["parallel", "parallel"]
             } ins(%4, %5, %6 : tensor<131072x128xi4>, tensor<131072xf32>, tensor<131072xf32>) outs(%7 : tensor<131072x128xf32>) {
        ^bb0(%in: i4, %in_0: f32, %in_1: f32, %out: f32):
          %9 = arith.extui %in : i4 to i32
          %10 = arith.uitofp %9 : i32 to f32
          %11 = arith.subf %10, %in_1 : f32
          %12 = arith.mulf %11, %in_0 : f32
          linalg.yield %12 : f32
        } -> tensor<131072x128xf32>
        flow.dispatch.tensor.store %8, %3, offsets = [0, 0], sizes = [131072, 128], strides = [1, 1] : tensor<131072x128xf32> -> !flow.dispatch.tensor<writeonly:tensor<131072x128xf32>>
        return
      }
    }
  }
}

//   CHECK-LABEL: spirv.func @i4_dequant()

//         CHECK: spirv.VectorShuffle [0 : i32, 1 : i32] {{.*}} : vector<4xi32> -> vector<2xi32>
//         CHECK: spirv.VectorShuffle [0 : i32, 0 : i32, 1 : i32, 1 : i32]
//         CHECK: spirv.BitwiseAnd
//         CHECK: spirv.ShiftRightLogical
//         CHECK: spirv.BitwiseAnd
//         CHECK: spirv.VectorShuffle [2 : i32, 3 : i32] {{.*}} : vector<4xi32> -> vector<2xi32>
// CHECK-COUNT-3: spirv.VectorShuffle [0 : i32, 0 : i32, 1 : i32, 1 : i32]

// CHECK-COUNT-4: spirv.ConvertUToF {{.+}} : vector<4xi32> to vector<4xf32>
// CHECK-COUNT-4: spirv.FSub
// CHECK-COUNT-4: spirv.FMul
