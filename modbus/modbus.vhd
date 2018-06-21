LIBRARY ieee ;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
use ieee.numeric_std;
use ieee.numeric_std.all;

-- ITT Giorgi - MODBUS - Sequencer module

-- Top-level module
entity MODBUS is
	port	(
			CLK		 	:in std_logic ;								-- Master Clock 4MHz
			RST			:in std_logic;									-- Master Clear active low - A
			START		:in std_logic;									-- Start measuring - active low
			READY_TX	:in std_logic;									-- TX UART module ready to accept a new byte, active low
			SEND		:out std_logic;								-- Send one byte, active low
			DATA_IN		:in std_logic_vector(7 downto 0);		-- Parallel data in
			DATA_OUT	:out std_logic_vector(7 downto 0);	-- Parallel data out
			READY_RX	:in std_logic;									-- RX data valid, active low
			START_REC :out std_logic;								-- Start uart RX, active low
			DATA_POS	:out std_logic_vector(7 downto 0);
			DATA_NEG	:out std_logic_vector(7 downto 0);
			DATA_VALID	:out std_logic
			);
END MODBUS ;

architecture BEH of MODBUS is
	type		DATA is array (0 to 7) of std_logic_vector(7 downto 0);
	type		DATA_1 is array (0 to 8) of std_logic_vector(7 downto 0);
	type 		STATE is (IDLE,SEND_BYTE1,SEND_BYTE2,CNT_INC1,CNT_INC2,WAIT_RX1,SAMPLE_RX,CLEAR_CNT,ATTESA,DELAY);
	type		STATE1 is (IDLE1,R1,R2,R3,WAIT_NOR);
	type		STATE2 is (IDLE2, SEND_START,WAIT_NOSTART);
	constant	CLOCK_RATE:			natural := 50000000;
	constant	MEASURE_TIME:		natural := 1000; --ms
	constant	CLK_MEAS_TIME:		natural := (CLOCK_RATE/MEASURE_TIME) * 1000;
	constant	TWOMS:					natural := (CLOCK_RATE/1000) * 2;
	constant	DATA_TX:			DATA:= (x"01",x"04",x"00",x"0b",x"00",x"02",x"00",x"09");
	signal		DELAY_CNT:			natural range 0 to CLK_MEAS_TIME;
	signal		DATA_RX:			DATA_1;
	signal 		PRES_STATE,NEXT_STATE: 	STATE;
	signal 		PRES_STATE1,NEXT_STATE1: 	STATE1;
	signal		CNT:				natural range 0 to 9;
	signal		INT_READY_RX:	std_logic;
	signal 		DELAY1:	natural range 0 to TWOMS;
	
	begin --BEH


process(DATA_RX)	-- Floating Point data extraction
 variable		SIGN:		std_logic;	-- 1 negative, 0 positive
 variable		EXPONENT:	std_logic_vector(7 downto 0);
 variable		MANTIX:		std_logic_vector(23 downto 0);
 variable 		DATA_TEMP:	std_logic_vector(23 downto 0);
 variable		COMMA_POS:	natural range 0 to 255;
 variable		K:			natural range 0 to 23;
	begin
		DATA_TEMP			:= (others => '0');
		DATA_POS			<= (others => '0');
		DATA_NEG			<= (others => '0');
		SIGN				:= DATA_RX(5)(7);
		EXPONENT(7 downto 1):= DATA_RX(5)(6 downto 0);
		EXPONENT(0)			:= DATA_RX(6)(7);
		MANTIX(23)			:= '1';
		MANTIX(22 downto 16):= DATA_RX(6)(6 downto 0);
		MANTIX(15 downto 8) := DATA_RX(4)(7 downto 0);
		MANTIX(7 downto 0)  := DATA_RX(5)(7 downto 0);
		COMMA_POS			:= to_integer(unsigned(EXPONENT))-127;
		K					:= 0;
		for I in 0 to 23 loop
			if (23-I>COMMA_POS) then null;
								else DATA_TEMP(K) := MANTIX(I);
									 K:= K+1;
			end if;
		end loop;
		if (SIGN = '1')	then DATA_NEG <= DATA_TEMP(7 downto 0);
							else DATA_POS <= DATA_TEMP(7 downto 0);
		end if;
end process;


process (CLK,RST)	-- Master State Machine
  begin
	if (RST='0') then
		PRES_STATE <= IDLE;
		PRES_STATE1 <= IDLE1;
		elsif (rising_edge(CLK)) then
			PRES_STATE <= NEXT_STATE;
			PRES_STATE1 <= NEXT_STATE1;
	end if;
end process;



process (PRES_STATE1,READY_RX)
	begin
		NEXT_STATE1	<=	PRES_STATE1;
		case PRES_STATE1 is
			when IDLE1			=>	if (READY_RX='0') then NEXT_STATE1 <= R1;
												end if;
			when R1				=>	NEXT_STATE1	<=	R2;
			when R2				=>	NEXT_STATE1	<=	R3;
			when R3				=>	NEXT_STATE1	<=	WAIT_NOR;
			when WAIT_NOR	=>	if (READY_RX ='1' ) then NEXT_STATE1	<=	IDLE1;
												end if;
		end case;
end process;

process(PRES_STATE1)
	begin
		INT_READY_RX	<= '1';
		if ((PRES_STATE1 = R1) or (PRES_STATE1 = R2)) then
			INT_READY_RX	<= '0';
		end if;
end process;


process (PRES_STATE,CNT,READY_TX,INT_READY_RX,START,DELAY_CNT,START,DELAY1)	-- Master State Machine
	begin
		NEXT_STATE <= PRES_STATE;
		case PRES_STATE is
			when IDLE 				=> 	if (START='0') then NEXT_STATE <= SEND_BYTE1;
													end if;
			when SEND_BYTE1 	=>	if (READY_TX = '0') then NEXT_STATE <= SEND_BYTE2;
													end if;
			when SEND_BYTE2	=>	if (READY_TX = '0') then NEXT_STATE <= CNT_INC1;
													end if;
			when CNT_INC1		=>	if (CNT=7) then NEXT_STATE <= CLEAR_CNT;
																	else NEXT_STATE <= SEND_BYTE1;
													end if;
			when CLEAR_CNT		=>	NEXT_STATE <= ATTESA;
			when ATTESA			=>	if (DELAY1 = 0) then NEXT_STATE <= WAIT_RX1;
													end if;
			when WAIT_RX1		=>	if (INT_READY_RX = '0')  then NEXT_STATE <= SAMPLE_RX;
													end if;
			when SAMPLE_RX	=>	NEXT_STATE <= CNT_INC2;
			when CNT_INC2		=>	if (CNT=8) then NEXT_STATE <= DELAY;
																	else NEXT_STATE <= WAIT_RX1;
													end if;
			when DELAY				=>	if (DELAY_CNT=0) then NEXT_STATE <= IDLE;
													end if;
		end case;
end process;

process(CLK,RST)		-- CNT management
	begin
		if (RST='0') then CNT <= 0;
		elsif rising_edge(CLK) then
			if ((PRES_STATE = CNT_INC1) or (PRES_STATE = CNT_INC2)) then
				CNT <= CNT +1;
			end if;
			if ((PRES_STATE = CLEAR_CNT) or (PRES_STATE=IDLE)) then
				CNT <= 0;
			end if;
		end if;
end process;

process(PRES_STATE,CNT)		-- Data sending
	begin
		DATA_OUT <= (others => '0');
		SEND		<= '1';
		if ((PRES_STATE = SEND_BYTE1) or (PRES_STATE = SEND_BYTE2)) then
			DATA_OUT <= DATA_TX(CNT);
		end if;
		if (PRES_STATE = SEND_BYTE1)  then
			SEND <= '0';
		end if;
end process;

process(CLK,RST)		-- Data receiving
	begin
		if (RST='0') then DATA_RX <= (others => x"00");
		elsif rising_edge(CLK) then
			if (PRES_STATE = SAMPLE_RX) then
					DATA_RX(CNT) <= DATA_IN;
			end if;
		end if;
end process;

process(PRES_STATE)		-- Start receiving management
	begin
		START_REC <= '1';
		if (PRES_STATE=WAIT_RX1) then START_REC <= '0';
		end if;
end process;


process(CLK,RST)		-- DELAY management
	begin
		if (RST='0') then DELAY_CNT <= CLK_MEAS_TIME;
								DELAY1 <= TWOMS;
		elsif rising_edge(CLK) then
			if (PRES_STATE = DELAY)  then
				DELAY_CNT <= DELAY_CNT - 1;
			end if;
			if (DELAY_CNT = 0) then
				DELAY_CNT <= CLK_MEAS_TIME;
			end if;
			if (PRES_STATE=ATTESA) then
				DELAY1 <= DELAY1-1;
				if (DELAY1=0) then DELAY1 <= TWOMS;
				end if;
			end if;
		end if;
end process;

process(PRES_STATE)
	begin
		DATA_VALID <= '1';
		if (PRES_STATE = DELAY) then DATA_VALID <= '0';
		end if;
end process;


	end BEH;