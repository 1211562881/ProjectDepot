module UART_Byte_Tx
(
	input CLK,					//系统时钟
	input RST,					//全局复位
	input Send_En,				//发送使能端（fpga每接收到一个字节就使能发送）
	input [7:0]Data_Byte,	//待发送数据
	
	output reg Rs232_Tx,		//发送数据线
	output reg Tx_Done,		//发送完成标志寄存器
	output reg Tx_State		//发送器当前状态
);

/************************** 异步串行总线测试参数设置 *******************************************/
	parameter bps_cut_MAX = 5208-1;	//波特率设置
	
/******************************************************************************************/
	localparam START_BIT = 1'b0;
	localparam STOP_BIT = 1'b1;
	
	reg bps_clk;				//波特率时钟
	reg [15:0]div_cut;		//分频计数器
	
	reg [3:0]bps_cut;			//波特率时钟计数
	
	reg [7:0]r_data_byte;	//发送缓存区

//分频计数器	
always@(posedge CLK or negedge RST)begin
	if(!RST)
		div_cut <= 16'b0;
	else if(Tx_State)begin
		if(div_cut==bps_cut_MAX)
			div_cut <= 16'b0;
		else
			div_cut <= div_cut+1;
	end
	else
		div_cut <= 16'b0;
end

//波特率时钟
always@(posedge CLK or negedge RST)begin
	if(!RST)
		bps_clk <= 1'b0;
	else if(div_cut==16'd1)
		bps_clk <= 1'b1;
	else
		bps_clk <= 1'b0;
end
	
//波特率时钟计数器
always@(posedge CLK or negedge RST)begin
	if(!RST)
		bps_cut <= 4'b0;
	else if(Tx_Done)
		bps_cut <= 4'b0;
	else if(bps_clk)
		bps_cut <= bps_cut+1'b1;
	else
		bps_cut <= bps_cut;		
end

//发送完成信号
always@(posedge CLK or negedge RST)begin
	if(!RST)
		Tx_Done <= 1'b0;
	else if(bps_cut==4'd11)
		Tx_Done <= 1'b1;
	else
		Tx_Done <= 1'b0;
end

//发送状态
always@(posedge CLK or negedge RST)begin
	if(!RST)
		Tx_State <= 1'b0;
	else if(Send_En)
		Tx_State <= 1'b1;
	else if(Tx_Done)
		Tx_State <= 1'b0;
	else
		Tx_State <= Tx_State;
end

//数据发送缓存区
always@(posedge CLK or negedge RST)begin
	if(!RST)
		r_data_byte <= 8'b0;
	else if(Send_En)
		r_data_byte <= Data_Byte;
	else
		r_data_byte <= r_data_byte;
end
	
//数据发送模块
always@(posedge CLK or negedge RST)begin
	if(!RST)
		Rs232_Tx <= 1'b1;  	//默认高电平
	else begin
		case(bps_cut)
			0:
				Rs232_Tx <= 1'b1;
			1:
				Rs232_Tx <= START_BIT;
			2:
				Rs232_Tx <= r_data_byte[0];
			3:
				Rs232_Tx <= r_data_byte[1];
			4:
				Rs232_Tx <= r_data_byte[2];
			5:
				Rs232_Tx <= r_data_byte[3];
			6:
				Rs232_Tx <= r_data_byte[4];
			7:
				Rs232_Tx <= r_data_byte[5];
			8:
				Rs232_Tx <= r_data_byte[6];
			9:
				Rs232_Tx <= r_data_byte[7];
			10:
				Rs232_Tx <= STOP_BIT;
			default:
				Rs232_Tx <= 1'b1;
		endcase
	end
end



endmodule
