use NativeCall;

enum GccJitType < VOID VOID-PTR BOOL CHAR SIGNED-CHAR
    UNSIGNED-CHAR SHORT UNSIGNED-SHORT INT UNSIGNED-INT
    LONG UNSIGNED-LONG LONG-LONG UNSIGNED-LONG-LONG
    FLOAT DOUBLE LONG-DOUBLE CONST-CHAR-PTR SIZE-T
    FILE-PTR COMPLEX-FLOAT COMPLEX-DOUBLE COMPLEX-LONG-DOUBLE >;

enum GccJitFuncType < EXPORTED INTERNAL IMPORTED ALWAYS_INLINE >;

enum GccJitOutputKind < ASSEMBLER OBJECT_FILE DYNAMIC_LIBRARY EXECUTABLE >;

enum GccJitBinOp < PLUS MINUS MULT DIVIDE MODULO BITWISE_AND BITWISE_XOR
    BITWISE_OR LOGICAL_AND LOGICAL_OR LSHIFT RSHIFT >;

class GccJit is repr("CPointer") {
    class Type is repr("CPointer") {
        method Type { self }
        method ptr { gcc_jit_type_get_pointer self.Type }
        method const { gcc_jit_type_get_const self.Type }
        method volatile { gcc_jit_type_get_volatile self.Type }
        method aligned { gcc_jit_type_get_aligned self.Type }
    }
    class Location is repr("CPointer") {}
    class Field is repr("CPointer") {
        method Field { self }
    }
    class RValue is repr("CPointer") {
        method RValue { self }
        method deref(Location :$location) { gcc_jit_rvalue_dereference self.RValue, $location }
        method access-field(Field() $field, Location :$location) {
            gcc_jit_rvalue_access_field self.RValue, $location, $field
        }
        method deref-field(Field() $field, Location :$location) {
            gcc_jit_rvalue_dereference_field self.RValue, $location, $field
        }
    }
    class LValue is repr("CPointer") is RValue {
        method LValue { self }
        method RValue { gcc_jit_lvalue_as_rvalue self }
        method addr(Location :$location) { gcc_jit_lvalue_get_address self.LValue, $location }
        method access-field(Field() $field, Location :$location) {
            gcc_jit_lvalue_access_field self.LValue, $location, $field
        }
    }
    class Param is repr("CPointer") is RValue {
        method RValue {
            gcc_jit_param_as_rvalue self
        }
    }
    class Block is repr("CPointer") {
        method Block { self }
        method add-eval(RValue() $rvalue, Location :$location) {
            gcc_jit_block_add_eval self.Block, $location, $rvalue
        }
        method add-assignment(LValue() $lvalue, RValue() $rvalue, Location :$location) {
            gcc_jit_block_add_assignment self.Block, $location, $lvalue, $rvalue
        }
        method add-assignment-op(LValue() $lvalue, GccJitBinOp $op, RValue() $rvalue, Location :$location) {
            gcc_jit_block_add_assignment_op self.Block, $location, $lvalue, +$op, $rvalue
        }
        method end-with-return(RValue() $rvalue, Location :$location) {
            gcc_jit_block_end_with_return self.Block, $location, $rvalue
        }
        method end-with-void-return(Location :$location) {
            gcc_jit_block_end_with_void_return self.Block, $location
        }
        method end-with-conditional(RValue() $rvalue, Block $true, Block $false, Location :$location) {
            gcc_jit_block_end_with_conditional self.Block, $location, $rvalue, $true, $false
        }
        method end-with-jump(Block $target, Location :$location) {
            gcc_jit_block_end_with_jump self.Block, $location, $target
        }
        method add-comment(Str() $comment, Location :$location) {
            gcc_jit_block_add_comment self.Block, $location, $comment
        }
        method function { gcc_jit_block_get_function self.Block }
    }
    class Function is repr("CPointer") {
        method new-block(Str() $name) {
            gcc_jit_function_new_block self, $name
        }
        method new-local(Type() $type, Str() $name, Location :$location) {
            gcc_jit_function_new_local self, $location, $type, $name
        }
    }
    class Union is repr("CPointer") is Type {
        method Type {
            gcc_jit_union_as_type self
        }
        method set-field(@fields, Location :$location) {
            gcc_jit_union_set_fields self, $location, CArray[Field].new(|@fields>>.Field)
        }
    }
    class Struct is repr("CPointer") is Type {
        method Type {
            gcc_jit_struct_as_type self
        }
        method set-field(@fields, Location :$location) {
            gcc_jit_struct_set_fields self, $location, CArray[Field].new(|@fields>>.Field)
        }
    }
    class Result is repr("CPointer") {
        method get-code(Str $name) {
            gcc_jit_result_get_code self, $name
        }
    }

    sub gcc_jit_context_set_bool_option(GccJit, int16, int16) is native("gccjit") { * }
    sub gcc_jit_context_acquire() returns GccJit is native("gccjit") { * }
    sub gcc_jit_context_get_type(
        GccJit,
        int16
    ) returns Type is native("gccjit") { * }
    sub gcc_jit_context_new_param(
        GccJit,
        Location,
        Type,
        Str
    ) returns Param is native("gccjit") { * }
    sub gcc_jit_context_new_binary_op(
        GccJit,
        Location,
        int16,
        Type,
        RValue,
        RValue
    ) returns RValue is native("gccjit") { * }
    sub gcc_jit_context_new_function(
        GccJit,
        Location,
        int16,
        Type,
        Str,
        int16,
        CArray[Param],
        int16
    ) returns Function is native("gccjit") { * }
    sub gcc_jit_context_compile(
        GccJit
    ) returns Result is native("gccjit") { * }
    sub gcc_jit_context_compile_to_file(
        GccJit,
        int16,
        Str
    ) is native("gccjit") { * }
    sub gcc_jit_context_new_call (
        GccJit,
        Location,
        Function,
        int16,
        CArray[RValue]
    ) returns RValue is native("gccjit") { * }
    sub gcc_jit_context_new_rvalue_from_int(
        GccJit,
        Type,
        int16
    ) returns RValue is native("gccjit") { * }
    sub gcc_jit_context_new_string_literal(
        GccJit,
        Str
    ) returns RValue is native("gccjit") { * }
    sub gcc_jit_param_as_rvalue(
        Param
    ) returns RValue is native("gccjit") { * };
    sub gcc_jit_function_new_block(
        Function,
        Str
    ) returns Block is native("gccjit") { * }
    sub gcc_jit_function_new_local(
        Function,
        Location,
        Type,
        Str
    ) returns LValue is native("gccjit") { * }
    sub gcc_jit_block_add_eval(
        Block,
        Location,
        RValue
    ) is native("gccjit") { * }
    sub gcc_jit_block_add_assignment(
        Block,
        Location,
        LValue,
        RValue
    ) is native("gccjit") { * }
    sub gcc_jit_block_add_assignment_op(
        Block,
        Location,
        RValue,
        int16,
        LValue
    ) is native("gccjit") { * }
    sub gcc_jit_block_add_comment(
        Block,
        Location,
        Str
    ) is native("gccjit") { * }
    sub gcc_jit_block_end_with_conditional(
        Block,
        Location,
        RValue,
        Block,
        Block
    ) is native("gccjit") { * }
    sub gcc_jit_block_end_with_jump(
        Block,
        Location,
        Block
    ) is native("gccjit") { * }
    sub gcc_jit_block_end_with_return(
        Block,
        Location,
        RValue
    ) is native("gccjit") { * }
    sub gcc_jit_block_end_with_void_return(
        Block,
        Location
    ) is native("gccjit") { * }
    sub gcc_jit_result_get_code(
        Result,
        Str
    ) returns Pointer is native("gccjit") { * }
    sub gcc_jit_context_new_struct_type(
        GccJit,
        Location,
        Str,
        int16,
        CArray[Field]
    ) returns Struct is native("gccjit") { * }
    sub gcc_jit_context_new_opaque_struct(
        GccJit,
        Location,
        Str,
    ) returns Struct is native("gccjit") { * }
    sub gcc_jit_struct_as_type(
        Struct
    ) returns Type is native("gccjit") { * }
    sub gcc_jit_union_as_type(
        Union
    ) returns Type is native("gccjit") { * }
    sub gcc_jit_context_new_union_type(
        GccJit,
        Location,
        Str,
        int16,
        CArray[Field]
    ) returns Struct is native("gccjit") { * }
    sub gcc_jit_struct_set_fields(
        Struct,
        Location,
        int16,
        CArray[Field]
    ) is native("gccjit") { * }
    sub gcc_jit_union_set_fields(
        Struct,
        Location,
        int16,
        CArray[Field]
    ) is native("gccjit") { * }
    sub gcc_jit_context_new_field(
        GccJit,
        Location,
        Type,
        Str
    ) returns Field is native("gccjit") { * }
    sub gcc_jit_type_get_pointer(
        Type
    ) returns Type is native("gccjit") { * }
    sub gcc_jit_type_get_const(
        Type
    ) returns Type is native("gccjit") { * }
    sub gcc_jit_type_get_volatile(
        Type
    ) returns Type is native("gccjit") { * }
    sub gcc_jit_context_new_array_type(
        GccJit,
	Location,
        Type,
	int16
    ) returns Type is native("gccjit") { * }
    sub gcc_jit_type_get_aligned(
        Type
    ) returns Type is native("gccjit") { * }
    sub gcc_jit_lvalue_as_rvalue(
        LValue
    ) returns RValue is native("gccjit") { * }
    sub gcc_jit_lvalue_get_address(
        LValue,
        Location
    ) returns RValue is native("gccjit") { * }
    sub gcc_jit_rvalue_dereference(
        RValue,
        Location
    ) returns LValue is native("gccjit") { * }
    sub gcc_jit_lvalue_access_field(
        LValue,
        Location,
        Field
    ) returns LValue is native("gccjit") { * }
    sub gcc_jit_rvalue_access_field(
        RValue,
        Location,
        Field
    ) returns RValue is native("gccjit") { * }
    sub gcc_jit_rvalue_dereference_field(
        RValue,
        Location,
        Field
    ) returns LValue is native("gccjit") { * }
    sub gcc_jit_context_new_array_access(
        GccJit,
        Location,
        RValue,
        RValue,
    ) returns LValue is native("gccjit") { * }
    sub gcc_jit_block_get_function(
        Block
    ) returns Function is native("gccjit") { * }

    method new { gcc_jit_context_acquire() }

    method get-type(GccJitType() $type) { gcc_jit_context_get_type self, $type }
    method void                 { $ //= self.get-type: VOID                }
    method void-ptr             { $ //= self.get-type: VOID-PTR            }
    method bool                 { $ //= self.get-type: BOOL                }
    method char                 { $ //= self.get-type: CHAR                }
    method signed-char          { $ //= self.get-type: SIGNED-CHAR         }
    method unsigned-char        { $ //= self.get-type: UNSIGNED-CHAR       }
    method short                { $ //= self.get-type: SHORT               }
    method unsigned-short       { $ //= self.get-type: UNSIGNED-SHORT      }
    method int                  { $ //= self.get-type: INT                 }
    method unsigned-int         { $ //= self.get-type: UNSIGNED-INT        }
    method long                 { $ //= self.get-type: LONG                }
    method unsigned-long        { $ //= self.get-type: UNSIGNED-LONG       }
    method long-long            { $ //= self.get-type: LONG-LONG           }
    method unsigned-long-long   { $ //= self.get-type: UNSIGNED-LONG-LONG  }
    method float                { $ //= self.get-type: FLOAT               }
    method double               { $ //= self.get-type: DOUBLE              }
    method long-double          { $ //= self.get-type: LONG-DOUBLE         }
    method const-char-ptr       { $ //= self.get-type: CONST-CHAR-PTR      }
    method size-t               { $ //= self.get-type: SIZE-T              }
    method file-ptr             { $ //= self.get-type: FILE-PTR            }
    method complex-float        { $ //= self.get-type: COMPLEX-FLOAT       }
    method complex-double       { $ //= self.get-type: COMPLEX-DOUBLE      }
    method complex-long-double  { $ //= self.get-type: COMPLEX-LONG-DOUBLE }

    method new-param(Type() $type, Str() $name, Location :$location) {
        gcc_jit_context_new_param self, $location, $type, $name
    }
    method new-function(GccJitFuncType() $ftype, Type() $type, Str() $name, *@params, Location :$location, Bool() :$variadic = False) {
        gcc_jit_context_new_function self, $location, $ftype,
            $type, $name, +@params, CArray[Param].new(|@params), +$variadic
    }
    method new-exported-function(Type() $type, Str() $name, *@params, Location :$location, Bool() :$variadic = False) {
        gcc_jit_context_new_function self, $location, EXPORTED,
            $type, $name, +@params, CArray[Param].new(|@params), +$variadic
    }
    method new-internal-function(Type() $type, Str() $name, *@params, Location :$location, Bool() :$variadic = False) {
        gcc_jit_context_new_function self, $location, INTERNAL,
            $type, $name, +@params, CArray[Param].new(|@params), +$variadic
    }
    method new-imported-function(Type() $type, Str() $name, *@params, Location :$location, Bool() :$variadic = False) {
        gcc_jit_context_new_function self, $location, IMPORTED,
            $type, $name, +@params, CArray[Param].new(|@params), +$variadic
    }
    method new-inlined-function(Type() $type, Str() $name, *@params, Location :$location, Bool() :$variadic = False) {
        gcc_jit_context_new_function self, $location, ALWAYS_INLINE,
            $type, $name, +@params, CArray[Param].new(|@params), +$variadic
    }
    method new-binary-op(GccJitBinOp() $op, Type() $type, RValue() $a, RValue() $b, Location :$location) {
            gcc_jit_context_new_binary_op self, $location, +$op, $type, $a, $b
    }
    method new-binary-plus(Type() $type, RValue() $a, RValue() $b, Location :$location) {
        self.new-binary-op(PLUS, $type, $a, $b, :$location)
    }
    method new-binary-minus(Type() $type, RValue() $a, RValue() $b, Location :$location) {
        self.new-binary-op(MINUS, $type, $a, $b, :$location)
    }
    method new-binary-mult(Type() $type, RValue() $a, RValue() $b, Location :$location) {
        self.new-binary-op(MULT, $type, $a, $b, :$location)
    }
    method new-binary-divide(Type() $type, RValue() $a, RValue() $b, Location :$location) {
        self.new-binary-op(DIVIDE, $type, $a, $b, :$location)
    }
    method new-binary-modulo(Type() $type, RValue() $a, RValue() $b, Location :$location) {
        self.new-binary-op(MODULO, $type, $a, $b, :$location)
    }
    method new-binary-bitwise_and(Type() $type, RValue() $a, RValue() $b, Location :$location) {
        self.new-binary-op(BITWISE_AND, $type, $a, $b, :$location)
    }
    method new-binary-bitwise_xor(Type() $type, RValue() $a, RValue() $b, Location :$location) {
        self.new-binary-op(BITWISE_XOR, $type, $a, $b, :$location)
    }
    method new-binary-bitwise_or(Type() $type, RValue() $a, RValue() $b, Location :$location) {
        self.new-binary-op(BITWISE_OR, $type, $a, $b, :$location)
    }
    method new-binary-logical_and(Type() $type, RValue() $a, RValue() $b, Location :$location) {
        self.new-binary-op(LOGICAL_AND, $type, $a, $b, :$location)
    }
    method new-binary-logical_or(Type() $type, RValue() $a, RValue() $b, Location :$location) {
        self.new-binary-op(LOGICAL_OR, $type, $a, $b, :$location)
    }
    method new-binary-lshift(Type() $type, RValue() $a, RValue() $b, Location :$location) {
        self.new-binary-op(LSHIFT, $type, $a, $b, :$location)
    }
    method new-binary-rshift(Type() $type, RValue() $a, RValue() $b, Location :$location) {
        self.new-binary-op(RSHIFT, $type, $a, $b, :$location)
    }
    method new-call (Function() $func, *@args, Location :$location) {
            gcc_jit_context_new_call self, $location, $func, +@args , CArray[RValue].new: |@args>>.RValue
    }
    method new-rvalue-from-int(Int() $val) {
        gcc_jit_context_new_rvalue_from_int self, self.int, $val
    }
    method new-string-literal(Str() $val) {
        gcc_jit_context_new_string_literal self, $val
    }

    method new-struct-type(Str() $name, *@fields, Location :$location) {
        gcc_jit_context_new_struct_type self, $location, $name, +@fields, @fields>>.Field
    }
    method new-opaque-struct(Str() $name, Location :$location) {
        gcc_jit_context_new_opaque_struct self, $location, $name
    }
    method new-union-type(Str() $name, *@fields, Location :$location) {
        gcc_jit_context_new_union_type self, $location, $name, +@fields, @fields>>.Field
    }
    method new-field(Type() $type, Str() $name, Location :$location) {
        gcc_jit_context_new_field self, $location, $type, $name
    }

    method compile {
        gcc_jit_context_compile self;
    }
    method compile-to-file(GccJitOutputKind() $kind, Str() $file) {
        gcc_jit_context_compile_to_file self, $kind, $file
    }
    method compile-to-assembler(Str() $file) {
        gcc_jit_context_compile_to_file self, ASSEMBLER, $file
    }
    method compile-to-object(Str() $file) {
        gcc_jit_context_compile_to_file self, OBJECT_FILE, $file
    }
    method compile-to-dyn-lib(Str() $file) {
        gcc_jit_context_compile_to_file self, DYNAMIC_LIBRARY, $file
    }
    method compile-to-executable(Str() $file) {
        gcc_jit_context_compile_to_file self, EXECUTABLE, $file
    }
    method new-array-access(RValue() $ptr, RValue() $index, Location :$location) {
        gcc_jit_context_new_array_access self, $location, $ptr, $index
    }
    method set-bool-option(int16 $opt, int16 $val) {
        gcc_jit_context_set_bool_option self, $opt, $val
    }
    method new-array-type(Type() $type, int16 $elems, Location :$location) { gcc_jit_context_new_array_type self, $location, $type, $elems }
}
