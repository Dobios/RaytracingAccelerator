----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/11/2019 06:12:56 PM
-- Design Name: 
-- Module Name: TraversalTest - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use work.memory_pkg.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity TraversalTest is
end TraversalTest;

architecture traversal of TraversalTest is
    -- Simulation parameters
    constant P_REQ_VALID              : real    := 1.0;
    constant P_MEM_READY              : real    := 1.0;
    constant P_RESP_READY             : real    := 1.0;
    constant MIN_MEM_LATENCY          : integer := 10;
    constant MAX_MEM_LATENCY          : integer := 32;
    constant MAX_MEM_INFLIGHT_REQUESTS: integer := MAX_MEM_LATENCY;
    constant MAX_IN_FLIGHT_REQUESTS   : integer := 8192;
    constant NUM_NODES                : integer := 76787; -- defines memory array size
    constant CURR_NODES_PREFIX        : integer := 0;
    constant NODE_DATA_WIDTH          : integer := 32;
    constant clock_period             : time    := 1 ns;
    
    -- clock and reset
    signal clock : std_logic;
    signal reset : std_logic; 
    
    -- BVHTraversal I/O signals
    signal rayNodeIn                : ray_node_t;
    signal rayNodeIn_valid          : std_logic;
    signal rayNodeIn_ready          : std_logic;
    signal rayNodeStackIdxOut       : ray_node_stackIdx_t;
    signal rayNodeStackIdxOut_valid : std_logic;
    signal rayNodeStackIdxOut_ready : std_logic;
    
    -- Mikail's Memory System Interface
    signal addrOut_bits_id        : std_logic_vector(ID_WIDTH - 1 downto 0);
    signal addrOut_bits_nodeIdx   : std_logic_vector(NODE_ID_WIDTH - 1 downto 0);
    signal addrOut_ready          : std_logic;
    signal addrOut_valid          : std_logic;
    signal dataIn_bits_id         : std_logic_vector(ID_WIDTH - 1 downto 0);
    signal dataIn_bits_data       : std_logic_vector(255 downto 0);
    signal dataIn_valid           : std_logic;
    signal dataIn_ready           : std_logic;
    
     -- Control boolean & bvh_root constant
    signal done     : boolean;  
    signal bvh_root : node_t;
  
    -- Memory component ports
    signal ray_addr  : integer := 0;
    signal ray_data  : ray_t;
    signal node_addr : integer := 0;
    signal node_data : node_t;
  
    -- Memory Components
    component ray_memory is
        port(
          address : in integer;
          data    : out ray_t
        );
    end component ray_memory;
  
    component node_memory is
        port(
          address : in integer;
          data    : out node_t
      );
    end component node_memory;
  
    -- Procedures
      procedure sync_wait_until_value (
         signal sig   : in std_logic;
         constant val : in std_logic;
         signal clk   : in std_logic
      ) is
      begin
         while sig /= val loop
             wait until rising_edge(clk);
         end loop;
      end sync_wait_until_value;
      
      -- Functions
      function is_leaf(
        node : node_t
      ) return boolean is
      begin 
          return node.data(63) = '1';
      end function is_leaf;
    
begin

    --Instantiate DUT
--    bbox : entity work.BboxIntersect
--    port map(
--          clock => clock, 
--          reset => reset,
--          io_enable => intersect_ready,
--          io_ray_origin_0 => rayNodeIn.ray.origin(0),
--          io_ray_origin_1 => rayNodeIn.ray.origin(1),
--          io_ray_origin_2 => rayNodeIn.ray.origin(2),
--          io_ray_dir_0 => rayNodeIn.ray.dir(0),
--          io_ray_dir_1 => rayNodeIn.ray.dir(1),
--          io_ray_dir_2 => rayNodeIn.ray.dir(2),
--          io_ray_dRcp_0 => rayNodeIn.ray.dRcp(0),
--          io_ray_dRcp_1 => rayNodeIn.ray.dRcp(1),
--          io_ray_dRcp_2 => rayNodeIn.ray.dRcp(2),
--          io_ray_minT => rayNodeIn.ray.minT,
--          io_ray_maxT => rayNodeIn.ray.maxT,
--          io_min_0 => rayNodeIn.node.bbox.min(0),
--          io_min_1 => rayNodeIn.node.bbox.min(1),
--          io_min_2 => rayNodeIn.node.bbox.min(2),
--          io_max_0 => rayNodeIn.node.bbox.max(0),
--          io_max_1 => rayNodeIn.node.bbox.max(1),
--          io_max_2 => rayNodeIn.node.bbox.max(2),
--          io_intersect => intersect
--        );

    --Instantiate DUT
    traversal: entity work.BVHTraversal
    port map(
      clock => clock,
      reset => reset, 
      io_rayNodeIn_ready => rayNodeIn_ready,
      io_rayNodeIn_valid => rayNodeIn_valid,
      io_rayNodeIn_bits_ray_origin_0 => rayNodeIn.ray.origin(0),
      io_rayNodeIn_bits_ray_origin_1 => rayNodeIn.ray.origin(1),
      io_rayNodeIn_bits_ray_origin_2 => rayNodeIn.ray.origin(2),
      io_rayNodeIn_bits_ray_dir_0 => rayNodeIn.ray.dir(0),
      io_rayNodeIn_bits_ray_dir_1 => rayNodeIn.ray.dir(1),
      io_rayNodeIn_bits_ray_dir_2 => rayNodeIn.ray.dir(2),
      io_rayNodeIn_bits_ray_dRcp_0 => rayNodeIn.ray.dRcp(0),
      io_rayNodeIn_bits_ray_dRcp_1 => rayNodeIn.ray.dRcp(1),
      io_rayNodeIn_bits_ray_dRcp_2 => rayNodeIn.ray.dRcp(2),
      io_rayNodeIn_bits_ray_minT => rayNodeIn.ray.minT,
      io_rayNodeIn_bits_ray_maxT => rayNodeIn.ray.maxT,
      io_rayNodeIn_bits_ray_id => rayNodeIn.ray.id,
      io_rayNodeIn_bits_node_data => rayNodeIn.node.data,
      io_rayNodeIn_bits_node_bbox_min_0 => rayNodeIn.node.bbox.min(0),
      io_rayNodeIn_bits_node_bbox_min_1 => rayNodeIn.node.bbox.min(1),
      io_rayNodeIn_bits_node_bbox_min_2 => rayNodeIn.node.bbox.min(2),
      io_rayNodeIn_bits_node_bbox_max_0 => rayNodeIn.node.bbox.max(0),
      io_rayNodeIn_bits_node_bbox_max_1 => rayNodeIn.node.bbox.max(1),
      io_rayNodeIn_bits_node_bbox_max_2 => rayNodeIn.node.bbox.max(2),
      io_rayNodeIn_bits_nodeIdx => rayNodeIn.nodeIdx,
      io_rayNodeStackIdxOut_ready => rayNodeStackIdxOut_ready,
      io_rayNodeStackIdxOut_valid => rayNodeStackIdxOut_valid,
      io_rayNodeStackIdxOut_bits_ray_origin_0 => rayNodeStackIdxOut.ray.origin(0),
      io_rayNodeStackIdxOut_bits_ray_origin_1 => rayNodeStackIdxOut.ray.origin(1),
      io_rayNodeStackIdxOut_bits_ray_origin_2 => rayNodeStackIdxOut.ray.origin(2),
      io_rayNodeStackIdxOut_bits_ray_dir_0 => rayNodeStackIdxOut.ray.dir(0),
      io_rayNodeStackIdxOut_bits_ray_dir_1 => rayNodeStackIdxOut.ray.dir(1),
      io_rayNodeStackIdxOut_bits_ray_dir_2 => rayNodeStackIdxOut.ray.dir(2),
      io_rayNodeStackIdxOut_bits_ray_dRcp_0 => rayNodeStackIdxOut.ray.dRcp(0),
      io_rayNodeStackIdxOut_bits_ray_dRcp_1 => rayNodeStackIdxOut.ray.dRcp(1),
      io_rayNodeStackIdxOut_bits_ray_dRcp_2 => rayNodeStackIdxOut.ray.dRcp(2),
      io_rayNodeStackIdxOut_bits_ray_minT => rayNodeStackIdxOut.ray.minT,
      io_rayNodeStackIdxOut_bits_ray_maxT => rayNodeStackIdxOut.ray.maxT,
      io_rayNodeStackIdxOut_bits_ray_id => rayNodeStackIdxOut.ray.id,
      io_rayNodeStackIdxOut_bits_node_data => rayNodeStackIdxOut.node.data,
      io_rayNodeStackIdxOut_bits_node_bbox_min_0 => rayNodeStackIdxOut.node.bbox.min(0),
      io_rayNodeStackIdxOut_bits_node_bbox_min_1 => rayNodeStackIdxOut.node.bbox.min(1),
      io_rayNodeStackIdxOut_bits_node_bbox_min_2 => rayNodeStackIdxOut.node.bbox.min(2),
      io_rayNodeStackIdxOut_bits_node_bbox_max_0 => rayNodeStackIdxOut.node.bbox.max(0),
      io_rayNodeStackIdxOut_bits_node_bbox_max_1 => rayNodeStackIdxOut.node.bbox.max(1),
      io_rayNodeStackIdxOut_bits_node_bbox_max_2 => rayNodeStackIdxOut.node.bbox.max(2),
      io_rayNodeStackIdxOut_bits_nodeIdx => rayNodeStackIdxOut.nodeIdx,
      io_rayNodeStackIdxOut_bits_stackIdx => rayNodeStackIdxOut.stackIdx,
      io_addrOut_ready => addrOut_ready,
      io_addrOut_valid => addrOut_valid,
      io_addrOut_bits_id => addrOut_bits_id,
      io_addrOut_bits_nodeIdx => addrOut_bits_nodeIdx,
      io_dataIn_ready => dataIn_ready,
      io_dataIn_valid => dataIn_valid,
      io_dataIn_bits_id => dataIn_bits_id,
      io_dataIn_bits_data => dataIn_bits_data
    );
    
    -- Generate clock signal
    clock_gen : process
    begin
      if not done then
          clock <= '1', '0' after clock_period/2;
          wait for clock_period;
      else
          wait;
      end if;
    end process clock_gen;
  
    -- Instantiate memory components
    rays : ray_memory
      port map(
          address => ray_addr,
          data    => ray_data
      );
      
    nodes : node_memory
      port map(
          address => node_addr,
          data    => node_data
      );
    
    -- Feed inputs to the Traversal module
    feedInput : process
      
      procedure synch_reset is 
      begin 
          reset <= '1';
          wait until rising_edge(clock);
          wait for clock_period / 2;
          reset <= '0';
      end procedure synch_reset;
      
    begin
      ray_addr  <= 0;
      rayNodeIn.nodeIdx <= (NODE_ID_WIDTH - 1 downto 0 => '0');
      
      wait for 1 ps;
      
      --Begin with a reset
      synch_reset;
    
      -- Get the first 100 rays from the simulated memory
      for i in 0 to 2000 loop
          
          --Extract the ray from the initialized ray RAM
          ray_addr <= i;
          rayNodeIn_valid <= '0';
          
          wait for 1 ps;
          
          rayNodeIn.ray <= ray_data;
          rayNodeIn.node <= bvh_root;
          
          -- Hold valid until ready
          rayNodeIn_valid <= '1';
          
          -- sync_wait_unil_value
          wait until rising_edge(clock);
          sync_wait_until_value(rayNodeIn_ready, '1', clock);
          
      end loop;
      
      -- Stop the ray feeding
      rayNodeIn_valid <= '0';
      
      -- Signal the end of the simulation
      -- done <= true;
      wait;
      
    end process feedInput;
    
    -- Mikhails Memory System^TM
    memory: process
    
    type data_array is array(0 to NUM_NODES-1) of std_logic_vector(NODE_DATA_WIDTH-1 downto 0);
    variable data: data_array;
    variable int_tmp: integer;
    type id_array is array(0 to MAX_MEM_INFLIGHT_REQUESTS-1) of std_logic_vector(ID_WIDTH-1 downto 0);
    variable ids_in_flight: id_array;
    type int_array is array(0 to MAX_MEM_INFLIGHT_REQUESTS-1) of integer;
    variable expiration_times, reqs_in_flight: int_array;
    
    variable seed1: positive;
    variable seed2: positive;
    variable rand: real;
    
    variable tail_ptr: integer := 0;
    variable head_ptr: integer := 0;
    variable num_requests_in_flight: integer := 0;
    variable advance_to_next_response: boolean := true;
    variable i: integer := 0;
    variable j: integer := 0;
    variable upper_limit: integer := 0;
    variable first_iteration: boolean;
    begin
    
    -- Get root directly from memory
    node_addr <= 0;
    wait for 1 ps;
    bvh_root  <= node_data;
    
    -- Memory stuff
    addrOut_ready <= '0'; 
    dataIn_valid <= '0'; 
    
    -- sync_wait_until_value
    wait until rising_edge(clock);
    sync_wait_until_value(reset, '0', clock);
    
    for i in 0 to MAX_MEM_INFLIGHT_REQUESTS-1 loop
       expiration_times(i) := -1;
    end loop;
    i := 0;
    
    external_memory_loop: loop
        uniform(seed1, seed2, rand);
        if rand < P_MEM_READY and ((tail_ptr /= head_ptr and (not( addrOut_valid = '1'))) or (num_requests_in_flight = 0) or (addrOut_ready = '1' and AddrOut_valid = '1' and ((head_ptr + 1 mod MAX_MEM_INFLIGHT_REQUESTS) /= tail_ptr) and (head_ptr /= tail_ptr))) then
            addrOut_ready <= '1';
        else
            addrOut_ready <= '0';
        end if;
        
        -- Accept a new request
        if addrOut_ready = '1' and addrOut_valid = '1' then
            reqs_in_flight(head_ptr) := to_integer(unsigned(addrOut_bits_nodeIdx)); 
            ids_in_flight(head_ptr) := addrOut_bits_id;
            uniform(seed1, seed2, rand);
            assert expiration_times(head_ptr) = -1 report "Overwriting in-flight memory request" severity failure;
            expiration_times(head_ptr) := i + MIN_MEM_LATENCY + integer(rand * real(MAX_MEM_LATENCY - MIN_MEM_LATENCY));
            head_ptr := head_ptr + 1;
            if head_ptr = MAX_MEM_INFLIGHT_REQUESTS then
                head_ptr := 0;
            end if;
            num_requests_in_flight := num_requests_in_flight + 1;
        end if;
        
        if advance_to_next_response then
            dataIn_valid <= '0';
        end if;
        
        if ((expiration_times(tail_ptr) >= 0) and advance_to_next_response) then
            -- We look for an entry that has already expired
            j := tail_ptr;
            first_iteration := true;
            
            while j /= head_ptr or first_iteration loop
            first_iteration := false;
            -- for j in tail_ptr to head_ptr-1 loop
                -- All entries before tail_ptr have been sent out
                -- There is at least one entry between tail_ptr and head_ptr that has not been sent out
                if ((i >= expiration_times(j)) and (0 <= expiration_times(j))) then
                    dataIn_valid <= '1';
                    
                    -- Return value found in the node ROM
                    dataIn_bits_id <= ids_in_flight(j);
                    node_addr <= reqs_in_flight(j);
                    wait for 1 ps;
                    dataIn_bits_data <= std_logic_vector(node_data.data) & node_data.bbox.min(2) & node_data.bbox.min(1) & node_data.bbox.min(0) 
                       & node_data.bbox.max(2) & node_data.bbox.max(1) & node_data.bbox.max(0);
                    
                    expiration_times(j) := -1;
                    -- Move the tail pointer until it points to a request that did not expire yet
                    first_iteration := true;
                    while (tail_ptr /= head_ptr or first_iteration) and expiration_times(tail_ptr) = -1 loop
                       first_iteration := false;
                       tail_ptr := tail_ptr + 1;
                       if tail_ptr = MAX_MEM_INFLIGHT_REQUESTS then
                           tail_ptr := 0;
                       end if;
                    end loop;
                    first_iteration := false;
                    exit;
                end if;
                
                j := j + 1;
                
                if j = MAX_MEM_INFLIGHT_REQUESTS then
                    j := 0;
                end if;
            end loop;
        end if;
        
        wait until rising_edge(clock);
        
        if dataIn_valid = '1' then
            if dataIn_ready = '1' then
                advance_to_next_response := true;
                num_requests_in_flight := num_requests_in_flight - 1;
            else
                advance_to_next_response := false;
            end if;
        end if;
        
        i := i + 1;
        
        exit external_memory_loop when done;
    end loop;
    
    dataIn_valid <= '0';
    wait;
    end process memory;
    
      -- Consume the Node outputs of the fetch component
    consumeOutputs : process
    begin
      
      rayNodeStackIdxOut_ready <= '1';
      
      -- Check that the output node is always the root of the tree
      while not done loop
          
          if rayNodeStackIdxOut_valid = '1' then
            assert is_leaf(rayNodeStackIdxOut.node) report "Output node isn't a leaf!" severity error;
          end if;
          
          -- Make loop synchronous
          wait until rising_edge(clock);
      end loop;
      
      -- End process when done
      if done then
          wait;
      end if;
      
    end process consumeOutputs;

end traversal;
