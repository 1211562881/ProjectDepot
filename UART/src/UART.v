module UART
(
	input CLK,
	input RST,
	input Rs232_Rx,
	
	output wire Rs232_Tx,
	output wire Tx_Done,
	output wire Tx_State
);

	wire [7:0]UART_Data_Byte;
	wire UART_Send_En;

	UART_Byte_Tx UART_Byte_Tx1
	(
			.CLK(CLK),
			.RST(RST),
			.Send_En(UART_Send_En),
			.Data_Byte(UART_Data_Byte),
			.Rs232_Tx(Rs232_Tx),
			.Tx_Done(Tx_Done),
			.Tx_State(Tx_State)
		);
		
		
	UART_Byte_Rx UART_Byte_Rx1
	(
			.CLK(CLK),
			.RST(RST),
			.Rs232_Rx(Rs232_Rx),
			.Data_Byte(UART_Data_Byte),
			.Rx_Done(UART_Send_En)
		);



endmodule
