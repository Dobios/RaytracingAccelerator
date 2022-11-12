module BboxIntersect( // @[:@29.2]
  input         clock, // @[:@30.4]
  input         reset, // @[:@31.4]
  input         io_enable, // @[:@32.4]
  input  [31:0] io_ray_origin_0, // @[:@32.4]
  input  [31:0] io_ray_origin_1, // @[:@32.4]
  input  [31:0] io_ray_origin_2, // @[:@32.4]
  input  [31:0] io_ray_dir_0, // @[:@32.4]
  input  [31:0] io_ray_dir_1, // @[:@32.4]
  input  [31:0] io_ray_dir_2, // @[:@32.4]
  input  [31:0] io_ray_dRcp_0, // @[:@32.4]
  input  [31:0] io_ray_dRcp_1, // @[:@32.4]
  input  [31:0] io_ray_dRcp_2, // @[:@32.4]
  input  [31:0] io_ray_minT, // @[:@32.4]
  input  [31:0] io_ray_maxT, // @[:@32.4]
  input  [31:0] io_min_0, // @[:@32.4]
  input  [31:0] io_min_1, // @[:@32.4]
  input  [31:0] io_min_2, // @[:@32.4]
  input  [31:0] io_max_0, // @[:@32.4]
  input  [31:0] io_max_1, // @[:@32.4]
  input  [31:0] io_max_2, // @[:@32.4]
  output        io_intersect // @[:@32.4]
);
  wire  blackBox_ap_return; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_max_2; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_max_1; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_max_0; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_min_2; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_min_1; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_min_0; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_ray_maxt; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_ray_mint; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_ray_dRcp_2; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_ray_dRcp_1; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_ray_dRcp_0; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_ray_d_2; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_ray_d_1; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_ray_d_0; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_ray_o_2; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_ray_o_1; // @[BVHTraversal.scala 24:26:@34.4]
  wire [31:0] blackBox_ray_o_0; // @[BVHTraversal.scala 24:26:@34.4]
  wire  blackBox_ap_ce; // @[BVHTraversal.scala 24:26:@34.4]
  wire  blackBox_ap_rst; // @[BVHTraversal.scala 24:26:@34.4]
  wire  blackBox_ap_clk; // @[BVHTraversal.scala 24:26:@34.4]
  Bbox_RayIntersect blackBox ( // @[BVHTraversal.scala 24:26:@34.4]
    .ap_return(blackBox_ap_return),
    .max_2(blackBox_max_2),
    .max_1(blackBox_max_1),
    .max_0(blackBox_max_0),
    .min_2(blackBox_min_2),
    .min_1(blackBox_min_1),
    .min_0(blackBox_min_0),
    .ray_maxt(blackBox_ray_maxt),
    .ray_mint(blackBox_ray_mint),
    .ray_dRcp_2(blackBox_ray_dRcp_2),
    .ray_dRcp_1(blackBox_ray_dRcp_1),
    .ray_dRcp_0(blackBox_ray_dRcp_0),
    .ray_d_2(blackBox_ray_d_2),
    .ray_d_1(blackBox_ray_d_1),
    .ray_d_0(blackBox_ray_d_0),
    .ray_o_2(blackBox_ray_o_2),
    .ray_o_1(blackBox_ray_o_1),
    .ray_o_0(blackBox_ray_o_0),
    .ap_ce(blackBox_ap_ce),
    .ap_rst(blackBox_ap_rst),
    .ap_clk(blackBox_ap_clk)
  );
  assign io_intersect = blackBox_ap_return; // @[BVHTraversal.scala 55:18:@76.4]
  assign blackBox_max_2 = io_max_2; // @[BVHTraversal.scala 52:23:@75.4]
  assign blackBox_max_1 = io_max_1; // @[BVHTraversal.scala 51:23:@74.4]
  assign blackBox_max_0 = io_max_0; // @[BVHTraversal.scala 50:23:@73.4]
  assign blackBox_min_2 = io_min_2; // @[BVHTraversal.scala 48:23:@72.4]
  assign blackBox_min_1 = io_min_1; // @[BVHTraversal.scala 47:23:@71.4]
  assign blackBox_min_0 = io_min_0; // @[BVHTraversal.scala 46:23:@70.4]
  assign blackBox_ray_maxt = io_ray_maxT; // @[BVHTraversal.scala 44:26:@69.4]
  assign blackBox_ray_mint = io_ray_minT; // @[BVHTraversal.scala 43:26:@68.4]
  assign blackBox_ray_dRcp_2 = io_ray_dRcp_2; // @[BVHTraversal.scala 41:28:@67.4]
  assign blackBox_ray_dRcp_1 = io_ray_dRcp_1; // @[BVHTraversal.scala 40:28:@66.4]
  assign blackBox_ray_dRcp_0 = io_ray_dRcp_0; // @[BVHTraversal.scala 39:28:@65.4]
  assign blackBox_ray_d_2 = io_ray_dir_2; // @[BVHTraversal.scala 37:25:@64.4]
  assign blackBox_ray_d_1 = io_ray_dir_1; // @[BVHTraversal.scala 36:25:@63.4]
  assign blackBox_ray_d_0 = io_ray_dir_0; // @[BVHTraversal.scala 35:25:@62.4]
  assign blackBox_ray_o_2 = io_ray_origin_2; // @[BVHTraversal.scala 33:25:@61.4]
  assign blackBox_ray_o_1 = io_ray_origin_1; // @[BVHTraversal.scala 32:25:@60.4]
  assign blackBox_ray_o_0 = io_ray_origin_0; // @[BVHTraversal.scala 31:25:@59.4]
  assign blackBox_ap_ce = io_enable; // @[BVHTraversal.scala 29:24:@58.4]
  assign blackBox_ap_rst = reset; // @[BVHTraversal.scala 28:24:@57.4]
  assign blackBox_ap_clk = clock; // @[BVHTraversal.scala 27:24:@56.4]
endmodule
module simpleTraversal( // @[:@78.2]
  input         clock, // @[:@79.4]
  input         reset, // @[:@80.4]
  output        io_rayNodeIn_ready, // @[:@81.4]
  input         io_rayNodeIn_valid, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_ray_origin_0, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_ray_origin_1, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_ray_origin_2, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_ray_dir_0, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_ray_dir_1, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_ray_dir_2, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_ray_dRcp_0, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_ray_dRcp_1, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_ray_dRcp_2, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_ray_minT, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_ray_maxT, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_ray_id, // @[:@81.4]
  input  [63:0] io_rayNodeIn_bits_node_data, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_node_bbox_min_0, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_node_bbox_min_1, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_node_bbox_min_2, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_node_bbox_max_0, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_node_bbox_max_1, // @[:@81.4]
  input  [31:0] io_rayNodeIn_bits_node_bbox_max_2, // @[:@81.4]
  input  [10:0] io_rayNodeIn_bits_nodeIdx, // @[:@81.4]
  output        io_intersect // @[:@81.4]
);
  wire  bboxIntersect_clock; // @[BVHTraversal.scala 88:31:@83.4]
  wire  bboxIntersect_reset; // @[BVHTraversal.scala 88:31:@83.4]
  wire  bboxIntersect_io_enable; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_ray_origin_0; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_ray_origin_1; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_ray_origin_2; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_ray_dir_0; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_ray_dir_1; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_ray_dir_2; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_ray_dRcp_0; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_ray_dRcp_1; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_ray_dRcp_2; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_ray_minT; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_ray_maxT; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_min_0; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_min_1; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_min_2; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_max_0; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_max_1; // @[BVHTraversal.scala 88:31:@83.4]
  wire [31:0] bboxIntersect_io_max_2; // @[BVHTraversal.scala 88:31:@83.4]
  wire  bboxIntersect_io_intersect; // @[BVHTraversal.scala 88:31:@83.4]
  BboxIntersect bboxIntersect ( // @[BVHTraversal.scala 88:31:@83.4]
    .clock(bboxIntersect_clock),
    .reset(bboxIntersect_reset),
    .io_enable(bboxIntersect_io_enable),
    .io_ray_origin_0(bboxIntersect_io_ray_origin_0),
    .io_ray_origin_1(bboxIntersect_io_ray_origin_1),
    .io_ray_origin_2(bboxIntersect_io_ray_origin_2),
    .io_ray_dir_0(bboxIntersect_io_ray_dir_0),
    .io_ray_dir_1(bboxIntersect_io_ray_dir_1),
    .io_ray_dir_2(bboxIntersect_io_ray_dir_2),
    .io_ray_dRcp_0(bboxIntersect_io_ray_dRcp_0),
    .io_ray_dRcp_1(bboxIntersect_io_ray_dRcp_1),
    .io_ray_dRcp_2(bboxIntersect_io_ray_dRcp_2),
    .io_ray_minT(bboxIntersect_io_ray_minT),
    .io_ray_maxT(bboxIntersect_io_ray_maxT),
    .io_min_0(bboxIntersect_io_min_0),
    .io_min_1(bboxIntersect_io_min_1),
    .io_min_2(bboxIntersect_io_min_2),
    .io_max_0(bboxIntersect_io_max_0),
    .io_max_1(bboxIntersect_io_max_1),
    .io_max_2(bboxIntersect_io_max_2),
    .io_intersect(bboxIntersect_io_intersect)
  );
  assign io_rayNodeIn_ready = bboxIntersect_io_enable; // @[BVHTraversal.scala 98:32:@105.4]
  assign io_intersect = bboxIntersect_io_intersect; // @[BVHTraversal.scala 99:18:@106.4]
  assign bboxIntersect_clock = clock; // @[:@84.4]
  assign bboxIntersect_reset = reset; // @[:@85.4]
  assign bboxIntersect_io_enable = io_rayNodeIn_valid; // @[BVHTraversal.scala 96:32:@104.4]
  assign bboxIntersect_io_ray_origin_0 = io_rayNodeIn_bits_ray_origin_0; // @[BVHTraversal.scala 92:26:@95.4]
  assign bboxIntersect_io_ray_origin_1 = io_rayNodeIn_bits_ray_origin_1; // @[BVHTraversal.scala 92:26:@96.4]
  assign bboxIntersect_io_ray_origin_2 = io_rayNodeIn_bits_ray_origin_2; // @[BVHTraversal.scala 92:26:@97.4]
  assign bboxIntersect_io_ray_dir_0 = io_rayNodeIn_bits_ray_dir_0; // @[BVHTraversal.scala 92:26:@92.4]
  assign bboxIntersect_io_ray_dir_1 = io_rayNodeIn_bits_ray_dir_1; // @[BVHTraversal.scala 92:26:@93.4]
  assign bboxIntersect_io_ray_dir_2 = io_rayNodeIn_bits_ray_dir_2; // @[BVHTraversal.scala 92:26:@94.4]
  assign bboxIntersect_io_ray_dRcp_0 = io_rayNodeIn_bits_ray_dRcp_0; // @[BVHTraversal.scala 92:26:@89.4]
  assign bboxIntersect_io_ray_dRcp_1 = io_rayNodeIn_bits_ray_dRcp_1; // @[BVHTraversal.scala 92:26:@90.4]
  assign bboxIntersect_io_ray_dRcp_2 = io_rayNodeIn_bits_ray_dRcp_2; // @[BVHTraversal.scala 92:26:@91.4]
  assign bboxIntersect_io_ray_minT = io_rayNodeIn_bits_ray_minT; // @[BVHTraversal.scala 92:26:@88.4]
  assign bboxIntersect_io_ray_maxT = io_rayNodeIn_bits_ray_maxT; // @[BVHTraversal.scala 92:26:@87.4]
  assign bboxIntersect_io_min_0 = io_rayNodeIn_bits_node_bbox_min_0; // @[BVHTraversal.scala 93:26:@98.4]
  assign bboxIntersect_io_min_1 = io_rayNodeIn_bits_node_bbox_min_1; // @[BVHTraversal.scala 93:26:@99.4]
  assign bboxIntersect_io_min_2 = io_rayNodeIn_bits_node_bbox_min_2; // @[BVHTraversal.scala 93:26:@100.4]
  assign bboxIntersect_io_max_0 = io_rayNodeIn_bits_node_bbox_max_0; // @[BVHTraversal.scala 94:26:@101.4]
  assign bboxIntersect_io_max_1 = io_rayNodeIn_bits_node_bbox_max_1; // @[BVHTraversal.scala 94:26:@102.4]
  assign bboxIntersect_io_max_2 = io_rayNodeIn_bits_node_bbox_max_2; // @[BVHTraversal.scala 94:26:@103.4]
endmodule
