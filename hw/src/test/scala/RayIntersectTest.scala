package RayIntersect

import chisel3._

object MyTopLevelVerilog extends App {
  //chisel3.Driver.execute(args, () => new FetchBVH(10, 11))
  //chisel3.Driver.execute(args, () => new BVHTraversal(10, 11))
  //chisel3.Driver.execute(args, () => new simpleTraversal(10, 11))
  //chisel3.Driver.execute(args, () => new TraversalControl(10, 11))
  //chisel3.Driver.execute(args, () => new BboxIntersect(10))
  //chisel3.Driver.execute(args, () => new LeafIntersect(10, 11, 32))
  chisel3.Driver.execute(args, () => new RayIntersectAccelerator(10, 11, 32))
}
