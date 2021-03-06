
module soc_system (
	avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_neg_in,
	avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_neg_out,
	avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_pos_in,
	avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_pos_out,
	avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_valid_in,
	avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_start_pumps,
	avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_start_loads,
	avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_battery,
	clk_clk,
	reset_reset_n);	

	input	[7:0]	avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_neg_in;
	output	[7:0]	avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_neg_out;
	input	[7:0]	avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_pos_in;
	output	[7:0]	avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_pos_out;
	input		avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_data_valid_in;
	output		avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_start_pumps;
	output		avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_start_loads;
	input	[7:0]	avalon_interface_to_smart_meter_fsms_0_interface_to_fsm_battery;
	input		clk_clk;
	input		reset_reset_n;
endmodule
