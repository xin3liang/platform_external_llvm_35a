//===-------- X86PadShortFunction.cpp - pad short functions -----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines the pass which will pad short functions to prevent
// a stall if a function returns before the return address is ready. This
// is needed for some Intel Atom processors.
//
//===----------------------------------------------------------------------===//

#include <algorithm>

#define DEBUG_TYPE "x86-pad-short-functions"
#include "X86.h"
#include "X86InstrInfo.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Target/TargetInstrInfo.h"

using namespace llvm;

STATISTIC(NumBBsPadded, "Number of basic blocks padded");

namespace {
  struct VisitedBBInfo {
    // HasReturn - Whether the BB contains a return instruction
    bool HasReturn;

    // Cycles - Number of cycles until return if HasReturn is true, otherwise
    // number of cycles until end of the BB
    unsigned int Cycles;

    VisitedBBInfo() : HasReturn(false), Cycles(0) {}
    VisitedBBInfo(bool HasReturn, unsigned int Cycles)
      : HasReturn(HasReturn), Cycles(Cycles) {}
  };

  struct PadShortFunc : public MachineFunctionPass {
    static char ID;
    PadShortFunc() : MachineFunctionPass(ID)
                   , Threshold(4), TM(0), TII(0) {}

    bool runOnMachineFunction(MachineFunction &MF) override;

    const char *getPassName() const override {
      return "X86 Atom pad short functions";
    }

  private:
    void findReturns(MachineBasicBlock *MBB,
                     unsigned int Cycles = 0);

    bool cyclesUntilReturn(MachineBasicBlock *MBB,
                           unsigned int &Cycles);

    void addPadding(MachineBasicBlock *MBB,
                    MachineBasicBlock::iterator &MBBI,
                    unsigned int NOOPsToAdd);

    const unsigned int Threshold;

    // ReturnBBs - Maps basic blocks that return to the minimum number of
    // cycles until the return, starting from the entry block.
    DenseMap<MachineBasicBlock*, unsigned int> ReturnBBs;

    // VisitedBBs - Cache of previously visited BBs.
    DenseMap<MachineBasicBlock*, VisitedBBInfo> VisitedBBs;

    const TargetMachine *TM;
    const TargetInstrInfo *TII;
  };

  char PadShortFunc::ID = 0;
}

FunctionPass *llvm::createX86PadShortFunctions() {
  return new PadShortFunc();
}

/// runOnMachineFunction - Loop over all of the basic blocks, inserting
/// NOOP instructions before early exits.
bool PadShortFunc::runOnMachineFunction(MachineFunction &MF) {
  const AttributeSet &FnAttrs = MF.getFunction()->getAttributes();
  if (FnAttrs.hasAttribute(AttributeSet::FunctionIndex,
                           Attribute::OptimizeForSize) ||
      FnAttrs.hasAttribute(AttributeSet::FunctionIndex,
                           Attribute::MinSize)) {
    return false;
  }

  TM = &MF.getTarget();
  TII = TM->getInstrInfo();

  // Search through basic blocks and mark the ones that have early returns
  ReturnBBs.clear();
  VisitedBBs.clear();
  findReturns(MF.begin());

  bool MadeChange = false;

  MachineBasicBlock *MBB;
  unsigned int Cycles = 0;

  // Pad the identified basic blocks with NOOPs
  for (DenseMap<MachineBasicBlock*, unsigned int>::iterator I = ReturnBBs.begin();
       I != ReturnBBs.end(); ++I) {
    MBB = I->first;
    Cycles = I->second;

    if (Cycles < Threshold) {
      // BB ends in a return. Skip over any DBG_VALUE instructions
      // trailing the terminator.
      assert(MBB->size() > 0 &&
             "Basic block should contain at least a RET but is empty");
      MachineBasicBlock::iterator ReturnLoc = --MBB->end();

      while (ReturnLoc->isDebugValue())
        --ReturnLoc;
      assert(ReturnLoc->isReturn() && !ReturnLoc->isCall() &&
             "Basic block does not end with RET");

      addPadding(MBB, ReturnLoc, Threshold - Cycles);
      NumBBsPadded++;
      MadeChange = true;
    }
  }

  return MadeChange;
}

/// findReturn - Starting at MBB, follow control flow and add all
/// basic blocks that contain a return to ReturnBBs.
void PadShortFunc::findReturns(MachineBasicBlock *MBB, unsigned int Cycles) {
  // If this BB has a return, note how many cycles it takes to get there.
  bool hasReturn = cyclesUntilReturn(MBB, Cycles);
  if (Cycles >= Threshold)
    return;

  if (hasReturn) {
    ReturnBBs[MBB] = std::max(ReturnBBs[MBB], Cycles);
    return;
  }

  // Follow branches in BB and look for returns
  for (MachineBasicBlock::succ_iterator I = MBB->succ_begin();
       I != MBB->succ_end(); ++I) {
    if (*I == MBB)
      continue;
    findReturns(*I, Cycles);
  }
}

/// cyclesUntilReturn - return true if the MBB has a return instruction,
/// and return false otherwise.
/// Cycles will be incremented by the number of cycles taken to reach the
/// return or the end of the BB, whichever occurs first.
bool PadShortFunc::cyclesUntilReturn(MachineBasicBlock *MBB,
                                     unsigned int &Cycles) {
  // Return cached result if BB was previously visited
  DenseMap<MachineBasicBlock*, VisitedBBInfo>::iterator it
    = VisitedBBs.find(MBB);
  if (it != VisitedBBs.end()) {
    VisitedBBInfo BBInfo = it->second;
    Cycles += BBInfo.Cycles;
    return BBInfo.HasReturn;
  }

  unsigned int CyclesToEnd = 0;

  for (MachineBasicBlock::iterator MBBI = MBB->begin();
        MBBI != MBB->end(); ++MBBI) {
    MachineInstr *MI = MBBI;
    // Mark basic blocks with a return instruction. Calls to other
    // functions do not count because the called function will be padded,
    // if necessary.
    if (MI->isReturn() && !MI->isCall()) {
      VisitedBBs[MBB] = VisitedBBInfo(true, CyclesToEnd);
      Cycles += CyclesToEnd;
      return true;
    }

    CyclesToEnd += TII->getInstrLatency(TM->getInstrItineraryData(), MI);
  }

  VisitedBBs[MBB] = VisitedBBInfo(false, CyclesToEnd);
  Cycles += CyclesToEnd;
  return false;
}

/// addPadding - Add the given number of NOOP instructions to the function
/// just prior to the return at MBBI
void PadShortFunc::addPadding(MachineBasicBlock *MBB,
                              MachineBasicBlock::iterator &MBBI,
                              unsigned int NOOPsToAdd) {
  DebugLoc DL = MBBI->getDebugLoc();

  while (NOOPsToAdd-- > 0) {
    BuildMI(*MBB, MBBI, DL, TII->get(X86::NOOP));
    BuildMI(*MBB, MBBI, DL, TII->get(X86::NOOP));
  }
}