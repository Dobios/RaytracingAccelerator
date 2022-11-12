package RayIntersect

import chisel3._
import chisel3.util._ //for switch struture
import chisel3.experimental._

/**
* Module that handles the initialization step of the RayIntersect function.
* This includes associating an Id and a NodeIdx to each ray and fetching the root
* of the BVH tree from memory.
*/
class FetchBVH(id_width: Int, index_width: Int) extends Module {
	val io = IO(new Bundle {
		val rayIn 			= Flipped(DecoupledIO(new Ray(id_width)))
		val rayNodeIdxOut	= DecoupledIO(new RayNodeIdx(id_width, index_width))
		val node 			= DecoupledIO(new BVHNode())
		
		//Mikhail's Memory system interface
		val addrOut 		= DecoupledIO(new IdNodeIdx(id_width, index_width))
		val dataIn 			= Flipped(DecoupledIO(new Bundle {
			val id = UInt(id_width.W)
			val data = UInt(256.W)
		}))
	})

	//--------------------- Decleration zone --------------------------------

	//Initialize ray-Id queue filled with id's from 0 to 2^id_width - 1
	val rayIdQ 		= Module(new FreeLabelQueue(id_width, 0, "src/main/outputs", true))

	//Signal bundling a ray with it's associated nodeIdx (to be stored in the RayBuffer)
	val rayNodeType = new RayNodeIdx(id_width, index_width)
	val rayNode 	= Wire(rayNodeType)

	//Instantiate the ray buffer, current id & idNode bundle 
	val rayBuffer 	= Module(new XilinxSimpleDualPortNoChangeBRAM(rayNode.getWidth, 1 << id_width))
	val id			= Wire(UInt(id_width.W))
	val nodeAddr 	= Wire(new IdNodeIdx(id_width, index_width))

	//Output valid & ready signals 
	val memoryValid 		= Wire(Bool())
	val resultValid 		= Wire(Bool())
	val qReady 				= Wire(Bool())
	val resultReady			= Wire(Bool())
	val delayedResultValid  = ShiftRegister(resultValid, 2, false.B, resultReady)

	//--------------------- Architecture ------------------------------------
	//Connect clock and reset for rayBuffer
	rayBuffer.io.clock := clock
	rayBuffer.io.reset := reset

	//Result validity logic
	resultValid := io.dataIn.valid & io.rayNodeIdxOut.ready & io.node.ready
	memoryValid := rayIdQ.io.deq.valid & io.rayIn.valid
	qReady 		:= io.addrOut.ready & io.rayIn.valid 

	//Result ready
	resultReady := io.rayNodeIdxOut.ready & io.node.ready

	//Set input, rayIdQ and rayBuffer ready signals
	io.rayIn.ready 		:= rayIdQ.io.deq.valid & io.addrOut.ready
	rayIdQ.io.deq.ready := qReady

	//Set memory system interface and rayIdQ validity
	io.addrOut.valid 	:= memoryValid
	rayIdQ.io.enq.valid := resultValid

	//Set memory system interface ready signal
	io.dataIn.ready := rayIdQ.io.enq.ready & resultReady

	//Associate the ray to a the BVH tree root
	rayNode.ray 	:= io.rayIn.bits
	rayNode.nodeIdx := 0.U	

	//Write the rays to the ray buffer using a new id
	id := rayIdQ.io.deq.bits
	rayBuffer.write(id, rayNode.asUInt(), memoryValid)

 	//Request a memory read for the current ray's node
	nodeAddr.id 	 := id
	nodeAddr.nodeIdx := rayNode.nodeIdx
	io.addrOut.bits  := nodeAddr

	//Recycle the used Ids
	rayIdQ.io.enq.bits := io.dataIn.bits.id

	//Set output validity
	io.rayNodeIdxOut.valid := delayedResultValid
	io.node.valid 		   := delayedResultValid

	//Set output bits
	io.rayNodeIdxOut.bits := rayNodeType.fromBits(rayBuffer.read(io.dataIn.bits.id, resultReady))
	io.node.bits 		  := (new BVHNode()).fromBits(ShiftRegister(io.dataIn.bits.data, 2, resultReady))
}