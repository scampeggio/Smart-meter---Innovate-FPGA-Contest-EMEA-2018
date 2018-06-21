LIBRARY ieee ;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

-- ITT Giorgi - Registers update

entity M1 is
	port	(
			CLK		 	:in std_logic ;						-- Master Clock 4MHz
			RST			:in std_logic;						-- Master Clear active low - A
			DATA_IN		:in std_logic_vector (7 downto 0) ;	-- DATA IN from UART power meter
			READY		:in std_logic;						-- Byte ready from UART - active low
			DATA_NEG	:out std_logic_vector (7 downto 0);
			DATA_POS	:out std_logic_vector (7 downto 0);
			DATA_VALID	:out std_logic						-- Data out valid - active low
			);
END M1 ;

architecture BEH of M1 is
	type STATES is (IDLE,GET_SYNC,W_NREADY1,SYNCD,W_READY,GET_DATA,W_NREADY2,DATA_OK);
	signal NEXT_STATE,PRES_STATE: STATES;
	signal COUNT						: natural range 0 to 3;
	signal DATA_GOT						: std_logic_vector (7 downto 0);
	signal BATTERY_LEVEL				: std_logic_vector (7 downto 0);
	signal BATTERY_POWER_TO_MAIN_LINE	: std_logic_vector (7 downto 0);
	signal MAIN_LINE_POWER_TO_BATTERY	: std_logic_vector (7 downto 0);
	signal OVERALL_POWER_FROM_MAIN_LINE	: std_logic_vector (7 downto 0);
	signal OVERALL_POWER_TO_MAIN_LINE	: std_logic_vector (7 downto 0);
	signal OVERALL_POWER_AVAILABLE_LOC	: std_logic_vector (7 downto 0);
	signal OVERALL_POWER_REQUESTED		: std_logic_vector (7 downto 0);
	signal OVERALL_POWER_AVAILABLE_REM	: std_logic_vector (7 downto 0);

	signal POWER_MEASURE				: std_logic_vector (23 downto 0);
	
begin  --BEH


process (POWER_MEASURE)
	begin
		DATA_NEG <= (others => '0');
		DATA_POS <= (others => '0');
		if (POWER_MEASURE(8) = '0') then
			DATA_NEG <= (others => '0');
			DATA_POS <= POWER_MEASURE(7 downto 0);
		end if;
		if (POWER_MEASURE(8) = '1') then
			DATA_POS <= (others => '0');
			DATA_NEG <= not (POWER_MEASURE(7 downto 0)-"00000001");
		end if;
end process;


process (CLK,RST)
  begin
	if (RST='0') then
		PRES_STATE <= IDLE;
		elsif (rising_edge(CLK)) then
			PRES_STATE <= NEXT_STATE;
	end if;
end process;


process (DATA_GOT,PRES_STATE,COUNT,READY)
  begin
	NEXT_STATE <= PRES_STATE;
	case PRES_STATE is
		when IDLE 	=> 	if (READY = '0') 					-- Waiting for data ready
							then NEXT_STATE <= GET_SYNC;
						end if;
					
		when GET_SYNC => NEXT_STATE <= W_NREADY1;

		when W_NREADY1 => 	if (DATA_GOT = x"55")		
								then NEXT_STATE <= SYNCD;
								else NEXT_STATE <= IDLE;
							end if;
							if READY = '0' 	then NEXT_STATE <= W_NREADY1;
							end if;
					
		when SYNCD	 => NEXT_STATE <= W_READY;
		
		when W_READY => if (READY = '0') 				
							then NEXT_STATE <= GET_DATA;
						end if;
						
		when GET_DATA => NEXT_STATE <= W_NREADY2;
					
		when W_NREADY2 => if COUNT = 0 				
							then NEXT_STATE <= DATA_OK;
							else NEXT_STATE <= W_READY;
						end if;
						if ((READY = '0') and (COUNT /= 0)) then NEXT_STATE <= W_NREADY2;
						end if;
		
		when DATA_OK   =>  if (READY = '1') then NEXT_STATE <= IDLE;
							end if;
						
	end case;
end process;

process (CLK,RST)
  begin
	if (RST='0') then
		COUNT <= 3;
		elsif (rising_edge(CLK)) then
			if (PRES_STATE = GET_DATA)	-- Count data bit in
				then COUNT <=COUNT-1;
			end if;
			if (PRES_STATE = IDLE) then
				COUNT <= 3;
			end if;
	end if;
end process;


process (CLK,RST)
  begin
	if (RST='0') then
		DATA_GOT <= (others => '0');
		elsif (rising_edge(CLK)) then
			if ((PRES_STATE = GET_DATA)	or (PRES_STATE = GET_SYNC))			
				then DATA_GOT <= DATA_IN;
			end if;
	end if;
end process;


process (CLK,RST)
	begin
		if (RST='0') then
			POWER_MEASURE <= (others => '0');
		elsif (rising_edge(CLK)) then
			case COUNT is
				when 2 => POWER_MEASURE(23 downto 16) <= DATA_GOT;
				when 1 => POWER_MEASURE(15 downto 8) <= DATA_GOT;
				when 0 => POWER_MEASURE(7 downto 0) <= DATA_GOT;
				when others => POWER_MEASURE <= POWER_MEASURE;
			end case;
		end if;
end process;

process (CLK,RST)
	begin
		if (RST='0') then
			DATA_VALID <= '1';
		elsif (rising_edge(CLK)) then
			if (PRES_STATE = DATA_OK) then DATA_VALID <= '0';
			end if;
			if (PRES_STATE = SYNCD) then DATA_VALID <= '1';
			end if;
		end if;
end process;

END BEH;


	