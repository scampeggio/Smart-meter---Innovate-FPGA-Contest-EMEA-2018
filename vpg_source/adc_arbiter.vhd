library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_signed.all;
use ieee.numeric_std.all;

entity ADC_ARBITER is
port
( clk: in std_logic;                
  reset_n: in std_logic;

  START: 	out std_logic;
  CH: 		out std_logic_vector(2 downto 0);
  DONE: 		in std_logic;
  DATA_IN: 	in std_logic_vector(11 downto 0);
  BATTERY:	buffer std_logic_vector(7 downto 0)
);
end ADC_ARBITER;

architecture BEH of ADC_ARBITER is

type STATE is (IDLE,MEASURE,WAIT_FOR,REG_DATA);
signal PRES_STATE,NEXT_STATE: STATE;
signal CNT: natural range 0 to 10000000;

begin

CH <= "000";


process (clk,reset_n)
  begin
	if (reset_n='0') then 
		PRES_STATE <= IDLE;
	elsif rising_edge(clk) then
		PRES_STATE <= NEXT_STATE;
	end if;
end process;


process (PRES_STATE,CNT,DONE)
	begin
		NEXT_STATE<= PRES_STATE;
		case PRES_STATE is
			when IDLE		=>	if (CNT = 0) then NEXT_STATE <= MEASURE;
									end if;
								
			when MEASURE	=>	if (DONE='0') then NEXT_STATE <= WAIT_FOR;
									end if;
								
			when WAIT_FOR	=>	if (DONE='1') then NEXT_STATE <= REG_DATA;
									end if;
									
			when REG_DATA	=>	NEXT_STATE <= IDLE;
		end case;
end process;


process(PRES_STATE)
	begin
		START <= '0';
		if (PRES_STATE = MEASURE) then START <= '1';
		end if;
end process;


process (clk,reset_n)
  begin
	if (reset_n='0') then 
		BATTERY <= (others =>'0');
	elsif rising_edge(clk) then
		if (PRES_STATE = REG_DATA) then BATTERY <= (DATA_IN(11 downto 4));
		end if;
	end if;
end process;


process (clk,reset_n)
  begin
	if (reset_n='0') then 
		CNT <= 0;
	elsif rising_edge(clk) then
		CNT <= CNT + 1;
		if (CNT = 10000000) then CNT <= 0;
		end if;
	end if;
end process;


end BEH;