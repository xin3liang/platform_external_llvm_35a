# Don't build the library in unbundled branches.
ifeq (,$(TARGET_BUILD_APPS))

LOCAL_PATH:= $(call my-dir)

llvm_pre_static_libraries := \
  libLLVMLinker \
  libLLVMipo \
  libLLVMIRReader \
  libLLVMBitWriter \
  libLLVMBitReader

llvm_arm_static_libraries := \
  libLLVMARMCodeGen \
  libLLVMARMAsmParser \
  libLLVMARMAsmPrinter \
  libLLVMARMInfo \
  libLLVMARMDesc \
  libLLVMARMDisassembler

llvm_x86_static_libraries := \
  libLLVMX86CodeGen \
  libLLVMX86Info \
  libLLVMX86Desc \
  libLLVMX86AsmParser \
  libLLVMX86AsmPrinter \
  libLLVMX86Utils \
  libLLVMX86Disassembler

llvm_mips_static_libraries := \
  libLLVMMipsCodeGen \
  libLLVMMipsInfo \
  libLLVMMipsDesc \
  libLLVMMipsAsmParser \
  libLLVMMipsAsmPrinter \
  libLLVMMipsDisassembler

llvm_arm64_static_libraries := \
  libLLVMARM64CodeGen \
  libLLVMARM64Info \
  libLLVMARM64Desc \
  libLLVMARM64AsmParser \
  libLLVMARM64AsmPrinter \
  libLLVMARM64Utils \
  libLLVMARM64Disassembler

llvm_post_static_libraries := \
  libLLVMAsmPrinter \
  libLLVMSelectionDAG \
  libLLVMCodeGen \
  libLLVMObject \
  libLLVMScalarOpts \
  libLLVMInstCombine \
  libLLVMInstrumentation \
  libLLVMTransformObjCARC \
  libLLVMTransformUtils \
  libLLVMipa \
  libLLVMAnalysis \
  libLLVMTarget \
  libLLVMMC \
  libLLVMMCParser \
  libLLVMCore \
  libLLVMAsmParser \
  libLLVMOption \
  libLLVMSupport \
  libLLVMVectorize \

llvm_host_static_libraries := \
  libLLVMExecutionEngine \
  libLLVMMCDisassembler \
  libLLVMRuntimeDyld \
  libLLVMJIT \
  libLLVMMCJIT \
  libLLVMProfileData

ifeq (true,$(FORCE_BUILD_LLVM_COMPONENTS))
# HOST LLVM shared library build
include $(CLEAR_VARS)
LOCAL_IS_HOST_MODULE := true

LOCAL_MODULE:= libLLVM

LOCAL_MODULE_TAGS := optional

# Host build pulls in all ARM, Mips, X86 components.
LOCAL_WHOLE_STATIC_LIBRARIES := \
  $(llvm_pre_static_libraries) \
  $(llvm_arm_static_libraries) \
  $(llvm_x86_static_libraries) \
  $(llvm_mips_static_libraries) \
  $(llvm_arm64_static_libraries) \
  $(llvm_host_static_libraries) \
  $(llvm_post_static_libraries)

ifeq ($(HOST_OS),windows)
  LOCAL_LDLIBS := -limagehlp -lpsapi
else
  LOCAL_LDLIBS := -ldl -lpthread
endif

include $(LLVM_HOST_BUILD_MK)
include $(BUILD_HOST_SHARED_LIBRARY)
endif

ifeq (,$(filter $(TARGET_ARCH),$(LLVM_SUPPORTED_ARCH)))
$(warning TODO $(TARGET_ARCH): Enable llvm build)
endif

ifneq (true,$(DISABLE_LLVM_DEVICE_BUILDS))
# DEVICE LLVM shared library build
include $(CLEAR_VARS)

LOCAL_MODULE:= libLLVM

LOCAL_MODULE_TAGS := optional

# Device build selectively pulls in ARM, Mips, X86 components.
LOCAL_WHOLE_STATIC_LIBRARIES := \
  $(llvm_pre_static_libraries)

LOCAL_WHOLE_STATIC_LIBRARIES_arm += $(llvm_arm_static_libraries)
LOCAL_WHOLE_STATIC_LIBRARIES_x86 += $(llvm_x86_static_libraries)
LOCAL_WHOLE_STATIC_LIBRARIES_x86_64 += $(llvm_x86_static_libraries)
LOCAL_WHOLE_STATIC_LIBRARIES_mips += $(llvm_mips_static_libraries)
LOCAL_WHOLE_STATIC_LIBRARIES_arm64 += $(llvm_arm64_static_libraries)

LOCAL_WHOLE_STATIC_LIBRARIES += $(llvm_post_static_libraries)

#LOCAL_LDLIBS := -ldl -lpthread
LOCAL_SHARED_LIBRARIES := libcutils libdl libc++

include $(LLVM_DEVICE_BUILD_MK)
include $(BUILD_SHARED_LIBRARY)

endif

endif # don't build in unbundled branches
