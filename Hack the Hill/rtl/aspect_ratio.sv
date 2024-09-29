module aspect_ratio(
    input  logic [10:0] pixel_x,        // X coordinate (11 bits for 0 to 1919)
    input  logic [10:0] pixel_y,        // Y coordinate (11 bits for 0 to 1079)
    input  logic [6:0] granularity,     // Granularity input [1, 120]
    output logic        rect_on         // Output signal, high when inside the rectangle
);
    // Parameters for the starting position of the rectangle
    parameter rect_x_start = 100;      // X-coordinate of the top-left corner
    parameter rect_y_start = 50;       // Y-coordinate of the top-left corner

    // Dynamically compute the rectangle width and height based on granularity
    logic [10:0] rect_width;
    logic [10:0] rect_height;

    // Calculate width and height based on the granularity
    always_comb begin
        rect_width  = 16 * granularity; // Width scaled by granularity (16 pixels per unit)
        rect_height = 9 * granularity;  // Height scaled by granularity (9 pixels per unit)
    end

    // Check if the current pixel is inside the dynamically sized rectangle
    always_comb begin
        if ((pixel_x >= rect_x_start && pixel_x < (rect_x_start+ rect_width)) &&
            (pixel_y >=rect_y_start&& pixel_y < (rect_y_start + rect_height))) begin
            rect_on = 1;  // Pixel is inside the rectangle
        end else begin
            rect_on = 0;  // Pixel is outside the rectangle
        end
    end
endmodule