LIBRARY ieee ;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
use ieee.numeric_std.all;

-- ITT Giorgi - FORCING arbiter

entity ARBITER2 is
	port	(
			CLK		 	:in std_logic ;						-- Master Clock 
			RST			:in std_logic;						-- Master Clear active low 
			SIRC_DATA	:in std_logic_vector (3 downto 0);
			UART_DATA	:in std_logic_vector (7 downto 0);
			DATA_VALID	:in std_logic;						-- Data valid from Sirc decoder
			READY		:in std_logic;						-- Ready from UART rx
			FORCE_LOAD	:buffer std_logic_vector(4 downto 0);	-- 
			FORCE_WRITE	:out std_logic						-- 
			);
END ARBITER2 ;

architecture BEH of ARBITER2 is
	type 		STATE1 is (IDLE1,GET_DATA1,SEND_FORCE1,WAIT_NX1);
	type 		STATE2 is (IDLE2,GET_DATA2,SEND_FORCE2,WAIT_NX2);
	signal 		PRES_STATE1,NEXT_STATE1: 	STATE1;
	signal 		PRES_STATE2,NEXT_STATE2: 	STATE2;
	signal		FORCED_STATUS: std_logic_vector (15 downto 0);
	
	begin --BEH


process (CLK,RST)	-- MAster State Machine
  begin
	if (RST='0') then
		PRES_STATE1 <= IDLE1;
		PRES_STATE2 <= IDLE2;
		elsif (rising_edge(CLK)) then
			PRES_STATE1 <= NEXT_STATE1;
			PRES_STATE2 <= NEXT_STATE2;
	end if;
end process;



process (PRES_STATE1,DATA_VALID)	-- MAster State Machine1
	begin
		NEXT_STATE1 <= PRES_STATE1;
		case PRES_STATE1 is
			when IDLE1 			=> if (DATA_VALID='0') 	then NEXT_STATE1 <= GET_DATA1;
									end if;
			when GET_DATA1 		=> NEXT_STATE1 <= SEND_FORCE1;
			when SEND_FORCE1	=> NEXT_STATE1 <= WAIT_NX1;
			when WAIT_NX1		=> if (DATA_VALID='1') then NEXT_STATE1 <= IDLE1;
									end if;
		end case;
end process;


process (PRES_STATE2,READY)	-- MAster State Machine2
	begin
		NEXT_STATE2 <= PRES_STATE2;
		case PRES_STATE2 is
			when IDLE2 			=> if (READY='0') 	then NEXT_STATE2 <= GET_DATA2;
									end if;
			when GET_DATA2 		=> NEXT_STATE2 <= SEND_FORCE2;
			when SEND_FORCE2	=> NEXT_STATE2 <= WAIT_NX2;
			when WAIT_NX2		=> if (READY='1') then NEXT_STATE2 <= IDLE2;
									end if;
		end case;
end process;

process (CLK,RST)	-- MAster State Machine
  begin
	if (RST='0') then
		FORCE_LOAD		<= (others => '0'); 
		FORCED_STATUS 	<= (others => '0'); 
		elsif (rising_edge(CLK)) then
		if (PRES_STATE1=GET_DATA1) then FORCE_LOAD(3 downto 0) <= SIRC_DATA;
										FORCED_STATUS(to_integer(unsigned(SIRC_DATA))) <= not FORCED_STATUS(to_integer(unsigned(SIRC_DATA)));
										FORCE_LOAD(4) <= not(FORCED_STATUS(to_integer(unsigned(SIRC_DATA))));
		end if;
		if (PRES_STATE2=GET_DATA2) then FORCE_LOAD(3 downto 0) <= UART_DATA(3 downto 0);
										FORCE_LOAD(4) <= UART_DATA(7);
										FORCED_STATUS(to_integer(unsigned(UART_DATA(3 downto 0)))) <= UART_DATA(7);
		end if;
	end if;
end process;


process (PRES_STATE1,PRES_STATE2)
	begin
		FORCE_WRITE <= '1';
		if (PRES_STATE1=SEND_FORCE1) or (PRES_STATE2=SEND_FORCE2)
			then FORCE_WRITE <= '0';
		end if;
end process;

end BEH;