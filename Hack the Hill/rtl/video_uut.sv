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

typedef struct packed {
	logic [9:0]  	Y;     // 10 bits for Y component
	logic [4:0]  	Cb;     // 5 bits for U component
	logic [4:0]  	Cr;     // 5 bits for V component
	bit          alive; // 1 for alive, 0 for dead
	bit				nextAlive; //is the pixel alive the next generation?
} pixel_t;

//(GLOBAL VARS)
pixel_t pixels_arr[53:0][95:0];
int neighbors = 0; //count of live neighbours for a single cell
int aspect_ratio_x = 16;
int aspect_ratio_y = 9;
int x_dim = 1920;
int y_dim = 1080;

function void YCbCrfromRGB(input int R, input int G, input int B, output int Y, output int Cb, output int Cr);
    Y =  0.299 * R + 0.587 * G + 0.114 * B;
    Cb = -0.169 * R - 0.331 * G + 0.500 * B + 128;
    Cr =  0.500 * R - 0.419 * G - 0.081 * B + 128;
endfunction

function logic [19:0] YCbCrtoData(input int Y_i, input int Cb_i, input int Cr_i, input bit display_U);
    logic [9:0] Y;
    logic [9:0] Cb, Cr;

    Y = (Y_i);
    Cb = (Cb_i);
    Cr = (Cr_i);

	if (display_U) begin
		return {Y[9], Cb[9], Y[8], Cb[8], Y[7], Cb[7], Y[6], Cb[6], Y[5], Cb[5], 
            Y[4], Cb[4], Y[3], Cb[3], Y[2], Cb[2], Y[1], Cb[1], Y[0], Cb[0]};
	end else begin
		return {Y[9], Cr[9], Y[8], Cr[8], Y[7], Cr[7], Y[6], Cr[6], Y[5], Cr[5], 
            Y[4], Cr[4], Y[3], Cr[3], Y[2], Cr[2], Y[1], Cr[1], Y[0], Cr[0]};
end
endfunction

function bit in_bounds(
    input  int X,          // Horizontal pixel coordinate
    input  int Y,          // Vertical pixel coordinate
    input  int granularity,// Granularity input
	 input  logic[31:0] hCount,
	 input logic[31:0] vCount
);

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

function int toGranularXCoord(
	 input  logic[31:0] hCount,
    input  int granularity// Granularity input
);
   int rect_width = x_dim / (aspect_ratio_x * granularity);
	return hCount / rect_width;
endfunction

function int toGranularYCoord(
	 input logic[31:0] vCount,
    input  int granularity // Granularity input
);
   int rect_height = y_dim / (aspect_ratio_y * granularity);
	return (vCount-46) / rect_height;
endfunction


//---------- ACTUAL LOGIC START ---------------------------------------
reg [19:0]  vid_d1;
reg [3:0]   fvht_d1;
logic       alternate;
int 			y, cb, cr;
int			y1, cb1, cr1;
int			y2, cb2, cr2;
int			y3, cb3, cr3;
logic[31:0]			hCount, vCount;
reg 			h_prev, v_prev;
int granularX, granularY;
int frameCounter = 0;

//logic[10:0] yBorder;
int granularity = 6;

initial begin
	alternate = 1'b0;
   YCbCrfromRGB(255, 0, 0, y, cb, cr);
   //YCbCrfromRGB(0, 255, 0, y1, cb1, cr1);
	y1 = 450;
	cb1 = 289;
	cr1 = 231;
   YCbCrfromRGB(0, 0, 255, y2, cb2, cr2);
	hCount <= 0;
	vCount <= 0;
	h_prev <= fvht_i[1];
	v_prev <= fvht_i[2];
	//yBorder <= 0;
	
	//seed the board
	pixels_arr = '{default: '{default: '{10'b0, 5'b0, 5'b0, 1'b0, 1'b0}}}; //default dead
	
	//set some alive pixels
	pixels_arr[0][0] = '{10'b1, 5'b1, 5'b1, 1'b1, 1'b0};
	pixels_arr[1][1] = '{10'b1, 5'b1, 5'b1, 1'b1, 1'b0};
	pixels_arr[2][2] = '{10'b1, 5'b1, 5'b1, 1'b1, 1'b0};
	pixels_arr[3][3] = '{10'b1, 5'b1, 5'b1, 1'b1, 1'b0};
	pixels_arr[4][4] = '{10'b1, 5'b1, 5'b1, 1'b1, 1'b0};
	pixels_arr[5][5] = '{10'b1, 5'b1, 5'b1, 1'b1, 1'b0};
	pixels_arr[6][6] = '{10'b1, 5'b1, 5'b1, 1'b1, 1'b0};
	pixels_arr[30][50] = '{10'b1, 5'b1, 5'b1, 1'b1, 1'b0};
	pixels_arr[53][95] = '{10'b1, 5'b1, 5'b1, 1'b1, 1'b0};
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
		  
		  granularity <= vid_sel_i ? 1 : 6;
    
        //draw within bounds 
		  if (hCount <= 1919 && vCount >= 45) begin
				granularX <= toGranularXCoord(hCount, granularity);
				granularY <= toGranularYCoord(vCount, granularity);
				if (granularX >= 0 && granularX < granularity * aspect_ratio_x && granularY >= 0 && granularY < granularity * aspect_ratio_y) begin
						if (pixels_arr[granularY][granularX].alive) begin
							vid_d1 <= YCbCrtoData(y, cb, cr, alternate);
						end else begin
							vid_d1 <= YCbCrtoData(y1, cb1, cr1, alternate);
						end
						
						//update game of life logic
						if (frameCounter == 198) begin //change pixel state
							pixels_arr[granularY][granularX].alive <= pixels_arr[granularY][granularX].nextAlive;
						end else if (frameCounter == 199) begin //get pixel next state
						
						  // Calculate neighbors
                    neighbors = 0; // Reset neighbors count for the current cell

						  /////// j -> granularY
                    // Calculate neighbors with boundary checks
                    if (granularY > 1) neighbors = neighbors + pixels_arr[granularY-1][granularX].alive ? 1 : 0; // top
                    if (granularY < 7*granularity) neighbors = neighbors + pixels_arr[granularY+1][granularX].alive ? 1 : 0; // bottom
                    if (granularX > 1) neighbors = neighbors + pixels_arr[granularY][granularX-1].alive ? 1 : 0; // left
                    if (granularX < 14*granularity) neighbors = neighbors + pixels_arr[granularY][granularX+1].alive ? 1 : 0; // right
                    if (granularY > 1 && granularX > 1) neighbors = neighbors + pixels_arr[granularY-1][granularX-1].alive ? 1 : 0; // top-left
                    if (granularY > 1 && granularX < 14*granularity) neighbors = neighbors + pixels_arr[granularY-1][granularX+1].alive ? 1 : 0; // top-right
                    if (granularY < 7 && granularX > 1) neighbors = neighbors + pixels_arr[granularY+1][granularX-1].alive ? 1 : 0; // bottom-left
                    if (granularY < 7 && granularX < 14*granularity) neighbors = neighbors + pixels_arr[granularY+1][granularX+1].alive ? 1 : 0; // bottom-right

                    // Update output based on neighbors
                    if (pixels_arr[granularY][granularX]) begin
                        case (neighbors)
                            4'b0000: pixels_arr[granularY][granularX].nextAlive <= 0;
                            4'b0001: pixels_arr[granularY][granularX].nextAlive <= 0;
                            4'b0010: pixels_arr[granularY][granularX].nextAlive <= pixels_arr[granularY][granularX].alive;
                            4'b0011: pixels_arr[granularY][granularX].nextAlive <= pixels_arr[granularY][granularX].alive;
                            default: pixels_arr[granularY][granularX].nextAlive <= 0;
                        endcase
                    end else if (neighbors == 3) begin
                        pixels_arr[granularY][granularX].nextAlive <= 1; // Cell becomes alive
                    end else begin
                        pixels_arr[granularY][granularX].nextAlive <= 0; // Default to dead
                    end
						  
						end
				end
		  end
		  
		  //put pre-frame actions here
		  if (fvht_i[1] == 1'b1 && h_prev == 1'b0 && fvht_i[2] == 1'b0 && v_prev == 1'b1) begin //new frame	  
				frameCounter = frameCounter + 1;
				if (frameCounter == 200) begin
						frameCounter = 0;
				end
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

