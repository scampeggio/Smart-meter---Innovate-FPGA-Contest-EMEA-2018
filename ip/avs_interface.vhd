LIBRARY ieee ;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

-- ITT Giorgi - AVS interface HPS to FSMs- Smart Meter project

entity AVS_INTERFACE is
	port	(
			CLK		 		:in std_logic ;								-- Master Clock
			RESET_N			:in std_logic;									-- Master Clear active low

			DATA_NEG_IN		:in std_logic_vector (7 downto 0);		-- PW sinked from meter
			DATA_POS_IN		:in std_logic_vector (7 downto 0);		-- PW sourced from meter
			DATA_VALID_IN	:in std_logic;									-- Data_valid from meter- asserted low
			
			BATTERY			:in std_logic_vector (7 downto 0);		-- Battery level
			
			DATA_NEG_OUT	:out std_logic_vector (7 downto 0);		-- PW sinked to FSMs
			DATA_POS_OUT	:out std_logic_vector (7 downto 0);		-- PW sourced to FSMs
			START_PUMPS		:out std_logic;								-- Start signal to PUMPS, asserted low
			START_LOADS		:out std_logic;								-- Start signal to LOADS, asserted low

-- Avalon MM interface
			AVS_INTERFACE_WRITE		:in std_logic;
			AVS_INTERFACE_ADDRESS	:in std_logic_vector(2 downto 0);
			AVS_INTERFACE_READDATA	:out std_logic_vector(7 downto 0);
			AVS_INTERFACE_WRITEDATA	:in std_logic_vector(7 downto 0)
			);
END AVS_INTERFACE ;

architecture BEH of AVS_INTERFACE is
	constant	CLOCK_RATE:				integer := 50000000;
--	type 		STATE is (IDLE,WAIT_START,FIND_START,WAIT_BIT,GET_BIT,WAIT_PARITY,GET_PARITY,WAIT_STOP,GET_STOP);

	signal	DATA_VALID_IN_REG:	std_logic_vector(7 downto 0);
	signal	DATA_NEG_IN_REG:		std_logic_vector(7 downto 0);
	signal	DATA_POS_IN_REG:		std_logic_vector(7 downto 0);
	signal	DATA_VALID_HPS_REG:	std_logic_vector(7 downto 0);
	signal	DATA_NEG_HPS_REG:		std_logic_vector(7 downto 0);
	signal	DATA_POS_HPS_REG:		std_logic_vector(7 downto 0);
	signal	START_OUT_REG:			std_logic_vector(7 downto 0);
	
	signal	INT_DATA_NEG_OUT:		std_logic_vector(7 downto 0);
	signal	INT_DATA_POS_OUT:		std_logic_vector(7 downto 0);
	
	
	begin --BEH

	
START_LOADS <= not(START_OUT_REG(0));
START_PUMPS <= not(START_OUT_REG(1));

process (CLK,RESET_N)	-- Data received from meter register
  begin
	if (RESET_N='0') then
		DATA_VALID_IN_REG <= (others => '0');
		DATA_NEG_IN_REG 	<= (others => '0');
		DATA_POS_IN_REG 	<= (others => '0');
		elsif (rising_edge(CLK)) then
		DATA_VALID_IN_REG <= (others => '0');
			if (DATA_VALID_IN = '0')
				then 		DATA_VALID_IN_REG(0) <= '1';
							DATA_NEG_IN_REG 		<= DATA_NEG_IN;
							DATA_POS_IN_REG 		<= DATA_POS_IN;
				else		DATA_VALID_IN_REG(0) <= '0';
			end if;
	end if;
end process;


process (CLK,RESET_N)	-- Data writing to internal registers
  begin
	if (RESET_N='0') then
		DATA_NEG_OUT 	<= (others => '0');
		DATA_POS_OUT 	<= (others => '0');
		elsif (rising_edge(CLK)) then
			if (DATA_VALID_IN_REG(0) = '1')
				then 		DATA_NEG_OUT 		<= INT_DATA_NEG_OUT;
							DATA_POS_OUT 		<= INT_DATA_POS_OUT;
			end if;
	end if;
end process;


process (CLK,RESET_N)	-- HPS to FSMs registers writing
	begin
		if (RESET_N='0') then
			DATA_NEG_HPS_REG <= (others => '0');
			DATA_POS_HPS_REG <= (others => '0');
			START_OUT_REG 	  <= (others => '0');
		elsif (rising_edge(CLK)) then
			if (AVS_INTERFACE_WRITE = '1') then
				case AVS_INTERFACE_ADDRESS is
					when "100"	=>	DATA_POS_HPS_REG	<=	AVS_INTERFACE_WRITEDATA;
					when "101"	=>	DATA_NEG_HPS_REG	<=	AVS_INTERFACE_WRITEDATA;
					when "110"	=>	START_OUT_REG		<=	AVS_INTERFACE_WRITEDATA;
					when others	=>	null;
				end case;
			end if;
		end if;
end process;


-- FSMs registers reading by HPS
process (DATA_NEG_IN_REG,DATA_POS_IN_REG,DATA_VALID_IN_REG)
	begin
		AVS_INTERFACE_READDATA	<=	(others => '0');
		case AVS_INTERFACE_ADDRESS is
			when "000"	=>	AVS_INTERFACE_READDATA	<=	DATA_VALID_IN_REG;
			when "001"	=>	AVS_INTERFACE_READDATA	<=	DATA_POS_IN_REG;
			when "010"	=>	AVS_INTERFACE_READDATA	<=	DATA_NEG_IN_REG;
			when "011"	=> AVS_INTERFACE_READDATA	<= BATTERY;
			when others	=>	null;
		end case;

end process;


-- Data processing
process (DATA_NEG_IN_REG,DATA_POS_IN_REG,DATA_NEG_HPS_REG,DATA_POS_HPS_REG)
	begin
		INT_DATA_NEG_OUT <= DATA_NEG_IN_REG;
		INT_DATA_POS_OUT <= DATA_POS_IN_REG;
		if ((DATA_NEG_IN_REG /= "00000000") and (DATA_POS_HPS_REG /= "00000000")) then
				if (DATA_POS_HPS_REG > DATA_NEG_IN_REG) then
					INT_DATA_NEG_OUT	<= (others => '0');
					INT_DATA_POS_OUT	<= DATA_POS_HPS_REG - DATA_NEG_IN_REG;
																	 else
					INT_DATA_NEG_OUT	<= DATA_NEG_IN_REG- DATA_POS_HPS_REG;
					INT_DATA_POS_OUT	<= (others => '0');
				end if;
		end if;
		if ((DATA_NEG_IN_REG /= "00000000") and (DATA_NEG_HPS_REG /= "00000000")) then
			INT_DATA_NEG_OUT	<= DATA_NEG_IN_REG + DATA_NEG_HPS_REG;
		end if;
		if ((DATA_POS_IN_REG /= "00000000") and (DATA_POS_HPS_REG /= "00000000")) then
			INT_DATA_POS_OUT	<= DATA_POS_IN_REG + DATA_POS_HPS_REG;
		end if;
		if ((DATA_POS_IN_REG /= "00000000") and (DATA_NEG_HPS_REG /= "00000000")) then
				if (DATA_NEG_HPS_REG > DATA_POS_IN_REG) then
					INT_DATA_POS_OUT	<= (others => '0');
					INT_DATA_NEG_OUT	<= DATA_NEG_HPS_REG - DATA_POS_IN_REG;
																	 else
					INT_DATA_POS_OUT	<= DATA_POS_IN_REG- DATA_NEG_HPS_REG;
					INT_DATA_NEG_OUT	<= (others => '0');
				end if;
		end if;
end process;


end BEH;