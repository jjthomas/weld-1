; PRELUDE:

; Common prelude to add at the start of generated LLVM modules.

; Unsigned data types -- we use these in the generated code for clarity and to make
; template substitution work nicely when calling type-specific functions
%u8 = type i8;
%u16 = type i16;
%u32 = type i32;
%u64 = type i64;

; LLVM intrinsic functions
declare void @llvm.memcpy.p0i8.p0i8.i64(i8*, i8*, i64, i32, i1)
declare void @llvm.memset.p0i8.i64(i8*, i8, i64, i32, i1)
declare float @llvm.exp.f32(float)
declare double @llvm.exp.f64(double)

declare float @llvm.log.f32(float)
declare double @llvm.log.f64(double)

declare <4 x float> @llvm.sqrt.v4f32(<4 x float>)
declare <8 x float> @llvm.sqrt.v8f32(<8 x float>)
declare <4 x float> @llvm.log.v4f32(<4 x float>)
declare <8 x float> @llvm.log.v8f32(<8 x float>)
declare <4 x float> @llvm.exp.v4f32(<4 x float>)
declare <8 x float> @llvm.exp.v8f32(<8 x float>)

declare <2 x double> @llvm.sqrt.v2f64(<2 x double>)
declare <4 x double> @llvm.sqrt.v4f64(<4 x double>)
declare <2 x double> @llvm.log.v2f64(<2 x double>)
declare <4 x double> @llvm.log.v4f64(<4 x double>)
declare <2 x double> @llvm.exp.v2f64(<2 x double>)
declare <4 x double> @llvm.exp.v4f64(<4 x double>)

declare float @llvm.sqrt.f32(float)
declare double @llvm.sqrt.f64(double)

declare i64 @llvm.ctlz.i64(i64, i1)

declare float @llvm.maxnum.f32(float, float)
declare double @llvm.maxnum.f64(double, double)
declare float @llvm.minnum.f32(float, float)
declare double @llvm.minnum.f64(double, double)

; std library functions
declare i8* @malloc(i64)
declare void @qsort(i8*, i64, i64, i32 (i8*, i8*)*)
declare i32 @memcmp(i8*, i8*, i64)
declare float @erff(float)
declare double @erf(double)

declare i32 @puts(i8* nocapture) nounwind

; Weld runtime functions

declare i64     @weld_run_begin(void (%work_t*)*, i8*, i64, i32)
declare i8*     @weld_run_get_result(i64)

declare i8*     @weld_run_malloc(i64, i64)
declare i8*     @weld_run_realloc(i64, i8*, i64)
declare void    @weld_run_free(i64, i8*)

declare void    @weld_run_set_errno(i64, i64)
declare i64     @weld_run_get_errno(i64)

declare i32     @weld_rt_thread_id()
declare void    @weld_rt_abort_thread()
declare i32     @weld_rt_get_nworkers()
declare i64     @weld_rt_get_run_id()

declare void    @weld_rt_start_loop(%work_t*, i8*, i8*, void (%work_t*)*, void (%work_t*)*, i64, i64, i32)
declare void    @weld_rt_set_result(i8*)

declare i8*     @weld_rt_new_vb(i64, i64, i32)
declare void    @weld_rt_new_vb_piece(i8*, %work_t*, i32)
declare %vb.vp* @weld_rt_cur_vb_piece(i8*, i32)
declare %vb.out @weld_rt_result_vb(i8*)

declare i8*     @weld_rt_new_merger(i64, i32)
declare i8*     @weld_rt_get_merger_at_index(i8*, i64, i32)
declare void    @weld_rt_free_merger(i8*)

declare i8*     @weld_rt_dict_new(i32, i32 (i8*, i8*)*, i32, i32, i64, i64)
declare i8*     @weld_rt_dict_lookup(i8*, i32, i8*)
declare void    @weld_rt_dict_put(i8*, i8*)
declare i8*     @weld_rt_dict_finalize_next_local_slot(i8*)
declare i8*     @weld_rt_dict_finalize_global_slot_for_local(i8*, i8*)
declare i8*     @weld_rt_dict_to_array(i8*, i32, i32)
declare i64     @weld_rt_dict_get_size(i8*)
declare void    @weld_rt_dict_free(i8*)

declare i8*     @weld_rt_gb_new(i32, i32 (i8*, i8*)*, i32, i64, i64)
declare void    @weld_rt_gb_merge(i8*, i8*, i32, i8*)
declare i8*     @weld_rt_gb_result(i8*)
declare void    @weld_rt_gb_free(i8*)

; Parallel runtime structures
; work_t struct in runtime.h
%work_t = type { i8*, i64, i64, i64, i32, i64*, i64*, i32, i64, void (%work_t*)*, %work_t*, i32, i32, i32 }
; vec_piece struct in runtime.h
%vb.vp = type { i8*, i64, i64, i64*, i64*, i32 }
; vec_output struct in runtime.h
%vb.out = type { i8*, i64 }

; Input argument (input data pointer, nworkers, mem_limit)
%input_arg_t = type { i64, i32, i64 }
; Return type (output data pointer, run ID, errno)
%output_arg_t = type { i64, i64, i64 }

; Hash functions

; Combines two hash values using the method in Effective Java
define i32 @hash_combine(i32 %start, i32 %value) alwaysinline {
  ; return 31 * start + value
  %1 = mul i32 %start, 31
  %2 = add i32 %1, %value
  ret i32 %2
}

; Mixes the bits in a hash code, similar to Java's HashMap
define i32 @hash_finalize(i32 %hash) {
  ; h ^= (h >>> 20) ^ (h >>> 12);
  ; return h ^ (h >>> 7) ^ (h >>> 4);
  %1 = lshr i32 %hash, 20
  %2 = lshr i32 %hash, 12
  %3 = xor i32 %hash, %1
  %h2 = xor i32 %3, %2
  %4 = lshr i32 %h2, 7
  %5 = lshr i32 %h2, 4
  %6 = xor i32 %h2, %4
  %res = xor i32 %6, %5
  ret i32 %res
}

define i32 @i64.hash(i64 %arg) {
  ; return (i32) ((arg >>> 32) ^ arg)
  %1 = lshr i64 %arg, 32
  %2 = xor i64 %arg, %1
  %3 = trunc i64 %2 to i32
  ret i32 %3
}

define i32 @i32.hash(i32 %arg) {
  ret i32 %arg
}

define i32 @i16.hash(i16 %arg) {
  %1 = zext i16 %arg to i32
  ret i32 %1
}

define i32 @i8.hash(i8 %arg) {
  %1 = zext i8 %arg to i32
  ret i32 %1
}

define i32 @i1.hash(i1 %arg) {
  %1 = zext i1 %arg to i32
  ret i32 %1
}

define i32 @u64.hash(%u64 %arg) {
  %1 = call i32 @i64.hash(i64 %arg)
  ret i32 %1
}

define i32 @u32.hash(%u32 %arg) {
  %1 = call i32 @i32.hash(i32 %arg)
  ret i32 %1
}

define i32 @u16.hash(%u16 %arg) {
  %1 = call i32 @i16.hash(i16 %arg)
  ret i32 %1
}

define i32 @u8.hash(%u8 %arg) {
  %1 = call i32 @i8.hash(i8 %arg)
  ret i32 %1
}

define i32 @float.hash(float %arg) {
  %1 = bitcast float %arg to i32
  ret i32 %1
}

define i32 @double.hash(double %arg) {
  %1 = bitcast double %arg to i64
  %2 = call i32 @i64.hash(i64 %1)
  ret i32 %2
}

; Template for a vector, its builder type, and its helper functions.
;
; Parameters:
; - NAME: name to give generated type, without % or @ prefix
; - ELEM: LLVM type of the element (e.g. i32 or %MyStruct)
; - ELEM_PREFIX: prefix for helper functions on ELEM (e.g. @i32 or @MyStruct)
; - VECSIZE: Size of vectors.

%v0 = type { float*, i64 }           ; elements, size
%v0.bld = type i8*

; VecMerger
%v0.vm.bld = type %v0*

; Returns a pointer to builder data for index i (generally, i is the thread ID).
define %v0.vm.bld @v0.vm.bld.getPtrIndexed(%v0.vm.bld %bldPtr, i32 %i) alwaysinline {
  %mergerPtr = getelementptr %v0, %v0* null, i32 1
  %mergerSize = ptrtoint %v0* %mergerPtr to i64
  %asPtr = bitcast %v0.vm.bld %bldPtr to i8*
  %rawPtr = call i8* @weld_rt_get_merger_at_index(i8* %asPtr, i64 %mergerSize, i32 %i)
  %ptr = bitcast i8* %rawPtr to %v0.vm.bld
  ret %v0.vm.bld %ptr
}

; Initialize and return a new vecmerger with the given initial vector.
define %v0.vm.bld @v0.vm.bld.new(%v0 %vec) {
  %nworkers = call i32 @weld_rt_get_nworkers()
  %structSizePtr = getelementptr %v0, %v0* null, i32 1
  %structSize = ptrtoint %v0* %structSizePtr to i64
  
  %bldPtr = call i8* @weld_rt_new_merger(i64 %structSize, i32 %nworkers)
  %typedPtr = bitcast i8* %bldPtr to %v0.vm.bld
  
  ; Copy the initial value into the first vector
  %first = call %v0.vm.bld @v0.vm.bld.getPtrIndexed(%v0.vm.bld %typedPtr, i32 0)
  %cloned = call %v0 @v0.clone(%v0 %vec)
  %capacity = call i64 @v0.size(%v0 %vec)
  store %v0 %cloned, %v0.vm.bld %first
  br label %entry
  
entry:
  %cond = icmp ult i32 1, %nworkers
  br i1 %cond, label %body, label %done
  
body:
  %i = phi i32 [ 1, %entry ], [ %i2, %body ]
  %vecPtr = call %v0* @v0.vm.bld.getPtrIndexed(%v0.vm.bld %typedPtr, i32 %i)
  %newVec = call %v0 @v0.new(i64 %capacity)
  call void @v0.zero(%v0 %newVec)
  store %v0 %newVec, %v0* %vecPtr
  %i2 = add i32 %i, 1
  %cond2 = icmp ult i32 %i2, %nworkers
  br i1 %cond2, label %body, label %done
  
done:
  ret %v0.vm.bld %typedPtr
}

; Returns a pointer to the value an element should be merged into.
; The caller should perform the merge operation on the contents of this pointer
; and then store the resulting value back.
define i8* @v0.vm.bld.merge_ptr(%v0.vm.bld %bldPtr, i64 %index, i32 %workerId) {
  %bldPtrLocal = call %v0* @v0.vm.bld.getPtrIndexed(%v0.vm.bld %bldPtr, i32 %workerId)
  %vec = load %v0, %v0* %bldPtrLocal
  %elem = call float* @v0.at(%v0 %vec, i64 %index)
  %elemPtrRaw = bitcast float* %elem to i8*
  ret i8* %elemPtrRaw
}

; Initialize and return a new vector with the given size.
define %v0 @v0.new(i64 %size) {
  %elemSizePtr = getelementptr float, float* null, i32 1
  %elemSize = ptrtoint float* %elemSizePtr to i64
  %allocSize = mul i64 %elemSize, %size
  %runId = call i64 @weld_rt_get_run_id()
  %bytes = call i8* @weld_run_malloc(i64 %runId, i64 %allocSize)
  %elements = bitcast i8* %bytes to float*
  %1 = insertvalue %v0 undef, float* %elements, 0
  %2 = insertvalue %v0 %1, i64 %size, 1
  ret %v0 %2
}

; Zeroes a vector's underlying buffer.
define void @v0.zero(%v0 %v) {
  %elements = extractvalue %v0 %v, 0
  %size = extractvalue %v0 %v, 1
  %bytes = bitcast float* %elements to i8*
  
  %elemSizePtr = getelementptr float, float* null, i32 1
  %elemSize = ptrtoint float* %elemSizePtr to i64
  %allocSize = mul i64 %elemSize, %size
  call void @llvm.memset.p0i8.i64(i8* %bytes, i8 0, i64 %allocSize, i32 8, i1 0)
  ret void
}

define i32 @v0.elSize() {
  %elemSizePtr = getelementptr float, float* null, i32 1
  %elemSize = ptrtoint float* %elemSizePtr to i32
  ret i32 %elemSize
}

; Clone a vector.
define %v0 @v0.clone(%v0 %vec) {
  %elements = extractvalue %v0 %vec, 0
  %size = extractvalue %v0 %vec, 1
  %entrySizePtr = getelementptr float, float* null, i32 1
  %entrySize = ptrtoint float* %entrySizePtr to i64
  %allocSize = mul i64 %entrySize, %size
  %bytes = bitcast float* %elements to i8*
  %vec2 = call %v0 @v0.new(i64 %size)
  %elements2 = extractvalue %v0 %vec2, 0
  %bytes2 = bitcast float* %elements2 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* %bytes2, i8* %bytes, i64 %allocSize, i32 8, i1 0)
  ret %v0 %vec2
}

; Get a new vec object that starts at the index'th element of the existing vector, and has size size.
; If the specified size is greater than the remaining size, then the remaining size is used.
define %v0 @v0.slice(%v0 %vec, i64 %index, i64 %size) {
  ; Check if size greater than remaining size
  %currSize = extractvalue %v0 %vec, 1
  %remSize = sub i64 %currSize, %index
  %sgtr = icmp ugt i64 %size, %remSize
  %finSize = select i1 %sgtr, i64 %remSize, i64 %size
  
  %elements = extractvalue %v0 %vec, 0
  %newElements = getelementptr float, float* %elements, i64 %index
  %1 = insertvalue %v0 undef, float* %newElements, 0
  %2 = insertvalue %v0 %1, i64 %finSize, 1
  
  ret %v0 %2
}

; Initialize and return a new builder, with the given initial capacity.
define %v0.bld @v0.bld.new(i64 %capacity, %work_t* %cur.work, i32 %fixedSize) {
  %elemSizePtr = getelementptr float, float* null, i32 1
  %elemSize = ptrtoint float* %elemSizePtr to i64
  %newVb = call i8* @weld_rt_new_vb(i64 %elemSize, i64 %capacity, i32 %fixedSize)
  call void @v0.bld.newPieceInit(%v0.bld %newVb, %work_t* %cur.work)
  ret %v0.bld %newVb
}

define void @v0.bld.newPieceInit(%v0.bld %bldPtr, %work_t* %cur.work) {
  call void @weld_rt_new_vb_piece(i8* %bldPtr, %work_t* %cur.work, i32 1)
  ret void
}

define void @v0.bld.newPiece(%v0.bld %bldPtr, %work_t* %cur.work) {
  call void @weld_rt_new_vb_piece(i8* %bldPtr, %work_t* %cur.work, i32 0)
  ret void
}

; Append a value into a builder, growing its space if needed.
define %v0.bld @v0.bld.merge(%v0.bld %bldPtr, float %value, i32 %myId) {
entry:
  %curPiecePtr = call %vb.vp* @weld_rt_cur_vb_piece(i8* %bldPtr, i32 %myId)
  %bytesPtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 0
  %sizePtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 1
  %capacityPtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 2
  %size = load i64, i64* %sizePtr
  %capacity = load i64, i64* %capacityPtr
  %full = icmp eq i64 %size, %capacity
  br i1 %full, label %onFull, label %finish
  
onFull:
  %newCapacity = mul i64 %capacity, 2
  %elemSizePtr = getelementptr float, float* null, i32 1
  %elemSize = ptrtoint float* %elemSizePtr to i64
  %bytes = load i8*, i8** %bytesPtr
  %allocSize = mul i64 %elemSize, %newCapacity
  %runId = call i64 @weld_rt_get_run_id()
  %newBytes = call i8* @weld_run_realloc(i64 %runId, i8* %bytes, i64 %allocSize)
  store i8* %newBytes, i8** %bytesPtr
  store i64 %newCapacity, i64* %capacityPtr
  br label %finish
  
finish:
  %bytes1 = load i8*, i8** %bytesPtr
  %elements = bitcast i8* %bytes1 to float*
  %insertPtr = getelementptr float, float* %elements, i64 %size
  store float %value, float* %insertPtr
  %newSize = add i64 %size, 1
  store i64 %newSize, i64* %sizePtr
  ret %v0.bld %bldPtr
}

; Complete building a vector, trimming any extra space left while growing it.
define %v0 @v0.bld.result(%v0.bld %bldPtr) {
  %out = call %vb.out @weld_rt_result_vb(i8* %bldPtr)
  %bytes = extractvalue %vb.out %out, 0
  %size = extractvalue %vb.out %out, 1
  %elems = bitcast i8* %bytes to float*
  %1 = insertvalue %v0 undef, float* %elems, 0
  %2 = insertvalue %v0 %1, i64 %size, 1
  ret %v0 %2
}

; Get the length of a vector.
define i64 @v0.size(%v0 %vec) alwaysinline {
  %size = extractvalue %v0 %vec, 1
  ret i64 %size
}

; Get a pointer to the index'th element.
define float* @v0.at(%v0 %vec, i64 %index) alwaysinline {
  %elements = extractvalue %v0 %vec, 0
  %ptr = getelementptr float, float* %elements, i64 %index
  ret float* %ptr
}


; Get the length of a VecBuilder.
define i64 @v0.bld.size(%v0.bld nocapture %bldPtr, i32 %myId) readonly nounwind norecurse {
  %curPiecePtr = call %vb.vp* @weld_rt_cur_vb_piece(i8* %bldPtr, i32 %myId)
  %sizePtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 1
  %size = load i64, i64* %sizePtr
  ret i64 %size
}

; Get a pointer to the index'th element of a VecBuilder.
define float* @v0.bld.at(%v0.bld nocapture %bldPtr, i64 %index, i32 %myId) readonly nounwind norecurse {
  %curPiecePtr = call %vb.vp* @weld_rt_cur_vb_piece(i8* %bldPtr, i32 %myId)
  %bytesPtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 0
  %bytes = load i8*, i8** %bytesPtr
  %elements = bitcast i8* %bytes to float*
  %ptr = getelementptr float, float* %elements, i64 %index
  ret float* %ptr
}

; Vector extensions for a vector, its builder type, and its helper functions.
;
; Parameters:
; - NAME: name to give generated type, without % or @ prefix
; - ELEM: LLVM type of the element (e.g. i32 or %MyStruct)
; - VECSIZE: Size of vectors.

; Get a pointer to the index'th element, fetching a vector
define <4 x float>* @v0.vat(%v0 %vec, i64 %index) {
  %elements = extractvalue %v0 %vec, 0
  %ptr = getelementptr float, float* %elements, i64 %index
  %retPtr = bitcast float* %ptr to <4 x float>*
  ret <4 x float>* %retPtr
}

; Append a value into a builder, growing its space if needed.
define %v0.bld @v0.bld.vmerge(%v0.bld %bldPtr, <4 x float> %value, i32 %myId) {
entry:
  %curPiecePtr = call %vb.vp* @weld_rt_cur_vb_piece(i8* %bldPtr, i32 %myId)
  %curPiece = load %vb.vp, %vb.vp* %curPiecePtr
  %size = extractvalue %vb.vp %curPiece, 1
  %capacity = extractvalue %vb.vp %curPiece, 2
  %adjusted = add i64 %size, 4
  %full = icmp sgt i64 %adjusted, %capacity
  br i1 %full, label %onFull, label %finish
  
onFull:
  %newCapacity = mul i64 %capacity, 2
  %elemSizePtr = getelementptr float, float* null, i32 1
  %elemSize = ptrtoint float* %elemSizePtr to i64
  %bytes = extractvalue %vb.vp %curPiece, 0
  %allocSize = mul i64 %elemSize, %newCapacity
  %runId = call i64 @weld_rt_get_run_id()
  %newBytes = call i8* @weld_run_realloc(i64 %runId, i8* %bytes, i64 %allocSize)
  %curPiece1 = insertvalue %vb.vp %curPiece, i8* %newBytes, 0
  %curPiece2 = insertvalue %vb.vp %curPiece1, i64 %newCapacity, 2
  br label %finish
  
finish:
  %curPiece3 = phi %vb.vp [ %curPiece, %entry ], [ %curPiece2, %onFull ]
  %bytes1 = extractvalue %vb.vp %curPiece3, 0
  %elements = bitcast i8* %bytes1 to float*
  %insertPtr = getelementptr float, float* %elements, i64 %size
  %vecInsertPtr = bitcast float* %insertPtr to <4 x float>*
  store <4 x float> %value, <4 x float>* %vecInsertPtr, align 1
  %newSize = add i64 %size, 4
  %curPiece4 = insertvalue %vb.vp %curPiece3, i64 %newSize, 1
  store %vb.vp %curPiece4, %vb.vp* %curPiecePtr
  ret %v0.bld %bldPtr
}

; Template for a vector, its builder type, and its helper functions.
;
; Parameters:
; - NAME: name to give generated type, without % or @ prefix
; - ELEM: LLVM type of the element (e.g. i32 or %MyStruct)
; - ELEM_PREFIX: prefix for helper functions on ELEM (e.g. @i32 or @MyStruct)
; - VECSIZE: Size of vectors.

%v1 = type { i32*, i64 }           ; elements, size
%v1.bld = type i8*

; VecMerger
%v1.vm.bld = type %v1*

; Returns a pointer to builder data for index i (generally, i is the thread ID).
define %v1.vm.bld @v1.vm.bld.getPtrIndexed(%v1.vm.bld %bldPtr, i32 %i) alwaysinline {
  %mergerPtr = getelementptr %v1, %v1* null, i32 1
  %mergerSize = ptrtoint %v1* %mergerPtr to i64
  %asPtr = bitcast %v1.vm.bld %bldPtr to i8*
  %rawPtr = call i8* @weld_rt_get_merger_at_index(i8* %asPtr, i64 %mergerSize, i32 %i)
  %ptr = bitcast i8* %rawPtr to %v1.vm.bld
  ret %v1.vm.bld %ptr
}

; Initialize and return a new vecmerger with the given initial vector.
define %v1.vm.bld @v1.vm.bld.new(%v1 %vec) {
  %nworkers = call i32 @weld_rt_get_nworkers()
  %structSizePtr = getelementptr %v1, %v1* null, i32 1
  %structSize = ptrtoint %v1* %structSizePtr to i64
  
  %bldPtr = call i8* @weld_rt_new_merger(i64 %structSize, i32 %nworkers)
  %typedPtr = bitcast i8* %bldPtr to %v1.vm.bld
  
  ; Copy the initial value into the first vector
  %first = call %v1.vm.bld @v1.vm.bld.getPtrIndexed(%v1.vm.bld %typedPtr, i32 0)
  %cloned = call %v1 @v1.clone(%v1 %vec)
  %capacity = call i64 @v1.size(%v1 %vec)
  store %v1 %cloned, %v1.vm.bld %first
  br label %entry
  
entry:
  %cond = icmp ult i32 1, %nworkers
  br i1 %cond, label %body, label %done
  
body:
  %i = phi i32 [ 1, %entry ], [ %i2, %body ]
  %vecPtr = call %v1* @v1.vm.bld.getPtrIndexed(%v1.vm.bld %typedPtr, i32 %i)
  %newVec = call %v1 @v1.new(i64 %capacity)
  call void @v1.zero(%v1 %newVec)
  store %v1 %newVec, %v1* %vecPtr
  %i2 = add i32 %i, 1
  %cond2 = icmp ult i32 %i2, %nworkers
  br i1 %cond2, label %body, label %done
  
done:
  ret %v1.vm.bld %typedPtr
}

; Returns a pointer to the value an element should be merged into.
; The caller should perform the merge operation on the contents of this pointer
; and then store the resulting value back.
define i8* @v1.vm.bld.merge_ptr(%v1.vm.bld %bldPtr, i64 %index, i32 %workerId) {
  %bldPtrLocal = call %v1* @v1.vm.bld.getPtrIndexed(%v1.vm.bld %bldPtr, i32 %workerId)
  %vec = load %v1, %v1* %bldPtrLocal
  %elem = call i32* @v1.at(%v1 %vec, i64 %index)
  %elemPtrRaw = bitcast i32* %elem to i8*
  ret i8* %elemPtrRaw
}

; Initialize and return a new vector with the given size.
define %v1 @v1.new(i64 %size) {
  %elemSizePtr = getelementptr i32, i32* null, i32 1
  %elemSize = ptrtoint i32* %elemSizePtr to i64
  %allocSize = mul i64 %elemSize, %size
  %runId = call i64 @weld_rt_get_run_id()
  %bytes = call i8* @weld_run_malloc(i64 %runId, i64 %allocSize)
  %elements = bitcast i8* %bytes to i32*
  %1 = insertvalue %v1 undef, i32* %elements, 0
  %2 = insertvalue %v1 %1, i64 %size, 1
  ret %v1 %2
}

; Zeroes a vector's underlying buffer.
define void @v1.zero(%v1 %v) {
  %elements = extractvalue %v1 %v, 0
  %size = extractvalue %v1 %v, 1
  %bytes = bitcast i32* %elements to i8*
  
  %elemSizePtr = getelementptr i32, i32* null, i32 1
  %elemSize = ptrtoint i32* %elemSizePtr to i64
  %allocSize = mul i64 %elemSize, %size
  call void @llvm.memset.p0i8.i64(i8* %bytes, i8 0, i64 %allocSize, i32 8, i1 0)
  ret void
}

define i32 @v1.elSize() {
  %elemSizePtr = getelementptr i32, i32* null, i32 1
  %elemSize = ptrtoint i32* %elemSizePtr to i32
  ret i32 %elemSize
}

; Clone a vector.
define %v1 @v1.clone(%v1 %vec) {
  %elements = extractvalue %v1 %vec, 0
  %size = extractvalue %v1 %vec, 1
  %entrySizePtr = getelementptr i32, i32* null, i32 1
  %entrySize = ptrtoint i32* %entrySizePtr to i64
  %allocSize = mul i64 %entrySize, %size
  %bytes = bitcast i32* %elements to i8*
  %vec2 = call %v1 @v1.new(i64 %size)
  %elements2 = extractvalue %v1 %vec2, 0
  %bytes2 = bitcast i32* %elements2 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* %bytes2, i8* %bytes, i64 %allocSize, i32 8, i1 0)
  ret %v1 %vec2
}

; Get a new vec object that starts at the index'th element of the existing vector, and has size size.
; If the specified size is greater than the remaining size, then the remaining size is used.
define %v1 @v1.slice(%v1 %vec, i64 %index, i64 %size) {
  ; Check if size greater than remaining size
  %currSize = extractvalue %v1 %vec, 1
  %remSize = sub i64 %currSize, %index
  %sgtr = icmp ugt i64 %size, %remSize
  %finSize = select i1 %sgtr, i64 %remSize, i64 %size
  
  %elements = extractvalue %v1 %vec, 0
  %newElements = getelementptr i32, i32* %elements, i64 %index
  %1 = insertvalue %v1 undef, i32* %newElements, 0
  %2 = insertvalue %v1 %1, i64 %finSize, 1
  
  ret %v1 %2
}

; Initialize and return a new builder, with the given initial capacity.
define %v1.bld @v1.bld.new(i64 %capacity, %work_t* %cur.work, i32 %fixedSize) {
  %elemSizePtr = getelementptr i32, i32* null, i32 1
  %elemSize = ptrtoint i32* %elemSizePtr to i64
  %newVb = call i8* @weld_rt_new_vb(i64 %elemSize, i64 %capacity, i32 %fixedSize)
  call void @v1.bld.newPieceInit(%v1.bld %newVb, %work_t* %cur.work)
  ret %v1.bld %newVb
}

define void @v1.bld.newPieceInit(%v1.bld %bldPtr, %work_t* %cur.work) {
  call void @weld_rt_new_vb_piece(i8* %bldPtr, %work_t* %cur.work, i32 1)
  ret void
}

define void @v1.bld.newPiece(%v1.bld %bldPtr, %work_t* %cur.work) {
  call void @weld_rt_new_vb_piece(i8* %bldPtr, %work_t* %cur.work, i32 0)
  ret void
}

; Append a value into a builder, growing its space if needed.
define %v1.bld @v1.bld.merge(%v1.bld %bldPtr, i32 %value, i32 %myId) {
entry:
  %curPiecePtr = call %vb.vp* @weld_rt_cur_vb_piece(i8* %bldPtr, i32 %myId)
  %bytesPtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 0
  %sizePtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 1
  %capacityPtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 2
  %size = load i64, i64* %sizePtr
  %capacity = load i64, i64* %capacityPtr
  %full = icmp eq i64 %size, %capacity
  br i1 %full, label %onFull, label %finish
  
onFull:
  %newCapacity = mul i64 %capacity, 2
  %elemSizePtr = getelementptr i32, i32* null, i32 1
  %elemSize = ptrtoint i32* %elemSizePtr to i64
  %bytes = load i8*, i8** %bytesPtr
  %allocSize = mul i64 %elemSize, %newCapacity
  %runId = call i64 @weld_rt_get_run_id()
  %newBytes = call i8* @weld_run_realloc(i64 %runId, i8* %bytes, i64 %allocSize)
  store i8* %newBytes, i8** %bytesPtr
  store i64 %newCapacity, i64* %capacityPtr
  br label %finish
  
finish:
  %bytes1 = load i8*, i8** %bytesPtr
  %elements = bitcast i8* %bytes1 to i32*
  %insertPtr = getelementptr i32, i32* %elements, i64 %size
  store i32 %value, i32* %insertPtr
  %newSize = add i64 %size, 1
  store i64 %newSize, i64* %sizePtr
  ret %v1.bld %bldPtr
}

; Complete building a vector, trimming any extra space left while growing it.
define %v1 @v1.bld.result(%v1.bld %bldPtr) {
  %out = call %vb.out @weld_rt_result_vb(i8* %bldPtr)
  %bytes = extractvalue %vb.out %out, 0
  %size = extractvalue %vb.out %out, 1
  %elems = bitcast i8* %bytes to i32*
  %1 = insertvalue %v1 undef, i32* %elems, 0
  %2 = insertvalue %v1 %1, i64 %size, 1
  ret %v1 %2
}

; Get the length of a vector.
define i64 @v1.size(%v1 %vec) alwaysinline {
  %size = extractvalue %v1 %vec, 1
  ret i64 %size
}

; Get a pointer to the index'th element.
define i32* @v1.at(%v1 %vec, i64 %index) alwaysinline {
  %elements = extractvalue %v1 %vec, 0
  %ptr = getelementptr i32, i32* %elements, i64 %index
  ret i32* %ptr
}


; Get the length of a VecBuilder.
define i64 @v1.bld.size(%v1.bld nocapture %bldPtr, i32 %myId) readonly nounwind norecurse {
  %curPiecePtr = call %vb.vp* @weld_rt_cur_vb_piece(i8* %bldPtr, i32 %myId)
  %sizePtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 1
  %size = load i64, i64* %sizePtr
  ret i64 %size
}

; Get a pointer to the index'th element of a VecBuilder.
define i32* @v1.bld.at(%v1.bld nocapture %bldPtr, i64 %index, i32 %myId) readonly nounwind norecurse {
  %curPiecePtr = call %vb.vp* @weld_rt_cur_vb_piece(i8* %bldPtr, i32 %myId)
  %bytesPtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 0
  %bytes = load i8*, i8** %bytesPtr
  %elements = bitcast i8* %bytes to i32*
  %ptr = getelementptr i32, i32* %elements, i64 %index
  ret i32* %ptr
}

; Vector extensions for a vector, its builder type, and its helper functions.
;
; Parameters:
; - NAME: name to give generated type, without % or @ prefix
; - ELEM: LLVM type of the element (e.g. i32 or %MyStruct)
; - VECSIZE: Size of vectors.

; Get a pointer to the index'th element, fetching a vector
define <4 x i32>* @v1.vat(%v1 %vec, i64 %index) {
  %elements = extractvalue %v1 %vec, 0
  %ptr = getelementptr i32, i32* %elements, i64 %index
  %retPtr = bitcast i32* %ptr to <4 x i32>*
  ret <4 x i32>* %retPtr
}

; Append a value into a builder, growing its space if needed.
define %v1.bld @v1.bld.vmerge(%v1.bld %bldPtr, <4 x i32> %value, i32 %myId) {
entry:
  %curPiecePtr = call %vb.vp* @weld_rt_cur_vb_piece(i8* %bldPtr, i32 %myId)
  %curPiece = load %vb.vp, %vb.vp* %curPiecePtr
  %size = extractvalue %vb.vp %curPiece, 1
  %capacity = extractvalue %vb.vp %curPiece, 2
  %adjusted = add i64 %size, 4
  %full = icmp sgt i64 %adjusted, %capacity
  br i1 %full, label %onFull, label %finish
  
onFull:
  %newCapacity = mul i64 %capacity, 2
  %elemSizePtr = getelementptr i32, i32* null, i32 1
  %elemSize = ptrtoint i32* %elemSizePtr to i64
  %bytes = extractvalue %vb.vp %curPiece, 0
  %allocSize = mul i64 %elemSize, %newCapacity
  %runId = call i64 @weld_rt_get_run_id()
  %newBytes = call i8* @weld_run_realloc(i64 %runId, i8* %bytes, i64 %allocSize)
  %curPiece1 = insertvalue %vb.vp %curPiece, i8* %newBytes, 0
  %curPiece2 = insertvalue %vb.vp %curPiece1, i64 %newCapacity, 2
  br label %finish
  
finish:
  %curPiece3 = phi %vb.vp [ %curPiece, %entry ], [ %curPiece2, %onFull ]
  %bytes1 = extractvalue %vb.vp %curPiece3, 0
  %elements = bitcast i8* %bytes1 to i32*
  %insertPtr = getelementptr i32, i32* %elements, i64 %size
  %vecInsertPtr = bitcast i32* %insertPtr to <4 x i32>*
  store <4 x i32> %value, <4 x i32>* %vecInsertPtr, align 1
  %newSize = add i64 %size, 4
  %curPiece4 = insertvalue %vb.vp %curPiece3, i64 %newSize, 1
  store %vb.vp %curPiece4, %vb.vp* %curPiecePtr
  ret %v1.bld %bldPtr
}

%s0 = type { i32, i32 }
%s1 = type { float, float, float, float, float, i32 }
%s2 = type { %s0, %s1 }
; Template for a vector, its builder type, and its helper functions.
;
; Parameters:
; - NAME: name to give generated type, without % or @ prefix
; - ELEM: LLVM type of the element (e.g. i32 or %MyStruct)
; - ELEM_PREFIX: prefix for helper functions on ELEM (e.g. @i32 or @MyStruct)
; - VECSIZE: Size of vectors.

%v2 = type { %s2*, i64 }           ; elements, size
%v2.bld = type i8*

; VecMerger
%v2.vm.bld = type %v2*

; Returns a pointer to builder data for index i (generally, i is the thread ID).
define %v2.vm.bld @v2.vm.bld.getPtrIndexed(%v2.vm.bld %bldPtr, i32 %i) alwaysinline {
  %mergerPtr = getelementptr %v2, %v2* null, i32 1
  %mergerSize = ptrtoint %v2* %mergerPtr to i64
  %asPtr = bitcast %v2.vm.bld %bldPtr to i8*
  %rawPtr = call i8* @weld_rt_get_merger_at_index(i8* %asPtr, i64 %mergerSize, i32 %i)
  %ptr = bitcast i8* %rawPtr to %v2.vm.bld
  ret %v2.vm.bld %ptr
}

; Initialize and return a new vecmerger with the given initial vector.
define %v2.vm.bld @v2.vm.bld.new(%v2 %vec) {
  %nworkers = call i32 @weld_rt_get_nworkers()
  %structSizePtr = getelementptr %v2, %v2* null, i32 1
  %structSize = ptrtoint %v2* %structSizePtr to i64
  
  %bldPtr = call i8* @weld_rt_new_merger(i64 %structSize, i32 %nworkers)
  %typedPtr = bitcast i8* %bldPtr to %v2.vm.bld
  
  ; Copy the initial value into the first vector
  %first = call %v2.vm.bld @v2.vm.bld.getPtrIndexed(%v2.vm.bld %typedPtr, i32 0)
  %cloned = call %v2 @v2.clone(%v2 %vec)
  %capacity = call i64 @v2.size(%v2 %vec)
  store %v2 %cloned, %v2.vm.bld %first
  br label %entry
  
entry:
  %cond = icmp ult i32 1, %nworkers
  br i1 %cond, label %body, label %done
  
body:
  %i = phi i32 [ 1, %entry ], [ %i2, %body ]
  %vecPtr = call %v2* @v2.vm.bld.getPtrIndexed(%v2.vm.bld %typedPtr, i32 %i)
  %newVec = call %v2 @v2.new(i64 %capacity)
  call void @v2.zero(%v2 %newVec)
  store %v2 %newVec, %v2* %vecPtr
  %i2 = add i32 %i, 1
  %cond2 = icmp ult i32 %i2, %nworkers
  br i1 %cond2, label %body, label %done
  
done:
  ret %v2.vm.bld %typedPtr
}

; Returns a pointer to the value an element should be merged into.
; The caller should perform the merge operation on the contents of this pointer
; and then store the resulting value back.
define i8* @v2.vm.bld.merge_ptr(%v2.vm.bld %bldPtr, i64 %index, i32 %workerId) {
  %bldPtrLocal = call %v2* @v2.vm.bld.getPtrIndexed(%v2.vm.bld %bldPtr, i32 %workerId)
  %vec = load %v2, %v2* %bldPtrLocal
  %elem = call %s2* @v2.at(%v2 %vec, i64 %index)
  %elemPtrRaw = bitcast %s2* %elem to i8*
  ret i8* %elemPtrRaw
}

; Initialize and return a new vector with the given size.
define %v2 @v2.new(i64 %size) {
  %elemSizePtr = getelementptr %s2, %s2* null, i32 1
  %elemSize = ptrtoint %s2* %elemSizePtr to i64
  %allocSize = mul i64 %elemSize, %size
  %runId = call i64 @weld_rt_get_run_id()
  %bytes = call i8* @weld_run_malloc(i64 %runId, i64 %allocSize)
  %elements = bitcast i8* %bytes to %s2*
  %1 = insertvalue %v2 undef, %s2* %elements, 0
  %2 = insertvalue %v2 %1, i64 %size, 1
  ret %v2 %2
}

; Zeroes a vector's underlying buffer.
define void @v2.zero(%v2 %v) {
  %elements = extractvalue %v2 %v, 0
  %size = extractvalue %v2 %v, 1
  %bytes = bitcast %s2* %elements to i8*
  
  %elemSizePtr = getelementptr %s2, %s2* null, i32 1
  %elemSize = ptrtoint %s2* %elemSizePtr to i64
  %allocSize = mul i64 %elemSize, %size
  call void @llvm.memset.p0i8.i64(i8* %bytes, i8 0, i64 %allocSize, i32 8, i1 0)
  ret void
}

define i32 @v2.elSize() {
  %elemSizePtr = getelementptr %s2, %s2* null, i32 1
  %elemSize = ptrtoint %s2* %elemSizePtr to i32
  ret i32 %elemSize
}

; Clone a vector.
define %v2 @v2.clone(%v2 %vec) {
  %elements = extractvalue %v2 %vec, 0
  %size = extractvalue %v2 %vec, 1
  %entrySizePtr = getelementptr %s2, %s2* null, i32 1
  %entrySize = ptrtoint %s2* %entrySizePtr to i64
  %allocSize = mul i64 %entrySize, %size
  %bytes = bitcast %s2* %elements to i8*
  %vec2 = call %v2 @v2.new(i64 %size)
  %elements2 = extractvalue %v2 %vec2, 0
  %bytes2 = bitcast %s2* %elements2 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* %bytes2, i8* %bytes, i64 %allocSize, i32 8, i1 0)
  ret %v2 %vec2
}

; Get a new vec object that starts at the index'th element of the existing vector, and has size size.
; If the specified size is greater than the remaining size, then the remaining size is used.
define %v2 @v2.slice(%v2 %vec, i64 %index, i64 %size) {
  ; Check if size greater than remaining size
  %currSize = extractvalue %v2 %vec, 1
  %remSize = sub i64 %currSize, %index
  %sgtr = icmp ugt i64 %size, %remSize
  %finSize = select i1 %sgtr, i64 %remSize, i64 %size
  
  %elements = extractvalue %v2 %vec, 0
  %newElements = getelementptr %s2, %s2* %elements, i64 %index
  %1 = insertvalue %v2 undef, %s2* %newElements, 0
  %2 = insertvalue %v2 %1, i64 %finSize, 1
  
  ret %v2 %2
}

; Initialize and return a new builder, with the given initial capacity.
define %v2.bld @v2.bld.new(i64 %capacity, %work_t* %cur.work, i32 %fixedSize) {
  %elemSizePtr = getelementptr %s2, %s2* null, i32 1
  %elemSize = ptrtoint %s2* %elemSizePtr to i64
  %newVb = call i8* @weld_rt_new_vb(i64 %elemSize, i64 %capacity, i32 %fixedSize)
  call void @v2.bld.newPieceInit(%v2.bld %newVb, %work_t* %cur.work)
  ret %v2.bld %newVb
}

define void @v2.bld.newPieceInit(%v2.bld %bldPtr, %work_t* %cur.work) {
  call void @weld_rt_new_vb_piece(i8* %bldPtr, %work_t* %cur.work, i32 1)
  ret void
}

define void @v2.bld.newPiece(%v2.bld %bldPtr, %work_t* %cur.work) {
  call void @weld_rt_new_vb_piece(i8* %bldPtr, %work_t* %cur.work, i32 0)
  ret void
}

; Append a value into a builder, growing its space if needed.
define %v2.bld @v2.bld.merge(%v2.bld %bldPtr, %s2 %value, i32 %myId) {
entry:
  %curPiecePtr = call %vb.vp* @weld_rt_cur_vb_piece(i8* %bldPtr, i32 %myId)
  %bytesPtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 0
  %sizePtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 1
  %capacityPtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 2
  %size = load i64, i64* %sizePtr
  %capacity = load i64, i64* %capacityPtr
  %full = icmp eq i64 %size, %capacity
  br i1 %full, label %onFull, label %finish
  
onFull:
  %newCapacity = mul i64 %capacity, 2
  %elemSizePtr = getelementptr %s2, %s2* null, i32 1
  %elemSize = ptrtoint %s2* %elemSizePtr to i64
  %bytes = load i8*, i8** %bytesPtr
  %allocSize = mul i64 %elemSize, %newCapacity
  %runId = call i64 @weld_rt_get_run_id()
  %newBytes = call i8* @weld_run_realloc(i64 %runId, i8* %bytes, i64 %allocSize)
  store i8* %newBytes, i8** %bytesPtr
  store i64 %newCapacity, i64* %capacityPtr
  br label %finish
  
finish:
  %bytes1 = load i8*, i8** %bytesPtr
  %elements = bitcast i8* %bytes1 to %s2*
  %insertPtr = getelementptr %s2, %s2* %elements, i64 %size
  store %s2 %value, %s2* %insertPtr
  %newSize = add i64 %size, 1
  store i64 %newSize, i64* %sizePtr
  ret %v2.bld %bldPtr
}

; Complete building a vector, trimming any extra space left while growing it.
define %v2 @v2.bld.result(%v2.bld %bldPtr) {
  %out = call %vb.out @weld_rt_result_vb(i8* %bldPtr)
  %bytes = extractvalue %vb.out %out, 0
  %size = extractvalue %vb.out %out, 1
  %elems = bitcast i8* %bytes to %s2*
  %1 = insertvalue %v2 undef, %s2* %elems, 0
  %2 = insertvalue %v2 %1, i64 %size, 1
  ret %v2 %2
}

; Get the length of a vector.
define i64 @v2.size(%v2 %vec) alwaysinline {
  %size = extractvalue %v2 %vec, 1
  ret i64 %size
}

; Get a pointer to the index'th element.
define %s2* @v2.at(%v2 %vec, i64 %index) alwaysinline {
  %elements = extractvalue %v2 %vec, 0
  %ptr = getelementptr %s2, %s2* %elements, i64 %index
  ret %s2* %ptr
}


; Get the length of a VecBuilder.
define i64 @v2.bld.size(%v2.bld nocapture %bldPtr, i32 %myId) readonly nounwind norecurse {
  %curPiecePtr = call %vb.vp* @weld_rt_cur_vb_piece(i8* %bldPtr, i32 %myId)
  %sizePtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 1
  %size = load i64, i64* %sizePtr
  ret i64 %size
}

; Get a pointer to the index'th element of a VecBuilder.
define %s2* @v2.bld.at(%v2.bld nocapture %bldPtr, i64 %index, i32 %myId) readonly nounwind norecurse {
  %curPiecePtr = call %vb.vp* @weld_rt_cur_vb_piece(i8* %bldPtr, i32 %myId)
  %bytesPtr = getelementptr inbounds %vb.vp, %vb.vp* %curPiecePtr, i32 0, i32 0
  %bytes = load i8*, i8** %bytesPtr
  %elements = bitcast i8* %bytes to %s2*
  %ptr = getelementptr %s2, %s2* %elements, i64 %index
  ret %s2* %ptr
}

; Template for a dictionary and its helper functions. Uses linear probing.
;
; Parameters:
; - NAME: name to give generated type, without % or @ prefix
; - KEY: LLVM type of key (e.g. i32 or %MyStruct)
; - VALUE: LLVM type of value (e.g. i32 or %MyStruct)
; - KEY_PREFIX: prefix for helper functions of key (e.g. @i32 or @MyStruct)
; - KV_STRUCT: name of struct holding {KEY, VALUE} (should be generated outside)
; - KV_VEC: name of vector of KV_STRUCTs (should be generated outside)
; - KV_VEC_PREFIX: prefix for helper functions of KV_VEC

; isFilled, key, value (packed so that C code can easily store it in a byte array without
; considering padding)
%d0.entry = type <{ i8, %s0, %s1 }>
%d0.slot = type %d0.entry*                ; handle to an entry in the API
%d0 = type i8*  ; entries, size, capacity

; Initialize and return a new dictionary with the given initial capacity.
; The capacity must be a power of 2.
define %d0 @d0.new(i64 %capacity) {
  %keySizePtr = getelementptr %s0, %s0* null, i32 1
  %keySize = ptrtoint %s0* %keySizePtr to i32
  %valSizePtr = getelementptr %s1, %s1* null, i32 1
  %valSize = ptrtoint %s1* %valSizePtr to i32
  %dict = call i8* @weld_rt_dict_new(i32 %keySize, i32 (i8*, i8*)* @s0.eq_on_pointers,
  i32 %valSize, i32 %valSize, i64 100000000000, i64 %capacity)
  ret %d0 %dict
}

; Free dictionary
define void @d0.free(%d0 %dict) {
  call void @weld_rt_dict_free(i8* %dict)
  ret void
}

; Get the size of a dictionary.
define i64 @d0.size(%d0 %dict) {
  %size = call i64 @weld_rt_dict_get_size(i8* %dict)
  ret i64 %size
}

; Check whether a slot is filled.
define i1 @d0.slot.filled(%d0.slot %slot) {
  %filledPtr = getelementptr %d0.entry, %d0.slot %slot, i64 0, i32 0
  %filled_i8 = load i8, i8* %filledPtr
  %filled = trunc i8 %filled_i8 to i1
  ret i1 %filled
}

; Get the key for a slot (only valid if filled).
define %s0 @d0.slot.key(%d0.slot %slot) {
  %keyPtr = getelementptr %d0.entry, %d0.slot %slot, i64 0, i32 1
  %key = load %s0, %s0* %keyPtr
  ret %s0 %key
}

; Get the value for a slot (only valid if filled).
define %s1 @d0.slot.value(%d0.slot %slot) {
  %valuePtr = getelementptr %d0.entry, %d0.slot %slot, i64 0, i32 2
  %value = load %s1, %s1* %valuePtr
  ret %s1 %value
}

; Look up the given key, returning a slot for it. The slot functions may be
; used to tell whether the entry is filled, get its value, etc, and the put()
; function may be used to put a new value into the slot.
define %d0.slot @d0.lookup(%d0 %dict, %s0 %key) {
  %keyPtr = alloca %s0
  store %s0 %key, %s0* %keyPtr
  %finalizedHash = call i32 @s0.hash(%s0 %key)
  %keyPtrRaw = bitcast %s0* %keyPtr to i8*
  %slotRaw = call i8* @weld_rt_dict_lookup(i8* %dict, i32 %finalizedHash, i8* %keyPtrRaw)
  %slot = bitcast i8* %slotRaw to %d0.slot
  ret %d0.slot %slot
}

; Set the key and value at a given slot. The slot is assumed to have been
; returned by a lookup() on the same key provided here, and any old value for
; the key will be replaced. A new %d0 is returned reusing the same storage.
define %d0 @d0.put(%d0 %dict, %d0.slot %slot, %s0 %key, %s1 %value) {
  %keyPtr = getelementptr %d0.entry, %d0.entry* %slot, i64 0, i32 1
  %valuePtr = getelementptr %d0.entry, %d0.entry* %slot, i64 0, i32 2
  store %s0 %key, %s0* %keyPtr
  store %s1 %value, %s1* %valuePtr
  %slotRaw = bitcast %d0.slot %slot to i8*
  call void @weld_rt_dict_put(i8* %dict, i8* %slotRaw)
  ret %d0 %dict
}

; Get the entries of a dictionary as a vector.
define %v2 @d0.tovec(%d0 %dict) {
  %valOffsetPtr = getelementptr %s2, %s2* null, i32 0, i32 1
  %valOffset = ptrtoint %s1* %valOffsetPtr to i32
  %structSizePtr = getelementptr %s2, %s2* null, i32 1
  %structSize = ptrtoint %s2* %structSizePtr to i32
  %arrRaw = call i8* @weld_rt_dict_to_array(i8* %dict, i32 %valOffset, i32 %structSize)
  %arr = bitcast i8* %arrRaw to %s2*
  %size = call i64 @weld_rt_dict_get_size(i8* %dict)
  %1 = insertvalue %v2 undef, %s2* %arr, 0
  %2 = insertvalue %v2 %1, i64 %size, 1
  ret %v2 %2
}

define i32 @s0.hash(%s0 %value) {
  %p.p0 = extractvalue %s0 %value, 0
  %p.p1 = call i32 @i32.hash(i32 %p.p0)
  %p.p2 = call i32 @hash_combine(i32 0, i32 %p.p1)
  %p.p3 = extractvalue %s0 %value, 1
  %p.p4 = call i32 @i32.hash(i32 %p.p3)
  %p.p5 = call i32 @hash_combine(i32 %p.p2, i32 %p.p4)
  ret i32 %p.p5
}

define i1 @i32.eq(i32 %a, i32 %b) alwaysinline {
                      %1 = icmp eq i32 %a, %b
                      ret i1 %1
                    }
define i32 @i32.eq_on_pointers(i8* %a, i8* %b) {
  %aTypedPtr = bitcast i8* %a to i32*
  %bTypedPtr = bitcast i8* %b to i32*
  %aTyped = load i32, i32* %aTypedPtr
  %bTyped = load i32, i32* %bTypedPtr
  %resultBool = call i1 @i32.eq(i32 %aTyped, i32 %bTyped)
  %result = zext i1 %resultBool to i32
  ret i32 %result
}

define i1 @s0.eq(%s0 %a, %s0 %b) {
  %p.p6 = extractvalue %s0 %a , 0
  %p.p7 = extractvalue %s0 %b, 0
  %p.p8 = call i1 @i32.eq(i32 %p.p6, i32 %p.p7)
  br i1 %p.p8, label %l1, label %l0
l0:
  ret i1 0
l1:
  %p.p9 = extractvalue %s0 %a , 1
  %p.p10 = extractvalue %s0 %b, 1
  %p.p11 = call i1 @i32.eq(i32 %p.p9, i32 %p.p10)
  br i1 %p.p11, label %l3, label %l2
l2:
  ret i1 0
l3:
  ret i1 1
}

define i32 @s0.eq_on_pointers(i8* %a, i8* %b) {
  %aTypedPtr = bitcast i8* %a to %s0*
  %bTypedPtr = bitcast i8* %b to %s0*
  %aTyped = load %s0, %s0* %aTypedPtr
  %bTyped = load %s0, %s0* %bTypedPtr
  %resultBool = call i1 @s0.eq(%s0 %aTyped, %s0 %bTyped)
  %result = zext i1 %resultBool to i32
  ret i32 %result
}

; Template for a dictmerger and its helper functions.
;
; Parameters:
; - NAME: name to give generated type, without % or @ prefix
; - KEY: LLVM type of key (e.g. i32 or %MyStruct)
; - VALUE: LLVM type of value (e.g. i32 or %MyStruct)
; - KV_STRUCT: name of struct holding {KEY, VALUE} (should be generated outside)
;
; In addition, the function d0.bld.merge_op(%s1, %s1) is expected to be
; defined, implementing the operation needed to merge two values.

%d0.bld = type %d0

; Initialize and return a new dictionary with the given initial capacity.
; The capacity must be a power of 2.
define %d0.bld @d0.bld.new(i64 %capacity) {
  %bld = call %d0 @d0.new(i64 %capacity)
  ret %d0.bld %bld
}

; Append a value into a builder, growing its space if needed.
define %d0.bld @d0.bld.merge(%d0.bld %bld, %s2 %keyValue) {
entry:
  %key = extractvalue %s2 %keyValue, 0
  %value = extractvalue %s2 %keyValue, 1
  %slot = call %d0.slot @d0.lookup(%d0 %bld, %s0 %key)
  %filled = call i1 @d0.slot.filled(%d0.slot %slot)
  br i1 %filled, label %onFilled, label %onEmpty
  
onFilled:
  %oldValue = call %s1 @d0.slot.value(%d0.slot %slot)
  %newValue = call %s1 @d0.bld.merge_op(%s1 %oldValue, %s1 %value)
  call %d0 @d0.put(%d0 %bld, %d0.slot %slot, %s0 %key, %s1 %newValue)
  br label %done
  
onEmpty:
  call %d0 @d0.put(%d0 %bld, %d0.slot %slot, %s0 %key, %s1 %value)
  br label %done
  
done:
  ret %d0.bld %bld
}

; Complete building a dictionary
define %d0 @d0.bld.result(%d0.bld %bld) {
start:
  br label %entry
entry:
  %nextSlotRaw = call i8* @weld_rt_dict_finalize_next_local_slot(i8* %bld)
  %nextSlotLong = ptrtoint i8* %nextSlotRaw to i64
  %isNull = icmp eq i64 %nextSlotLong, 0
  br i1 %isNull, label %done, label %body
body:
  %nextSlot = bitcast i8* %nextSlotRaw to %d0.slot
  %key = call %s0 @d0.slot.key(%d0.slot %nextSlot)
  %localValue = call %s1 @d0.slot.value(%d0.slot %nextSlot)
  %globalSlotRaw = call i8* @weld_rt_dict_finalize_global_slot_for_local(i8* %bld, i8* %nextSlotRaw)
  %globalSlot = bitcast i8* %globalSlotRaw to %d0.slot
  %filled = call i1 @d0.slot.filled(%d0.slot %globalSlot)
  br i1 %filled, label %onFilled, label %onEmpty
onFilled:
  %globalValue = call %s1 @d0.slot.value(%d0.slot %globalSlot)
  %newValue = call %s1 @d0.bld.merge_op(%s1 %localValue, %s1 %globalValue)
  call %d0 @d0.put(%d0 %bld, %d0.slot %globalSlot, %s0 %key, %s1 %newValue)
  br label %entry
onEmpty:
  call %d0 @d0.put(%d0 %bld, %d0.slot %globalSlot, %s0 %key, %s1 %localValue)
  br label %entry
done:
  ret %d0 %bld
}

define %s1 @d0.bld.merge_op(%s1 %a, %s1 %b) alwaysinline {
  %t1 = extractvalue %s1 %a, 0
  %t2 = extractvalue %s1 %b, 0
  %t4 = fadd float %t1, %t2
  %t3 = insertvalue %s1 undef, float %t4, 0
  %t5 = extractvalue %s1 %a, 1
  %t6 = extractvalue %s1 %b, 1
  %t8 = fadd float %t5, %t6
  %t7 = insertvalue %s1 %t3, float %t8, 1
  %t9 = extractvalue %s1 %a, 2
  %t10 = extractvalue %s1 %b, 2
  %t12 = fadd float %t9, %t10
  %t11 = insertvalue %s1 %t7, float %t12, 2
  %t13 = extractvalue %s1 %a, 3
  %t14 = extractvalue %s1 %b, 3
  %t16 = fadd float %t13, %t14
  %t15 = insertvalue %s1 %t11, float %t16, 3
  %t17 = extractvalue %s1 %a, 4
  %t18 = extractvalue %s1 %b, 4
  %t20 = fadd float %t17, %t18
  %t19 = insertvalue %s1 %t15, float %t20, 4
  %t21 = extractvalue %s1 %a, 5
  %t22 = extractvalue %s1 %b, 5
  %t24 = add i32 %t21, %t22
  %t23 = insertvalue %s1 %t19, i32 %t24, 5
  ret %s1 %t23
}

%s3 = type { i32, i32, float, float, float, i32, float }
%s4 = type { %d0.bld, %v0, %v0, %v1, %v0, %v1, %v1, %v0 }
%s5 = type { %d0.bld }
%s6 = type { %v0, %v0, %v1, %v0, %v1, %v1, %v0 }
%s7 = type { %v1, %v1, %v0, %v0, %v0, %v1, %v0 }

; BODY:

define void @f2(%d0.bld %fn0_tmp.in, %work_t* %cur.work, i32 %cur.tid) {
fn.entry:
  %fn0_tmp = alloca %d0.bld
  %fn2_tmp = alloca %d0
  %fn2_tmp.1 = alloca %v2
  store %d0.bld %fn0_tmp.in, %d0.bld* %fn0_tmp
  br label %b.b0
b.b0:
  ; fn2_tmp = result(fn0_tmp)
  %t.t0 = load %d0.bld, %d0.bld* %fn0_tmp
  %t.t1 = call %d0 @d0.bld.result(%d0.bld %t.t0)
  store %d0 %t.t1, %d0* %fn2_tmp
  ; fn2_tmp#1 = toVec(fn2_tmp)
  %t.t2 = load %d0, %d0* %fn2_tmp
  %t.t3 = call %v2 @d0.tovec(%d0 %t.t2)
  store %v2 %t.t3, %v2* %fn2_tmp.1
  ; return fn2_tmp#1
  %t.t4 = load %v2, %v2* %fn2_tmp.1
  %t.t5 = getelementptr %v2, %v2* null, i32 1
  %t.t6 = ptrtoint %v2* %t.t5 to i64
  %t.t9 = call i64 @weld_rt_get_run_id()
  %t.t7 = call i8* @weld_run_malloc(i64 %t.t9, i64 %t.t6)
  %t.t8 = bitcast i8* %t.t7 to %v2*
  store %v2 %t.t4, %v2* %t.t8
  call void @weld_rt_set_result(i8* %t.t7)
  br label %body.end
body.end:
  ret void
}

define void @f1(%d0.bld %fn0_tmp.in, %v0 %l_discount.in, %v0 %l_ep.in, %v1 %l_linestatus.in, %v0 %l_quantity.in, %v1 %l_returnflag.in, %v1 %l_shipdate.in, %v0 %l_tax.in, %work_t* %cur.work, i64 %lower.idx, i64 %upper.idx, i32 %cur.tid) {
fn.entry:
  %fn0_tmp = alloca %d0.bld
  %l_discount = alloca %v0
  %l_ep = alloca %v0
  %l_linestatus = alloca %v1
  %l_quantity = alloca %v0
  %l_returnflag = alloca %v1
  %l_shipdate = alloca %v1
  %l_tax = alloca %v0
  %b.3 = alloca %d0.bld
  %fn1_tmp = alloca i32
  %fn1_tmp.1 = alloca i32
  %fn1_tmp.2 = alloca i1
  %fn1_tmp.3 = alloca float
  %fn1_tmp.4 = alloca float
  %fn1_tmp.5 = alloca float
  %fn1_tmp.6 = alloca float
  %fn1_tmp.7 = alloca float
  %fn1_tmp.8 = alloca i32
  %fn1_tmp.9 = alloca i32
  %fn1_tmp.10 = alloca %s0
  %fn1_tmp.11 = alloca float
  %fn1_tmp.12 = alloca float
  %fn1_tmp.13 = alloca float
  %fn1_tmp.14 = alloca float
  %fn1_tmp.15 = alloca i32
  %fn1_tmp.16 = alloca %s1
  %fn1_tmp.17 = alloca %s2
  %i.3 = alloca i64
  %sum_disc_price = alloca float
  %x = alloca %s3
  %cur.idx = alloca i64
  store %d0.bld %fn0_tmp.in, %d0.bld* %fn0_tmp
  store %v0 %l_discount.in, %v0* %l_discount
  store %v0 %l_ep.in, %v0* %l_ep
  store %v1 %l_linestatus.in, %v1* %l_linestatus
  store %v0 %l_quantity.in, %v0* %l_quantity
  store %v1 %l_returnflag.in, %v1* %l_returnflag
  store %v1 %l_shipdate.in, %v1* %l_shipdate
  store %v0 %l_tax.in, %v0* %l_tax
  store %d0.bld %fn0_tmp.in, %d0.bld* %b.3
  store i64 %lower.idx, i64* %cur.idx
  br label %loop.start
loop.start:
  %t.t0 = load i64, i64* %cur.idx
  %t.t1 = icmp ult i64 %t.t0, %upper.idx
  br i1 %t.t1, label %loop.body, label %loop.end
loop.body:
  %t.t2 = load %v1, %v1* %l_returnflag
  %t.t3 = call i32* @v1.at(%v1 %t.t2, i64 %t.t0)
  %t.t4 = load i32, i32* %t.t3
  %t.t5 = insertvalue %s3 undef, i32 %t.t4, 0
  %t.t6 = load %v1, %v1* %l_linestatus
  %t.t7 = call i32* @v1.at(%v1 %t.t6, i64 %t.t0)
  %t.t8 = load i32, i32* %t.t7
  %t.t9 = insertvalue %s3 %t.t5, i32 %t.t8, 1
  %t.t10 = load %v0, %v0* %l_quantity
  %t.t11 = call float* @v0.at(%v0 %t.t10, i64 %t.t0)
  %t.t12 = load float, float* %t.t11
  %t.t13 = insertvalue %s3 %t.t9, float %t.t12, 2
  %t.t14 = load %v0, %v0* %l_ep
  %t.t15 = call float* @v0.at(%v0 %t.t14, i64 %t.t0)
  %t.t16 = load float, float* %t.t15
  %t.t17 = insertvalue %s3 %t.t13, float %t.t16, 3
  %t.t18 = load %v0, %v0* %l_discount
  %t.t19 = call float* @v0.at(%v0 %t.t18, i64 %t.t0)
  %t.t20 = load float, float* %t.t19
  %t.t21 = insertvalue %s3 %t.t17, float %t.t20, 4
  %t.t22 = load %v1, %v1* %l_shipdate
  %t.t23 = call i32* @v1.at(%v1 %t.t22, i64 %t.t0)
  %t.t24 = load i32, i32* %t.t23
  %t.t25 = insertvalue %s3 %t.t21, i32 %t.t24, 5
  %t.t26 = load %v0, %v0* %l_tax
  %t.t27 = call float* @v0.at(%v0 %t.t26, i64 %t.t0)
  %t.t28 = load float, float* %t.t27
  %t.t29 = insertvalue %s3 %t.t25, float %t.t28, 6
  store %s3 %t.t29, %s3* %x
  store i64 %t.t0, i64* %i.3
  br label %b.b0
b.b0:
  ; fn1_tmp = x.$5
  %t.t30 = getelementptr inbounds %s3, %s3* %x, i32 0, i32 5
  %t.t31 = load i32, i32* %t.t30
  store i32 %t.t31, i32* %fn1_tmp
  ; fn1_tmp#1 = 19980901
  store i32 19980901, i32* %fn1_tmp.1
  ; fn1_tmp#2 = <= fn1_tmp fn1_tmp#1
  %t.t32 = load i32, i32* %fn1_tmp
  %t.t33 = load i32, i32* %fn1_tmp.1
  %t.t34 = icmp sle i32 %t.t32, %t.t33
  store i1 %t.t34, i1* %fn1_tmp.2
  ; branch fn1_tmp#2 B1 B2
  %t.t35 = load i1, i1* %fn1_tmp.2
  br i1 %t.t35, label %b.b1, label %b.b2
b.b1:
  ; fn1_tmp#3 = x.$3
  %t.t36 = getelementptr inbounds %s3, %s3* %x, i32 0, i32 3
  %t.t37 = load float, float* %t.t36
  store float %t.t37, float* %fn1_tmp.3
  ; fn1_tmp#4 = 1.0F
  store float 1.000000000000000000000000000000e0, float* %fn1_tmp.4
  ; fn1_tmp#5 = x.$4
  %t.t38 = getelementptr inbounds %s3, %s3* %x, i32 0, i32 4
  %t.t39 = load float, float* %t.t38
  store float %t.t39, float* %fn1_tmp.5
  ; fn1_tmp#6 = - fn1_tmp#4 fn1_tmp#5
  %t.t40 = load float, float* %fn1_tmp.4
  %t.t41 = load float, float* %fn1_tmp.5
  %t.t42 = fsub float %t.t40, %t.t41
  store float %t.t42, float* %fn1_tmp.6
  ; fn1_tmp#7 = * fn1_tmp#3 fn1_tmp#6
  %t.t43 = load float, float* %fn1_tmp.3
  %t.t44 = load float, float* %fn1_tmp.6
  %t.t45 = fmul float %t.t43, %t.t44
  store float %t.t45, float* %fn1_tmp.7
  ; sum_disc_price = fn1_tmp#7
  %t.t46 = load float, float* %fn1_tmp.7
  store float %t.t46, float* %sum_disc_price
  ; fn1_tmp#8 = x.$0
  %t.t47 = getelementptr inbounds %s3, %s3* %x, i32 0, i32 0
  %t.t48 = load i32, i32* %t.t47
  store i32 %t.t48, i32* %fn1_tmp.8
  ; fn1_tmp#9 = x.$1
  %t.t49 = getelementptr inbounds %s3, %s3* %x, i32 0, i32 1
  %t.t50 = load i32, i32* %t.t49
  store i32 %t.t50, i32* %fn1_tmp.9
  ; fn1_tmp#10 = {fn1_tmp#8,fn1_tmp#9}
  %t.t51 = load i32, i32* %fn1_tmp.8
  %t.t52 = getelementptr inbounds %s0, %s0* %fn1_tmp.10, i32 0, i32 0
  store i32 %t.t51, i32* %t.t52
  %t.t53 = load i32, i32* %fn1_tmp.9
  %t.t54 = getelementptr inbounds %s0, %s0* %fn1_tmp.10, i32 0, i32 1
  store i32 %t.t53, i32* %t.t54
  ; fn1_tmp#11 = x.$2
  %t.t55 = getelementptr inbounds %s3, %s3* %x, i32 0, i32 2
  %t.t56 = load float, float* %t.t55
  store float %t.t56, float* %fn1_tmp.11
  ; fn1_tmp#12 = x.$6
  %t.t57 = getelementptr inbounds %s3, %s3* %x, i32 0, i32 6
  %t.t58 = load float, float* %t.t57
  store float %t.t58, float* %fn1_tmp.12
  ; fn1_tmp#13 = + fn1_tmp#4 fn1_tmp#12
  %t.t59 = load float, float* %fn1_tmp.4
  %t.t60 = load float, float* %fn1_tmp.12
  %t.t61 = fadd float %t.t59, %t.t60
  store float %t.t61, float* %fn1_tmp.13
  ; fn1_tmp#14 = * sum_disc_price fn1_tmp#13
  %t.t62 = load float, float* %sum_disc_price
  %t.t63 = load float, float* %fn1_tmp.13
  %t.t64 = fmul float %t.t62, %t.t63
  store float %t.t64, float* %fn1_tmp.14
  ; fn1_tmp#15 = 1
  store i32 1, i32* %fn1_tmp.15
  ; fn1_tmp#16 = {fn1_tmp#11,fn1_tmp#3,sum_disc_price,fn1_tmp#14,fn1_tmp#5,fn1_tmp#15}
  %t.t65 = load float, float* %fn1_tmp.11
  %t.t66 = getelementptr inbounds %s1, %s1* %fn1_tmp.16, i32 0, i32 0
  store float %t.t65, float* %t.t66
  %t.t67 = load float, float* %fn1_tmp.3
  %t.t68 = getelementptr inbounds %s1, %s1* %fn1_tmp.16, i32 0, i32 1
  store float %t.t67, float* %t.t68
  %t.t69 = load float, float* %sum_disc_price
  %t.t70 = getelementptr inbounds %s1, %s1* %fn1_tmp.16, i32 0, i32 2
  store float %t.t69, float* %t.t70
  %t.t71 = load float, float* %fn1_tmp.14
  %t.t72 = getelementptr inbounds %s1, %s1* %fn1_tmp.16, i32 0, i32 3
  store float %t.t71, float* %t.t72
  %t.t73 = load float, float* %fn1_tmp.5
  %t.t74 = getelementptr inbounds %s1, %s1* %fn1_tmp.16, i32 0, i32 4
  store float %t.t73, float* %t.t74
  %t.t75 = load i32, i32* %fn1_tmp.15
  %t.t76 = getelementptr inbounds %s1, %s1* %fn1_tmp.16, i32 0, i32 5
  store i32 %t.t75, i32* %t.t76
  ; fn1_tmp#17 = {fn1_tmp#10,fn1_tmp#16}
  %t.t77 = load %s0, %s0* %fn1_tmp.10
  %t.t78 = getelementptr inbounds %s2, %s2* %fn1_tmp.17, i32 0, i32 0
  store %s0 %t.t77, %s0* %t.t78
  %t.t79 = load %s1, %s1* %fn1_tmp.16
  %t.t80 = getelementptr inbounds %s2, %s2* %fn1_tmp.17, i32 0, i32 1
  store %s1 %t.t79, %s1* %t.t80
  ; merge(b#3, fn1_tmp#17)
  %t.t81 = load %d0.bld, %d0.bld* %b.3
  %t.t82 = load %s2, %s2* %fn1_tmp.17
  call %d0.bld @d0.bld.merge(%d0.bld %t.t81, %s2 %t.t82)
  ; jump B3
  br label %b.b3
b.b2:
  ; jump B3
  br label %b.b3
b.b3:
  ; end
  br label %body.end
body.end:
  br label %loop.terminator
loop.terminator:
  %t.t83 = load i64, i64* %cur.idx
  %t.t84 = add nsw nuw i64 %t.t83, 1
  store i64 %t.t84, i64* %cur.idx
  br label %loop.start
loop.end:
  ret void
}

define void @f1_wrapper(%d0.bld %fn0_tmp, %v0 %l_discount, %v0 %l_ep, %v1 %l_linestatus, %v0 %l_quantity, %v1 %l_returnflag, %v1 %l_shipdate, %v0 %l_tax, %work_t* %cur.work, i32 %cur.tid) {
fn.entry:
  %fn0_tmp.ptr = alloca %d0.bld
  %l_discount.ptr = alloca %v0
  %l_ep.ptr = alloca %v0
  %l_linestatus.ptr = alloca %v1
  %l_quantity.ptr = alloca %v0
  %l_returnflag.ptr = alloca %v1
  %l_shipdate.ptr = alloca %v1
  %l_tax.ptr = alloca %v0
  store %d0.bld %fn0_tmp, %d0.bld* %fn0_tmp.ptr
  store %v0 %l_discount, %v0* %l_discount.ptr
  store %v0 %l_ep, %v0* %l_ep.ptr
  store %v1 %l_linestatus, %v1* %l_linestatus.ptr
  store %v0 %l_quantity, %v0* %l_quantity.ptr
  store %v1 %l_returnflag, %v1* %l_returnflag.ptr
  store %v1 %l_shipdate, %v1* %l_shipdate.ptr
  store %v0 %l_tax, %v0* %l_tax.ptr
  %t.t0 = call i64 @v1.size(%v1 %l_returnflag)
  %t.t1 = call i64 @v1.size(%v1 %l_returnflag)
  %t.t2 = sub i64 %t.t0, 1
  %t.t3 = mul i64 1, %t.t2
  %t.t4 = add i64 %t.t3, 0
  %t.t5 = icmp slt i64 %t.t4, %t.t1
  br i1 %t.t5, label %t.t6, label %fn.boundcheckfailed
t.t6:
  %t.t7 = call i64 @v1.size(%v1 %l_linestatus)
  %t.t8 = sub i64 %t.t0, 1
  %t.t9 = mul i64 1, %t.t8
  %t.t10 = add i64 %t.t9, 0
  %t.t11 = icmp slt i64 %t.t10, %t.t7
  br i1 %t.t11, label %t.t12, label %fn.boundcheckfailed
t.t12:
  %t.t13 = call i64 @v0.size(%v0 %l_quantity)
  %t.t14 = sub i64 %t.t0, 1
  %t.t15 = mul i64 1, %t.t14
  %t.t16 = add i64 %t.t15, 0
  %t.t17 = icmp slt i64 %t.t16, %t.t13
  br i1 %t.t17, label %t.t18, label %fn.boundcheckfailed
t.t18:
  %t.t19 = call i64 @v0.size(%v0 %l_ep)
  %t.t20 = sub i64 %t.t0, 1
  %t.t21 = mul i64 1, %t.t20
  %t.t22 = add i64 %t.t21, 0
  %t.t23 = icmp slt i64 %t.t22, %t.t19
  br i1 %t.t23, label %t.t24, label %fn.boundcheckfailed
t.t24:
  %t.t25 = call i64 @v0.size(%v0 %l_discount)
  %t.t26 = sub i64 %t.t0, 1
  %t.t27 = mul i64 1, %t.t26
  %t.t28 = add i64 %t.t27, 0
  %t.t29 = icmp slt i64 %t.t28, %t.t25
  br i1 %t.t29, label %t.t30, label %fn.boundcheckfailed
t.t30:
  %t.t31 = call i64 @v1.size(%v1 %l_shipdate)
  %t.t32 = sub i64 %t.t0, 1
  %t.t33 = mul i64 1, %t.t32
  %t.t34 = add i64 %t.t33, 0
  %t.t35 = icmp slt i64 %t.t34, %t.t31
  br i1 %t.t35, label %t.t36, label %fn.boundcheckfailed
t.t36:
  %t.t37 = call i64 @v0.size(%v0 %l_tax)
  %t.t38 = sub i64 %t.t0, 1
  %t.t39 = mul i64 1, %t.t38
  %t.t40 = add i64 %t.t39, 0
  %t.t41 = icmp slt i64 %t.t40, %t.t37
  br i1 %t.t41, label %t.t42, label %fn.boundcheckfailed
t.t42:
  br label %fn.boundcheckpassed
fn.boundcheckfailed:
  %t.t43 = call i64 @weld_rt_get_run_id()
  call void @weld_run_set_errno(i64 %t.t43, i64 5)
  call void @weld_rt_abort_thread()
  ; Unreachable!
  br label %fn.end
fn.boundcheckpassed:
  %t.t44 = icmp ule i64 %t.t0, 16384
  br i1 %t.t44, label %for.ser, label %for.par
for.ser:
  call void @f1(%d0.bld %fn0_tmp, %v0 %l_discount, %v0 %l_ep, %v1 %l_linestatus, %v0 %l_quantity, %v1 %l_returnflag, %v1 %l_shipdate, %v0 %l_tax, %work_t* %cur.work, i64 0, i64 %t.t0, i32 %cur.tid)
  call void @f2(%d0.bld %fn0_tmp, %work_t* %cur.work, i32 %cur.tid)
  br label %fn.end
for.par:
  %fn0_tmp.ab = load %d0.bld, %d0.bld* %fn0_tmp.ptr
  %l_discount.ab = load %v0, %v0* %l_discount.ptr
  %l_ep.ab = load %v0, %v0* %l_ep.ptr
  %l_linestatus.ab = load %v1, %v1* %l_linestatus.ptr
  %l_quantity.ab = load %v0, %v0* %l_quantity.ptr
  %l_returnflag.ab = load %v1, %v1* %l_returnflag.ptr
  %l_shipdate.ab = load %v1, %v1* %l_shipdate.ptr
  %l_tax.ab = load %v0, %v0* %l_tax.ptr
  %fn0_tmp.ac = load %d0.bld, %d0.bld* %fn0_tmp.ptr
  %t.t45 = insertvalue %s4 undef, %d0.bld %fn0_tmp.ab, 0
  %t.t46 = insertvalue %s4 %t.t45, %v0 %l_discount.ab, 1
  %t.t47 = insertvalue %s4 %t.t46, %v0 %l_ep.ab, 2
  %t.t48 = insertvalue %s4 %t.t47, %v1 %l_linestatus.ab, 3
  %t.t49 = insertvalue %s4 %t.t48, %v0 %l_quantity.ab, 4
  %t.t50 = insertvalue %s4 %t.t49, %v1 %l_returnflag.ab, 5
  %t.t51 = insertvalue %s4 %t.t50, %v1 %l_shipdate.ab, 6
  %t.t52 = insertvalue %s4 %t.t51, %v0 %l_tax.ab, 7
  %t.t53 = getelementptr inbounds %s4, %s4* null, i32 1
  %t.t54 = ptrtoint %s4* %t.t53 to i64
  %t.t55 = call i8* @malloc(i64 %t.t54)
  %t.t56 = bitcast i8* %t.t55 to %s4*
  store %s4 %t.t52, %s4* %t.t56
  %t.t57 = insertvalue %s5 undef, %d0.bld %fn0_tmp.ac, 0
  %t.t58 = getelementptr inbounds %s5, %s5* null, i32 1
  %t.t59 = ptrtoint %s5* %t.t58 to i64
  %t.t60 = call i8* @malloc(i64 %t.t59)
  %t.t61 = bitcast i8* %t.t60 to %s5*
  store %s5 %t.t57, %s5* %t.t61
  call void @weld_rt_start_loop(%work_t* %cur.work, i8* %t.t55, i8* %t.t60, void (%work_t*)* @f1_par, void (%work_t*)* @f2_par, i64 0, i64 %t.t0, i32 16384)
  br label %fn.end
fn.end:
  ret void
}

define void @f1_par(%work_t* %cur.work) {
entry:
  %fn0_tmp = alloca %d0.bld
  %l_discount = alloca %v0
  %l_ep = alloca %v0
  %l_linestatus = alloca %v1
  %l_quantity = alloca %v0
  %l_returnflag = alloca %v1
  %l_shipdate = alloca %v1
  %l_tax = alloca %v0
  %t.t1 = getelementptr inbounds %work_t, %work_t* %cur.work, i32 0, i32 0
  %t.t2 = load i8*, i8** %t.t1
  %t.t0 = bitcast i8* %t.t2 to %s4*
  %t.t3 = getelementptr inbounds %s4, %s4* %t.t0, i32 0, i32 0
  %fn0_tmp.load = load %d0.bld, %d0.bld* %t.t3
  %t.t4 = getelementptr inbounds %s4, %s4* %t.t0, i32 0, i32 1
  %l_discount.load = load %v0, %v0* %t.t4
  %t.t5 = getelementptr inbounds %s4, %s4* %t.t0, i32 0, i32 2
  %l_ep.load = load %v0, %v0* %t.t5
  %t.t6 = getelementptr inbounds %s4, %s4* %t.t0, i32 0, i32 3
  %l_linestatus.load = load %v1, %v1* %t.t6
  %t.t7 = getelementptr inbounds %s4, %s4* %t.t0, i32 0, i32 4
  %l_quantity.load = load %v0, %v0* %t.t7
  %t.t8 = getelementptr inbounds %s4, %s4* %t.t0, i32 0, i32 5
  %l_returnflag.load = load %v1, %v1* %t.t8
  %t.t9 = getelementptr inbounds %s4, %s4* %t.t0, i32 0, i32 6
  %l_shipdate.load = load %v1, %v1* %t.t9
  %t.t10 = getelementptr inbounds %s4, %s4* %t.t0, i32 0, i32 7
  %l_tax.load = load %v0, %v0* %t.t10
  store %d0.bld %fn0_tmp.load, %d0.bld* %fn0_tmp
  store %v0 %l_discount.load, %v0* %l_discount
  store %v0 %l_ep.load, %v0* %l_ep
  store %v1 %l_linestatus.load, %v1* %l_linestatus
  store %v0 %l_quantity.load, %v0* %l_quantity
  store %v1 %l_returnflag.load, %v1* %l_returnflag
  store %v1 %l_shipdate.load, %v1* %l_shipdate
  store %v0 %l_tax.load, %v0* %l_tax
  %cur.tid = call i32 @weld_rt_thread_id()
  %t.t11 = getelementptr %work_t, %work_t* %cur.work, i32 0, i32 1
  %t.t12 = load i64, i64* %t.t11
  %t.t13 = getelementptr %work_t, %work_t* %cur.work, i32 0, i32 2
  %t.t14 = load i64, i64* %t.t13
  %fn0_tmp.arg = load %d0.bld, %d0.bld* %fn0_tmp
  %l_discount.arg = load %v0, %v0* %l_discount
  %l_ep.arg = load %v0, %v0* %l_ep
  %l_linestatus.arg = load %v1, %v1* %l_linestatus
  %l_quantity.arg = load %v0, %v0* %l_quantity
  %l_returnflag.arg = load %v1, %v1* %l_returnflag
  %l_shipdate.arg = load %v1, %v1* %l_shipdate
  %l_tax.arg = load %v0, %v0* %l_tax
  %t.t15 = getelementptr inbounds %work_t, %work_t* %cur.work, i32 0, i32 4
  %t.t16 = load i32, i32* %t.t15
  %t.t17 = trunc i32 %t.t16 to i1
  br i1 %t.t17, label %new_pieces, label %fn_call
new_pieces:
  br label %fn_call
fn_call:
  call void @f1(%d0.bld %fn0_tmp.arg, %v0 %l_discount.arg, %v0 %l_ep.arg, %v1 %l_linestatus.arg, %v0 %l_quantity.arg, %v1 %l_returnflag.arg, %v1 %l_shipdate.arg, %v0 %l_tax.arg, %work_t* %cur.work, i64 %t.t12, i64 %t.t14, i32 %cur.tid)
  ret void
}

define void @f2_par(%work_t* %cur.work) {
entry:
  %fn0_tmp = alloca %d0.bld
  %cur.tid = call i32 @weld_rt_thread_id()
  %t.t1 = getelementptr inbounds %work_t, %work_t* %cur.work, i32 0, i32 0
  %t.t2 = load i8*, i8** %t.t1
  %t.t0 = bitcast i8* %t.t2 to %s5*
  %t.t3 = getelementptr inbounds %s5, %s5* %t.t0, i32 0, i32 0
  %fn0_tmp.load = load %d0.bld, %d0.bld* %t.t3
  store %d0.bld %fn0_tmp.load, %d0.bld* %fn0_tmp
  %fn0_tmp.arg = load %d0.bld, %d0.bld* %fn0_tmp
  %t.t4 = getelementptr inbounds %work_t, %work_t* %cur.work, i32 0, i32 4
  %t.t5 = load i32, i32* %t.t4
  %t.t6 = trunc i32 %t.t5 to i1
  br i1 %t.t6, label %new_pieces, label %fn_call
new_pieces:
  br label %fn_call
fn_call:
  call void @f2(%d0.bld %fn0_tmp.arg, %work_t* %cur.work, i32 %cur.tid)
  ret void
}

define void @f0(%v0 %l_discount.in, %v0 %l_ep.in, %v1 %l_linestatus.in, %v0 %l_quantity.in, %v1 %l_returnflag.in, %v1 %l_shipdate.in, %v0 %l_tax.in, %work_t* %cur.work, i32 %cur.tid) {
fn.entry:
  %l_discount = alloca %v0
  %l_ep = alloca %v0
  %l_linestatus = alloca %v1
  %l_quantity = alloca %v0
  %l_returnflag = alloca %v1
  %l_shipdate = alloca %v1
  %l_tax = alloca %v0
  %fn0_tmp = alloca %d0.bld
  store %v0 %l_discount.in, %v0* %l_discount
  store %v0 %l_ep.in, %v0* %l_ep
  store %v1 %l_linestatus.in, %v1* %l_linestatus
  store %v0 %l_quantity.in, %v0* %l_quantity
  store %v1 %l_returnflag.in, %v1* %l_returnflag
  store %v1 %l_shipdate.in, %v1* %l_shipdate
  store %v0 %l_tax.in, %v0* %l_tax
  br label %b.b0
b.b0:
  ; fn0_tmp = new dictmerger[{i32,i32},{f32,f32,f32,f32,f32,i32},+]()
  %t.t0 = call %d0.bld @d0.bld.new(i64 16)
  store %d0.bld %t.t0, %d0.bld* %fn0_tmp
  ; for [l_returnflag, l_linestatus, l_quantity, l_ep, l_discount, l_shipdate, l_tax, ] fn0_tmp b#3 i#3 x F1 F2 true
  %t.t1 = load %d0.bld, %d0.bld* %fn0_tmp
  %t.t2 = load %v0, %v0* %l_discount
  %t.t3 = load %v0, %v0* %l_ep
  %t.t4 = load %v1, %v1* %l_linestatus
  %t.t5 = load %v0, %v0* %l_quantity
  %t.t6 = load %v1, %v1* %l_returnflag
  %t.t7 = load %v1, %v1* %l_shipdate
  %t.t8 = load %v0, %v0* %l_tax
  call void @f1_wrapper(%d0.bld %t.t1, %v0 %t.t2, %v0 %t.t3, %v1 %t.t4, %v0 %t.t5, %v1 %t.t6, %v1 %t.t7, %v0 %t.t8, %work_t* %cur.work, i32 %cur.tid)
  br label %body.end
body.end:
  ret void
}

define void @f0_par(%work_t* %cur.work) {
  %cur.tid = call i32 @weld_rt_thread_id()
  %t.t1 = getelementptr inbounds %work_t, %work_t* %cur.work, i32 0, i32 0
  %t.t2 = load i8*, i8** %t.t1
  %t.t0 = bitcast i8* %t.t2 to %s6*
  %t.t3 = getelementptr inbounds %s6, %s6* %t.t0, i32 0, i32 0
  %l_discount = load %v0, %v0* %t.t3
  %t.t4 = getelementptr inbounds %s6, %s6* %t.t0, i32 0, i32 1
  %l_ep = load %v0, %v0* %t.t4
  %t.t5 = getelementptr inbounds %s6, %s6* %t.t0, i32 0, i32 2
  %l_linestatus = load %v1, %v1* %t.t5
  %t.t6 = getelementptr inbounds %s6, %s6* %t.t0, i32 0, i32 3
  %l_quantity = load %v0, %v0* %t.t6
  %t.t7 = getelementptr inbounds %s6, %s6* %t.t0, i32 0, i32 4
  %l_returnflag = load %v1, %v1* %t.t7
  %t.t8 = getelementptr inbounds %s6, %s6* %t.t0, i32 0, i32 5
  %l_shipdate = load %v1, %v1* %t.t8
  %t.t9 = getelementptr inbounds %s6, %s6* %t.t0, i32 0, i32 6
  %l_tax = load %v0, %v0* %t.t9
  call void @f0(%v0 %l_discount, %v0 %l_ep, %v1 %l_linestatus, %v0 %l_quantity, %v1 %l_returnflag, %v1 %l_shipdate, %v0 %l_tax, %work_t* %cur.work, i32 %cur.tid)
  ret void
}

define i64 @run(i64 %r.input) {
  %r.inp_typed = inttoptr i64 %r.input to %input_arg_t*
  %r.inp_val = load %input_arg_t, %input_arg_t* %r.inp_typed
  %r.args = extractvalue %input_arg_t %r.inp_val, 0
  %r.nworkers = extractvalue %input_arg_t %r.inp_val, 1
  %r.memlimit = extractvalue %input_arg_t %r.inp_val, 2
  %r.args_typed = inttoptr i64 %r.args to %s7*
  %r.args_val = load %s7, %s7* %r.args_typed
  %l_discount = extractvalue %s7 %r.args_val, 4
  %l_ep = extractvalue %s7 %r.args_val, 3
  %l_linestatus = extractvalue %s7 %r.args_val, 1
  %l_quantity = extractvalue %s7 %r.args_val, 2
  %l_returnflag = extractvalue %s7 %r.args_val, 0
  %l_shipdate = extractvalue %s7 %r.args_val, 5
  %l_tax = extractvalue %s7 %r.args_val, 6
  %t.t0 = insertvalue %s6 undef, %v0 %l_discount, 0
  %t.t1 = insertvalue %s6 %t.t0, %v0 %l_ep, 1
  %t.t2 = insertvalue %s6 %t.t1, %v1 %l_linestatus, 2
  %t.t3 = insertvalue %s6 %t.t2, %v0 %l_quantity, 3
  %t.t4 = insertvalue %s6 %t.t3, %v1 %l_returnflag, 4
  %t.t5 = insertvalue %s6 %t.t4, %v1 %l_shipdate, 5
  %t.t6 = insertvalue %s6 %t.t5, %v0 %l_tax, 6
  %t.t7 = getelementptr inbounds %s6, %s6* null, i32 1
  %t.t8 = ptrtoint %s6* %t.t7 to i64
  %t.t9 = call i8* @malloc(i64 %t.t8)
  %t.t10 = bitcast i8* %t.t9 to %s6*
  store %s6 %t.t6, %s6* %t.t10
  %t.t11 = call i64 @weld_run_begin(void (%work_t*)* @f0_par, i8* %t.t9, i64 %r.memlimit, i32 %r.nworkers)
  %res_ptr = call i8* @weld_run_get_result(i64 %t.t11)
  %res_address = ptrtoint i8* %res_ptr to i64
  %t.t12 = call i64 @weld_run_get_errno(i64 %t.t11)
  %t.t13 = insertvalue %output_arg_t undef, i64 %res_address, 0
  %t.t14 = insertvalue %output_arg_t %t.t13, i64 %t.t11, 1
  %t.t15 = insertvalue %output_arg_t %t.t14, i64 %t.t12, 2
  %t.t16 = getelementptr %output_arg_t, %output_arg_t* null, i32 1
  %t.t17 = ptrtoint %output_arg_t* %t.t16 to i64
  %t.t18 = call i8* @malloc(i64 %t.t17)
  %t.t19 = bitcast i8* %t.t18 to %output_arg_t*
  store %output_arg_t %t.t15, %output_arg_t* %t.t19
  %t.t20 = ptrtoint %output_arg_t* %t.t19 to i64
  ret i64 %t.t20
}

