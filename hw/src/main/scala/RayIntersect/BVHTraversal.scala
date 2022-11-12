package RayIntersect

import chisel3._
import chisel3.util._ //for switch struture
import chisel3.experimental._

/**
* Module simplifying the interface with the bounding box
* intersect blackbox.
*/
class BboxIntersect(id_width : Int) extends Module {
    val io = IO(new Bundle {
        //Clock enable 
        val enable      = Input(Bool())

        val ray 		= Input(new Ray(id_width))
        val min 		= Input(Vec(3, UInt(32.W)))
        val max			= Input(Vec(3, UInt(32.W)))
        val intersect 	= Output(Bool())      
    })

    val blackBox = Module(new Bbox_RayIntersect())

    //connect inputs
    blackBox.io.ap_clk := clock
    blackBox.io.ap_rst := reset
    blackBox.io.ap_ce  := io.enable

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

    blackBox.io.min_0 := io.min(0)
    blackBox.io.min_1 := io.min(1)
    blackBox.io.min_2 := io.min(2)

    blackBox.io.max_0 := io.max(0)
    blackBox.io.max_1 := io.max(1)
    blackBox.io.max_2 := io.max(2)

    //connect output
    io.intersect := blackBox.io.ap_return 
}

//===============================================================================================
//============================INIT_SUB-MODULE====================================================
//===============================================================================================

class InitTraversal(id_width: Int, index_width: Int) extends Module {
    val io = IO(new Bundle {
                val enqIn               = Flipped(DecoupledIO(UInt(id_width.W)))
                val rayNodeIn           = Flipped(DecoupledIO(new RayBVHNode(id_width, index_width)))
                val rayNodeStackIdxOut  = DecoupledIO(new RayIdBVHNodeStackIdx(id_width, index_width))
            })

    //--------------------- Decleration zone --------------------------------

    //Stack index set to 0 in the initialization module
    val stackIdx = const.STACK_INIT_VAL

    //Initialize ray-Id queue filled with id's from 0 to 2^id_width - 1
    val rayIdQ = Module(new FreeLabelQueue(id_width, 0, "src/main/outputs", true))

    //Module ready & valid signals
    val inReady     = Wire(Bool())
    val resultValid = Wire(Bool())

    //--------------------- Architecture ------------------------------------

    //Set ready and valid signals
    inReady      := rayIdQ.io.enq.ready & io.rayNodeStackIdxOut.ready
    resultValid  := rayIdQ.io.deq.valid & io.rayNodeIn.valid

    //Set IO ready and valid signals
    io.enqIn.ready              := inReady
    io.rayNodeIn.ready          := inReady
    io.rayNodeStackIdxOut.valid := resultValid

    //Set RayIdQ ready and valid signals
    rayIdQ.io.deq.ready := io.rayNodeIn.valid
    rayIdQ.io.enq.valid := io.enqIn.valid

    //Enqueue the given value
    rayIdQ.io.enq.bits := io.enqIn.bits

    //Bundle the given rayNodeIdx with an Id and a stackIdx
    io.rayNodeStackIdxOut.bits.ray      := io.rayNodeIn.bits.ray
    io.rayNodeStackIdxOut.bits.rayId    := rayIdQ.io.deq.bits
    io.rayNodeStackIdxOut.bits.node     := io.rayNodeIn.bits.node
    io.rayNodeStackIdxOut.bits.nodeIdx  := io.rayNodeIn.bits.nodeIdx
    io.rayNodeStackIdxOut.bits.stackIdx := stackIdx.U    
}

//===============================================================================================
//============================BUFFER_SUB-MODULE==================================================
//===============================================================================================

class RayNodeBuffer(id_width: Int, index_width: Int) extends Module {
    val io = IO(new Bundle {
            val readAddr = Input(UInt(id_width.W))
            val readEn   = Input(Bool())
            val arbReady = Input(Bool())

            val writeData1 = Flipped(DecoupledIO(new RayIdBVHNodeStackIdx(id_width, index_width))) 
            val writeData2 = Flipped(DecoupledIO(new RayIdBVHNodeStackIdx(id_width, index_width)))

            //Arbiter results that are output to be sent back to BboxIntersect
            val rayNode_bits  = Output(new RayIdBVHNodeStackIdx(id_width, index_width))
            val rayNode_valid = Output(Bool())

            val readData = Output(new RayIdBVHNodeStackIdx(id_width, index_width))
    })
    //--------------------- Decleration zone --------------------------------

    //Data type used by the arbiter
    val wrDataType   = new RayIdBVHNodeStackIdx(id_width, index_width)

    //RayNodeBuffer Arbiter
    val arb  = Module(new RRArbiter(wrDataType, 2))

    //RayNodeStack Buffer
    val rayNodeStackBuffer = Module(new XilinxSimpleDualPortNoChangeBRAM(io.writeData1.bits.getWidth, id_width))

    //--------------------- Architecture ------------------------------------
    //Connect clock and reset for rayNodeStackBuffer
	rayNodeStackBuffer.io.clock := clock
	rayNodeStackBuffer.io.reset := reset

    //Connect Arbiter interface to its signals
    arb.io.in(0) <> io.writeData1
    arb.io.in(1) <> io.writeData2

    //Connect Arbiter Output to the outside world
    io.rayNode_bits := arb.io.out.bits
    io.rayNode_valid := arb.io.out.valid

    //Set Arbiter output ready signal
    arb.io.out.ready := io.arbReady

    //Connect Buffer ports
    rayNodeStackBuffer.write(arb.io.out.bits.rayId, arb.io.out.bits.asUInt, arb.io.out.valid)
    io.readData := wrDataType.fromBits(rayNodeStackBuffer.read(io.readAddr, io.readEn))
}

//===============================================================================================
//============================CONTROL_SUB-MODULE=================================================
//===============================================================================================

/**
* Submodule that houses the entire control flow for the traversal part of the raytracer
*/
class TraversalControl(id_width: Int, index_width: Int) extends Module {
    val io = IO(new Bundle {
        val dataIn = Flipped(DecoupledIO(new Bundle {
            val intersect      = Bool()
            val rayNodeStackIn = new RayIdBVHNodeStackIdx(id_width, index_width)
        }))

        val dataOut = DecoupledIO(new Bundle {
            val rayNodeStackOut = new RayIdBVHNodeStackIdx(id_width, index_width)
            val state           = UInt(3.W) //State = TRAVERSAL & LEAF & DONE & RETURN
        })
    })
    //--------------------- Decleration zone --------------------------------

    //Output valid signal and bits
    val dalayedOutValid       = ShiftRegister(io.dataIn.valid, 2, io.dataOut.ready)
    val delayedRayNodeStackIn = ShiftRegister(io.dataIn.bits.rayNodeStackIn, 2, io.dataOut.ready)

    //Stack memory depth constant and rayNodeStack Type
    val stackMemDepth    = id_width * const.STACK_SIZE
    val rayNodeStackType = new RayIdBVHNodeStackIdx(id_width, index_width)
    
    //In flight ray's states
    val inFlightState = Wire(UInt(3.W))
    val delayedState = ShiftRegister(inFlightState, 2, io.dataOut.ready)

    //Stack memory and its signals
    val stackMem       = Module(new XilinxSimpleDualPortNoChangeBRAM(index_width, stackMemDepth))
    val stackMemWrEn   = Wire(Bool())
    val stackMemWrAddr = Wire(UInt(stackMemDepth.W))
    val stackMemRdAddr = Wire(UInt(stackMemDepth.W))

    //FSM transition signals
    val isStateTraverse = Wire(Bool())
    val isStateLeaf     = Wire(Bool())
    val isStateDone     = Wire(Bool())
    val isStateReturn   = Wire(Bool())

    //Traverse intermediary signals
    val traverseTempStackIdx            = Wire(UInt(const.STACK_SIZE.W))
    val traverseTempNodeIdx             = Wire(UInt(const.STACK_SIZE.W))
    val traverseTempRayNodeStack        = Wire(rayNodeStackType)
    val delayedTraverseTempRayNodeStack = ShiftRegister(traverseTempRayNodeStack, 2, io.dataOut.ready)

    //GoBack intermediary signals
    val goBackTempStackIdx            = Wire(UInt(const.STACK_SIZE.W))
    val goBackTempNodeIdx             = Wire(UInt(const.STACK_SIZE.W))
    val delayedGoBackTempStackIdx      = ShiftRegister(goBackTempStackIdx, 2, io.dataOut.ready)
    val goBackTempRayNodeStack        = Wire(rayNodeStackType)

    //--------------------- Architecture ------------------------------------
    dontTouch(delayedState)
    
    //Connect stackMem clock and reset
    stackMem.io.clock := clock
    stackMem.io.reset := reset

    //Result data path and dataIn ready
    io.dataOut.valid      := (delayedState =/= 0.U) 
    io.dataOut.bits.state := delayedState
    io.dataIn.ready       := io.dataOut.ready

    //Set FSM transition signals
    isStateTraverse := io.dataIn.bits.intersect & ~io.dataIn.bits.rayNodeStackIn.node.isLeaf 
    isStateLeaf     := io.dataIn.bits.intersect & io.dataIn.bits.rayNodeStackIn.node.isLeaf 
    isStateDone     := ~io.dataIn.bits.intersect & (io.dataIn.bits.rayNodeStackIn.stackIdx === 0.U) 
    isStateReturn   := ~io.dataIn.bits.intersect & (io.dataIn.bits.rayNodeStackIn.stackIdx =/= 0.U) 

    //Traversal data path: Connect writing interface to stackMem and update TempRayNodeStack
    stackMemWrAddr := io.dataIn.bits.rayNodeStackIn.stackIdx + (io.dataIn.bits.rayNodeStackIn.rayId * const.STACK_SIZE.U)
    stackMem.write(stackMemWrAddr, io.dataIn.bits.rayNodeStackIn.node.rightChild, isStateTraverse & io.dataIn.valid)

    traverseTempStackIdx := io.dataIn.bits.rayNodeStackIn.stackIdx + 1.U
    traverseTempNodeIdx  := io.dataIn.bits.rayNodeStackIn.nodeIdx + 1.U

    traverseTempRayNodeStack.stackIdx := traverseTempStackIdx
    traverseTempRayNodeStack.nodeIdx  := traverseTempNodeIdx
    traverseTempRayNodeStack.ray      := io.dataIn.bits.rayNodeStackIn.ray
    traverseTempRayNodeStack.rayId    := io.dataIn.bits.rayNodeStackIn.rayId
    traverseTempRayNodeStack.node     := io.dataIn.bits.rayNodeStackIn.node

    //GoBack data path: Connect reading interface to stackMem and update tempRayNodeStack
    goBackTempStackIdx := io.dataIn.bits.rayNodeStackIn.stackIdx - 1.U
    stackMemRdAddr     := goBackTempStackIdx
    goBackTempNodeIdx  := stackMem.read(stackMemRdAddr, io.dataOut.ready)

    goBackTempRayNodeStack.stackIdx := delayedGoBackTempStackIdx
    goBackTempRayNodeStack.nodeIdx  := goBackTempNodeIdx
    goBackTempRayNodeStack.ray      := delayedRayNodeStackIn.ray
    goBackTempRayNodeStack.rayId    := delayedRayNodeStackIn.rayId
    goBackTempRayNodeStack.node     := delayedRayNodeStackIn.node

    //Initial control
    when(isStateTraverse) {
        stackMemWrEn := true.B
        inFlightState := 1.U
    }.elsewhen(isStateLeaf) {
        stackMemWrEn := false.B
        inFlightState := 2.U 
    }.elsewhen(isStateDone) {
        stackMemWrEn := false.B
        inFlightState := 3.U 
    }.elsewhen(isStateReturn) {
        stackMemWrEn := false.B
        inFlightState := 4.U
    }.otherwise {
        stackMemWrEn := false.B
        inFlightState := 0.U
    }

    //Final output control (sequential)
    {
        //default output
        io.dataOut.bits.rayNodeStackOut <> delayedRayNodeStackIn

        switch(delayedState) {
            //No Valid state
            is(0.U) {
                io.dataOut.bits.rayNodeStackOut <> delayedRayNodeStackIn
            }
            //Traverse
            is(1.U) {
                io.dataOut.bits.rayNodeStackOut <> delayedTraverseTempRayNodeStack
            }
            //Leaf
            is(2.U) {
                io.dataOut.bits.rayNodeStackOut <> delayedRayNodeStackIn
            }
            //Done
            is(3.U) {
                io.dataOut.bits.rayNodeStackOut <> delayedRayNodeStackIn
            }
            //GoBack
            is(4.U) {
                io.dataOut.bits.rayNodeStackOut <> goBackTempRayNodeStack
            }
        }
    }
}

//===============================================================================================
//============================FETCH-PREP_SUB-MODULE==============================================
//===============================================================================================

class TraversalFetchPrep(id_width: Int, index_width: Int) extends Module {
    val io = IO(new Bundle {
        val wrData = Flipped(DecoupledIO(new RayIdBVHNodeStackIdx(id_width, index_width)))
        val dataOut = DecoupledIO(new RayIdBVHNodeStackIdx(id_width, index_width))
    
        //Mikhail's Memory system interface
		val addrOut  = DecoupledIO(new IdNodeIdx(id_width, index_width))
		val dataIn 	 = Flipped(DecoupledIO(new Bundle {
			val id   = UInt(id_width.W)
			val data = UInt(256.W)
		}))
    })
    //--------------------- Decleration zone --------------------------------

    //Module ready and valid signals
    val resultValid  = Wire(Bool())
    val resultReady  = Wire(Bool())

    //Data type used by the arbiter
    val buffDataType   = new RayIdBVHNodeStackIdx(id_width, index_width)

    ///RayNodeStack Buffer
    val rayNodeStackBuffer = Module(new XilinxSimpleDualPortNoChangeBRAM(io.wrData.bits.getWidth, id_width))

    //Delayed version of the valid signal 
    val delayedValid = ShiftRegister(resultValid, 2, false.B, resultReady)

    //--------------------- Architecture ------------------------------------

    //Connect buffer clock and reset
    rayNodeStackBuffer.io.clock := clock
    rayNodeStackBuffer.io.reset := reset

    //Set ready and valid signals and connect them to the input and output
    resultValid      := io.dataIn.valid 
    resultReady      := io.dataOut.ready
    io.dataOut.valid := delayedValid

    //Connect arbiter ports to the rayNodeStack buffer
    rayNodeStackBuffer.write(io.wrData.bits.rayId, io.wrData.bits.asUInt, io.wrData.valid)
    io.dataOut.bits := buffDataType.fromBits(rayNodeStackBuffer.read(io.dataIn.bits.id, io.dataIn.valid))

    //Connect to Mikhail's Memory System
    io.addrOut.bits.nodeIdx := io.wrData.bits.nodeIdx
    io.addrOut.bits.id      := io.wrData.bits.rayId
    io.addrOut.valid        := io.wrData.valid
    io.wrData.ready         := io.addrOut.ready
    io.dataIn.ready         := resultReady
}

//===============================================================================================
//============================TOP-LEVEL-TRAVERSAL_MODULE=========================================
//===============================================================================================

/**
* Top-level Module handling the traversal of the BVH tree.
*/
class BVHTraversal(id_width : Int, index_width : Int) extends Module {
    val io = IO(new Bundle {
        val rayNodeIn          = Flipped(DecoupledIO(new RayBVHNode(id_width, index_width)))
        val rayNodeStackIdxOut = DecoupledIO(new RayBVHNodeStackIdx(id_width, index_width))
        
        //Mikhail's Memory system interface
		val addrOut  = DecoupledIO(new IdNodeIdx(id_width, index_width))
		val dataIn 	 = Flipped(DecoupledIO(new Bundle {
			val id   = UInt(id_width.W)
			val data = UInt(256.W)
		}))
    })
	//--------------------- Decleration zone --------------------------------

    //Various ready, valid and enable signals 
    val bboxEnable      = Wire(Bool())
    val rayBuffRdEn     = Wire(Bool())
    val controlOutReady = Wire(Bool())
    val rayNodeOutValid = Wire(Bool())
    val initEnqValid    = Wire(Bool())
    val prepWrValid     = Wire(Bool())
    
    //Instanciate all sub-modules
    val bboxIntersect = Module(new BboxIntersect(id_width))
    val initTraversal = Module(new InitTraversal(id_width, index_width))
    val rayNodeBuffer = Module(new RayNodeBuffer(id_width, index_width))
    val control       = Module(new TraversalControl(id_width, index_width))
    val prepFetch     = Module(new TraversalFetchPrep(id_width, index_width))

    //Delayed Id and ready signals 
    val delayedId       = ShiftRegister(rayNodeBuffer.io.rayNode_bits.rayId, const.BBOX_LATENCY - 2, false.B, bboxEnable)
    val delayedIntValid = ShiftRegister(rayNodeBuffer.io.rayNode_valid, const.BBOX_LATENCY - 2, false.B, bboxEnable)
    val controlInValid  = ShiftRegister(delayedIntValid, 2)

    //Mikhail's Memory System output signals
    val mmsNodeOut  = Wire(new BVHNode())
    val delayedNode = ShiftRegister(mmsNodeOut, 2, io.dataIn.valid)

    //Temporary signals
    val wrDataType       = new RayIdBVHNodeStackIdx(id_width, index_width)
    val tempPrepFetchOut = Wire(wrDataType)

    //--------------------- Architecture ------------------------------------

    //Set various ready, valid and enable signals
    bboxEnable      := control.io.dataIn.ready
    rayBuffRdEn     := control.io.dataIn.ready & io.rayNodeStackIdxOut.ready & delayedIntValid
    controlOutReady := initTraversal.io.enqIn.ready & prepFetch.io.wrData.ready & io.rayNodeStackIdxOut.ready

    //Connect InitTraversal ports
    initTraversal.io.rayNodeIn   <> io.rayNodeIn
    initTraversal.io.enqIn.bits  := control.io.dataOut.bits.rayNodeStackOut.rayId 
    initTraversal.io.enqIn.valid := initEnqValid 

    //Connect BBoxIntersect and pipeline
    bboxIntersect.io.enable := bboxEnable
    bboxIntersect.io.ray    := rayNodeBuffer.io.rayNode_bits.ray
    bboxIntersect.io.min    := rayNodeBuffer.io.rayNode_bits.node.bbox.min
    bboxIntersect.io.max    := rayNodeBuffer.io.rayNode_bits.node.bbox.max

    //Connect RayNodeBuffer ports
    rayNodeBuffer.io.writeData1       <> initTraversal.io.rayNodeStackIdxOut
    rayNodeBuffer.io.readEn           := rayBuffRdEn
    rayNodeBuffer.io.readAddr         := delayedId
    rayNodeBuffer.io.arbReady         := initTraversal.io.rayNodeStackIdxOut.valid
    rayNodeBuffer.io.writeData2.bits  := tempPrepFetchOut
    rayNodeBuffer.io.writeData2.valid := prepFetch.io.dataOut.valid

    //Connect control ports
    control.io.dataIn.bits.intersect      := bboxIntersect.io.intersect
    control.io.dataIn.bits.rayNodeStackIn := rayNodeBuffer.io.readData
    control.io.dataIn.valid               := controlInValid
    control.io.dataOut.ready              := controlOutReady

    //Connect PrepFetch ports
    prepFetch.io.wrData.bits   := control.io.dataOut.bits.rayNodeStackOut
    prepFetch.io.wrData.valid  := prepWrValid
    prepFetch.io.dataOut.ready := rayNodeBuffer.io.writeData2.ready

    //Update the node
    tempPrepFetchOut.node     := mmsNodeOut
    tempPrepFetchOut.nodeIdx  := prepFetch.io.dataOut.bits.nodeIdx
    tempPrepFetchOut.ray      := prepFetch.io.dataOut.bits.ray 
    tempPrepFetchOut.rayId    := prepFetch.io.dataOut.bits.rayId
    tempPrepFetchOut.stackIdx := prepFetch.io.dataOut.bits.stackIdx
    
    //Connect to MMS
    prepFetch.io.dataIn <> io.dataIn
    io.addrOut          <> prepFetch.io.addrOut

    //Convert MMS output back to a BVHNode
    mmsNodeOut := (new BVHNode()).fromBits(io.dataIn.bits.data)

    //Connect output
    io.rayNodeStackIdxOut.bits  := control.io.dataOut.bits.rayNodeStackOut
    io.rayNodeStackIdxOut.valid := rayNodeOutValid

    //InitTraversal's Id enqueuing valid signal multiplexing (only valid if state is DONE)
    when(control.io.dataOut.bits.state === 3.U) {
        initEnqValid := control.io.dataOut.valid
    } otherwise {
        initEnqValid := false.B
    }

    //PrepFetch's wrData valid signal multiplexing (only valid if state is GOBACK or TRAVERSE)
    when(control.io.dataOut.bits.state === 4.U || control.io.dataOut.bits.state === 1.U) {
        prepWrValid := control.io.dataOut.valid
    } otherwise {
        prepWrValid := false.B
    }

    //Output's valid signal multiplexing (only valid if state is LEAF)
    when(control.io.dataOut.bits.state === 2.U) {
        rayNodeOutValid := control.io.dataOut.valid
    } otherwise {
        rayNodeOutValid := false.B
    }
}