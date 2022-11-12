package RayIntersect

import java.io.{BufferedWriter, File, FileWriter}

import chisel3._
import chisel3.util._
//import graphaccelerator.util.SimultaneousUpDownSaturatingCounter

class BRAMQueueIO(addrWidth: Int, dataWidth: Int) extends Bundle {
  val enq = Flipped(DecoupledIO(UInt(dataWidth.W)))
  val deq = DecoupledIO(UInt(dataWidth.W))
  val count = Output(UInt((addrWidth+1).W))
  val almostEmpty = Output(Bool())
}

class BRAMQueue(val dataWidth: Int, val depth: Int, val resetCount: Int=0, val almostEmptyMargin: Int=0, initFilePath: String="", ramStyle: String="block") extends Module {
    val addrWidth = log2Ceil(depth)
    val io = IO(new BRAMQueueIO(addrWidth, dataWidth))

    val memory = Module(new XilinxSimpleDualPortNoChangeBRAM(width=dataWidth, depth=depth, initFile=initFilePath, ramStyle=ramStyle))

    memory.io.clock := clock
    memory.io.reset := reset
    val full = Wire(Bool())
    val empty = Wire(Bool())
    val wrEn = io.enq.valid & ~full

    /* Enqueue side */
    /* Nothing fancy here */
    val enqPtr = Counter(wrEn, depth)
    memory.io.addra := enqPtr._1
    memory.io.wea := wrEn
    memory.io.dina := io.enq.bits

    /* Dequeue side */
    /* To minimize latency and avoid bubbles despite the fact that the memory
     * has a 2-cycle latency, we try to always fill up the output 2-stage
     * pipeline. For this reason, we distinguish the situation where the entire
     * FIFO is empty (when empty = true) from that of only the BRAM is empty,
     * but there may be some valid elements in the output pipeline
     * (bramEmpty = true). */
    val bramEmpty = Wire(Bool())
    val rdEn = Wire(Bool())
    val deqPtr = Counter(rdEn, depth)
    memory.io.addrb := deqPtr._1
    val enb = Wire(Bool())
    val regceb = Wire(Bool())
    val valid0 = RegEnable(~bramEmpty, init=false.B, enable=enb)
    enb := (~bramEmpty & ~valid0) | regceb
    memory.io.enb := enb
    rdEn := enb & ~bramEmpty
    val valid1 = RegEnable(valid0, init=false.B, enable=regceb)
    regceb := (valid0 & ~valid1) | io.deq.ready
    memory.io.regceb := regceb
    io.deq.valid := valid1
    io.deq.bits := memory.io.doutb

    /* Element counter */
    val elemCounter = Module(new SimultaneousUpDownSaturatingCounter(depth, resetCount))
    elemCounter.io.increment := wrEn
    elemCounter.io.decrement := rdEn
    elemCounter.io.load := false.B
    elemCounter.io.loadValue := DontCare
    full := elemCounter.io.saturatingUp
    bramEmpty := elemCounter.io.saturatingDown
    empty := bramEmpty & ~valid0 & ~valid1
    io.enq.ready := ~full

    when(valid0 & valid1) {
        io.count := elemCounter.io.currValue + 2.U
    } .elsewhen(valid0 | valid1) {
        io.count := elemCounter.io.currValue + 1.U
    } .otherwise {
        io.count := elemCounter.io.currValue
    }

    io.almostEmpty := io.count <= almostEmptyMargin.U
}

/* Same interface as a normal Chisel Queue, but we need to manually instantiate the
 * BRAM because it has to be initialized */
class FreeLabelQueue(rowAddrWidth: Int, almostEmptyMargin: Int, outputDir: String, useAbsolutePathsForBramInit: Boolean) extends Module {
  val io = IO(new Bundle {
      val enq = Flipped(DecoupledIO(UInt(rowAddrWidth.W)))
      val deq = DecoupledIO(UInt(rowAddrWidth.W))
      val count = Output(UInt((rowAddrWidth+1).W))
      val almostEmpty = Output(Bool())
  })
  val memDepth = 1 << rowAddrWidth

  /* Generate BRAM initialization data
   * (all numbers from 0 to memDepth-1) */
  // val initFilePath = new File(".").getAbsolutePath() + "/FRQBRAM.hex"
  val initFilePath = outputDir + s"/FLQBRAM${FreeLabelQueue.instanceCounter}.mif"
  val paramFilePath = if(useAbsolutePathsForBramInit) new File(initFilePath).getAbsolutePath else new File(initFilePath).getName()
  FreeLabelQueue.instanceCounter += 1
  val file = new File(initFilePath)
  val bw = new BufferedWriter(new FileWriter(file))
  val rowAddrWidthHex = scala.math.ceil(rowAddrWidth.toDouble / 4).toInt
  val formatString = s"%0${rowAddrWidthHex}x"
  for(addr <- 0 until memDepth) {
      bw.write(formatString.format(addr) + "\n")
  }
  bw.close()

  val bramQueue = Module(new BRAMQueue(rowAddrWidth, memDepth, memDepth, almostEmptyMargin, paramFilePath))
  io.enq <> bramQueue.io.enq
  io.deq <> bramQueue.io.deq
  io.count := bramQueue.io.count
  io.almostEmpty := bramQueue.io.almostEmpty
}

object FreeLabelQueue {
  var instanceCounter = 0
  def apply(size: Int, outputDir: String = ".", useAbsolutePathsForBramInit: Boolean = false, almostFullMargin: Int=0)= {
    require(isPow2(size))
    val rowAddrWidth = log2Ceil(size)
    Module(new FreeLabelQueue(rowAddrWidth, almostFullMargin, outputDir, useAbsolutePathsForBramInit))
  }
}