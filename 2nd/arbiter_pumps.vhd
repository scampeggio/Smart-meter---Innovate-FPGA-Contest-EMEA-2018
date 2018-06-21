LIBRARY ieee ;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
USE ieee.numeric_std.all;

-- ITT Giorgi - PUMP arbiter

entity ARBITER_PUMPS is
	port	(
			CLK		 	:in std_logic ;							-- Master Clock 
			RST			:in std_logic;							-- Master Clear active low 
			START		:in std_logic;							-- Activate the module - active low
			DATA_NEG,DATA_POS : in std_logic_vector(7 downto 0);-- Power data
			DATA_VALID: 		in std_logic;					-- Power data valid - active low
			DATA_CHARGE			:out std_logic_vector(7 downto 0);	-- PWM Data battery charge
			DATA_DISCHARGE		:out std_logic_vector(7 downto 0);	-- PWM Data battery discharge
			DATA_CHARGE_VALID	:out std_logic;						-- PWM Data battery charge valid - active low
			DATA_DISCHARGE_VALID:out std_logic;						-- PWM Data battery discharge valid - active low
			BATTERY				:in std_logic_vector(7 downto 0)	-- Battery level
			);
END ARBITER_PUMPS ;

architecture BEH of ARBITER_PUMPS is

	constant B_CHARGED: std_logic_vector(1 downto 0) := "10";
	constant B_DISCHARGED: std_logic_vector(1 downto 0) := "01";
	type 		STATE is (IDLE,CHECK_PW,CHECK_BAT1,CHARGE,MSG1,CHECK_BAT2,DISCHARGE,MSG2);
	signal 		PRES_STATE,NEXT_STATE: 	STATE;
	signal 		POWER_SOURCED,POWER_SINKED: natural range 0 to 255;
	signal 		POWER_UPDATED,INT_DATA_VALID: std_logic;
	signal		BAT_UPDATED:	std_logic;
	signal		BAT_REG:		std_logic_vector (1 downto 0);
	signal		BATTERY_STATUS: std_logic_vector (1 downto 0);	-- 10=Charged,01=Discharged,00=Not Discharged,11=N/A
	
begin --BEH


process(BATTERY)
	begin
		BATTERY_STATUS <= "00";
		if (to_integer(unsigned(BATTERY)) > 240) then 
			BATTERY_STATUS <= B_CHARGED;
		end if;
		if (to_integer(unsigned(BATTERY)) < 100) then 
			BATTERY_STATUS <= B_DISCHARGED;
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



process (PRES_STATE,BAT_REG,POWER_UPDATED,POWER_SOURCED,POWER_SINKED,BAT_UPDATED,START)	-- MAster State Machine
	begin
		NEXT_STATE <= PRES_STATE;
		case PRES_STATE is
			when IDLE 		=> 	if (((POWER_UPDATED='0') or (BAT_UPDATED='0')) and (START = '0')) then NEXT_STATE <= CHECK_PW;
								end if;
			
			when CHECK_PW 	=> 	NEXT_STATE <= IDLE;
								if (POWER_SOURCED > 0) then NEXT_STATE <= CHECK_BAT1;
								end if;
								if (POWER_SINKED > 0) then NEXT_STATE <= CHECK_BAT2;
								end if;

			when CHECK_BAT1	=> 	NEXT_STATE <= CHARGE;
								if (BAT_REG = B_CHARGED) then NEXT_STATE <= MSG1;
								end if;

			when CHARGE 	=> 	if (POWER_UPDATED='0') then NEXT_STATE <= CHECK_PW;
								end if;
								if (BAT_REG = B_CHARGED) then NEXT_STATE <= MSG1;
								end if;

			when MSG1 		=> 	NEXT_STATE <= IDLE;

			when CHECK_BAT2	=>	NEXT_STATE <= DISCHARGE;
								if (BAT_REG = B_DISCHARGED) then NEXT_STATE <= MSG2;
								end if;

			when DISCHARGE 	=> 	if (POWER_UPDATED='0') then NEXT_STATE <= CHECK_PW;
								end if;
								if (BAT_REG = B_DISCHARGED) then NEXT_STATE <= MSG2;
								end if;

			when MSG2 		=> 	NEXT_STATE <= IDLE;
		end case;
end process;


process (CLK,RST)
	begin
		if (RST='0') then	POWER_SOURCED 	<= 0;
							POWER_SINKED 	<= 0;
		elsif rising_edge(CLK) then 
				if (POWER_UPDATED = '0') then 	POWER_SOURCED 	<= to_integer(unsigned(DATA_POS));
												POWER_SINKED 	<= to_integer(unsigned(DATA_NEG));
				end if;
		end if;
end process;

process (CLK,RST)
	begin 
		if (RST = '0') then BAT_UPDATED <= '1';
			elsif rising_edge(CLK) then
				BAT_REG <= BATTERY_STATUS;
				BAT_UPDATED <= '1';
				if (BAT_REG /= BATTERY_STATUS) then BAT_UPDATED  <= '0';
				end if;
		end if;
end process;




process (CLK,RST)
	begin 
		if (RST = '0') then POWER_UPDATED <= '1';
			elsif rising_edge(CLK) then
				INT_DATA_VALID <= DATA_VALID;
				POWER_UPDATED  <= not (INT_DATA_VALID and not (DATA_VALID));
		end if;
end process;


process (PRES_STATE,POWER_SOURCED,POWER_SINKED)
	begin
		DATA_CHARGE				<= (others => '0');
		DATA_DISCHARGE			<= (others => '0');
		DATA_CHARGE_VALID		<= '1';
		DATA_DISCHARGE_VALID	<= '1';
		
		case PRES_STATE is
			when CHARGE		=>	DATA_CHARGE				<= std_logic_vector(to_unsigned(POWER_SOURCED,8));
								DATA_CHARGE_VALID		<= '0';
			when DISCHARGE	=>	DATA_DISCHARGE			<= std_logic_vector(to_unsigned(POWER_SINKED,8));
								DATA_DISCHARGE_VALID	<= '0';
								
			when others		=>	DATA_CHARGE				<= (others => '0');
								DATA_DISCHARGE			<= (others => '0');
								DATA_CHARGE_VALID		<= '1';
								DATA_DISCHARGE_VALID	<= '1';
		end case;
end process;

	end BEH;