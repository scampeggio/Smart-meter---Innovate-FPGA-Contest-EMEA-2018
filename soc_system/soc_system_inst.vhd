	component soc_system is
		port (
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_neg_in   : in  std_logic_vector(7 downto 0) := (others => 'X'); -- data_neg_in
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_neg_out  : out std_logic_vector(7 downto 0);                    -- data_neg_out
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_pos_in   : in  std_logic_vector(7 downto 0) := (others => 'X'); -- data_pos_in
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_pos_out  : out std_logic_vector(7 downto 0);                    -- data_pos_out
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_valid_in : in  std_logic                    := 'X';             -- data_valid_in
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_start_pumps   : out std_logic;                                       -- start_pumps
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_start_loads   : out std_logic;                                       -- start_loads
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_battery       : in  std_logic_vector(7 downto 0) := (others => 'X'); -- battery
			clk_clk                                                               : in  std_logic                    := 'X';             -- clk
			reset_reset_n                                                         : in  std_logic                    := 'X'              -- reset_n
		);
	end component soc_system;

	u0 : component soc_system
		port map (
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_neg_in   => CONNECTED_TO_avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_neg_in,   -- avalon_interface_to_smart_meter_fsms_0_interface_to_fsm.data_neg_in
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_neg_out  => CONNECTED_TO_avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_neg_out,  --                                                        .data_neg_out
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_pos_in   => CONNECTED_TO_avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_pos_in,   --                                                        .data_pos_in
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_pos_out  => CONNECTED_TO_avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_pos_out,  --                                                        .data_pos_out
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_valid_in => CONNECTED_TO_avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_valid_in, --                                                        .data_valid_in
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_start_pumps   => CONNECTED_TO_avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_start_pumps,   --                                                        .start_pumps
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_start_loads   => CONNECTED_TO_avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_start_loads,   --                                                        .start_loads
			avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_battery       => CONNECTED_TO_avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_battery,       --                                                        .battery
			clk_clk                                                               => CONNECTED_TO_clk_clk,                                                               --                                                     clk.clk
			reset_reset_n                                                         => CONNECTED_TO_reset_reset_n                                                          --                                                   reset.reset_n
		);

