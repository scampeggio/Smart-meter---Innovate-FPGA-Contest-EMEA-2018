LIBRARY ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_signed.all ;

-- ITT "Giorgi" Brindisi
-- 
-- Decoder for Sony SIRC protocol (up to 20 bit)
--
-- DATA_IN : Data input from infrared sensor (TSOP1738 or similar)
--
-- DATA_OUT : 0000 to 1111 with DATA_VALID asserted low
--


ENTITY SIRC is
		port (CLK, RST			: in std_logic;
			DATA_IN				: in std_logic;
			DATA_OUT			: out std_logic_vector(3 downto 0);
			DATA_VALID			: out std_logic
			) ;
end SIRC ;

architecture BEH of SIRC is
	constant BITS_IN_FRAME: integer := 20;
	constant CLK_RATE: integer := 50000000;
	constant DELAY1: integer := (CLK_RATE/1000000)*128;	-- 128us
	constant DELAY2: integer := (CLK_RATE/1000000)*16;	-- 16us
	type STATE is (IDLE,START1,START2,GET0,GET1,FOUND_BIT,WAIT_BIT,END_BIT,CLEAR_COUNT,REG);
	signal PRES_STATE,NEXT_STATE: STATE;
	signal SHIFT				: std_logic_vector (0 to BITS_IN_FRAME-1);
	signal START_BIT_TIME		: integer range 0 to (CLK_RATE*4)/1000;	-- up to 4ms
	signal BIT_COUNT			: integer range 0 to BITS_IN_FRAME;
	signal BIT_TIME_COUNT		: integer range 0 to (CLK_RATE*4)/1000;	-- up to 4ms
	signal DATA					: std_logic;


begin --  BEH
	
	
	process (CLK,RST)
		begin
			if (RST='0') then
				PRES_STATE <= IDLE;
			elsif rising_edge(CLK) then
				PRES_STATE <= NEXT_STATE;
			end if;
	end process;

	process (CLK,RST)
		begin
			if (RST='0') then
				START_BIT_TIME <= 0;
			elsif rising_edge(CLK) then
				if PRES_STATE = START1
					then START_BIT_TIME <= START_BIT_TIME +1;
				end if;
				if PRES_STATE = IDLE
					then START_BIT_TIME <= 0;
				end if;
			end if;
	end process;

	process (CLK,RST)
		begin
			if (RST='0') then
				BIT_TIME_COUNT <= 0;
			elsif rising_edge(CLK) then
				if ((PRES_STATE = FOUND_BIT) or (PRES_STATE = END_BIT))
					then BIT_TIME_COUNT <= BIT_TIME_COUNT +1;
				end if;
				if ((PRES_STATE = IDLE) or (PRES_STATE = GET1) or (PRES_STATE = GET0) or (PRES_STATE = CLEAR_COUNT))
					then BIT_TIME_COUNT <= 0;
				end if;
			end if;
	end process;

	process (CLK,RST)
		begin
			if (RST='0') then
				SHIFT <= (others => '0');
				BIT_COUNT <= 0;
			elsif rising_edge(CLK) then
				if (PRES_STATE = GET1)
					then BIT_COUNT <= BIT_COUNT +1;
						 SHIFT (BIT_COUNT) <= '1';
				end if;
				if (PRES_STATE = GET0)
					then BIT_COUNT <= BIT_COUNT +1;
						 SHIFT (BIT_COUNT) <= '0';
				end if;
				if PRES_STATE = START2
					then SHIFT <= (others => '0');
						 BIT_COUNT <= 0;
				end if;
			end if;
	end process;
		
		
		
	process (DATA,START_BIT_TIME,PRES_STATE,BIT_COUNT,BIT_TIME_COUNT)
		begin
			NEXT_STATE <= PRES_STATE;
			case PRES_STATE is
				when IDLE => if DATA = '0'  then NEXT_STATE <= IDLE;
											else NEXT_STATE <= START1;
							 end if;
							
				when START1 => if DATA = '0'  then NEXT_STATE <= START2;
														else NEXT_STATE <= START1;
									end if;
				
				when START2 => if DATA = '0'  then NEXT_STATE <= START2;
											  else NEXT_STATE <= FOUND_BIT;
							   end if;

				when FOUND_BIT => if BIT_TIME_COUNT > ((START_BIT_TIME/4)+DELAY1) then
											if DATA = '1' then NEXT_STATE <= GET1;
																else NEXT_STATE <= GET0;
											end if;
								  end if;
							
				when WAIT_BIT => if DATA = '0' then NEXT_STATE <= END_BIT;
									end if;

				when END_BIT => if DATA = '0' then NEXT_STATE <= END_BIT;
											  else NEXT_STATE <= CLEAR_COUNT;
									end if;
								if	BIT_TIME_COUNT > (START_BIT_TIME + DELAY2)  then NEXT_STATE <= IDLE;
								end if;
				
				when CLEAR_COUNT => NEXT_STATE <= FOUND_BIT;

				when GET0 => NEXT_STATE <= END_BIT;

				when GET1 => NEXT_STATE <= WAIT_BIT;
				when REG	 => NEXT_STATE <= IDLE;
				
			end case;
		end process;

		
--	process (PRES_STATE)
--		begin
--				DATA_VALID <= '1';
--				DATA_OUT <= (others => '0');
--					case PRES_STATE is
--						when IDLE	=>			DATA_OUT <= "0001";
--						when START1 =>  DATA_OUT <= "0010";
--						when START2 =>  DATA_OUT <= "0011";
--						when FOUND_BIT =>  DATA_OUT <= "0100";
--						when WAIT_BIT =>  DATA_OUT <= "0101";
--						when END_BIT =>  DATA_OUT <= "0110";
--						when CLEAR_COUNT =>  DATA_OUT <= "0111";
--						when GET0 =>  DATA_OUT <= "1000";
--						when GET1 =>  DATA_OUT <= "1001";
--						when REG =>  DATA_OUT <= "1111";
--						when others => 		DATA_OUT <= (others => '0');
--					end case;
--	end process;		
--		

	process (PRES_STATE,SHIFT)
		begin
				DATA_VALID <= '1';
				DATA_OUT <= "0000";
				if (PRES_STATE = IDLE) then
					case SHIFT (0 to 8) is
						when "000000001" =>  DATA_OUT <= "0001";
													DATA_VALID 	<= '0';
						when "100000001" =>  DATA_OUT <= "0010";
													DATA_VALID 	<= '0';
						when "010000001" =>  DATA_OUT <= "0011";
													DATA_VALID 	<= '0';
						when "110000001" =>  DATA_OUT <= "0100";
													DATA_VALID 	<= '0';
						when "001000001" =>  DATA_OUT <= "0101";
													DATA_VALID 	<= '0';
						when "101000001" =>  DATA_OUT <= "0110";
													DATA_VALID 	<= '0';
						when "011000001" =>  DATA_OUT <= "0111";
													DATA_VALID 	<= '0';
						when "111000001" =>  DATA_OUT <= "1000";
													DATA_VALID 	<= '0';
						when "000100001" =>  DATA_OUT <= "1001";
													DATA_VALID 	<= '0';
						when "100100001" =>  DATA_OUT <= "0000";
													DATA_VALID 	<= '0';
						when others => 		DATA_OUT <= (others => '0');
													DATA_VALID 	<= '1';
					end case;
				end if;
	end process;

	
		
--	process (CLK,RST)
--		begin
--			if (RST='0') then DATA_OUT <= (others => '0');
--									DATA_VALID <= '1';
--			elsif rising_edge(CLK) then
----				DATA_VALID <= '1';
--				if (PRES_STATE = START1) then DATA_VALID <= '1';
--				end if;
--				
--				if (PRES_STATE = REG) then
--					case SHIFT (0 to 8) is
--						when "000000001" =>  DATA_OUT <= "0001";
--													DATA_VALID 	<= '0';
--						when "100000001" =>  DATA_OUT <= "0010";
--													DATA_VALID 	<= '0';
--						when "010000001" =>  DATA_OUT <= "0011";
--													DATA_VALID 	<= '0';
--						when "110000001" =>  DATA_OUT <= "0100";
--													DATA_VALID 	<= '0';
--						when "001000001" =>  DATA_OUT <= "0101";
--													DATA_VALID 	<= '0';
--						when "101000001" =>  DATA_OUT <= "0110";
--													DATA_VALID 	<= '0';
--						when "011000001" =>  DATA_OUT <= "0111";
--													DATA_VALID 	<= '0';
--						when "111000001" =>  DATA_OUT <= "1000";
--													DATA_VALID 	<= '0';
--						when "000100001" =>  DATA_OUT <= "1001";
--													DATA_VALID 	<= '0';
--						when "100100001" =>  DATA_OUT <= "0000";
--													DATA_VALID 	<= '0';
--						when others => 		DATA_OUT <= (others => '0');
--													DATA_VALID 	<= '1';
--					end case;
--				end if;
--			end if;
--	end process;

	DATA <= not (DATA_IN);
	
end BEH;
