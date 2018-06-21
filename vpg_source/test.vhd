library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_signed.all;
use ieee.numeric_std.all;

entity TEST is
port
( clk: in std_logic;                
  reset_n: in std_logic;

  STATUS: 	buffer std_logic_vector(15 downto 0);
  FORCED: 	buffer std_logic_vector(15 downto 0);
  CHARGE: 	buffer std_logic_vector(7 downto 0);
  DISCHARGE: buffer std_logic_vector(7 downto 0);
  P_SOURCED: buffer std_logic_vector(7 downto 0);
  P_SINKED:	buffer std_logic_vector(7 downto 0);
  BATTERY:	buffer std_logic_vector(7 downto 0)
);
end TEST;

architecture BEH of TEST is

signal CNT: natural range 0 to 20000000;

begin


process (clk,reset_n)
  begin
	if (reset_n='0') then 
		CNT <= 0;
	elsif rising_edge(clk) then
		CNT <= CNT + 1;
		if (CNT = 20000000) then CNT <= 0;
		end if;
	end if;
end process;


process (clk,reset_n)
  begin
	if (reset_n='0') then 
		  STATUS <= (others => '0');
		  FORCED <= (others => '0');
		  CHARGE <= (others => '0');
		  DISCHARGE <= (others => '0');
		  P_SOURCED <= (others => '0');
		  P_SINKED <= (others => '0');
		  BATTERY <= (others => '0');
	elsif rising_edge(clk) then
		if (CNT = 0) then
			STATUS <= STATUS xor FORCED;
			FORCED <= FORCED + x"5aa5";
			CHARGE <= CHARGE + "00000111";
			DISCHARGE <= DISCHARGE + x"0f";
			P_SOURCED <= CHARGE + DISCHARGE;
			P_SINKED <= P_SINKED + x"03";
			BATTERY <= BATTERY + x"01";
		end if;
	end if;
end process;

end BEH;