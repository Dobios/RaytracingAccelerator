package RayIntersect

import chisel3._
import chisel3.experimental._
import chisel3.util.{HasBlackBoxResource, log2Ceil}
//import graphaccelerator.interfaces.{Xilinx2R1WSDPBRAMIO, XilinxSimpleDualPortBRAMBlackBoxIO, XilinxTrueDualPortBRAMBlackBoxIO}

class XilinxTrueDualPortReadFirstBRAM(width: Int,
                                 depth: Int,
                                 performance: String="HIGH_PERFORMANCE",
                                 initFile: String="")
                                 extends BlackBox(Map("RAM_WIDTH" -> width,
                                                      "RAM_DEPTH" -> depth,
                                                      "RAM_PERFORMANCE" -> performance,
                                                      "INIT_FILE" -> initFile))
                                 with HasBlackBoxResource {
    val io = IO(new XilinxTrueDualPortBRAMBlackBoxIO(log2Ceil(depth), width))

    setResource("/XilinxTrueDualPortReadFirstBRAM.v")
}

object XilinxSimpleDualPortNoChangeBRAM {
  val latency = 2
}

class XilinxSimpleDualPortNoChangeBRAM(width: Int,
                                       depth: Int,
                                       performance: String="HIGH_PERFORMANCE",
                                       initFile: String="",
                                       ramStyle: String="block")
                                       extends BlackBox(Map("RAM_WIDTH" -> width,
                                                            "RAM_DEPTH" -> depth,
                                                            "RAM_PERFORMANCE" -> performance,
                                                            "INIT_FILE" -> initFile,
                                                            "RAM_STYLE" -> ramStyle))
                                       with HasBlackBoxResource with Memory {
    val io = IO(new XilinxSimpleDualPortBRAMBlackBoxIO(log2Ceil(depth), width))
    val acceptedRamStyles = Seq("block", "distributed", "registers", "ultra")
    require(acceptedRamStyles contains ramStyle)
    def write(wrAddr: UInt, wrData: UInt, wrEn: Bool): Unit = {
      io.wea := wrEn
      io.addra := wrAddr
      io.dina := wrData
    }

    def read(rdAddr: UInt, rdEn: Bool): UInt = {
      io.addrb := rdAddr
      io.regceb := rdEn
      io.enb := rdEn
      io.doutb
    }

    def defaultBindings(clock: Clock, reset: core.Reset): Unit = {
      io.clock := clock
      io.reset := reset
    }
    setResource("/XilinxSimpleDualPortNoChangeBRAM.v")
}

class SinglePortBRAMIO[T <: Data](addrWidth: Int, dataType: T) extends Bundle {
  val rdAddr = Input(UInt(addrWidth.W))
  val rdEn = Input(Bool())
  val rdData = Output(dataType)
  val wrAddr = Input(UInt(addrWidth.W))
  val wrEn = Input(Bool())
  val wrData = Input(dataType)
}

class SDPNoChangeWithStToLoad[T <: Data](addrWidth: Int, dataType: T, numStages: Int=2, initFile: String="", takeStToLdWrAddr: Boolean=true)
  extends Module with Memory {
    require(numStages == 2 || numStages == 3)
    val io = IO(new SinglePortBRAMIO(addrWidth, dataType))
    val dataWidth = dataType.getWidth
    val memory = Module(new XilinxSimpleDualPortNoChangeBRAM(dataWidth, 1 << addrWidth, initFile=initFile))
    val storeToLoad = Module(if (numStages == 2) new StoreToLoadForwardingTwoStages(dataType, addrWidth) else new StoreToLoadForwardingThreeStages(dataType, addrWidth))

    memory.defaultBindings(clock, reset)

    if(takeStToLdWrAddr) {
      memory.write(storeToLoad.io.wrAddr, io.wrData.asUInt, io.wrEn)
    } else {
      memory.write(io.wrAddr, io.wrData.asUInt, io.wrEn)
    }
    storeToLoad.io.wrEn := io.wrEn
    storeToLoad.io.dataOutToMem := io.wrData

    val rdData = memory.read(io.rdAddr, io.rdEn)
    storeToLoad.io.rdAddr := io.rdAddr
    storeToLoad.io.pipelineReady := io.rdEn
    storeToLoad.io.dataInFromMem := rdData.asTypeOf(dataType)
    io.rdData := storeToLoad.io.dataInFixed

    def write(wrData: T, wrEn: Bool): Unit = {
      io.wrData := wrData
      io.wrEn   := wrEn
    }

    def write(wrAddr: UInt, wrData: UInt, wrEn: Bool): Unit = {
      io.wrAddr := wrAddr
      io.wrData := wrData.asUInt
      io.wrEn   := wrEn
    }

    def read(rdAddr: UInt, rdEn: Bool): UInt = {
      io.rdAddr := rdAddr
      io.rdEn := rdEn
      io.rdData.asUInt
    }

}

/* Default values for testing */
object AXIBRAMInterface {
    val addrWidth = 8
    val axiDataWidth = 128
    val bramDataWidth = 72
}

trait Memory extends BaseModule {
  def read(rdAddr: UInt, rdEn: Bool): UInt
  def write(wrAddr: UInt, wrData: UInt, wrEn: Bool): Unit
  val latency: Int = 2
}

/* A 2W/1R memory made of 4 XilinxSimpleDualPortNoChangeBRAM (c.f. LaForest et al. "Multi-Ported Memories for FPGAs via XOR") */
/* WARNING: It takes 3 cycles before a write can be read back. */
class TwoWriteOneReadPortBRAM(addrWidth: Int, dataWidth: Int) extends Module {
    val io = IO(new Bundle{
        val wraddra = Input(UInt(addrWidth.W))
        val wea = Input(Bool())
        val dina = Input(UInt(dataWidth.W))
        val wraddrb = Input(UInt(addrWidth.W))
        val web = Input(Bool())
        val dinb = Input(UInt(dataWidth.W))
        val rdaddr = Input(UInt(addrWidth.W))
        val rden = Input(Bool())
        val dout = Output(UInt(dataWidth.W))
    })


    val writeMemColumn = Array.fill(2)(Module(new XilinxSimpleDualPortNoChangeBRAM(dataWidth, (1 << addrWidth))).io)
    val readMemColumn = Array.fill(2)(Module(new XilinxSimpleDualPortNoChangeBRAM(dataWidth, (1 << addrWidth))).io)
    for(i <- 0 until 2) {
      writeMemColumn(i).clock := clock
      writeMemColumn(i).reset := reset
      readMemColumn(i).clock := clock
      readMemColumn(i).reset := reset
    }

    val delayedDinA = RegNext(RegNext(io.dina))
    val delayedWeA = RegNext(RegNext(io.wea))
    val delayedWrAddrA = RegNext(RegNext(io.wraddra))
    writeMemColumn(0).addra := delayedWrAddrA
    writeMemColumn(0).wea := delayedWeA
    writeMemColumn(1).addrb := io.wraddra
    writeMemColumn(1).enb := true.B
    writeMemColumn(1).regceb := true.B
    writeMemColumn(0).dina := delayedDinA ^ writeMemColumn(1).doutb
    readMemColumn(0).addra := delayedWrAddrA
    readMemColumn(0).wea := delayedWeA
    readMemColumn(0).dina := delayedDinA ^ writeMemColumn(1).doutb

    val delayedDinB = RegNext(RegNext(io.dinb))
    val delayedWeB = RegNext(RegNext(io.web))
    val delayedWrAddrB = RegNext(RegNext(io.wraddrb))
    writeMemColumn(1).addra := delayedWrAddrB
    writeMemColumn(1).wea := delayedWeB
    writeMemColumn(0).addrb := io.wraddrb
    writeMemColumn(0).enb := true.B
    writeMemColumn(0).regceb := true.B
    writeMemColumn(1).dina := delayedDinB ^ writeMemColumn(0).doutb
    writeMemColumn(1).addra := delayedWrAddrB
    writeMemColumn(1).wea := delayedWeB
    readMemColumn(1).dina := delayedDinB ^ writeMemColumn(0).doutb
    readMemColumn(1).addra := delayedWrAddrB
    readMemColumn(1).wea := delayedWeB

    readMemColumn(0).addrb := io.rdaddr
    readMemColumn(0).enb := io.rden
    readMemColumn(0).regceb := io.rden
    readMemColumn(1).addrb := io.rdaddr
    readMemColumn(1).enb := io.rden
    readMemColumn(1).regceb := io.rden
    io.dout := readMemColumn(0).doutb ^ readMemColumn(1).doutb

}

/* A 2R/1W memory made of two SDP memories that share the write port. */
class TwoReadOneWritePortBRAM(addrWidth: Int, dataWidth: Int) extends Module with Memory {
  val memDepth = 1 << addrWidth
  val io = IO(new Xilinx2R1WSDPBRAMIO(addrWidth, dataWidth))

  val memA = Module(new XilinxSimpleDualPortNoChangeBRAM(dataWidth, memDepth))
  memA.defaultBindings(clock, reset)

  val memB = Module(new XilinxSimpleDualPortNoChangeBRAM(dataWidth, memDepth))
  memB.defaultBindings(clock, reset)

  memA.write(io.wrAddr, io.wrData, io.wrEn)
  memB.write(io.wrAddr, io.wrData, io.wrEn)

  val rddataA = memA.read(io.rdAddrA, io.rdEnA)
  val rddataB = memB.read(io.rdAddrB, io.rdEnB)

  def readA(rdAddr: UInt, rdEn: Bool): UInt = {
    io.rdAddrA := rdAddr
    io.rdEnA := rdEn
    rddataA
  }

  def readB(rdAddr: UInt, rdEn: Bool): UInt = {
    io.rdAddrB := rdAddr
    io.rdEnB := rdEn
    rddataB
  }

  def read(rdAddr: UInt, rdEn: Bool): UInt = readA(rdAddr, rdEn)

  def write(wrAddr: UInt, wrData: UInt, wrEn: Bool): Unit = {
    io.wrAddr := wrAddr
    io.wrData := wrData
    io.wrEn := wrEn
  }
}

class TwoReadOneWritePortBRAMWithStToLoad[T <: Data](addrWidth: Int, dataType: T, numStages: Int=2)
  extends Module with Memory {
  require(numStages == 2 | numStages == 3) // TODO: integrate StToLoadForward with arbitrary stages
  val dataWidth = dataType.getWidth
  val io = IO(new Xilinx2R1WSDPBRAMIO(addrWidth, dataWidth))
  val memory = Module(new TwoReadOneWritePortBRAM(addrWidth, dataWidth))
  val storeToLoadA = Module(if (numStages == 2) new StoreToLoadForwardingTwoStages(dataType, addrWidth) else new StoreToLoadForwardingThreeStages(dataType, addrWidth))
  val storeToLoadB = Module(if (numStages == 2) new StoreToLoadForwardingTwoStages(dataType, addrWidth) else new StoreToLoadForwardingThreeStages(dataType, addrWidth))


  memory.write(io.wrAddr, io.wrData.asUInt, io.wrEn)
  storeToLoadA.io.wrEn := io.wrEn
  storeToLoadA.io.dataOutToMem := io.wrData
  storeToLoadB.io.wrEn := io.wrEn
  storeToLoadB.io.dataOutToMem := io.wrData

  val rdDataA = memory.readA(io.rdAddrA, io.rdEnA)
  storeToLoadA.io.rdAddr := io.rdAddrA
  storeToLoadA.io.pipelineReady := io.rdEnA
  storeToLoadA.io.dataInFromMem := rdDataA.asTypeOf(dataType)
  io.rdDataA := storeToLoadA.io.dataInFixed

  val rdDataB = memory.readB(io.rdAddrB, io.rdEnB)
  storeToLoadB.io.rdAddr := io.rdAddrB
  storeToLoadB.io.pipelineReady := io.rdEnB
  storeToLoadB.io.dataInFromMem := rdDataB.asTypeOf(dataType)
  io.rdDataB := storeToLoadB.io.dataInFixed

  def write(wrAddr: UInt, wrData: UInt, wrEn: Bool): Unit = {
    io.wrAddr := wrAddr
    io.wrData := wrData
    io.wrEn   := wrEn
  }

  def readA(rdAddr: UInt, rdEn: Bool): UInt = {
    io.rdAddrA := rdAddr
    io.rdEnA := rdEn
    io.rdDataA
  }

  def readB(rdAddr: UInt, rdEn: Bool): UInt = {
    io.rdAddrB := rdAddr
    io.rdEnB := rdEn
    io.rdDataB
  }

  def read(rdAddr: UInt, rdEn: Bool): UInt = readA(rdAddr, rdEn).asUInt
}