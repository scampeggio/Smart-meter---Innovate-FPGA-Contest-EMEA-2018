LIBRARY ieee ;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

-- ITT Giorgi - FIFO arbiter

entity ARBITER is
	port	(
			CLK		 	:in std_logic ;						-- Master Clock 
			RST			:in std_logic;						-- Master Clear active low 
			EMPTY		:in std_logic;						-- Empty flag from fifo - active low
			RDREQ		:out std_logic;						-- READ from FIFO - active low
			SEND		:out std_logic;						-- Start transmission to UART - active low
			READY		:in std_logic						-- UART TX ready to send, active low
			);
END ARBITER ;

architecture BEH of ARBITER is
	type 		STATE is (IDLE,READ_FIFO,GET_DATA,START_TX,WAIT_TX);
	signal 		PRES_STATE,NEXT_STATE: 	STATE;
	
	begin --BEH


process (CLK,RST)	-- MAster State Machine
  begin
	if (RST='0') then
		PRES_STATE <= IDLE;
		elsif (rising_edge(CLK)) then
			PRES_STATE <= NEXT_STATE;
	end if;
end process;



process (PRES_STATE,EMPTY,READY)	-- MAster State Machine
	begin
		NEXT_STATE <= PRES_STATE;
		case PRES_STATE is
			when IDLE => if EMPTY='0' 	then NEXT_STATE <= READ_FIFO;
						 end if;
			when READ_FIFO 	=> NEXT_STATE <= GET_DATA;
			when GET_DATA 	=> if (READY = '0') then NEXT_STATE <= START_TX;
							   end if;
			when START_TX 	=> if (READY = '1') then NEXT_STATE <= WAIT_TX;
							   end if;
			when WAIT_TX 	=> if (READY = '0') then NEXT_STATE <= IDLE;
							   end if;
		end case;
end process;

process (PRES_STATE)
	begin
		RDREQ	<= '1';
		SEND 	<= '1';
		case PRES_STATE is
			when READ_FIFO	=>	RDREQ	<= '0';
			when START_TX	=>	SEND	<= '0';
			when others		=>	RDREQ	<= '1';
								SEND 	<= '1';
		end case;
end process;

	end BEH;