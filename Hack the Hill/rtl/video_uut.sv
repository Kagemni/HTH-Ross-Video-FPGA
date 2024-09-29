/****************************************************************************
FILENAME     :  video_uut.sv
PROJECT      :  Hack the Hill 2024
****************************************************************************/

/*  INSTANTIATION TEMPLATE  -------------------------------------------------

video_uut video_uut (       
    .clk_i          ( ),//               
    .cen_i          ( ),//
    .vid_sel_i      ( ),//
    .vdat_bars_i    ( ),//[19:0]
    .vdat_colour_i  ( ),//[19:0]
    .fvht_i         ( ),//[ 3:0]
    .fvht_o         ( ),//[ 3:0]
    .video_o        ( ) //[19:0]
);

-------------------------------------------------------------------------- */


module video_uut (
    input  wire         clk_i           ,// clock
    input  wire         cen_i           ,// clock enable
    input  wire         vid_sel_i       ,// select source video
    input  wire [19:0]  vdat_bars_i     ,// input video {luma, chroma}
    input  wire [19:0]  vdat_colour_i   ,// input video {luma, chroma}
    input  wire [3:0]   fvht_i          ,// input video timing signals (bits 1 and 2 are what we should focus on)
    output wire [3:0]   fvht_o          ,// 1 clk pulse after falling edge on input signal
    output wire [19:0]  video_o          // 1 clk pulse after any edge on input signal
); 

function void YUVfromRGB(input int R, input int G, input int B, output int Y, output int U, output int V);
    Y =  0.3 * R + 0.59 * G + 0.11 * B;
    U = -0.147 * R - 0.289 * G + 0.436 * B;
    V =  0.615 * R - 0.515 * G - 0.1 * B;
endfunction

function logic [19:0] YUVtoData(input int Y_i, input int U_i, input int V_i, input bit display_U);
    logic [9:0] Y;
    logic [9:0] U, V;
    
    Y = (Y_i);
    U = (U_i);
    V = (V_i);
	 
	 if (display_U) begin
			return {Y, U};
	 end else begin
			return {Y, V};
	 end
	 //return {Y[9], U[4], Y[8], V[4], Y[7], U[3], Y[6], V[3], Y[5], U[2], Y[4], V[2], Y[3], U[1], Y[2], V[1], Y[1], U[0], Y[0], V[0]};
	 //return {Y, U, V};
endfunction

function bit in_bounds(
    input  int X,          // Horizontal pixel coordinate
    input  int Y,          // Vertical pixel coordinate
    input  int granularity,// Granularity input
	 input  logic[31:0] hCount,
	 input logic[31:0] vCount
);
    // Parameters for aspect ratio
    parameter int aspect_ratio_x = 16;
    parameter int aspect_ratio_y = 9;
	 parameter int x_dim = 1920;
	 parameter int y_dim = 1080;

    // Rectangle dimensions based on granularity
    int rect_width;                 // Width of each rectangle
    int rect_height;                // Height of each rectangle
	 
    int Hstart;
    int Hend;
    int Vstart;
    int Vend;

    // Ensure granularity is at least 1 to avoid division by zero
    if (granularity < 1) begin
			granularity = 1;
	 end

    // Calculate rectangle dimensions
    rect_width  = x_dim / (aspect_ratio_x * granularity);
    rect_height = y_dim / (aspect_ratio_y * granularity);

    // Calculate Hstart, Hend, Vstart, and Vend based on input coordinates
    Hstart = X * rect_width;         // Horizontal start of the rectangle
    Hend   = Hstart + rect_width;          // Horizontal end of the rectangle
    Vstart = Y * rect_height;        // Vertical start of the rectangle
    Vend   = Vstart + rect_height;         // Vertical end of the rectangle

    if (hCount >= Hstart && hCount < Hend && vCount-46 >= Vstart && vCount-46 < Vend) begin
			return 1'b1; //in bounds
	 end else begin
			return 1'b0; //not in bounds
	 end

endfunction



//---------- ACTUAL LOGIC START ---------------------------------------
reg [19:0]  vid_d1;
reg [3:0]   fvht_d1;
logic       alternate;
int 			y, u, v;
int			y1, u1, v1;
int			y2, u2, v2;
int			y3, u3, v3;
logic[31:0]			hCount, vCount;
reg 			h_prev, v_prev;

//logic[10:0] yBorder;
int granularity = 2;

initial begin
	alternate = 1'b0;
	YUVfromRGB(255, 0, 0, y, u, v);
	YUVfromRGB(0, 255, 0, y1, u1, v1);
	YUVfromRGB(0, 0, 255, y2, u2, v2);
	YUVfromRGB(0, 0, 0, y3, u3, v3);
	hCount <= 0;
	vCount <= 0;
	h_prev <= fvht_i[1];
	v_prev <= fvht_i[2];
	//yBorder <= 0;
end

always @(posedge clk_i) begin
    if(cen_i) begin
	 
        if (h_prev == 1'b1 && fvht_i[1] == 1'b0) begin //check when newline begins (negative edge)
            hCount <= 0;
            vCount <= vCount + 1;
        end else if (fvht_i[1] == 1'b0) begin //we are in viewable space
            hCount <= hCount + 1;
        end
        
        if (v_prev == 1'b0 && fvht_i[2] == 1'b1) begin //check when we start at top again (rising edge)
            vCount <= 0;
        end
		  
		  granularity <= vid_sel_i ? 3 : 2;
    
        //draw within bounds
        if (hCount <= 1919) begin
				 
				 if (in_bounds(0, 0, granularity, hCount, vCount)) begin
						vid_d1 <= YUVtoData(y, u, v, alternate);
				 end else if (in_bounds(1, 1, granularity, hCount, vCount)) begin
						vid_d1 <= YUVtoData(y2, u2, v2, alternate);
				 end else if (in_bounds(2, 2, granularity, hCount, vCount)) begin
						vid_d1 <= YUVtoData(y, u, v, alternate);
				 end else if (in_bounds(3, 3, granularity, hCount, vCount)) begin
						vid_d1 <= YUVtoData(y2, u2, v2, alternate);
				 end else if (in_bounds(15, 8, granularity, hCount, vCount)) begin
						vid_d1 <= YUVtoData(y, u, v, alternate);
				 end else begin
						vid_d1 <= YUVtoData(y1, u1, v1, alternate);
				 end
            
        end
		  
		  //put pre-frame actions here
		  if (fvht_i[1] == 1'b1 && h_prev == 1'b0 && fvht_i[2] == 1'b0 && v_prev == 1'b1) begin //new frame	  
		  //if (yBorder == 1125) begin
			//yBorder <= 0;
		  //end else begin
		   //yBorder <= yBorder + 3;
		  //end
		  end
	
		  v_prev <= fvht_i[2];
		  h_prev <= fvht_i[1];
        fvht_d1 <= fvht_i;
		  alternate <= (h_prev == 1'b1 && fvht_i[1] == 1'b0) ? 0 : ~alternate;
    end
end

// OUTPUT
assign fvht_o  = fvht_d1;
assign video_o = vid_d1;

endmodule

