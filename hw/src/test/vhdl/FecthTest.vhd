library IEEE;
use IEEE.std_logic_1164.all;
use work.memory_pkg.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

entity fetch_bvh_test is
end fetch_bvh_test;

architecture fetch of fetch_bvh_test is
    
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
  constant clock_period             : time    := 1 ns;
  constant NODE_DATA_WIDTH          : integer := 32;

  -- Fetch ports
  signal rayIn                  : ray_t;
  signal rayIn_id               : integer;
  signal rayIn_ready            : std_logic;
  signal rayIn_valid            : std_logic;
  signal rayNodeIdxOut          : ray_nodeIdx_t;
  signal rayNodeIdxOut_ready    : std_logic;
  signal rayNodeIdxOut_valid    : std_logic;
  signal node                   : node_t;
  signal node_ready             : std_logic;
  signal node_valid             : std_logic;
  signal addrOut_bits_id        : std_logic_vector(ID_WIDTH - 1 downto 0);
  signal addrOut_bits_nodeIdx   : std_logic_vector(NODE_ID_WIDTH - 1 downto 0);
  signal addrOut_ready          : std_logic;
  signal addrOut_valid          : std_logic;
  signal dataIn_bits_id         : std_logic_vector(ID_WIDTH - 1 downto 0);
  signal dataIn_bits_data       : std_logic_vector(255 downto 0);
  signal dataIn_valid           : std_logic;
  signal dataIn_ready           : std_logic;
  signal memReadyIn             : std_logic;  
  
  signal clock : std_logic;
  signal reset : std_logic;   
  
  -- Control boolean and root constant
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
    function ray_to_string(
        ray : in ray_t
    ) return string is
    begin 
          return "origin : (" & INTEGER'IMAGE(to_integer(unsigned(ray.origin(0)))) & ", " &
           INTEGER'IMAGE(to_integer(unsigned(ray.origin(1)))) & ", " & INTEGER'IMAGE(to_integer(unsigned(ray.origin(2)))) &
           "); dir : (" & INTEGER'IMAGE(to_integer(unsigned(ray.dir(0)))) & ", " & INTEGER'IMAGE(to_integer(unsigned(ray.dir(1)))) & 
           ", " & INTEGER'IMAGE(to_integer(unsigned(ray.dir(2)))) &
           "); dRcp : (" & INTEGER'IMAGE(to_integer(unsigned(ray.dRcp(0)))) & ", " & INTEGER'IMAGE(to_integer(unsigned(ray.dRcp(1)))) &
           ", " & INTEGER'IMAGE(to_integer(unsigned(ray.dRcp(2)))) & "); minT : " & INTEGER'IMAGE(to_integer(unsigned(ray.minT))) 
           & "; maxT : " & INTEGER'IMAGE(to_integer(unsigned(ray.maxT))) & "; id : " & INTEGER'IMAGE(to_integer(unsigned(ray.id)));
    end function ray_to_string;
  
begin
    
  -- Instantiate DUT
  fetchBVH: entity work.FetchBVH 
  port map(
    clock                               => clock,
    reset                               => reset,
    io_rayIn_ready                      => rayIn_ready,
    io_rayIn_valid                      => rayIn_valid,
    io_rayIn_bits_origin_0              => rayIn.origin(0),
    io_rayIn_bits_origin_1              => rayIn.origin(1),
    io_rayIn_bits_origin_2              => rayIn.origin(2),
    io_rayIn_bits_dir_0                 => rayIn.dir(0),
    io_rayIn_bits_dir_1                 => rayIn.dir(1),
    io_rayIn_bits_dir_2                 => rayIn.dir(2),
    io_rayIn_bits_dRcp_0                => rayIn.dRcp(0),
    io_rayIn_bits_dRcp_1                => rayIn.dRcp(1),
    io_rayIn_bits_dRcp_2                => rayIn.dRcp(2),
    io_rayIN_bits_minT                  => rayIn.minT,
    io_rayIN_bits_maxT                  => rayIn.maxT,
    io_rayIN_bits_id                    => rayIn.id,
    io_rayNodeIdxOut_ready              => rayNodeIdxOut_ready,
    io_rayNodeIdxOut_valid              => rayNodeIdxOut_valid,
    io_rayNodeIdxOut_bits_ray_origin_0  => rayNodeIdxOut.ray.origin(0),
    io_rayNodeIdxOut_bits_ray_origin_1  => rayNodeIdxOut.ray.origin(1),
    io_rayNodeIdxOut_bits_ray_origin_2  => rayNodeIdxOut.ray.origin(2),
    io_rayNodeIdxOut_bits_ray_dir_0     => rayNodeIdxOut.ray.dir(0),
    io_rayNodeIdxOut_bits_ray_dir_1     => rayNodeIdxOut.ray.dir(1),
    io_rayNodeIdxOut_bits_ray_dir_2     => rayNodeIdxOut.ray.dir(2),
    io_rayNodeIdxOut_bits_ray_dRcp_0    => rayNodeIdxOut.ray.dRcp(0),
    io_rayNodeIdxOut_bits_ray_dRcp_1    => rayNodeIdxOut.ray.dRcp(1),
    io_rayNodeIdxOut_bits_ray_dRcp_2    => rayNodeIdxOut.ray.dRcp(2),
    io_rayNodeIdxOut_bits_ray_minT      => rayNodeIdxOut.ray.minT,
    io_rayNodeIdxOut_bits_ray_maxT      => rayNodeIdxOut.ray.maxT,
    io_rayNodeIdxOut_bits_ray_id        => rayNodeIdxOut.ray.id, 
    io_rayNodeIdxOut_bits_nodeIdx       => rayNodeIdxOut.nodeIdx,
    io_node_ready                       => node_ready,
    io_node_valid                       => node_valid,
    io_node_bits_data                   => node.data,
    io_node_bits_bbox_min_0             => node.bbox.min(0),
    io_node_bits_bbox_min_1             => node.bbox.min(1),
    io_node_bits_bbox_min_2             => node.bbox.min(2),
    io_node_bits_bbox_max_0             => node.bbox.max(0),
    io_node_bits_bbox_max_1             => node.bbox.max(1),
    io_node_bits_bbox_max_2             => node.bbox.max(2),
    io_addrOut_ready                    => addrOut_ready,
    io_addrOut_valid                    => addrOut_valid,
    io_addrOut_bits_id                  => addrOut_bits_id,
    io_addrOut_bits_nodeIdx             => addrOut_bits_nodeIdx,
    io_dataIn_ready                     => dataIn_ready,
    io_dataIn_valid                     => dataIn_valid,
    io_dataIn_bits_id                   => dataIn_bits_id,
    io_dataIn_bits_data                 => dataIn_bits_data,
    io_memReadyIn                       => memReadyIn
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
      
  -- Set memory to ready 
  memReadyIn <= '1';
  
  -- Test FetchBVH
  feedRays : process
      
      procedure synch_reset is 
      begin 
          reset <= '1';
          wait until rising_edge(clock);
          wait for clock_period / 2;
          reset <= '0';
      end procedure synch_reset;
      
  begin
      ray_addr  <= 0;
      
      --Begin with a reset
      synch_reset;
  
      -- Get the first 100 rays from the simulated memory
      for i in 0 to 99 loop
          
          --Extract the ray from the initialized ray RAM
          ray_addr <= i;
          wait for 1 ps;
          rayIn <= ray_data;
          
          -- Hold valid until ready
          rayIn_valid <= '1';
          
          -- sync_wait_unil_value
          wait until rising_edge(clock);
          sync_wait_until_value(rayIn_ready, '1', clock);
          
      end loop;
      
      -- Stop the ray feeding
      rayIn_valid <= '0';
      
      -- Signal the end of the simulation
      
      wait;
      
  end process feedRays;
  
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
  consumeNodes : process
  begin
      node_ready <= '1';
      sync_wait_until_value(node_valid, '1', clock);
      
      -- Check that the output node is always the root of the tree
      while node_valid = '1' loop
      
            assert bvh_root = node report "Fetched node isn't the root!" severity error;
            
            -- Make loop synchronous
            wait until rising_edge(clock);
      end loop;
      
      -- End process when done
      if done then
          wait;
      end if;
      
  end process consumeNodes;
  
  -- Consume the RayIndex outputs of the fetch component
  consumeNodeIdx : process
      file rays_out           : text open write_mode is "tb_rays_out.txt";
      variable file_line      : line;
      variable counter        : integer := 0;
      
  begin
      rayNodeIdxOut_ready <= '1';
      sync_wait_until_value(rayNodeIdxOut_valid, '1', clock);
      
      while rayNodeIdxOut_valid = '1' loop
          
          -- Write all of the rays to a file
          write(file_line, ray_to_string(rayNodeIdxOut.ray));
          writeline(rays_out, file_line);
          
          counter := counter + 1;
          
          -- Check that all of the node idx's are 0
          assert rayNodeIdxOut.nodeIdx = (NODE_ID_WIDTH - 1 downto 0 => '0') report "Fetched nodeIdx isn't 0!" severity error;
          
          -- Make loop synchronous
          wait until rising_edge(clock);
      end loop;
      
      -- End process when done
      if counter = 100 then
          done <= true;
          wait;
      end if;
      
  end process consumeNodeIdx;
  
end architecture fetch;