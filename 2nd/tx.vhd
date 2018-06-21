LIBRARY ieee ;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

-- ITT Giorgi - UART - TX module

entity TX is
	port	(
			CLK		 	:in std_logic ;						-- Master Clock 50MHz
			RST			:in std_logic;						-- Master Clear active low - A
			DATA_PAR	:in std_logic_vector (7 downto 0) ;	-- Parallel data in - to be sent
			SEND		:in std_logic;						-- Start transmission - active low
			DATA_OUT	:out std_logic;						-- Serial data out
			READY		:out std_logic						-- TX ready to send, active low
			);
END TX ;

architecture BEH of TX is
	constant	CLOCK_RATE:				integer := 50000000;
	constant	BAUD_RATE:				integer := 9600;
	constant	BIT_LENGHT: 			integer := CLOCK_RATE/BAUD_RATE;
	type 		STATE is (IDLE,SEND_START,SEND_BIT,CHANGE_BIT,SEND_PARITY,SEND_STOP);
	type		STATES is (NO_TX,SEND_REC,WAIT_NOSEND);
	signal 		PRES_STATE,NEXT_STATE: 	STATE;
	signal		PRESS,NEXTS:			STATES;
	signal 		BIT_DURATION: 			integer range 0 to BIT_LENGHT;	-- Count bit duration
	signal		BIT_TO_SEND:			integer range 0 to 7;			-- Count bits sent
	signal		INT_DATA_OUT:			std_logic;
	signal		PARITY:					std_logic;
	signal		DATA_IN:				std_logic_vector (7 downto 0) ;
	
	begin --BEH

DATA_OUT <= INT_DATA_OUT;
DATA_IN <= (DATA_PAR);

process (PRES_STATE,DATA_IN,BIT_TO_SEND,PARITY)	-- Generations serial stream and signals
	begin
		INT_DATA_OUT <= '1';
		if (PRES_STATE = SEND_START) then INT_DATA_OUT <= '0';
		end if;
		if (PRES_STATE = SEND_PARITY) then INT_DATA_OUT <= PARITY;
		end if;
		if ((PRES_STATE = SEND_BIT) or (PRES_STATE = CHANGE_BIT)) then
			for I in 0 to 7 loop
				if BIT_TO_SEND = I then INT_DATA_OUT <= DATA_IN(I);
				end if;
			end loop;
		end if;
		if (PRES_STATE=IDLE) then READY <= '0';
									else READY <= '1';
		end if;
end process;


process (CLK,RST)	-- MAster State Machine
  begin
	if (RST='0') then
		PRES_STATE <= IDLE;
		elsif (rising_edge(CLK)) then
			PRES_STATE <= NEXT_STATE;
	end if;
end process;



process (PRES_STATE,PRESS,BIT_DURATION,BIT_TO_SEND,SEND)	-- MAster State Machine
	begin
		case PRES_STATE is
			when IDLE => if SEND='0' then NEXT_STATE <= SEND_START;
									 else NEXT_STATE <= IDLE;
						 end if;
			when SEND_START => if (BIT_DURATION = BIT_LENGHT) then NEXT_STATE <= SEND_BIT;
															  else NEXT_STATE <= SEND_START;
							   end if;
			when SEND_BIT 	=> if (BIT_DURATION = BIT_LENGHT) then NEXT_STATE <= CHANGE_BIT;
															  else NEXT_STATE <= SEND_BIT;
							   end if;
			when CHANGE_BIT => if (BIT_TO_SEND = 7) then NEXT_STATE <= SEND_PARITY;
													else NEXT_STATE <= SEND_BIT;
							   end if;
			when SEND_PARITY => NEXT_STATE <= SEND_STOP;
--								if (BIT_DURATION = BIT_LENGHT) then NEXT_STATE <= SEND_STOP;
--															  else NEXT_STATE <= SEND_PARITY;
--							   end if;
			when SEND_STOP => 	if (BIT_DURATION = BIT_LENGHT) then NEXT_STATE <= IDLE;
															  else NEXT_STATE <= SEND_STOP;
							    end if;
			when others	=> NEXT_STATE <= IDLE;
		end case;
end process;

process (DATA_IN)	-- Even parity generation
 variable INT_PARITY: std_logic;
	begin
		INT_PARITY:='0';
		for I in 0 to 7 loop
			INT_PARITY:= INT_PARITY xor DATA_IN(I);
		end loop;
		PARITY <= INT_PARITY;
end process;

process (CLK,RST)	-- Bits sent count
  begin
	if (RST='0') then
		BIT_TO_SEND <= 0;
		elsif (rising_edge(CLK)) then
			if (PRES_STATE = CHANGE_BIT) then BIT_TO_SEND <= BIT_TO_SEND +1;
			end if;
			if (PRES_STATE = IDLE) then BIT_TO_SEND <= 0;
			end if;
	end if;
end process;


process (CLK,RST)	-- Bit duration
  begin
	if (RST='0') then
		BIT_DURATION <= 0;
		elsif (rising_edge(CLK)) then
			if (PRES_STATE /= IDLE) then BIT_DURATION <= BIT_DURATION +1;
			end if;

			if BIT_DURATION = BIT_LENGHT then BIT_DURATION <= 0;
			end if;
	end if;
end process;


	end BEH;