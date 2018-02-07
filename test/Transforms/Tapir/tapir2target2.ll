; Test that tapir2target [cilk] properly compiles nested detaches [more complex]
; RUN: opt < %s -O3 -S -tapir2target -tapir-target=cilk | FileCheck %s

; ModuleID = 'c2islModule'
source_filename = "c2islModule"
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @kernel_anon([24 x [21 x [33 x float]]]* noalias nonnull readonly %A, [24 x float]* noalias nonnull readonly %B, [24 x float]* noalias nonnull readonly %C, [24 x float]* noalias nonnull readonly %D, [24 x float]* noalias nonnull %O1) {
entry:
; CHECK: %0 = call i32 @__cilkrts_get_nworkers()
  %syncreg = call token @llvm.syncregion.start()
  br label %loop_header

loop_header:                                      ; preds = %loop_latch, %entry
  %c0 = phi i64 [ 0, %entry ], [ %1, %loop_latch ]
  %0 = icmp slt i64 %c0, 40
  br i1 %0, label %loop_body, label %loop_exit

loop_body:                                        ; preds = %loop_header
  detach within %syncreg, label %det.achd, label %loop_latch

loop_latch:                                       ; preds = %synced21, %loop_body
  %1 = add i64 %c0, 1
  br label %loop_header

loop_exit:                                        ; preds = %loop_header
  sync within %syncreg, label %synced22

det.achd:                                         ; preds = %loop_body
  %syncreg5 = call token @llvm.syncregion.start()
  br label %loop_header1

loop_header1:                                     ; preds = %loop_latch3, %det.achd
  %c1 = phi i64 [ 0, %det.achd ], [ %3, %loop_latch3 ]
  %2 = icmp slt i64 %c1, 24
  br i1 %2, label %loop_body2, label %loop_exit4

loop_body2:                                       ; preds = %loop_header1
  detach within %syncreg5, label %det.achd6, label %loop_latch3

loop_latch3:                                      ; preds = %block_exit20, %loop_body2
  %3 = add i64 %c1, 1
  br label %loop_header1

loop_exit4:                                       ; preds = %loop_header1
  sync within %syncreg5, label %synced21

det.achd6:                                        ; preds = %loop_body2
  br label %block_exit

block_exit:                                       ; preds = %det.achd6
  %4 = getelementptr inbounds [24 x float], [24 x float]* %O1, i64 %c0, i64 %c1
  store float 0.000000e+00, float* %4
  %syncreg11 = call token @llvm.syncregion.start()
  br label %loop_header7

loop_header7:                                     ; preds = %loop_latch9, %block_exit
  %c2 = phi i64 [ 0, %block_exit ], [ %6, %loop_latch9 ]
  %5 = icmp slt i64 %c2, 21
  br i1 %5, label %loop_body8, label %loop_exit10

loop_body8:                                       ; preds = %loop_header7
  detach within %syncreg11, label %det.achd12, label %loop_latch9

loop_latch9:                                      ; preds = %synced, %loop_body8
  %6 = add i64 %c2, 1
  br label %loop_header7

loop_exit10:                                      ; preds = %loop_header7
  sync within %syncreg11, label %synced19

det.achd12:                                       ; preds = %loop_body8
  %syncreg17 = call token @llvm.syncregion.start()
  br label %loop_header13

loop_header13:                                    ; preds = %loop_latch15, %det.achd12
  %c3 = phi i64 [ 0, %det.achd12 ], [ %8, %loop_latch15 ]
  %7 = icmp slt i64 %c3, 33
  br i1 %7, label %loop_body14, label %loop_exit16

loop_body14:                                      ; preds = %loop_header13
  detach within %syncreg17, label %det.achd18, label %loop_latch15

loop_latch15:                                     ; preds = %det.achd18, %loop_body14
  %8 = add i64 %c3, 1
  br label %loop_header13

loop_exit16:                                      ; preds = %loop_header13
  sync within %syncreg17, label %synced

det.achd18:                                       ; preds = %loop_body14
  %9 = getelementptr inbounds [24 x float], [24 x float]* %O1, i64 %c0, i64 %c1
  %10 = getelementptr inbounds [24 x float], [24 x float]* %B, i64 %c0, i64 %c1
  %11 = load float, float* %10
  %12 = getelementptr inbounds [24 x [21 x [33 x float]]], [24 x [21 x [33 x float]]]* %A, i64 %c0, i64 %c1, i64 %c2, i64 %c3
  %13 = load float, float* %12
  %14 = fmul float %13, %11
  %15 = getelementptr inbounds [24 x float], [24 x float]* %O1, i64 %c0, i64 %c1
  %16 = load float, float* %15
  %17 = fadd float %16, %14
  store float %17, float* %9
  reattach within %syncreg17, label %loop_latch15

synced:                                           ; preds = %loop_exit16
  reattach within %syncreg11, label %loop_latch9

synced19:                                         ; preds = %loop_exit10
  br label %block_exit20

block_exit20:                                     ; preds = %synced19
  reattach within %syncreg5, label %loop_latch3

synced21:                                         ; preds = %loop_exit4
  reattach within %syncreg, label %loop_latch

synced22:                                         ; preds = %loop_exit
  ret void
}

; Function Attrs: argmemonly nounwind
declare token @llvm.syncregion.start() #0

attributes #0 = { argmemonly nounwind }

