package RayIntersect

import chisel3._

class XilinxTrueDualPortBRAMIO(addrWidth: Int, dataWidth: Int) extends Bundle {
    val addra  = Input(UInt(addrWidth.W))
    val addrb  = Input(UInt(addrWidth.W))
    val dina   = Input(UInt(dataWidth.W))
    val dinb   = Input(UInt(dataWidth.W))
    val wea    = Input(Bool())
    val web    = Input(Bool())
    val ena    = Input(Bool())
    val enb    = Input(Bool())
    val regcea = Input(Bool())
    val regceb = Input(Bool())
    val douta  = Output(UInt(dataWidth.W))
    val doutb  = Output(UInt(dataWidth.W))

    override def cloneType = (new XilinxTrueDualPortBRAMIO(addrWidth, dataWidth)).asInstanceOf[this.type]
}

class XilinxTrueDualPortBRAMBlackBoxIO(addrWidth: Int, dataWidth: Int) extends XilinxTrueDualPortBRAMIO(addrWidth, dataWidth) {
    val clock  = Input(Clock())
    val reset  = Input(Bool())

    override def cloneType = (new XilinxTrueDualPortBRAMBlackBoxIO(addrWidth, dataWidth)).asInstanceOf[this.type]
}

class XilinxSimpleDualPortBRAMIO(addrWidth: Int, dataWidth: Int) extends Bundle {
    val addra  = Input(UInt(addrWidth.W))
    val addrb  = Input(UInt(addrWidth.W))
    val dina   = Input(UInt(dataWidth.W))
    val wea    = Input(Bool())
    val enb    = Input(Bool())
    val regceb = Input(Bool())
    val doutb  = Output(UInt(dataWidth.W))

    override def cloneType = (new XilinxSimpleDualPortBRAMIO(addrWidth, dataWidth)).asInstanceOf[this.type]
}
class XilinxSimpleDualPortBRAMBlackBoxIO(addrWidth: Int, dataWidth: Int) extends XilinxSimpleDualPortBRAMIO(addrWidth, dataWidth) {
    val clock  = Input(Clock())
    val reset  = Input(Bool())

    override def cloneType = (new XilinxSimpleDualPortBRAMBlackBoxIO(addrWidth, dataWidth)).asInstanceOf[this.type]
}

class XilinxDoublePumped2W2RSDPBRAMIO(addrWidth: Int, dataWidth: Int) extends Bundle {
    val rdaddra  = Input(UInt(addrWidth.W))
    val rdaddrb  = Input(UInt(addrWidth.W))
    val regcea = Input(Bool())
    val regceb = Input(Bool())
    val douta  = Output(UInt(dataWidth.W))
    val doutb  = Output(UInt(dataWidth.W))
    val wraddrc  = Input(UInt(addrWidth.W))
    val wraddrd  = Input(UInt(addrWidth.W))
    val dinc   = Input(UInt(dataWidth.W))
    val dind   = Input(UInt(dataWidth.W))
    val wec    = Input(Bool())
    val wed    = Input(Bool())

    override def cloneType = (new XilinxDoublePumped2W2RSDPBRAMIO(addrWidth, dataWidth)).asInstanceOf[this.type]
}

class XilinxDoublePumped2W2RSDPBRAMBlackBoxIO(addrWidth: Int, dataWidth: Int) extends XilinxDoublePumped2W2RSDPBRAMIO(addrWidth, dataWidth) {
    val clock   = Input(Clock())
    val clock2x = Input(Clock())
    val reset   = Input(Bool())

    override def cloneType = (new XilinxDoublePumped2W2RSDPBRAMBlackBoxIO(addrWidth, dataWidth)).asInstanceOf[this.type]
}

class Xilinx2R1WSDPBRAMIO(addrWidth: Int, dataWidth: Int) extends Bundle {
  val rdAddrA  = Input(UInt(addrWidth.W))
  val rdAddrB  = Input(UInt(addrWidth.W))
  val rdEnA = Input(Bool())
  val rdEnB = Input(Bool())
  val rdDataA  = Output(UInt(dataWidth.W))
  val rdDataB  = Output(UInt(dataWidth.W))
  val wrAddr  = Input(UInt(addrWidth.W))
  val wrData   = Input(UInt(dataWidth.W))
  val wrEn    = Input(Bool())

  override def cloneType = (new Xilinx2R1WSDPBRAMIO(addrWidth, dataWidth)).asInstanceOf[this.type]


}