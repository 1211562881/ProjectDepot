module UART_Byte_Rx
(
	input CLK,							//系统时钟
	input RST,							//全局复位
	input Rs232_Rx,					//串口接收端
	
	output reg [7:0]Data_Byte,		//数据存储端
	output reg Rx_Done				//接收完成(用于触发发送使能)
);

	parameter bps_cut_MAX = 325-1;	//波特率设置:9600bps(16倍采样率)
	
	
	reg [15:0]div_cut;					//分频计数器

	reg s0_Rs232_Rx,s1_Rs232_Rx;		//同步寄存器
	reg tmp0_Rs232_Rx,tmp1_Rs232_Rx;	//数据寄存器
	wire nedge;						//下降沿
	
	reg Rx_State;					//接收状态
	reg bps_clk;					//波特率时钟
	reg [7:0]bps_cut;				//波特率时钟计数器
	
	reg [2:0]r_data_byte[7:0];	//滤波暂存器
	reg [7:0]tmp_data_byte;		//数据缓存区
	
	reg [2:0]START_BIT;			//开始信号
	reg [2:0]STOP_BIT;			//停止信号
	
//同步寄存器
always@(posedge CLK or negedge RST)begin
	if(!RST)begin
		s0_Rs232_Rx <= 1'b0;
		s1_Rs232_Rx <= 1'b0;
	end
	else begin
		s0_Rs232_Rx <= Rs232_Rx;
		s1_Rs232_Rx <= s0_Rs232_Rx;
	end
end	

//数据寄存器
always@(posedge CLK or negedge RST)begin
	if(!RST)begin
		tmp0_Rs232_Rx <= 1'b0;
		tmp1_Rs232_Rx <= 1'b0;
	end
	else begin
		tmp0_Rs232_Rx <= s1_Rs232_Rx;
		tmp1_Rs232_Rx <= tmp0_Rs232_Rx;
	end
end	
	
assign nedge = (!tmp0_Rs232_Rx) & tmp1_Rs232_Rx;	//高电平为下降沿
	
//分频计数器
always@(posedge CLK or negedge RST)begin
	if(!RST)
		div_cut <= 16'b0;
	else if(Rx_State)begin
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
		bps_cut <= 8'b0;
	else if(Rx_Done || (bps_cut==8'd12 && (START_BIT >2) ))
		bps_cut <= 8'b0;
	else if(bps_clk)
		bps_cut <= bps_cut+1'b1;
	else
		bps_cut <= bps_cut;
end

//接收完成信号
always@(posedge CLK or negedge RST)begin
	if(!RST)
		Rx_Done <= 1'b0;
	else if(bps_cut==8'd159)
		Rx_Done <= 1'b1;
	else
		Rx_Done <= 1'b0;
end

//接收状态
always@(posedge CLK or negedge RST)begin
	if(!RST)
		Rx_State <= 1'b0;
	else if(nedge)
		Rx_State <= 1'b1;
	else if( Rx_Done || (bps_cut==8'd12 && (START_BIT >2) ) )
		Rx_State <= 1'b0;
	else
		Rx_State <= Rx_State;
end

//数据接收
always@(posedge CLK or negedge RST)begin
	if(!RST)begin
		START_BIT <= 3'd0;
		r_data_byte[0] <= 3'd0;
		r_data_byte[1] <= 3'd0;
		r_data_byte[2] <= 3'd0;
		r_data_byte[3] <= 3'd0;
		r_data_byte[4] <= 3'd0;
		r_data_byte[5] <= 3'd0;
		r_data_byte[6] <= 3'd0;
		r_data_byte[7] <= 3'd0;
		STOP_BIT <= 3'd0;
	end
	else begin
		case(bps_cut)
			0:begin
					START_BIT <= 3'd0;
					r_data_byte[0] <= 3'd0;
					r_data_byte[1] <= 3'd0;
					r_data_byte[2] <= 3'd0;
					r_data_byte[3] <= 3'd0;
					r_data_byte[4] <= 3'd0;
					r_data_byte[5] <= 3'd0;
					r_data_byte[6] <= 3'd0;
					r_data_byte[7] <= 3'd0;
					STOP_BIT <= 3'd0;
			end
			6,7,8,9,10,11:
				START_BIT <= START_BIT+s1_Rs232_Rx;
			22,23,24,25,26,27:
				r_data_byte[0] <= r_data_byte[0]+s1_Rs232_Rx;
			38,39,40,41,42,43:
				r_data_byte[1] <= r_data_byte[1]+s1_Rs232_Rx;
			54,55,56,57,58,59:
				r_data_byte[2] <= r_data_byte[2]+s1_Rs232_Rx;
			70,71,72,73,74,75:
				r_data_byte[3] <= r_data_byte[3]+s1_Rs232_Rx;
			86,87,88,89,90,91:
				r_data_byte[4] <= r_data_byte[4]+s1_Rs232_Rx;
			102,103,104,105,106,107:
				r_data_byte[5] <= r_data_byte[5]+s1_Rs232_Rx;
			118,119,120,121,122,123:
				r_data_byte[6] <= r_data_byte[6]+s1_Rs232_Rx;
			134,135,136,137,138,139:
				r_data_byte[7] <= r_data_byte[7]+s1_Rs232_Rx;
			150,151,152,153,154,155:
				STOP_BIT <= STOP_BIT+s1_Rs232_Rx;
		endcase
	end
end

//取平均
always@(posedge CLK or negedge RST)begin
	if(!RST)
		tmp_data_byte <= 8'd0;
	else if(bps_cut==8'd159)begin
		tmp_data_byte[0] <= r_data_byte[0][2];		//第0个数据的第二位
		tmp_data_byte[1] <= r_data_byte[1][2];
		tmp_data_byte[2] <= r_data_byte[2][2];
		tmp_data_byte[3] <= r_data_byte[3][2];
		tmp_data_byte[4] <= r_data_byte[4][2];
		tmp_data_byte[5] <= r_data_byte[5][2];
		tmp_data_byte[6] <= r_data_byte[6][2];
		tmp_data_byte[7] <= r_data_byte[7][2];
	end
end

//一个字节接收完毕后锁存到数据存储寄存器
always@(posedge CLK or negedge RST)begin
	if(!RST)
		Data_Byte <= 8'b0;
	else if(bps_cut==8'd159)
		Data_Byte <= tmp_data_byte;
	else
		Data_Byte <= Data_Byte;
end



	




endmodule
