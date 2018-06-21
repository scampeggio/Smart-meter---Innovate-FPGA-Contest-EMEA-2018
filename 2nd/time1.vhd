LIBRARY ieee ;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;

-- ITT Giorgi - sequencer simulator

entity TIME1 is
	port	(
			CLK		 	:in std_logic ;						-- Master Clock 
			RST			:in std_logic;						-- Master Clear active low 
			START1		:buffer std_logic;					-- START LOADS - active low
			START2		:buffer std_logic						-- START CHARGING - active low
			);
END TIME1 ;

architecture BEH of TIME1 is

	constant MAXDELAY: natural :=500000000;
	signal 	DELAY: natural range 0 to MAXDELAY;
	
	begin --BEH


process (CLK,RST)	-- MAster State Machine
  begin
	if (RST='0') then
		DELAY <=0;
		elsif (rising_edge(CLK)) then
			DELAY <= DELAY+1;
			if DELAY = MAXDELAY then DELAY <= 0;
			end if;
	end if;
end process;

process (CLK,RST)	-- MAster State Machine
  begin
	if (RST='0') then
		START1 <= '0';
		START2 <= '1';
		elsif (rising_edge(CLK)) then
			if DELAY = 0 then START1 <= not(START1);
									START2 <= not(START2);
			end if;
	end if;
end process;
	
	end BEH;