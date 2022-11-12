package RayIntersect

import chisel3._
import chisel3.util._ //for switch struture
import chisel3.experimental._


//===============================================================================================
//=================================System Top-Level==============================================
//===============================================================================================
class RayIntersectAccelerator(id_width: Int, index_width: Int, prim_id_width : Int) extends Module {
	//IO is the same as the RayIntersect function of the Nori raytracer
    val io = IO(new Bundle {
        val inData = Flipped(DecoupledIO(new Bundle {
            val ray 				= new Ray(32)
            val shadowRay 			= Bool()
            val mNodesAddr			= UInt(32.W) //Pointer to the m_nodes array
            val mTrAddr            = UInt(32.W)
        }))
        
        val outData = DecoupledIO(new Bundle {
            val its 				= new Intersection()
            val foundInt 	= Bool()
        })
        
		//Mikhail's Memory system interface
		val nodeAddr = DecoupledIO(UInt((new IdNodeIdx(id_width, 33)).getWidth.W))
		val nodeData = Flipped(DecoupledIO(UInt((new Bundle {
			val id   = UInt(id_width.W)
			val data = UInt(256.W)
		}).getWidth.W)))
        val primAddr = DecoupledIO(UInt((new IdTrIdx(id_width, 33)).getWidth.W))
		val primData = Flipped(DecoupledIO(UInt((new Bundle {
			val id    = UInt(id_width.W)
			val data  = UInt((new Triangle()).getWidth.W)
		}).getWidth.W)))
    })
    //--------------------- Decleration zone --------------------------------

    //Main modules
    val fetch         = Module(new FetchBVH(id_width, index_width))
    val traversal     = Module(new BVHTraversal(id_width, index_width))
    val leafIntersect = Module(new LeafIntersect(id_width, index_width, prim_id_width))

    //Arbiter types
    val nodeDataArbType = new RayBVHNode(id_width, index_width)
    val nodeAddrArbType = new IdNodeIdx(id_width, index_width)

    val nodeDataType = new Bundle {
			val id   = UInt(id_width.W)
			val data = UInt(256.W)
		}

    val primDataType = new Bundle {
			val id    = UInt(id_width.W)
			val data  = UInt((new Triangle()).getWidth.W)
		}

    //Arbiters
    val nodeDataArb = Module(new RRArbiter(nodeDataArbType, 2))
    val nodeAddrArb = Module(new RRArbiter(nodeAddrArbType, 2))

    //Various intermediary wires
    val fetchTraverseRayNode = Wire(nodeDataArbType)

    //Intermediary address signals
    val triangleAddress = Wire(new Bundle {
            val id    = UInt(id_width.W)
            val addr  = UInt(33.W) 
        })
    val nodeAddress = Wire(new Bundle {
            val id   = UInt(id_width.W)
            val addr = UInt(33.W)
        })
    //--------------------- Architecture ------------------------------------

    //Connect FetchBVH module interface
    fetch.io.rayIn.bits  := io.inData.bits.ray
    fetch.io.rayIn.valid := io.inData.valid
    io.inData.ready      := fetch.io.rayIn.ready
    fetch.io.rayNodeIdxOut.ready := nodeDataArb.io.in(0).ready
    fetch.io.node.ready          := nodeDataArb.io.in(0).ready

    //Prepare intermediary fetch to traversal signal
    fetchTraverseRayNode.ray      := fetch.io.rayNodeIdxOut.bits.ray
    fetchTraverseRayNode.nodeIdx  := fetch.io.rayNodeIdxOut.bits.nodeIdx
    fetchTraverseRayNode.node     := fetch.io.node.bits

     //Connect Traversal and leafIntersect module ports
    traversal.io.rayNodeIn          <> nodeDataArb.io.out
    leafIntersect.io.rayNodeStackIn <> traversal.io.rayNodeStackIdxOut
    leafIntersect.io.shadow         := io.inData.bits.shadowRay 
    //Maybe also make leafIntersect.io.rayNodeIn.valid depend on the system's input valid

    //Connect the intermediary signal with the arbiter
    nodeDataArb.io.in(0).bits  <> fetchTraverseRayNode
    nodeDataArb.io.in(0).valid := fetch.io.rayNodeIdxOut.valid & fetch.io.node.valid

    nodeDataArb.io.in(1).bits.ray       := leafIntersect.io.rayNodeOut.bits.ray
    nodeDataArb.io.in(1).bits.node      := leafIntersect.io.rayNodeOut.bits.node
    nodeDataArb.io.in(1).bits.nodeIdx   := leafIntersect.io.rayNodeOut.bits.nodeIdx
    
    nodeDataArb.io.in(1).valid := (leafIntersect.io.rayNodeOut.bits.stackIdx =/= 0.U) & leafIntersect.io.rayNodeOut.valid
    leafIntersect.io.rayNodeOut.ready := nodeDataArb.io.in(1).ready

    //Connet the nodeAddr arbiter interfaces
    nodeAddrArb.io.in(0) <> fetch.io.addrOut
    nodeAddrArb.io.in(1) <> traversal.io.addrOut

    fetch.io.dataIn.bits      <> nodeDataType.fromBits(io.nodeData.bits)
    traversal.io.dataIn.bits  <> nodeDataType.fromBits(io.nodeData.bits)
    fetch.io.dataIn.valid     := io.nodeData.valid
    traversal.io.dataIn.valid := io.nodeData.valid
    io.nodeData.ready         := fetch.io.dataIn.ready | traversal.io.dataIn.ready

    //Connect with mikhail's memory system interface
    nodeAddress.id    := nodeAddrArb.io.out.bits.id
    nodeAddress.addr  := io.inData.bits.mNodesAddr + nodeAddrArb.io.out.bits.nodeIdx
    io.nodeAddr.bits  := nodeAddress.asUInt
    io.nodeAddr.valid := nodeAddrArb.io.out.valid

    nodeAddrArb.io.out.ready := io.nodeAddr.ready

    triangleAddress.addr := leafIntersect.io.addrOut.bits.trIdx + io.inData.bits.mTrAddr
    triangleAddress.id   := leafIntersect.io.addrOut.bits.id
    io.primAddr.bits     := triangleAddress.asUInt
    io.primAddr.valid    := leafIntersect.io.addrOut.valid

    leafIntersect.io.addrOut.ready := io.primAddr.ready
    leafIntersect.io.dataIn.bits  <> primDataType.fromBits(io.primData.bits)
    leafIntersect.io.dataIn.valid := io.primData.valid
    io.primData.ready := leafIntersect.io.dataIn.ready

    //Connect output
    io.outData.bits.its            := leafIntersect.io.dataOut.bits.its
    io.outData.bits.foundInt       := leafIntersect.io.dataOut.bits.foundInt
    io.outData.valid               := (leafIntersect.io.rayNodeOut.bits.stackIdx === 0.U) & leafIntersect.io.dataOut.valid
    leafIntersect.io.dataOut.ready := io.outData.ready
}