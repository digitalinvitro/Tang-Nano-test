module test(
 input  clock, butA, butB, RX,
 output TX, G4, G5, ledr, ledg, ledb
); /*synthesis syn_useioff=1 */
reg [2:0]cnt = 3'd0;
reg rG = 1'b1, rB = 1'b1, rR = 1'b1;
reg [7:0]PWM_CNT = 8'd0;

wire RES = !butB;

assign ledr = rR; 
assign ledg = rG;
assign ledb = rB;

always@(posedge clock or posedge RES) begin
  if(RES) 
    cnt <= 0;
  else
    cnt <= cnt + 1'b1;
end

wire clk_pwm = cnt[2]; // clk/8 = 24/8 = 3MHz

wire [7:0]rxbyte;
wire rdy;

reg [6:0]CH_green = 7'h3E, CH_red = 7'h1E, CH_blue = 7'h7E;
reg [1:0]mxColor = 2'd0; // 'g'reen, 'r'ed, 'b'lue
reg sel = 1'b1;

wire busytx;
assign G4 = (mxColor == 2'd0)? rG : (mxColor == 2'd1)? rR : rB;

assign G5 = sel;

always@(negedge rdy or posedge RES) begin 
  if(RES) begin
    CH_green <= 7'h3E;
    CH_red   <= 7'h1E;
    CH_blue  <= 7'h7E;
    sel <= 1'b1;
    mxColor <= 2'd0;
  end else begin
    if(rxbyte == 8'h3D) sel <= !sel;
    if(sel == 1'b1) begin 
         if(rxbyte == 8'h67) mxColor <= 2'd0;
         if(rxbyte == 8'h72) mxColor <= 2'd1;
         if(rxbyte == 8'h62) mxColor <= 2'd2;
    end else if (rxbyte != 8'h3D) begin 
         if(mxColor == 2'd0) CH_green <= rxbyte[6:0];
         if(mxColor == 2'd1) CH_red   <= rxbyte[6:0];
         if(mxColor == 2'd2) CH_blue  <= rxbyte[6:0];
    end
  end
end

wire G_compare = (PWM_CNT == {1'b1,CH_green[6:0]})? 1'b1 : 1'b0;
wire R_compare = (PWM_CNT == {1'b1,CH_red[6:0]})? 1'b1 : 1'b0;
wire B_compare = (PWM_CNT == {1'b1,CH_blue[6:0]})? 1'b1 : 1'b0;
wire over_PWM = &PWM_CNT;

//wire clk_PWM = cnt[8]; // 0 - 12, 1 - 6, 2 - 3, 3 - 1,5, 4 - 0.75, 5 - 0.375

always@(posedge clk_pwm or posedge RES) begin
  if(RES) begin
    PWM_CNT <= 8'd0;
    {rR, rG, rB} <= 3'b111;
  end else begin
    PWM_CNT <= PWM_CNT + 1'b1;
    if((R_compare)|(over_PWM)) rR <= (R_compare)? 1'b0 : 1'b1;
    if((G_compare)|(over_PWM)) rG <= (G_compare)? 1'b0 : 1'b1;
    if((B_compare)|(over_PWM)) rB <= (B_compare)? 1'b0 : 1'b1;
  end
end

reg [23:0]cnt_delay = 24'd0;
always@(posedge clock or posedge RES) begin
  if(RES) begin
     cnt_delay <= 24'd0;
  end else begin
     cnt_delay <= (&cnt_delay)? {24{butA}} : cnt_delay + 1'b1;
  end
end

reg send = 1'b0;
always@(posedge clock or posedge RES) begin
  if(RES) 
     send <= 1'b0;
  else begin
     send <= (send)? !busytx : !butA & cnt_delay[23]; 
  end
end

wire [7:0]CH = {sel,((mxColor == 2'd0)? CH_green : (mxColor == 2'd1)? CH_red : CH_blue)};
wire TXM;
assign TX = (&cnt_delay)? RX : TXM;

serial_rx uart_rx(.reset(RES), .clk(clock), .rx(RX), .rxbyte(rxbyte), .ready(rdy));
serial_tx uart_tx(.reset(RES), .clk(clock), .sbyte(CH), .send(send), .tx(TXM), .busy(busytx));
endmodule
