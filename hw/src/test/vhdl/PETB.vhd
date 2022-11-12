
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.txt_util.all;
use std.textio.all;
use ieee.STD_LOGIC_TEXTIO.all;

entity PETB is
--  Port ( );
end PETB;

architecture behavioural of PETB is
  -- Simulation parameters
  constant CLK_PERIOD: time := 1 ns;
  constant P_REQ_VALID: real := 1.0;
  constant P_MEM_READY: real := 1.0;
  constant P_RESP_READY: real := 1.0;
  constant MIN_MEM_LATENCY: integer := 10;
  constant MAX_MEM_LATENCY: integer := 30;
  constant MAX_MEM_INFLIGHT_REQUESTS: integer := MAX_MEM_LATENCY;
  constant INPUT_FILE_PATH: string := "/home/asiatici/epfl/FPGAMSHR/graph-accelerator/test/pe/";
  constant INPUT_FILE_NAME: string := "soc-Epinions1";
  constant NUM_NODES: integer := 76787; -- defines memory array size
  constant CURR_NODES_PREFIX: integer := 0;

  -- PE parameters: must match those of the DUT
  constant TOTAL_NODE_ADDR_WIDTH: integer := 32;
  constant SRC_NODE_ADDR_WIDTH: integer := 11;
  constant DST_NODE_ADDR_WIDTH: integer := 10;
  constant NODE_DATA_WIDTH: integer := 32;
  constant MAX_IN_FLIGHT_REQUESTS: integer := 8192;
  constant EDGES_COUNT_WIDTH: integer := 32;

  -- Derived constants: DON'T TOUCH
  constant ID_WIDTH: integer := integer(ceil(log2(real(MAX_IN_FLIGHT_REQUESTS))));
  constant CURR_NODES_PREFIX_WIDTH: integer := TOTAL_NODE_ADDR_WIDTH - DST_NODE_ADDR_WIDTH;
  constant NUM_LOCAL_NODES: integer := 2 ** DST_NODE_ADDR_WIDTH;

  -- Control booleans
  signal done: boolean := false;
  signal sendEdges: boolean := false;
  signal stage: string(1 to 80);

  signal clock: std_logic;
  signal reset: std_logic;
  signal io_edgeStreamIn_ready: std_logic;
  signal io_edgeStreamIn_valid: std_logic;
  signal io_edgeStreamIn_bits_isSrcPrefix: std_logic;
  signal io_edgeStreamIn_bits_data: std_logic_vector(TOTAL_NODE_ADDR_WIDTH-1 downto 0);
  signal io_nodeStreamIn_ready: std_logic;
  signal io_nodeStreamIn_valid: std_logic;
  signal io_nodeStreamIn_bits: std_logic_vector(NODE_DATA_WIDTH-1 downto 0);
  signal io_nodeStreamOut_ready: std_logic;
  signal io_nodeStreamOut_valid: std_logic;
  signal io_nodeStreamOut_bits: std_logic_vector(NODE_DATA_WIDTH-1 downto 0);
  signal io_nodeAddrOut_ready: std_logic;
  signal io_nodeAddrOut_valid: std_logic;
  signal io_nodeAddrOut_bits_addr: std_logic_vector(TOTAL_NODE_ADDR_WIDTH-1 downto 0);
  signal io_nodeAddrOut_bits_id: std_logic_vector(ID_WIDTH-1 downto 0);
  signal io_nodeDataIn_ready: std_logic;
  signal io_nodeDataIn_valid: std_logic;
  signal io_nodeDataIn_bits_id: std_logic_vector(ID_WIDTH-1 downto 0);
  signal io_nodeDataIn_bits_data: std_logic_vector(NODE_DATA_WIDTH-1 downto 0);
  signal io_atLeastAnUpdate: std_logic;
  signal io_updateMemory: std_logic;
  signal io_running: std_logic;
  signal io_updating: std_logic;
  signal io_currNodesPrefix: std_logic_vector(CURR_NODES_PREFIX_WIDTH-1 downto 0);
  signal io_edgesToAdd_valid: std_logic;
  signal io_edgesToAdd_bits: std_logic_vector(EDGES_COUNT_WIDTH-1 downto 0);

  -- Procedures
    procedure sync_wait_until_value (
       signal sig: in std_logic;
       constant val: in std_logic;
       signal clk: in std_logic) is
    begin
       while sig /= val loop
           wait until rising_edge(clk);
       end loop;
    end sync_wait_until_value;

    procedure sync_wait_until_value (
       signal sig: in boolean;
       constant val: in boolean;
       signal clk: in std_logic) is
    begin
       while sig /= val loop
           wait until rising_edge(clk);
       end loop;
    end sync_wait_until_value;
begin

  clk_generation: process
    begin
        if not done then
            clock <= '1', '0' after CLK_PERIOD / 2;
            wait for CLK_PERIOD;
        else
            wait;
        end if;
    end process clk_generation;

    reset <= '1', '0' after 3 * CLK_PERIOD;

  dut: entity work.PE
  port map(
    clock => clock,
    reset => reset,
    io_edgeStreamIn_ready => io_edgeStreamIn_ready,
    io_edgeStreamIn_valid => io_edgeStreamIn_valid,
    io_edgeStreamIn_bits_isSrcPrefix => io_edgeStreamIn_bits_isSrcPrefix,
    io_edgeStreamIn_bits_data => io_edgeStreamIn_bits_data,
    io_nodeStreamIn_ready => io_nodeStreamIn_ready,
    io_nodeStreamIn_valid => io_nodeStreamIn_valid,
    io_nodeStreamIn_bits => io_nodeStreamIn_bits,
    io_nodeStreamOut_ready => io_nodeStreamOut_ready,
    io_nodeStreamOut_valid => io_nodeStreamOut_valid,
    io_nodeStreamOut_bits => io_nodeStreamOut_bits,
    io_nodeAddrOut_ready => io_nodeAddrOut_ready,
    io_nodeAddrOut_valid => io_nodeAddrOut_valid,
    io_nodeAddrOut_bits_addr => io_nodeAddrOut_bits_addr,
    io_nodeAddrOut_bits_id => io_nodeAddrOut_bits_id,
    io_nodeDataIn_ready => io_nodeDataIn_ready,
    io_nodeDataIn_valid => io_nodeDataIn_valid,
    io_nodeDataIn_bits_id => io_nodeDataIn_bits_id,
    io_nodeDataIn_bits_data => io_nodeDataIn_bits_data,
    io_atLeastAnUpdate => io_atLeastAnUpdate,
    io_updateMemory => io_updateMemory,
    io_running => io_running,
    io_updating => io_updating,
    io_currNodesPrefix => io_currNodesPrefix,
    io_edgesToAdd_valid => io_edgesToAdd_valid,
    io_edgesToAdd_bits => io_edgesToAdd_bits
  );

  edges_stream: process
    constant edges_file_name: string := INPUT_FILE_PATH & INPUT_FILE_NAME & "_edges.txt";
    file edges_text_input : text is in edges_file_name;
    variable edges_line_input  : line;

    constant edge_count_file_name: string := INPUT_FILE_PATH & INPUT_FILE_NAME & "_edge_count.txt";
    file edge_count_text_input : text is in edge_count_file_name;
    variable edge_count_line_input  : line;

    variable is_src_prefix, src, dst, edge_count: integer;
  begin
	skip_comments_edges: loop
		readline(edges_text_input, edges_line_input);
		exit skip_comments_edges when edges_line_input(1) /= '#';
	end loop;
	skip_comments_edge_count: loop
		readline(edge_count_text_input, edge_count_line_input);
		exit skip_comments_edge_count when edge_count_line_input(1) /= '#';
	end loop;

    io_edgeStreamIn_valid <= '0';
    io_edgesToAdd_valid <= '0';
    sync_wait_until_value(reset, '0', clock);
    sync_wait_until_value(sendEdges, true, clock);
    wait until rising_edge(clock);

    main_loop: loop
      read(edges_line_input, is_src_prefix);
      if is_src_prefix = 0 then
        read(edges_line_input, src);
        read(edges_line_input, dst);
        io_edgeStreamIn_bits_isSrcPrefix <= '0';
        io_edgeStreamIn_bits_data(DST_NODE_ADDR_WIDTH - 1 downto 0) <= std_logic_vector(to_unsigned(dst, DST_NODE_ADDR_WIDTH));
        io_edgeStreamIn_bits_data(DST_NODE_ADDR_WIDTH + SRC_NODE_ADDR_WIDTH - 1 downto DST_NODE_ADDR_WIDTH) <= std_logic_vector(to_unsigned(src, SRC_NODE_ADDR_WIDTH));
      else
        read(edges_line_input, src);
        io_edgeStreamIn_bits_isSrcPrefix <= '1';
        io_edgeStreamIn_bits_data <= std_logic_vector(to_unsigned(src, TOTAL_NODE_ADDR_WIDTH));
        read(edge_count_line_input, edge_count);
        io_edgesToAdd_valid <= '1';
        io_edgesToAdd_bits <= std_logic_vector(to_unsigned(edge_count, EDGES_COUNT_WIDTH));
        if not endfile(edge_count_text_input) then
            readline(edge_count_text_input, edge_count_line_input);
        end if;
      end if;
      io_edgeStreamIn_valid <= '1';
      wait until rising_edge(clock);
      io_edgesToAdd_valid <= '0';
      sync_wait_until_value(io_edgeStreamIn_ready, '1', clock);
      if endfile(edges_text_input) then
          exit main_loop;
      end if;
      readline(edges_text_input, edges_line_input);
    end loop;
    io_edgeStreamIn_valid <= '0';
    wait;
  end process edges_stream;

  memory: process
	--constant file_name: string := INPUT_FILE_PATH & INPUT_FILE_NAME & "_init_all.txt";
    --file text_input : text is in file_name;
    --variable line_input  : line;

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
	--while not endfile(text_input) loop
	--	skip_comments: loop
		--	readline(text_input, line_input);
		--	exit skip_comments when line_input(1) /= '#';
		--end loop;
	--	read(line_input, int_tmp);
		--data(i) := std_logic_vector(to_unsigned(int_tmp, NODE_DATA_WIDTH));
	--	i := i + 1;
--	end loop;

	io_nodeAddrOut_ready <= '0'; --addrout
	io_nodeDataIn_valid <= '0'; --dataIN
	sync_wait_until_value(reset, '0', clock);
	wait until rising_edge(clock);
	for i in 0 to MAX_MEM_INFLIGHT_REQUESTS-1 loop
	   expiration_times(i) := -1;
	end loop;
	i := 0;
	external_memory_loop: loop
		uniform(seed1, seed2, rand);
		if rand < P_MEM_READY and ((tail_ptr /= head_ptr and (not( io_nodeAddrOut_valid = '1'))) or (num_requests_in_flight = 0) or (io_nodeAddrOut_ready = '1' and io_nodeAddrOut_valid = '1' and ((head_ptr + 1 mod MAX_MEM_INFLIGHT_REQUESTS) /= tail_ptr) and (head_ptr /= tail_ptr))) then

		-- (((head_ptr + 1 mod MAX_MEM_INFLIGHT_REQUESTS) /= tail_ptr and advance_to_next_response) or (not advance_to_next_response and (head_ptr /= tail_ptr or num_requests_in_flight = 0))) then
			io_nodeAddrOut_ready <= '1';
		else
			io_nodeAddrOut_ready <= '0';
		end if;
		-- Accept a new request
		if io_nodeAddrOut_ready = '1' and io_nodeAddrOut_valid = '1' then
			reqs_in_flight(head_ptr) := to_integer(unsigned(io_nodeAddrOut_bits_addr ---addrOut_bits_nodeIdx));
			ids_in_flight(head_ptr) := io_nodeAddrOut_bits_id;---addrOut_bits_id
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
			io_nodeDataIn_valid <= '0';
		end if;
		if ((expiration_times(tail_ptr) >= 0) and advance_to_next_response) then
			-- We look for an entry that has already expired
			j := tail_ptr;
--			if head_ptr = 0 then
--			  upper_limit := MAX_MEM_INFLIGHT_REQUESTS - 1;
--			else
--			  upper_limit := head_ptr - 1;
--			end if;
            first_iteration := true;
			while j /= head_ptr or first_iteration loop
			first_iteration := false;
			-- for j in tail_ptr to head_ptr-1 loop
				-- All entries before tail_ptr have been sent out
				-- There is at least one entry between tail_ptr and head_ptr that has not been sent out
				if ((i >= expiration_times(j)) and (0 <= expiration_times(j))) then
					io_nodeDataIn_valid <= '1';
					io_nodeDataIn_bits_id <= ids_in_flight(j);
					io_nodeDataIn_bits_data <= data(reqs_in_flight(j));
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
		if io_nodeDataIn_valid = '1' then
			if io_nodeDataIn_ready = '1' then
				advance_to_next_response := true;
				num_requests_in_flight := num_requests_in_flight - 1;
			else
				advance_to_next_response := false;
			end if;
		end if;
		i := i + 1;
		exit external_memory_loop when done;
	end loop;
	io_nodeDataIn_valid <= '0';
	wait;
  end process memory;

  control: process
	constant nodes_in_file_name: string := INPUT_FILE_PATH & INPUT_FILE_NAME & "_init_curr.txt";
    file nodes_in_text_input : text is in nodes_in_file_name;
    variable line_input  : line;
    variable int_tmp: integer;

	constant out_file_name: string := INPUT_FILE_PATH & INPUT_FILE_NAME & "_out.txt";
    file text_output : text is out out_file_name;
    variable line_output  : line;

    variable seed1: positive;
    variable seed2: positive;
    variable rand: real;

    variable nodes_read: integer := 0;
  begin
	-- Write starting value of destination nodes
	stage(1 to 5) <= "reset";
	io_updateMemory <= '0';
	io_currNodesPrefix <= std_logic_vector(to_unsigned(CURR_NODES_PREFIX, CURR_NODES_PREFIX_WIDTH));
	io_nodeStreamIn_valid <= '0';
	io_nodeStreamOut_ready <= '0';
	sync_wait_until_value(reset, '0', clock);
	wait until rising_edge(clock);
	io_updateMemory <= '1';
	stage(1 to 23) <= "waiting for io_updating";
	sync_wait_until_value(io_updating, '1', clock);
	io_updateMemory <= '0';
	stage(1 to 27) <= "sending initial node values";
	skip_comments: loop
		readline(nodes_in_text_input, line_input);
		exit skip_comments when line_input(1) /= '#';
	end loop;
	-- io_nodeStreamOut_ready <= '1'; -- we don't care about the values read from memory but we need to consume it otherwise the system will stall
	nodes_in_loop: loop
      read(line_input, int_tmp);
      io_nodeStreamIn_bits <= std_logic_vector(to_unsigned(int_tmp, NODE_DATA_WIDTH));
      io_nodeStreamIn_valid <= '1';
      wait until rising_edge(clock);
      sync_wait_until_value(io_nodeStreamIn_ready, '1', clock);
      if endfile(nodes_in_text_input) then
        exit nodes_in_loop;
      else
        readline(nodes_in_text_input, line_input);
      end if;
    end loop;
    io_nodeStreamIn_valid <= '0';

    sync_wait_until_value(io_updating, '0', clock);
    sendEdges <= true;
    stage <= (others => ' ');
	stage(1 to 24) <= "waiting for io_running=1";
	sync_wait_until_value(io_running, '1', clock);
	stage(1 to 24) <= "waiting for io_running=0";
	sync_wait_until_value(io_running, '0', clock);
	-- io_updateMemory <= '1';
	stage <= (others => ' ');
	stage(1 to 16) <= "results readback";
    io_nodeStreamOut_ready <= '0';
    -- io_nodeStreamIn_valid <= '1';	-- not that we care, but we need to write something in order to be able to read back
	nodeStreamOut_loop: loop
		uniform(seed1, seed2, rand);
		if rand < P_RESP_READY then
			io_nodeStreamOut_ready <= '1';
		else
			io_nodeStreamOut_ready <= '0';
		end if;
		if (io_nodeStreamOut_ready = '1') and (io_nodeStreamOut_valid = '1') then
		    io_updateMemory <= '0';
			nodes_read := nodes_read + 1;
			write(line_output, hstr(io_nodeStreamOut_bits), right, 15);
			write(line_output, time'image(now), right, 15);
			writeline(text_output, line_output);
		end if;
		exit nodeStreamOut_loop when nodes_read = NUM_LOCAL_NODES;
		wait until rising_edge(clock);
	end loop;
	assert io_updating = '0' and io_running = '0' report "Module must be idle in the end" severity failure;
	done <= true;
	io_nodeStreamOut_ready <= '0';
	io_nodeStreamIn_valid <= '0';
	wait;
  end process control;

end behavioural;
