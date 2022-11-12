package RayIntersect

import chisel3._
import chisel3.experimental._
import chisel3.util._

object const {
	val float_size = 32
	val STACK_INIT_VAL = 0
	val STACK_SIZE = 16
	val BBOX_LATENCY = 14
	val PRIM_LATENCY = 85
}

/**
* class representing a 3D orthogonal plane
*/
class Frame() extends Bundle {
	val s = Vec(3, UInt(32.W))
	val t = Vec(3, UInt(32.W))
	val n = Vec(3, UInt(32.W))
}

/**
* class representing a 3D triangle
*/
class Triangle() extends Bundle {
	val p0 		  = Vec(3, UInt(32.W))
	val p1 		  = Vec(3, UInt(32.W))
	val p2 		  = Vec(3, UInt(32.W))
	val idx 	  = UInt(32.W)
	val meshAddr = UInt(32.W)
}

/**
* class representing a BVH node
*/
class BVHNode() extends Bundle {
	val data = UInt(64.W)

	val bbox = new Bundle {
		val min = Vec(3, UInt(32.W))
		val max = Vec(3, UInt(32.W))
	}

	def rightChild: UInt = (data << 32) 
	def leafStart : UInt = (data << 32)
	def leafSize  : UInt = data(32, 1)
	def start     : UInt = leafStart
	def end		  : UInt = leafStart + leafSize

	def isLeaf    : Bool = data(0)

	override def cloneType = (new BVHNode()).asInstanceOf[this.type]
}

/**
* class representing a ray as defined in the Nori raytracer
*/
class Ray(sid_width : Int) extends Bundle {
	val origin 	= Vec(3, UInt(32.W))
	val dir 	= Vec(3, UInt(32.W))
	val dRcp	= Vec(3, UInt(32.W)) //Componentwise reciprocals of the ray direction
	val minT	= UInt(32.W)
	val maxT 	= UInt(32.W)
	val id 		= UInt(32.W)

	override def cloneType = (new Ray(sid_width)).asInstanceOf[this.type]
}

/**
* class that bundles a BVHNode with its corresponding NodeIdx and a ray
*/
class RayBVHNode(id_width: Int, index_width : Int) extends Bundle {
	val ray 	= new Ray(id_width)
	val node 	= new BVHNode()
	val nodeIdx = UInt(index_width.W)

	override def cloneType = (new RayBVHNode(id_width, index_width)).asInstanceOf[this.type]
}

/**
* class bundling a BVHNode with it corresponding Node and stack Idx and a ray
*/
class RayBVHNodeStackIdx(id_width: Int, index_width: Int) extends Bundle {
	val ray 	 = new Ray(id_width)
	val node 	 = new BVHNode()
	val nodeIdx  = UInt(index_width.W)
	val stackIdx = UInt(index_width.W)

	override def cloneType = (new RayBVHNodeStackIdx(id_width, index_width)).asInstanceOf[this.type]
}

/**
* class bundling a BVHNode with it corresponding Node and stack Idx and a ray with an ID
*/
class RayIdBVHNodeStackIdx(id_width: Int, index_width: Int) extends Bundle {
	val ray 	 = new Ray(id_width)	
	val node 	 = new BVHNode()
	val nodeIdx  = UInt(index_width.W)
	val stackIdx = UInt(index_width.W)
	val rayId 	 = UInt(id_width.W)

	override def cloneType = (new RayIdBVHNodeStackIdx(id_width, index_width)).asInstanceOf[this.type]	
}

/**
* class bundling a BVHNode with it corresponding Node and stack Idx, ray with an ID and a primIntersect
* loop index.
*/
class RayIdBVHNodeStackTrIdx(id_width: Int, index_width: Int, prim_id_width: Int) extends Bundle {
	val ray 	 = new Ray(id_width)	
	val node 	 = new BVHNode()
	val nodeIdx  = UInt(index_width.W)
	val stackIdx = UInt(index_width.W)
	val rayId 	 = UInt(id_width.W)
	val trIdx 	 = UInt(prim_id_width.W)

	override def cloneType = (new RayIdBVHNodeStackTrIdx(id_width, index_width, prim_id_width)).asInstanceOf[this.type]	
}

/**
* class that bundles an ID wtih a NodeIndex (used as an input to the memory controller)
*/
class IdNodeIdx(id_width: Int, index_width: Int) extends Bundle {
	val id = UInt(id_width.W)
	val nodeIdx = UInt(index_width.W)

	override def cloneType = (new IdNodeIdx(id_width, index_width)).asInstanceOf[this.type]
}

/**
* class that bundles an ID wtih a TriangleIndex (used as an input to the memory controller)
*/
class IdTrIdx(id_width: Int, prim_id_width: Int) extends Bundle {
	val id = UInt(id_width.W)
	val trIdx = UInt(prim_id_width.W)

	override def cloneType = (new IdTrIdx(id_width, prim_id_width)).asInstanceOf[this.type]
}

/**
* class that bundles a ray ID with a BVH node (used as an output of the memory controller)
*/
class IdBVHNode(id_width: Int) extends Bundle {
	val id = UInt(id_width.W)
	val node = new BVHNode()

	override def cloneType = (new IdBVHNode(id_width)).asInstanceOf[this.type]
} 

class TraversingRay(id_width: Int) extends Bundle {
	val ray   = new Ray(id_width)
	val state = UInt(4.W)

	override def cloneType = (new TraversingRay(id_width)).asInstanceOf[this.type]
}

/**
* class that bundles a ray with its associated node idx (used in FetchBVH)
*/
class RayNodeIdx(id_width: Int, nodeIdx_width : Int) extends Bundle {
	val ray = new Ray(id_width)
	val nodeIdx = UInt(nodeIdx_width.W)

	override def cloneType = (new RayNodeIdx(id_width, nodeIdx_width)).asInstanceOf[this.type]
}

/**
* class recording local information about ray-triangle intersection
*/
class Intersection() extends Bundle {
	val t = UInt(32.W) 			//Unoccluded distance along the ray
	val u = UInt(32.W)			//UV coordinate, if any
	val v = UInt(32.W)			//Other UV coordinate
	val mesh 	= UInt(32.W) 			//pointer to the intersected mesh
}

class Bbox_RayIntersect() extends BlackBox with HasBlackBoxResource {
	val io = IO( new Bundle {
		val ap_clk 		= Input(Clock())
		val ap_rst 		= Input(Bool())
		val ap_ce 		= Input(Bool())

		//Unrolled Ray interface
		val ray_o_0 	= Input(UInt(32.W))
		val ray_o_1 	= Input(UInt(32.W))
		val ray_o_2 	= Input(UInt(32.W))
		val ray_d_0 	= Input(UInt(32.W))
		val ray_d_1 	= Input(UInt(32.W))
		val ray_d_2 	= Input(UInt(32.W))
		val ray_dRcp_0  = Input(UInt(32.W))
		val ray_dRcp_1  = Input(UInt(32.W))
		val ray_dRcp_2  = Input(UInt(32.W))
		val ray_mint 	= Input(UInt(32.W))
        val ray_maxt 	= Input(UInt(32.W))

        //Unrolled min
        val min_0 		= Input(UInt(32.W))
        val min_1 		= Input(UInt(32.W))
        val min_2 		= Input(UInt(32.W))

        //Unrolled max
        val max_0		= Input(UInt(32.W))
        val max_1		= Input(UInt(32.W))
        val max_2		= Input(UInt(32.W))

		//Result of the intersection test
		val ap_return	= Output(Bool()) 
	})

	setResource("/bboxIntersect/rayIntersect.v")
}

class Prim_RayIntersect() extends BlackBox with HasBlackBoxResource {
	val io = IO(new Bundle {
		val ap_clk 		= Input(Clock())
		val ap_rst 		= Input(Bool())
		val ap_ce		= Input(Bool())
		
		val triangle_p0_0 	= Input(UInt(32.W))
		val triangle_p0_1 	= Input(UInt(32.W))
		val triangle_p0_2 	= Input(UInt(32.W))
		val triangle_p1_0 	= Input(UInt(32.W))
		val triangle_p1_1 	= Input(UInt(32.W))
		val triangle_p1_2 	= Input(UInt(32.W))
		val triangle_p2_0 	= Input(UInt(32.W))
		val triangle_p2_1 	= Input(UInt(32.W))
		val triangle_p2_2 	= Input(UInt(32.W))
		val ray_o_0 		= Input(UInt(32.W))
		val ray_o_1 		= Input(UInt(32.W))
		val ray_o_2 		= Input(UInt(32.W))
		val ray_d_0 		= Input(UInt(32.W))
		val ray_d_1 		= Input(UInt(32.W))
		val ray_d_2 		= Input(UInt(32.W))
		val ray_dRcp_0 		= Input(UInt(32.W))
		val ray_dRcp_1 		= Input(UInt(32.W))
		val ray_dRcp_2 		= Input(UInt(32.W))
		val ray_mint 		= Input(UInt(32.W))
		val ray_maxt 		= Input(UInt(32.W))

		val u 				= Output(UInt(32.W))
		val u_ap_vld		= Output(Bool())
		val v 				= Output(UInt(32.W))
		val v_ap_vld		= Output(Bool())
		val t 				= Output(UInt(32.W))
		val t_ap_vld		= Output(Bool())
		val ap_return 		= Output(Bool())
	})

	setResource("/primIntersect/rayIntersect.v")
}