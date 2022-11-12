package RayIntersect

import chisel3._
import chisel3.util._ 
import chisel3.experimental._

/**
* Class used to abstract the interface with the Primitive Intersection 
* blackbox module.
*/
class PrimIntersect(id_width : Int) extends Module {
    val io = IO(new Bundle {
        val triangle 	= Input(new Triangle())
        val ray 		= Input(new Ray(id_width))
        val uvt         = DecoupledIO(new Bundle {
            val u = UInt(32.W)
            val v = UInt(32.W)
            val t = UInt(32.W)
        })
        val intersect 	= Output(Bool())
    })

    val blackBox = Module(new Prim_RayIntersect())

    blackBox.io.ap_clk := clock
    blackBox.io.ap_rst := reset

    //Connect the various inputs
    blackBox.io.triangle_p0_0 := io.triangle.p0(0)
    blackBox.io.triangle_p0_1 := io.triangle.p0(1)    
    blackBox.io.triangle_p0_2 := io.triangle.p0(2)

    blackBox.io.triangle_p1_0 := io.triangle.p1(0)
    blackBox.io.triangle_p1_1 := io.triangle.p1(1)
    blackBox.io.triangle_p1_2 := io.triangle.p1(2)

    blackBox.io.triangle_p2_0 := io.triangle.p2(0)
    blackBox.io.triangle_p2_1 := io.triangle.p2(1)
    blackBox.io.triangle_p2_2 := io.triangle.p2(2)

    blackBox.io.ray_o_0 := io.ray.origin(0)
    blackBox.io.ray_o_1 := io.ray.origin(1)
    blackBox.io.ray_o_2 := io.ray.origin(2)

    blackBox.io.ray_d_0 := io.ray.dir(0)
    blackBox.io.ray_d_1 := io.ray.dir(1)
    blackBox.io.ray_d_2 := io.ray.dir(2)

    blackBox.io.ray_dRcp_0 := io.ray.dRcp(0)
    blackBox.io.ray_dRcp_1 := io.ray.dRcp(1)
    blackBox.io.ray_dRcp_2 := io.ray.dRcp(2)

    blackBox.io.ray_mint := io.ray.minT
    blackBox.io.ray_maxt := io.ray.maxT

    //Connect the outputs if valid
    io.uvt.valid  	  := blackBox.io.u_ap_vld & blackBox.io.v_ap_vld & blackBox.io.t_ap_vld
    blackBox.io.ap_ce := io.uvt.ready
    io.uvt.bits.u 	  := blackBox.io.u 
    io.uvt.bits.v 	  := blackBox.io.v 
    io.uvt.bits.t 	  := blackBox.io.t 
    
    io.intersect := blackBox.io.ap_return
}

//===============================================================================================
//============================LEAF_INTERSECT-MODULE==============================================
//===============================================================================================

class LeafIntersect(id_width : Int, index_width : Int, prim_id_width : Int) extends Module {
    val io = IO(new Bundle {
        val rayNodeStackIn = Flipped(DecoupledIO(new RayBVHNodeStackIdx(id_width, index_width)))
        val shadow         = Input(Bool())
        val rayNodeOut     = DecoupledIO(new RayBVHNodeStackIdx(id_width, index_width))
        val dataOut        = DecoupledIO(new Bundle {
            val foundInt = Bool()
            val f        = UInt(index_width.W)
            val its      = new Intersection()         
        })

        //Mikhail's Memory system interface
		val addrOut   = DecoupledIO(new Bundle {
            val id    = UInt(id_width.W)
            val trIdx = UInt(prim_id_width.W) 
        })
		val dataIn 	  = Flipped(DecoupledIO(new Bundle {
			val id    = UInt(id_width.W)
			val data  = UInt((new Triangle()).getWidth.W)
		}))
    })
    //--------------------- Decleration zone --------------------------------

    //Primitive intersect module
    val primIntersect = Module(new PrimIntersect(id_width))

    //Initialize ray-Id queue filled with id's from 0 to 2^id_width - 1
    val rayIdQ = Module(new FreeLabelQueue(id_width, 0, "src/main/outputs", true))

    //InFlight ray bundle (where TrIdx is the loop index)
    val rayNodeStackTrIdxType = new RayIdBVHNodeStackTrIdx(id_width, index_width, prim_id_width)
    val rayNodeStackTrIdx     = Wire(rayNodeStackTrIdxType)
    val incRayNodeStackTrIdx  = Wire(rayNodeStackTrIdxType)
    val trIdxEqNodeEnd        = Wire(Bool())
    val itsData               = Wire(new Intersection())
    val mmsData               = Wire(new Bundle {
            val id        = UInt(id_width.W)
			val triangle  = new Triangle()
    })

    //Intermediate shadow wire
    val shadowRay = Wire(Bool())
    
    //RayBuffer and its write arbiter 
    val rayNodeStackBuffer = Module(new XilinxSimpleDualPortNoChangeBRAM(rayNodeStackTrIdxType.getWidth, id_width))
    val readData           = Wire(rayNodeStackTrIdxType)
    val arb                = Module(new RRArbiter(rayNodeStackTrIdxType, 2))
    val arbIn1Valid        = Wire(Bool())
    
    //I/O ready and valid signals
    val inReady         = Wire(Bool())
    val resultReady     = Wire(Bool())
    val dataOutValid    = Wire(Bool())
    val rayNodeOutValid = Wire(Bool())

    //Delayed signals
    val delayedShadow    = ShiftRegister(shadowRay, const.PRIM_LATENCY + 2)
    val delayed2MMSData  = ShiftRegister(mmsData, 2, io.dataIn.valid)
    val delayed87MMSData = ShiftRegister(delayed2MMSData, const.PRIM_LATENCY, io.dataIn.valid)
    val delayedPrimInt   = ShiftRegister(readData, const.PRIM_LATENCY, io.dataIn.valid)

    //--------------------- Architecture ------------------------------------
    //Connect intermediary shadow wire
    shadowRay := io.shadow

     //Connect clock and reset for rayNodeStackBuffer
	rayNodeStackBuffer.io.clock := clock
	rayNodeStackBuffer.io.reset := reset

    //Set input and rayIdQ ready signals 
    io.rayNodeStackIn.ready := inReady
    rayIdQ.io.deq.ready     := arb.io.in(0).ready
    rayIdQ.io.enq.valid     := rayNodeOutValid
    rayIdQ.io.enq.bits      := delayedPrimInt.rayId

    //Connect various ready and valid signals
    inReady         := rayIdQ.io.deq.valid & arb.io.in(0).ready
    resultReady     := (io.rayNodeOut.ready & io.dataOut.ready) & rayIdQ.io.enq.ready & arb.io.in(1).ready
    arbIn1Valid     := io.rayNodeStackIn.valid & rayIdQ.io.deq.valid
    rayNodeOutValid := delayedShadow | trIdxEqNodeEnd
    dataOutValid    := rayNodeOutValid & primIntersect.io.uvt.valid & primIntersect.io.intersect

    //Initalize the inflight ray bundle
    rayNodeStackTrIdx.trIdx    := io.rayNodeStackIn.bits.node.start
    rayNodeStackTrIdx.ray      := io.rayNodeStackIn.bits.ray
    rayNodeStackTrIdx.node     := io.rayNodeStackIn.bits.node
    rayNodeStackTrIdx.nodeIdx  := io.rayNodeStackIn.bits.nodeIdx
    rayNodeStackTrIdx.stackIdx := io.rayNodeStackIn.bits.stackIdx
    rayNodeStackTrIdx.rayId    := rayIdQ.io.deq.bits

    //Connect RayBuffer Writing arbiter interface
    arb.io.in(0).bits  := rayNodeStackTrIdx
    arb.io.in(0).valid := arbIn1Valid
    arb.io.in(1).bits  := incRayNodeStackTrIdx
    arb.io.in(1).valid := ~dataOutValid
    arb.io.out.ready   := io.addrOut.ready

    rayNodeStackBuffer.write(arb.io.out.bits.rayId, arb.io.out.bits.asUInt, arb.io.out.valid)
    readData := rayNodeStackTrIdxType.fromBits(rayNodeStackBuffer.read(io.dataIn.bits.id, io.dataIn.valid))

    //Connect to Mikhail's Memory System
    io.addrOut.bits.id    := arb.io.out.bits.rayId 
    io.addrOut.bits.trIdx := arb.io.out.bits.trIdx
    io.addrOut.valid      := arb.io.out.valid
    io.dataIn.ready       := resultReady
    mmsData.triangle      := (new Triangle()).fromBits(io.dataIn.bits.data)
    mmsData.id            := io.dataIn.bits.id

    //Connect PrimIntersect sub-module
    primIntersect.io.uvt.ready := resultReady
    primIntersect.io.ray       := readData.ray
    primIntersect.io.triangle  := mmsData.triangle

    //Increment loop index and check for end
    incRayNodeStackTrIdx.trIdx    := delayedPrimInt.trIdx + 1.U
    incRayNodeStackTrIdx.ray      := delayedPrimInt.ray
    incRayNodeStackTrIdx.rayId    := delayedPrimInt.rayId
    incRayNodeStackTrIdx.node     := delayedPrimInt.node
    incRayNodeStackTrIdx.nodeIdx  := delayedPrimInt.nodeIdx
    incRayNodeStackTrIdx.stackIdx := delayedPrimInt.stackIdx

    trIdxEqNodeEnd                := (delayedPrimInt.trIdx === delayedPrimInt.node.end)

    //Prepare intersection data
    itsData.mesh := delayed87MMSData.triangle.meshAddr
    itsData.u    := primIntersect.io.uvt.bits.u
    itsData.v    := primIntersect.io.uvt.bits.v
    itsData.t    := primIntersect.io.uvt.bits.t

    //Set output signals
    io.rayNodeOut.valid         := rayNodeOutValid
    io.rayNodeOut.bits.ray      := delayedPrimInt.ray
    io.rayNodeOut.bits.node     := delayedPrimInt.node
    io.rayNodeOut.bits.nodeIdx  := delayedPrimInt.nodeIdx
    io.rayNodeOut.bits.stackIdx := delayedPrimInt.stackIdx
    
    io.dataOut.bits.foundInt    := primIntersect.io.intersect
    io.dataOut.bits.f           := delayed87MMSData.triangle.idx
    io.dataOut.bits.its         := itsData
    io.dataOut.valid            := dataOutValid
}