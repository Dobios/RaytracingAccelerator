module SimultaneousUpDownSaturatingCounter( // @[:@21.2]
  input         clock, // @[:@22.4]
  input         reset, // @[:@23.4]
  output [10:0] io_currValue, // @[:@24.4]
  input         io_increment, // @[:@24.4]
  input         io_decrement, // @[:@24.4]
  output        io_saturatingUp, // @[:@24.4]
  output        io_saturatingDown // @[:@24.4]
);
  wire  _T_20; // @[UpDownCounters.scala 71:46:@26.4]
  wire [11:0] _T_22; // @[UpDownCounters.scala 71:71:@27.4]
  wire [10:0] _T_23; // @[UpDownCounters.scala 71:71:@28.4]
  wire [10:0] saturatingIncrement; // @[UpDownCounters.scala 71:32:@29.4]
  wire  _T_25; // @[UpDownCounters.scala 72:46:@30.4]
  wire [11:0] _T_27; // @[UpDownCounters.scala 72:66:@31.4]
  wire [11:0] _T_28; // @[UpDownCounters.scala 72:66:@32.4]
  wire [10:0] _T_29; // @[UpDownCounters.scala 72:66:@33.4]
  wire [10:0] saturatingDecrement; // @[UpDownCounters.scala 72:32:@34.4]
  wire  _T_30; // @[UpDownCounters.scala 74:19:@35.4]
  wire [10:0] _T_31; // @[Mux.scala 61:16:@36.4]
  wire [10:0] _T_32; // @[Mux.scala 61:16:@37.4]
  wire [10:0] _T_33; // @[Mux.scala 61:16:@38.4]
  reg [10:0] _T_37; // @[UpDownCounters.scala 73:26:@40.4]
  reg [31:0] _RAND_0;
  assign _T_20 = io_currValue < 11'h400; // @[UpDownCounters.scala 71:46:@26.4]
  assign _T_22 = io_currValue + 11'h1; // @[UpDownCounters.scala 71:71:@27.4]
  assign _T_23 = io_currValue + 11'h1; // @[UpDownCounters.scala 71:71:@28.4]
  assign saturatingIncrement = _T_20 ? _T_23 : io_currValue; // @[UpDownCounters.scala 71:32:@29.4]
  assign _T_25 = io_currValue > 11'h0; // @[UpDownCounters.scala 72:46:@30.4]
  assign _T_27 = io_currValue - 11'h1; // @[UpDownCounters.scala 72:66:@31.4]
  assign _T_28 = $unsigned(_T_27); // @[UpDownCounters.scala 72:66:@32.4]
  assign _T_29 = _T_28[10:0]; // @[UpDownCounters.scala 72:66:@33.4]
  assign saturatingDecrement = _T_25 ? _T_29 : io_currValue; // @[UpDownCounters.scala 72:32:@34.4]
  assign _T_30 = io_increment & io_decrement; // @[UpDownCounters.scala 74:19:@35.4]
  assign _T_31 = io_decrement ? saturatingDecrement : io_currValue; // @[Mux.scala 61:16:@36.4]
  assign _T_32 = io_increment ? saturatingIncrement : _T_31; // @[Mux.scala 61:16:@37.4]
  assign _T_33 = _T_30 ? io_currValue : _T_32; // @[Mux.scala 61:16:@38.4]
  assign io_currValue = _T_37; // @[UpDownCounters.scala 73:16:@42.4]
  assign io_saturatingUp = io_currValue == 11'h400; // @[UpDownCounters.scala 78:19:@44.4]
  assign io_saturatingDown = io_currValue == 11'h0; // @[UpDownCounters.scala 79:21:@46.4]
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE
  integer initvar;
  initial begin
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      #0.002 begin end
    `endif
  `ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  _T_37 = _RAND_0[10:0];
  `endif // RANDOMIZE_REG_INIT
  end
`endif // RANDOMIZE
  always @(posedge clock) begin
    if (reset) begin
      _T_37 <= 11'h400;
    end else begin
      if (_T_30) begin
        _T_37 <= io_currValue;
      end else begin
        if (io_increment) begin
          if (_T_20) begin
            _T_37 <= _T_23;
          end else begin
            _T_37 <= io_currValue;
          end
        end else begin
          if (io_decrement) begin
            if (_T_25) begin
              _T_37 <= _T_29;
            end else begin
              _T_37 <= io_currValue;
            end
          end else begin
            _T_37 <= io_currValue;
          end
        end
      end
    end
  end
endmodule
module BRAMQueue( // @[:@48.2]
  input        clock, // @[:@49.4]
  input        reset, // @[:@50.4]
  input        io_enq_valid, // @[:@51.4]
  input  [9:0] io_enq_bits, // @[:@51.4]
  input        io_deq_ready, // @[:@51.4]
  output       io_deq_valid, // @[:@51.4]
  output [9:0] io_deq_bits // @[:@51.4]
);
  wire  memory_reset; // @[BRAMQueue.scala 20:24:@53.4]
  wire  memory_clock; // @[BRAMQueue.scala 20:24:@53.4]
  wire [9:0] memory_doutb; // @[BRAMQueue.scala 20:24:@53.4]
  wire  memory_regceb; // @[BRAMQueue.scala 20:24:@53.4]
  wire  memory_enb; // @[BRAMQueue.scala 20:24:@53.4]
  wire  memory_wea; // @[BRAMQueue.scala 20:24:@53.4]
  wire [9:0] memory_dina; // @[BRAMQueue.scala 20:24:@53.4]
  wire [9:0] memory_addrb; // @[BRAMQueue.scala 20:24:@53.4]
  wire [9:0] memory_addra; // @[BRAMQueue.scala 20:24:@53.4]
  wire  elemCounter_clock; // @[BRAMQueue.scala 59:29:@118.4]
  wire  elemCounter_reset; // @[BRAMQueue.scala 59:29:@118.4]
  wire [10:0] elemCounter_io_currValue; // @[BRAMQueue.scala 59:29:@118.4]
  wire  elemCounter_io_increment; // @[BRAMQueue.scala 59:29:@118.4]
  wire  elemCounter_io_decrement; // @[BRAMQueue.scala 59:29:@118.4]
  wire  elemCounter_io_saturatingUp; // @[BRAMQueue.scala 59:29:@118.4]
  wire  elemCounter_io_saturatingDown; // @[BRAMQueue.scala 59:29:@118.4]
  wire  full; // @[BRAMQueue.scala 24:20:@65.4 BRAMQueue.scala 64:10:@125.4]
  wire  _T_17; // @[BRAMQueue.scala 26:31:@67.4]
  wire  wrEn; // @[BRAMQueue.scala 26:29:@68.4]
  reg [9:0] value; // @[Counter.scala 26:33:@69.4]
  reg [31:0] _RAND_0;
  wire [10:0] _T_23; // @[Counter.scala 35:22:@72.6]
  wire [9:0] _T_24; // @[Counter.scala 35:22:@73.6]
  wire [9:0] _GEN_0; // @[Counter.scala 63:17:@70.4]
  reg [9:0] value_1; // @[Counter.scala 26:33:@82.4]
  reg [31:0] _RAND_1;
  wire [10:0] _T_33; // @[Counter.scala 35:22:@85.6]
  wire [9:0] _T_34; // @[Counter.scala 35:22:@86.6]
  wire  bramEmpty; // @[BRAMQueue.scala 42:25:@80.4 BRAMQueue.scala 65:15:@126.4]
  wire  _T_41; // @[BRAMQueue.scala 49:13:@98.4]
  reg  valid0; // @[Reg.scala 19:20:@94.4]
  reg [31:0] _RAND_2;
  wire  _T_42; // @[BRAMQueue.scala 49:26:@99.4]
  wire  _T_43; // @[BRAMQueue.scala 49:24:@100.4]
  reg  valid1; // @[Reg.scala 19:20:@107.4]
  reg [31:0] _RAND_3;
  wire  _T_49; // @[BRAMQueue.scala 53:25:@111.4]
  wire  _T_50; // @[BRAMQueue.scala 53:23:@112.4]
  wire  regceb; // @[BRAMQueue.scala 53:34:@113.4]
  wire  enb; // @[BRAMQueue.scala 49:35:@101.4]
  wire  rdEn; // @[BRAMQueue.scala 51:17:@105.4]
  wire [9:0] _GEN_1; // @[Counter.scala 63:17:@83.4]
  wire  _GEN_2; // @[Reg.scala 20:19:@95.4]
  wire  _GEN_3; // @[Reg.scala 20:19:@108.4]
  XilinxSimpleDualPortNoChangeBRAM #(.RAM_STYLE("block"), .RAM_WIDTH(10), .RAM_DEPTH(1024), .RAM_PERFORMANCE("HIGH_PERFORMANCE"), .INIT_FILE("/home/andrewdobis/Desktop/Bachelor_Thesis/Raytracer/lap---raytracing-hardware-accelerator-for-fpga/Raytracer_Chisel/src/main/outputs/FLQBRAM0.mif")) memory ( // @[BRAMQueue.scala 20:24:@53.4]
    .reset(memory_reset),
    .clock(memory_clock),
    .doutb(memory_doutb),
    .regceb(memory_regceb),
    .enb(memory_enb),
    .wea(memory_wea),
    .dina(memory_dina),
    .addrb(memory_addrb),
    .addra(memory_addra)
  );
  SimultaneousUpDownSaturatingCounter elemCounter ( // @[BRAMQueue.scala 59:29:@118.4]
    .clock(elemCounter_clock),
    .reset(elemCounter_reset),
    .io_currValue(elemCounter_io_currValue),
    .io_increment(elemCounter_io_increment),
    .io_decrement(elemCounter_io_decrement),
    .io_saturatingUp(elemCounter_io_saturatingUp),
    .io_saturatingDown(elemCounter_io_saturatingDown)
  );
  assign full = elemCounter_io_saturatingUp; // @[BRAMQueue.scala 24:20:@65.4 BRAMQueue.scala 64:10:@125.4]
  assign _T_17 = ~ full; // @[BRAMQueue.scala 26:31:@67.4]
  assign wrEn = io_enq_valid & _T_17; // @[BRAMQueue.scala 26:29:@68.4]
  assign _T_23 = value + 10'h1; // @[Counter.scala 35:22:@72.6]
  assign _T_24 = value + 10'h1; // @[Counter.scala 35:22:@73.6]
  assign _GEN_0 = wrEn ? _T_24 : value; // @[Counter.scala 63:17:@70.4]
  assign _T_33 = value_1 + 10'h1; // @[Counter.scala 35:22:@85.6]
  assign _T_34 = value_1 + 10'h1; // @[Counter.scala 35:22:@86.6]
  assign bramEmpty = elemCounter_io_saturatingDown; // @[BRAMQueue.scala 42:25:@80.4 BRAMQueue.scala 65:15:@126.4]
  assign _T_41 = ~ bramEmpty; // @[BRAMQueue.scala 49:13:@98.4]
  assign _T_42 = ~ valid0; // @[BRAMQueue.scala 49:26:@99.4]
  assign _T_43 = _T_41 & _T_42; // @[BRAMQueue.scala 49:24:@100.4]
  assign _T_49 = ~ valid1; // @[BRAMQueue.scala 53:25:@111.4]
  assign _T_50 = valid0 & _T_49; // @[BRAMQueue.scala 53:23:@112.4]
  assign regceb = _T_50 | io_deq_ready; // @[BRAMQueue.scala 53:34:@113.4]
  assign enb = _T_43 | regceb; // @[BRAMQueue.scala 49:35:@101.4]
  assign rdEn = enb & _T_41; // @[BRAMQueue.scala 51:17:@105.4]
  assign _GEN_1 = rdEn ? _T_34 : value_1; // @[Counter.scala 63:17:@83.4]
  assign _GEN_2 = enb ? _T_41 : valid0; // @[Reg.scala 20:19:@95.4]
  assign _GEN_3 = regceb ? valid0 : valid1; // @[Reg.scala 20:19:@108.4]
  assign io_deq_valid = valid1; // @[BRAMQueue.scala 55:18:@116.4]
  assign io_deq_bits = memory_doutb; // @[BRAMQueue.scala 56:17:@117.4]
  assign memory_reset = reset; // @[BRAMQueue.scala 23:21:@64.4]
  assign memory_clock = clock; // @[BRAMQueue.scala 22:21:@63.4]
  assign memory_regceb = _T_50 | io_deq_ready; // @[BRAMQueue.scala 54:22:@115.4]
  assign memory_enb = _T_43 | regceb; // @[BRAMQueue.scala 50:19:@103.4]
  assign memory_wea = io_enq_valid & _T_17; // @[BRAMQueue.scala 32:19:@78.4]
  assign memory_dina = io_enq_bits; // @[BRAMQueue.scala 33:20:@79.4]
  assign memory_addrb = value_1; // @[BRAMQueue.scala 45:21:@90.4]
  assign memory_addra = value; // @[BRAMQueue.scala 31:21:@77.4]
  assign elemCounter_clock = clock; // @[:@119.4]
  assign elemCounter_reset = reset; // @[:@120.4]
  assign elemCounter_io_increment = io_enq_valid & _T_17; // @[BRAMQueue.scala 60:30:@121.4]
  assign elemCounter_io_decrement = enb & _T_41; // @[BRAMQueue.scala 61:30:@122.4]
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE
  integer initvar;
  initial begin
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      #0.002 begin end
    `endif
  `ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  value = _RAND_0[9:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{`RANDOM}};
  value_1 = _RAND_1[9:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_2 = {1{`RANDOM}};
  valid0 = _RAND_2[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_3 = {1{`RANDOM}};
  valid1 = _RAND_3[0:0];
  `endif // RANDOMIZE_REG_INIT
  end
`endif // RANDOMIZE
  always @(posedge clock) begin
    if (reset) begin
      value <= 10'h0;
    end else begin
      if (wrEn) begin
        value <= _T_24;
      end
    end
    if (reset) begin
      value_1 <= 10'h0;
    end else begin
      if (rdEn) begin
        value_1 <= _T_34;
      end
    end
    if (reset) begin
      valid0 <= 1'h0;
    end else begin
      if (enb) begin
        valid0 <= _T_41;
      end
    end
    if (reset) begin
      valid1 <= 1'h0;
    end else begin
      if (regceb) begin
        valid1 <= valid0;
      end
    end
  end
endmodule
module FreeLabelQueue( // @[:@153.2]
  input        clock, // @[:@154.4]
  input        reset, // @[:@155.4]
  input        io_enq_valid, // @[:@156.4]
  input  [9:0] io_enq_bits, // @[:@156.4]
  input        io_deq_ready, // @[:@156.4]
  output       io_deq_valid, // @[:@156.4]
  output [9:0] io_deq_bits // @[:@156.4]
);
  wire  bramQueue_clock; // @[BRAMQueue.scala 106:25:@158.4]
  wire  bramQueue_reset; // @[BRAMQueue.scala 106:25:@158.4]
  wire  bramQueue_io_enq_valid; // @[BRAMQueue.scala 106:25:@158.4]
  wire [9:0] bramQueue_io_enq_bits; // @[BRAMQueue.scala 106:25:@158.4]
  wire  bramQueue_io_deq_ready; // @[BRAMQueue.scala 106:25:@158.4]
  wire  bramQueue_io_deq_valid; // @[BRAMQueue.scala 106:25:@158.4]
  wire [9:0] bramQueue_io_deq_bits; // @[BRAMQueue.scala 106:25:@158.4]
  BRAMQueue bramQueue ( // @[BRAMQueue.scala 106:25:@158.4]
    .clock(bramQueue_clock),
    .reset(bramQueue_reset),
    .io_enq_valid(bramQueue_io_enq_valid),
    .io_enq_bits(bramQueue_io_enq_bits),
    .io_deq_ready(bramQueue_io_deq_ready),
    .io_deq_valid(bramQueue_io_deq_valid),
    .io_deq_bits(bramQueue_io_deq_bits)
  );
  assign io_deq_valid = bramQueue_io_deq_valid; // @[BRAMQueue.scala 108:10:@165.4]
  assign io_deq_bits = bramQueue_io_deq_bits; // @[BRAMQueue.scala 108:10:@164.4]
  assign bramQueue_clock = clock; // @[:@159.4]
  assign bramQueue_reset = reset; // @[:@160.4]
  assign bramQueue_io_enq_valid = io_enq_valid; // @[BRAMQueue.scala 107:10:@162.4]
  assign bramQueue_io_enq_bits = io_enq_bits; // @[BRAMQueue.scala 107:10:@161.4]
  assign bramQueue_io_deq_ready = io_deq_ready; // @[BRAMQueue.scala 108:10:@166.4]
endmodule
module FetchBVH( // @[:@188.2]
  input          clock, // @[:@189.4]
  input          reset, // @[:@190.4]
  output         io_rayIn_ready, // @[:@191.4]
  input          io_rayIn_valid, // @[:@191.4]
  input  [31:0]  io_rayIn_bits_origin_0, // @[:@191.4]
  input  [31:0]  io_rayIn_bits_origin_1, // @[:@191.4]
  input  [31:0]  io_rayIn_bits_origin_2, // @[:@191.4]
  input  [31:0]  io_rayIn_bits_dir_0, // @[:@191.4]
  input  [31:0]  io_rayIn_bits_dir_1, // @[:@191.4]
  input  [31:0]  io_rayIn_bits_dir_2, // @[:@191.4]
  input  [31:0]  io_rayIn_bits_dRcp_0, // @[:@191.4]
  input  [31:0]  io_rayIn_bits_dRcp_1, // @[:@191.4]
  input  [31:0]  io_rayIn_bits_dRcp_2, // @[:@191.4]
  input  [31:0]  io_rayIn_bits_minT, // @[:@191.4]
  input  [31:0]  io_rayIn_bits_maxT, // @[:@191.4]
  input  [31:0]  io_rayIn_bits_id, // @[:@191.4]
  input          io_rayNodeIdxOut_ready, // @[:@191.4]
  output         io_rayNodeIdxOut_valid, // @[:@191.4]
  output [31:0]  io_rayNodeIdxOut_bits_ray_origin_0, // @[:@191.4]
  output [31:0]  io_rayNodeIdxOut_bits_ray_origin_1, // @[:@191.4]
  output [31:0]  io_rayNodeIdxOut_bits_ray_origin_2, // @[:@191.4]
  output [31:0]  io_rayNodeIdxOut_bits_ray_dir_0, // @[:@191.4]
  output [31:0]  io_rayNodeIdxOut_bits_ray_dir_1, // @[:@191.4]
  output [31:0]  io_rayNodeIdxOut_bits_ray_dir_2, // @[:@191.4]
  output [31:0]  io_rayNodeIdxOut_bits_ray_dRcp_0, // @[:@191.4]
  output [31:0]  io_rayNodeIdxOut_bits_ray_dRcp_1, // @[:@191.4]
  output [31:0]  io_rayNodeIdxOut_bits_ray_dRcp_2, // @[:@191.4]
  output [31:0]  io_rayNodeIdxOut_bits_ray_minT, // @[:@191.4]
  output [31:0]  io_rayNodeIdxOut_bits_ray_maxT, // @[:@191.4]
  output [31:0]  io_rayNodeIdxOut_bits_ray_id, // @[:@191.4]
  output [10:0]  io_rayNodeIdxOut_bits_nodeIdx, // @[:@191.4]
  input          io_node_ready, // @[:@191.4]
  output         io_node_valid, // @[:@191.4]
  output [63:0]  io_node_bits_data, // @[:@191.4]
  output [31:0]  io_node_bits_bbox_min_0, // @[:@191.4]
  output [31:0]  io_node_bits_bbox_min_1, // @[:@191.4]
  output [31:0]  io_node_bits_bbox_min_2, // @[:@191.4]
  output [31:0]  io_node_bits_bbox_max_0, // @[:@191.4]
  output [31:0]  io_node_bits_bbox_max_1, // @[:@191.4]
  output [31:0]  io_node_bits_bbox_max_2, // @[:@191.4]
  input          io_addrOut_ready, // @[:@191.4]
  output         io_addrOut_valid, // @[:@191.4]
  output [9:0]   io_addrOut_bits_id, // @[:@191.4]
  output [10:0]  io_addrOut_bits_nodeIdx, // @[:@191.4]
  output         io_dataIn_ready, // @[:@191.4]
  input          io_dataIn_valid, // @[:@191.4]
  input  [9:0]   io_dataIn_bits_id, // @[:@191.4]
  input  [255:0] io_dataIn_bits_data, // @[:@191.4]
  input          io_memReadyIn // @[:@191.4]
);
  wire  rayIdQ_clock; // @[FetchBVH.scala 30:41:@193.4]
  wire  rayIdQ_reset; // @[FetchBVH.scala 30:41:@193.4]
  wire  rayIdQ_io_enq_valid; // @[FetchBVH.scala 30:41:@193.4]
  wire [9:0] rayIdQ_io_enq_bits; // @[FetchBVH.scala 30:41:@193.4]
  wire  rayIdQ_io_deq_ready; // @[FetchBVH.scala 30:41:@193.4]
  wire  rayIdQ_io_deq_valid; // @[FetchBVH.scala 30:41:@193.4]
  wire [9:0] rayIdQ_io_deq_bits; // @[FetchBVH.scala 30:41:@193.4]
  wire  rayBuffer_reset; // @[FetchBVH.scala 37:33:@197.4]
  wire  rayBuffer_clock; // @[FetchBVH.scala 37:33:@197.4]
  wire [394:0] rayBuffer_doutb; // @[FetchBVH.scala 37:33:@197.4]
  wire  rayBuffer_regceb; // @[FetchBVH.scala 37:33:@197.4]
  wire  rayBuffer_enb; // @[FetchBVH.scala 37:33:@197.4]
  wire  rayBuffer_wea; // @[FetchBVH.scala 37:33:@197.4]
  wire [394:0] rayBuffer_dina; // @[FetchBVH.scala 37:33:@197.4]
  wire [9:0] rayBuffer_addrb; // @[FetchBVH.scala 37:33:@197.4]
  wire [9:0] rayBuffer_addra; // @[FetchBVH.scala 37:33:@197.4]
  reg  _T_146; // @[Reg.scala 19:20:@214.4]
  reg [31:0] _RAND_0;
  wire  resultReady; // @[FetchBVH.scala 62:47:@231.4]
  wire  _T_148; // @[FetchBVH.scala 57:40:@224.4]
  wire  resultValid; // @[FetchBVH.scala 57:65:@225.4]
  wire  _GEN_0; // @[Reg.scala 20:19:@215.4]
  reg  delayedResultValid; // @[Reg.scala 19:20:@218.4]
  reg [31:0] _RAND_1;
  wire  _GEN_1; // @[Reg.scala 20:19:@219.4]
  wire [170:0] _T_160; // @[FetchBVH.scala 82:43:@259.4]
  wire [223:0] _T_166; // @[FetchBVH.scala 82:43:@265.4]
  wire [394:0] _T_183; // @[:@281.4 :@282.4]
  reg [255:0] _T_203; // @[Reg.scala 11:16:@322.4]
  reg [255:0] _RAND_2;
  reg [255:0] _T_205; // @[Reg.scala 11:16:@326.4]
  reg [255:0] _RAND_3;
  FreeLabelQueue rayIdQ ( // @[FetchBVH.scala 30:41:@193.4]
    .clock(rayIdQ_clock),
    .reset(rayIdQ_reset),
    .io_enq_valid(rayIdQ_io_enq_valid),
    .io_enq_bits(rayIdQ_io_enq_bits),
    .io_deq_ready(rayIdQ_io_deq_ready),
    .io_deq_valid(rayIdQ_io_deq_valid),
    .io_deq_bits(rayIdQ_io_deq_bits)
  );
  XilinxSimpleDualPortNoChangeBRAM #(.RAM_STYLE("block"), .RAM_WIDTH(395), .RAM_DEPTH(1024), .RAM_PERFORMANCE("HIGH_PERFORMANCE"), .INIT_FILE("")) rayBuffer ( // @[FetchBVH.scala 37:33:@197.4]
    .reset(rayBuffer_reset),
    .clock(rayBuffer_clock),
    .doutb(rayBuffer_doutb),
    .regceb(rayBuffer_regceb),
    .enb(rayBuffer_enb),
    .wea(rayBuffer_wea),
    .dina(rayBuffer_dina),
    .addrb(rayBuffer_addrb),
    .addra(rayBuffer_addra)
  );
  assign resultReady = io_rayNodeIdxOut_ready & io_node_ready; // @[FetchBVH.scala 62:47:@231.4]
  assign _T_148 = io_dataIn_valid & io_rayNodeIdxOut_ready; // @[FetchBVH.scala 57:40:@224.4]
  assign resultValid = _T_148 & io_node_ready; // @[FetchBVH.scala 57:65:@225.4]
  assign _GEN_0 = resultReady ? resultValid : _T_146; // @[Reg.scala 20:19:@215.4]
  assign _GEN_1 = resultReady ? _T_146 : delayedResultValid; // @[Reg.scala 20:19:@219.4]
  assign _T_160 = {io_rayIn_bits_dRcp_1,io_rayIn_bits_dRcp_0,io_rayIn_bits_minT,io_rayIn_bits_maxT,io_rayIn_bits_id,11'h0}; // @[FetchBVH.scala 82:43:@259.4]
  assign _T_166 = {io_rayIn_bits_origin_2,io_rayIn_bits_origin_1,io_rayIn_bits_origin_0,io_rayIn_bits_dir_2,io_rayIn_bits_dir_1,io_rayIn_bits_dir_0,io_rayIn_bits_dRcp_2}; // @[FetchBVH.scala 82:43:@265.4]
  assign _T_183 = rayBuffer_doutb; // @[:@281.4 :@282.4]
  assign io_rayIn_ready = rayIdQ_io_deq_valid & io_addrOut_ready; // @[FetchBVH.scala 65:33:@234.4]
  assign io_rayNodeIdxOut_valid = delayedResultValid; // @[FetchBVH.scala 93:32:@275.4]
  assign io_rayNodeIdxOut_bits_ray_origin_0 = _T_183[330:299]; // @[FetchBVH.scala 97:31:@319.4]
  assign io_rayNodeIdxOut_bits_ray_origin_1 = _T_183[362:331]; // @[FetchBVH.scala 97:31:@320.4]
  assign io_rayNodeIdxOut_bits_ray_origin_2 = _T_183[394:363]; // @[FetchBVH.scala 97:31:@321.4]
  assign io_rayNodeIdxOut_bits_ray_dir_0 = _T_183[234:203]; // @[FetchBVH.scala 97:31:@316.4]
  assign io_rayNodeIdxOut_bits_ray_dir_1 = _T_183[266:235]; // @[FetchBVH.scala 97:31:@317.4]
  assign io_rayNodeIdxOut_bits_ray_dir_2 = _T_183[298:267]; // @[FetchBVH.scala 97:31:@318.4]
  assign io_rayNodeIdxOut_bits_ray_dRcp_0 = _T_183[138:107]; // @[FetchBVH.scala 97:31:@313.4]
  assign io_rayNodeIdxOut_bits_ray_dRcp_1 = _T_183[170:139]; // @[FetchBVH.scala 97:31:@314.4]
  assign io_rayNodeIdxOut_bits_ray_dRcp_2 = _T_183[202:171]; // @[FetchBVH.scala 97:31:@315.4]
  assign io_rayNodeIdxOut_bits_ray_minT = _T_183[106:75]; // @[FetchBVH.scala 97:31:@312.4]
  assign io_rayNodeIdxOut_bits_ray_maxT = _T_183[74:43]; // @[FetchBVH.scala 97:31:@311.4]
  assign io_rayNodeIdxOut_bits_ray_id = _T_183[42:11]; // @[FetchBVH.scala 97:31:@310.4]
  assign io_rayNodeIdxOut_bits_nodeIdx = _T_183[10:0]; // @[FetchBVH.scala 97:31:@309.4]
  assign io_node_valid = delayedResultValid; // @[FetchBVH.scala 94:36:@276.4]
  assign io_node_bits_data = _T_205[255:192]; // @[FetchBVH.scala 98:35:@353.4]
  assign io_node_bits_bbox_min_0 = _T_205[127:96]; // @[FetchBVH.scala 98:35:@350.4]
  assign io_node_bits_bbox_min_1 = _T_205[159:128]; // @[FetchBVH.scala 98:35:@351.4]
  assign io_node_bits_bbox_min_2 = _T_205[191:160]; // @[FetchBVH.scala 98:35:@352.4]
  assign io_node_bits_bbox_max_0 = _T_205[31:0]; // @[FetchBVH.scala 98:35:@347.4]
  assign io_node_bits_bbox_max_1 = _T_205[63:32]; // @[FetchBVH.scala 98:35:@348.4]
  assign io_node_bits_bbox_max_2 = _T_205[95:64]; // @[FetchBVH.scala 98:35:@349.4]
  assign io_addrOut_valid = rayIdQ_io_deq_valid & io_rayIn_valid; // @[FetchBVH.scala 70:33:@238.4]
  assign io_addrOut_bits_id = rayIdQ_io_deq_bits; // @[FetchBVH.scala 87:26:@273.4]
  assign io_addrOut_bits_nodeIdx = 11'h0; // @[FetchBVH.scala 87:26:@272.4]
  assign io_dataIn_ready = io_memReadyIn; // @[FetchBVH.scala 74:25:@240.4]
  assign rayIdQ_clock = clock; // @[:@194.4]
  assign rayIdQ_reset = reset; // @[:@195.4]
  assign rayIdQ_io_enq_valid = _T_148 & io_node_ready; // @[FetchBVH.scala 71:29:@239.4]
  assign rayIdQ_io_enq_bits = io_dataIn_bits_id; // @[FetchBVH.scala 90:28:@274.4]
  assign rayIdQ_io_deq_ready = io_addrOut_ready & io_rayIn_valid; // @[FetchBVH.scala 66:29:@235.4]
  assign rayBuffer_reset = reset; // @[FetchBVH.scala 54:28:@223.4]
  assign rayBuffer_clock = clock; // @[FetchBVH.scala 53:28:@222.4]
  assign rayBuffer_regceb = io_rayNodeIdxOut_ready & io_node_ready; // @[XilinxBRAM.scala 48:17:@278.4]
  assign rayBuffer_enb = io_rayNodeIdxOut_ready & io_node_ready; // @[XilinxBRAM.scala 49:14:@279.4]
  assign rayBuffer_wea = io_rayIn_valid & rayIdQ_io_deq_valid; // @[XilinxBRAM.scala 41:14:@267.4]
  assign rayBuffer_dina = {_T_166,_T_160}; // @[XilinxBRAM.scala 43:15:@269.4]
  assign rayBuffer_addrb = io_dataIn_bits_id; // @[XilinxBRAM.scala 47:16:@277.4]
  assign rayBuffer_addra = rayIdQ_io_deq_bits; // @[XilinxBRAM.scala 42:16:@268.4]
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE
  integer initvar;
  initial begin
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      #0.002 begin end
    `endif
  `ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  _T_146 = _RAND_0[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{`RANDOM}};
  delayedResultValid = _RAND_1[0:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_2 = {8{`RANDOM}};
  _T_203 = _RAND_2[255:0];
  `endif // RANDOMIZE_REG_INIT
  `ifdef RANDOMIZE_REG_INIT
  _RAND_3 = {8{`RANDOM}};
  _T_205 = _RAND_3[255:0];
  `endif // RANDOMIZE_REG_INIT
  end
`endif // RANDOMIZE
  always @(posedge clock) begin
    if (reset) begin
      _T_146 <= 1'h0;
    end else begin
      if (resultReady) begin
        _T_146 <= resultValid;
      end
    end
    if (reset) begin
      delayedResultValid <= 1'h0;
    end else begin
      if (resultReady) begin
        delayedResultValid <= _T_146;
      end
    end
    if (resultReady) begin
      _T_203 <= io_dataIn_bits_data;
    end
    if (resultReady) begin
      _T_205 <= _T_203;
    end
  end
endmodule
