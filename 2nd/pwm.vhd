LIBRARY ieee ;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
use ieee.numeric_std;
use ieee.numeric_std.all;

-- ITT Giorgi - PWM generator

entity PWM is
	port	(
			CLK		 	:in std_logic ;						-- Master Clock 4MHz
			RST			:in std_logic;
			COMMAND		:in std_logic_vector (7 downto 0);	-- 7-0 bits duty cycle
			DATA_VALID	:in std_logic;						-- Asserted low if command valid
			DATA_OUT	:out std_logic						-- Serial data out
			);
END PWM ;

architecture BEH of PWM is
	constant	CLOCK_RATE:				integer := 50000000;		-- Hz
	constant	PWM_FREQ:				integer := 200;				-- Hz
	constant	CLK_PERIOD:				integer := CLOCK_RATE/PWM_FREQ;
	constant	CLK_STEP:				integer := CLK_PERIOD/255;
	signal 		CARRIER_PERIOD: 		integer range 0 to CLK_PERIOD;	    
	signal		ONE_DURATION:			integer range 0 to 255;		
	signal		CLK_STEP_DURATION:		integer range 0 to CLK_PERIOD;
	signal		INT_DATA_OUT:			std_logic;
	signal		INT_COMMAND:			std_logic_vector (7 downto 0);
	
	begin --BEH

DATA_OUT <= not(INT_DATA_OUT);


process (CLK,RST)	-- MAster State Machine
  begin
	if (RST='0') then
		CARRIER_PERIOD	<= 0;
		ONE_DURATION	<= 0;
		elsif (rising_edge(CLK)) then
			CARRIER_PERIOD <= CARRIER_PERIOD +1;
			CLK_STEP_DURATION <= CLK_STEP_DURATION +1;
			if (CARRIER_PERIOD = CLK_PERIOD) then CARRIER_PERIOD <= 0;
												  ONE_DURATION <= 0;
			end if;
			if (CLK_STEP_DURATION = CLK_STEP) then 	CLK_STEP_DURATION <= 0;
													ONE_DURATION <= ONE_DURATION +1;
		end if;
	end if;
end process;


process (CLK,RST)
  begin
	if (RST='0') then
		INT_DATA_OUT <= '0';
		INT_COMMAND <= (others => '0');
		elsif (rising_edge(CLK)) then
			if (CARRIER_PERIOD = 0) then INT_DATA_OUT <= '1';
			end if;
			if ONE_DURATION >= to_integer(unsigned(INT_COMMAND))
				then INT_DATA_OUT <= '0';
			end if;
			if (INT_DATA_OUT = '0') then INT_COMMAND <= COMMAND;
			end if;
			if (DATA_VALID = '1') then INT_DATA_OUT <= '0';
			end if;
	end if;
end process;


end BEH;