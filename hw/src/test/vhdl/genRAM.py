import array as arr

def genRAM():
    # Initialize our buffers
    rayMemInVHDL = []
    nodeMemInVHDL = []
    countR = 0
    countN = 0

    # Read the file while counting the number of lines
    with open("rays_out.txt") as rays:
        # Fill in the VHDL memory
        for ray in rays:
            rayMemInVHDL.append("mem(" + str(countR) + ") <= (" + ray + ");" )
            countR += 1
    with open("m_nodes_out.txt") as nodes:
        for node in nodes:  
            nodeMemInVHDL.append("mem(" + str(countN) + ") <= (" + node + ");")
            countN += 1

    # General VHDL file
    vhdlHeader = """
        library ieee;
        use ieee.std_logic_1164.all;

        package memory_pkg is
            type vertex is array(0 to 2) of real;
            
            type bounding_box is record
                min : vertex;
                max : vertex;
            end record bounding_box;
            
            --Elements contained within the memory
            type ray_t is record
                origin  : vertex;
                dir     : vertex;
                dRcp    : vertex;
                minT    : real;
                maxT    : real;
                id      : integer;
            end record ray_t;
            
            type node_t is record
                data : real;
                bbox : bounding_box;
            end record node_t;
                
            type memory_rays is array(0 to %s) of ray_t;
            type memory_nodes is array(0 to %s) of node_t;

        end package memory_pkg;

        use work.memory_pkg.all;

        entity ray_memory is
            port(
                address : in integer;
                data    : out ray_t
            );
        end ray_memory;

        architecture memoryArch of ray_memory is 
            
            signal mem : memory_rays; 
        begin 

            %s
            data <= mem(address);

        end memoryArch;

        use work.memory_pkg.all;

        entity node_memory is
            port(
                address : in integer;
                data    : out node_t
            );
        end node_memory;

        architecture memArch of node_memory is

            signal mem : memory_nodes;

        begin
            
            %s
            data <= mem(address)

        end memArch;

    """

    # Fill in the VHDL file with the number of rays and the memory filling VHDL
    outVHDL = vhdlHeader%(str(len(rayMemInVHDL)), len(str(nodeMemInVHDL)),
     '\n'.join(rayMemInVHDL), '\n'.join(nodeMemInVHDL))

    # Write the vhdl code to a file
    with open("ramGenFast.vhd", "w") as vhdl_file:
        vhdl_file.write(outVHDL)


def main():
    genRAM()

if __name__ == "__main__":
    main()