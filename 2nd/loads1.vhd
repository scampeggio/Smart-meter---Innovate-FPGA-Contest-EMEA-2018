LIBRARY ieee ;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
use ieee.numeric_std.all;

-- ITT Giorgi - Loads management system

entity LOADS1 is
	port (CLK, RST : in std_logic;
		START:				in std_logic;								-- Module Activate - active low
		DATA_NEG,DATA_POS : in std_logic_vector(7 downto 0);
		DATA_VALID: 		in std_logic;
		FORCE_LOAD:			in std_logic_vector(4 downto 0);			-- Force/Noforce 1/0, Load no 0000 to 1111
		FORCE_WRITE:		in std_logic;								-- Force Load data write, active low
		COMMAND_OUT:		out std_logic_vector(7 downto 0);			-- Command to loads switches - OXXNNNN (ON/OFF-XXX-LOAD NO)
		FORCED:				out std_logic_vector(15 downto 0);			-- Data for display
		ACTIVED:			out std_logic_vector(15 downto 0);			-- Data for Display
		FIFO_WRITE:			out std_logic);	 							-- Write signal to FIFO, active low
end LOADS1;

architecture BEH of LOADS1 is
	constant LOADS_NO: integer:= 16;
	type STATE is (IDLE,SEND_UPDATE,SINK,SOURCE,SEND_FORCE);
	type STATEF is (IDLEF,UPDATEF);
	type DATA_CONF is array (0 to LOADS_NO-1) of std_logic_vector (1 downto 0); -- FORCE/NOFORCE,ON/OFF
	signal INDEX1,INDEX2: natural range 0 to LOADS_NO-1;
	signal DATA: DATA_CONF;
	signal PRES_STATE, NEXT_STATE: STATE ;
	signal PRES_STATEF,NEXT_STATEF: STATEF;
	signal POWER_SOURCED,POWER_SINKED: natural range 0 to 255;
	signal POWER_UPDATED,INT_DATA_VALID: std_logic;
	signal INT_FORCE_LOAD: std_logic_vector(4 downto 0);
	signal MESSAGE: std_logic_vector(7 downto 0);
		
begin  --BEH

process(DATA)
	begin
		for I in 0 to 15 loop
			FORCED(I) 	<= DATA(I)(1);
			ACTIVED(I)	<= DATA(I)(0);
		end loop;
end process;

process (CLK,RST)
	begin 
		if (RST = '0') then PRES_STATE <= IDLE;
							PRES_STATEF <= IDLEF;
			elsif rising_edge(CLK) then
				PRES_STATE <= NEXT_STATE;
				PRES_STATEF <= NEXT_STATEF;
		end if;
end process;


process (CLK,RST)
	begin
		if (RST='0') then
		elsif rising_edge(CLK) then POWER_SOURCED 	<= 0;
									POWER_SINKED 	<= 0;
				if (POWER_UPDATED = '0') 	  then 	POWER_SOURCED 	<= to_integer(unsigned(DATA_POS));
																POWER_SINKED 	<= to_integer(unsigned(DATA_NEG));
				end if;
		end if;
end process;

	

process (PRES_STATE,PRES_STATEF,POWER_UPDATED,POWER_SOURCED,POWER_SINKED,INDEX1,DATA,START)
	begin
		NEXT_STATE <= PRES_STATE;
		case	PRES_STATE is
			when IDLE	=>	if (POWER_UPDATED = '0') then NEXT_STATE <=  SEND_UPDATE;
							end if;
							if (PRES_STATEF = UPDATEF) then NEXT_STATE <= SEND_FORCE;
							end if;
							if (START = '1') then NEXT_STATE <= IDLE;
							end if;

			when SEND_UPDATE	=> NEXT_STATE <= IDLE;
									if (POWER_SOURCED > 0) then NEXT_STATE <= SOURCE;
									end if;
									if (POWER_SINKED > 0) then NEXT_STATE <= SINK;
									end if;
									

			when SOURCE	=>	if ((INDEX1 = 0) or (DATA(INDEX1)(0) = '0')) then NEXT_STATE <= IDLE;
							end if;

			when SINK	=>	if ((INDEX1 = 0) or (DATA(INDEX1) = "01")) then NEXT_STATE <= IDLE;
							end if;

			when SEND_FORCE		=> 	NEXT_STATE <= IDLE;
		end case;
end process;

	
process (CLK,RST)
	begin 
		if (RST = '0') then POWER_UPDATED <= '1';
			elsif rising_edge(CLK) then
				INT_DATA_VALID <= DATA_VALID;
				POWER_UPDATED  <= not (INT_DATA_VALID and not (DATA_VALID));
		end if;
	end process;

process (CLK,RST)
	begin 
		if (RST = '0') then INT_FORCE_LOAD <= (others => '0');
			elsif rising_edge(CLK) then
				if (FORCE_WRITE = '0') then INT_FORCE_LOAD <= FORCE_LOAD;
				end if;
		end if;
end process;

process (PRES_STATEF,FORCE_WRITE)
	begin
		NEXT_STATEF <= PRES_STATEF;
		case PRES_STATEF is
			when IDLEF	=>	if (FORCE_WRITE = '0') then NEXT_STATEF <= UPDATEF;
							end if;

			when UPDATEF =>	NEXT_STATEF <=	IDLEF;
		end case;
end process;



process (CLK,RST)
	begin 
		if (RST = '0') then INDEX1 <=  LOADS_NO-1;
							MESSAGE <= (others => '0');
							FIFO_WRITE <= '1';
							DATA <= ("01","01","01","01","01","01","01","01",
									 "01","01","01","01","01","01","01","01");
			elsif rising_edge(CLK) then
				FIFO_WRITE <= '1';
				if (PRES_STATE = IDLE) then INDEX1 <= LOADS_NO-1;
				end if;
				if (PRES_STATE = SOURCE) then 	INDEX1 <= INDEX1 - 1;
												if (DATA(INDEX1)(0) = '0') then MESSAGE <= "1000" & std_logic_vector(to_unsigned(INDEX1,4));
																				DATA(INDEX1)(0) <= '1';
																				FIFO_WRITE <= '0';
												end if;
				end if;
				if (PRES_STATE = SINK) then 	INDEX1 <= INDEX1 - 1;
												if (DATA(INDEX1) = "01") then MESSAGE <= "0000" & std_logic_vector(to_unsigned(INDEX1,4));
																				DATA(INDEX1)(0) <= '0';
																				FIFO_WRITE <= '0';
												end if;
				end if;
				if (PRES_STATE = SEND_FORCE) then 	
					DATA(to_integer(unsigned(INT_FORCE_LOAD(3 downto 0))))(1) <= INT_FORCE_LOAD(4);
					if 	(INT_FORCE_LOAD(4) = '1')	then
						MESSAGE <= "1000" & INT_FORCE_LOAD(3 downto 0);
						DATA(to_integer(unsigned(INT_FORCE_LOAD(3 downto 0))))(0) <= '1';
						FIFO_WRITE <= '0';
					end if;
				end if;
		end if;
end process;

COMMAND_OUT <= MESSAGE;


end BEH;
