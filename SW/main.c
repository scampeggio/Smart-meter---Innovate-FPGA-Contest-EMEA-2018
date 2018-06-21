/*
This program demonstrate how to use hps communicate with FPGA through light AXI Bridge.
uses should program the FPGA by GHRD project before executing the program
refer to user manual chapter 7 for details about the demo
*/


#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include "hwlib.h"
#include "socal/socal.h"
#include "socal/hps.h"
#include "socal/alt_gpio.h"
#include "hps_0.h"

#define HW_REGS_BASE ( ALT_STM_OFST )
#define HW_REGS_SPAN ( 0x04000000 )
#define HW_REGS_MASK ( HW_REGS_SPAN - 1 )

int main() {

	void *virtual_base;
	int fd;
	void *start;
	void *data_pos_hps;
	void *data_neg_hps;
	void *data_pos;
	void *data_neg;
	void *battery;
	void *data_valid;

	// map the address space for the LED registers into user space so we can interact with them.
	// we'll actually map in the entire CSR span of the HPS since we want to access various registers within that span

	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) {
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return( 1 );
	}

	virtual_base = mmap( NULL, HW_REGS_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_REGS_BASE );

	if( virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap() failed...\n" );
		close( fd );
		return( 1 );
	}
	

	data_valid=virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + FSM_INTERFACE_0_BASE ) & ( unsigned long)( HW_REGS_MASK ) );
	data_pos=virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + FSM_INTERFACE_0_BASE +0x01 ) & ( unsigned long)( HW_REGS_MASK ) );
	data_neg=virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + FSM_INTERFACE_0_BASE +0x02 ) & ( unsigned long)( HW_REGS_MASK ) );
	battery=virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + FSM_INTERFACE_0_BASE +0x03 ) & ( unsigned long)( HW_REGS_MASK ) );	
	data_pos_hps=virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + FSM_INTERFACE_0_BASE +0x04 ) & ( unsigned long)( HW_REGS_MASK ) );
	data_neg_hps=virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + FSM_INTERFACE_0_BASE +0x05 ) & ( unsigned long)( HW_REGS_MASK ) );	
	start=virtual_base + ( ( unsigned long  )( ALT_LWFPGASLVS_OFST + FSM_INTERFACE_0_BASE +0x06 ) & ( unsigned long)( HW_REGS_MASK ) );
	

	// simulating messages from other sites

	while (1)
	{
	*(uint8_t *)start = 0x00;
	usleep( 500*1000 );
	*(uint8_t *)start = 0x01;
	usleep( 500*1000 );
	*(uint8_t *)start = 0x02;
	usleep( 500*1000 );
	*(uint8_t *)start = 0x03;
	usleep( 2000*1000 );

	*(uint8_t *)data_pos_hps = 0x50;
	usleep(10000*1000);
	*(uint8_t *)data_neg_hps = 0x20;
	usleep(5000*1000);
	*(uint8_t *)data_pos_hps = 0x00;
	*(uint8_t *)data_neg_hps = 0x00;
	usleep(5000*1000);

	}
	// clean up our memory mapping and exit
	
	if( munmap( virtual_base, HW_REGS_SPAN ) != 0 ) {
		printf( "ERROR: munmap() failed...\n" );
		close( fd );
		return( 1 );
	}

	close( fd );

	return( 0 );
}
