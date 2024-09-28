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
endfunction

reg [19:0]  vid_d1;
reg [3:0]   fvht_d1;
logic       alternate;
int 			y, u, v;

initial begin
	alternate = 1'b0;
	YUVfromRGB(255, 0, 0, y, u, v);
end

always @(posedge clk_i) begin
    if(cen_i) begin
			if (alternate) begin
        //vid_d1  <= (vid_sel_i)? vdat_colour_i : vdat_bars_i;
				vid_d1  <= (vid_sel_i)? vdat_bars_i : YUVtoData(y, u, v, 1'b0);
				alternate = 1'b0;
			end else begin
				vid_d1  <= (vid_sel_i)? vdat_colour_i : YUVtoData(y, u, v, 1'b1);
				alternate = 1'b1;
			end
			
       fvht_d1 <= fvht_i;
    end
end

// OUTPUT
assign fvht_o  = fvht_d1;
assign video_o = vid_d1;

endmodule

