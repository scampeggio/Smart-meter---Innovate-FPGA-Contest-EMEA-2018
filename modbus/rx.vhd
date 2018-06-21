LIBRARY ieee ;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

-- ITT Giorgi - UART - RX module

-- Top-level module
entity RX is
	port	(
			CLK		 	:in std_logic ;						-- Master Clock 4MHz
			RST			:in std_logic;						-- Master Clear active low - A
			DATA_OUT	:out std_logic_vector (7 downto 0);	-- Parallel data out - received
			REC			:in std_logic;						-- Start receiving - active low
			DATA_IN		:in std_logic;						-- Serial data in
			PARITY_OK	:out std_logic;						-- Asserted low when ok
			READY		:out std_logic						-- RX data valid, active low
		
			);
END RX ;

architecture BEH of RX is
	constant	CLOCK_RATE:				integer := 24000000;
	constant	BAUD_RATE:				integer := 9600;
	constant	BIT_LENGHT: 			integer := CLOCK_RATE/BAUD_RATE;
	constant	HALF_BIT_LENGHT:		integer := BIT_LENGHT/2;
	type 		STATE is (IDLE,WAIT_START,FIND_START,WAIT_BIT,GET_BIT,WAIT_PARITY,GET_PARITY,WAIT_STOP,GET_STOP);
	signal 		PRES_STATE,NEXT_STATE: 	STATE;
	signal 		BIT_DURATION: 			integer range 0 to BIT_LENGHT;	-- Count bit duration
	signal		BITS_GOT:				integer range 0 to 7;			-- Count bits got
	signal		INT_DATA_OUT:			std_logic_vector (7 downto 0);
	signal		PARITY:					std_logic;						-- Parity generated locally
	signal		RECEIVE:					boolean;
	
	begin --BEH

DATA_OUT <= INT_DATA_OUT;

RECEIVE <= REC='0';

process (CLK,RST)	-- Data received register
  begin
	if (RST='0') then
		INT_DATA_OUT <= (others => '0');
		elsif (rising_edge(CLK)) then
			if (PRES_STATE = FIND_START) then INT_DATA_OUT <= (others => '0');
			end if;
			if (PRES_STATE = GET_BIT) then
				INT_DATA_OUT(7) <= DATA_IN;
				for I in 6 downto 0 loop
					INT_DATA_OUT(I) <= INT_DATA_OUT(I+1);
				end loop;
			end if;
	end if;
end process;



process (CLK,RST)	-- Generations signals
	begin
	if (RST='0') then
		READY <= '1';
		elsif (rising_edge(CLK)) then
			if (PRES_STATE = FIND_START) then READY <= '1';
			end if;
			if (PRES_STATE = GET_STOP) then READY <= '0';
			end if;
	end if;
end process;


process (CLK,RST)	-- Master State Machine
  begin
	if (RST='0') then
		PRES_STATE <= IDLE;
		elsif (rising_edge(CLK)) then
			PRES_STATE <= NEXT_STATE;
	end if;
end process;

process (PRES_STATE,BIT_DURATION,BITS_GOT,RECEIVE,DATA_IN)	-- Master State Machine
	begin
		case PRES_STATE is
			when IDLE => if RECEIVE then NEXT_STATE <= WAIT_START;
										else NEXT_STATE <= IDLE;
						 end if;
			when WAIT_START => if DATA_IN = '1' then NEXT_STATE <= WAIT_START;
												else NEXT_STATE <= FIND_START;
							   end if;
			when FIND_START => if (BIT_DURATION = HALF_BIT_LENGHT) then NEXT_STATE <= WAIT_BIT;
																   else NEXT_STATE <= FIND_START;
							   end if;
			when WAIT_BIT 	=> if (BIT_DURATION = BIT_LENGHT) then NEXT_STATE <= GET_BIT;
															  else NEXT_STATE <= WAIT_BIT;
							   end if;
			when GET_BIT => if (BITS_GOT = 7) then NEXT_STATE <= WAIT_PARITY;
											  else NEXT_STATE <= WAIT_BIT;
							   end if;
			when WAIT_PARITY => if (BIT_DURATION = BIT_LENGHT) then NEXT_STATE <= GET_PARITY;
															   else NEXT_STATE <= WAIT_PARITY;
							   end if;
			when GET_PARITY => NEXT_STATE <= WAIT_STOP;
			
			when WAIT_STOP => 	if (BIT_DURATION = BIT_LENGHT)   then NEXT_STATE <= GET_STOP;
															   else NEXT_STATE <= WAIT_STOP;
							    end if;
			when GET_STOP =>   NEXT_STATE <= IDLE;
			
			when others	=> NEXT_STATE <= IDLE;
		end case;
end process;

process (INT_DATA_OUT)	-- Even parity generation
 variable INT_PARITY: std_logic;
	begin
		INT_PARITY:='0';
		for I in 0 to 7 loop
			INT_PARITY:= INT_PARITY xor INT_DATA_OUT(I);
		end loop;
		PARITY <= INT_PARITY;
end process;

process (CLK,RST)	-- Parity Getting and Checking 
  begin
	if (RST='0') then
		PARITY_OK <= '1';
		elsif (rising_edge(CLK)) then
			if (PRES_STATE = GET_PARITY)  then PARITY_OK <= (DATA_IN xor PARITY);
			end if;
			if (PRES_STATE = FIND_START) then PARITY_OK <= '1';
			end if;
	end if;
end process;

process (CLK,RST)	-- Bits received count
  begin
	if (RST='0') then
		BITS_GOT <= 0;
		elsif (rising_edge(CLK)) then
			if (PRES_STATE = GET_BIT) then BITS_GOT <= BITS_GOT +1;
			end if;
			if (PRES_STATE = IDLE) then BITS_GOT <= 0;
			end if;
	end if;
end process;


process (CLK,RST)	-- Bit duration
  begin
	if (RST='0') then
		BIT_DURATION <= 0;
		elsif (rising_edge(CLK)) then
			if ((PRES_STATE /= IDLE) and (PRES_STATE /= WAIT_START)) then BIT_DURATION <= BIT_DURATION +1;
			end if;
			if ((BIT_DURATION = HALF_BIT_LENGHT) and (PRES_STATE = FIND_START)) then BIT_DURATION <= 0;
			end if;
			if (BIT_DURATION = BIT_LENGHT) then BIT_DURATION <= 0;
			end if;
	end if;
end process;


	end BEH;