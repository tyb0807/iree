// Copyright 2023 The IREE Authors
//
// Licensed under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

#ifndef IREE_COMPILER_CODEGEN_COMMON_PASS_DETAIL_H_
#define IREE_COMPILER_CODEGEN_COMMON_PASS_DETAIL_H_

#include "iree/compiler/Dialect/HAL/IR/HALOps.h"
#include "mlir/Dialect/Affine/IR/AffineOps.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Pass/Pass.h"

namespace mlir {
namespace iree_compiler {

#define GEN_PASS_CLASSES
#include "iree/compiler/Codegen/Common/Passes.h.inc"

} // namespace iree_compiler
} // namespace mlir

#endif // IREE_COMPILER_CODEGEN_COMMON_PASS_DETAIL_H_
