`default_nettype none
`timescale 1ns/1ps

module frequency_counter #(
    localparam UPDATE_PERIOD = 1200,
    localparam BITS = 12
)(
    input wire clk,
    input wire reset,
    input wire signal,
    input wire [BITS-1:0] period,
    input wire period_load,
    output wire [6:0] segments,
    output wire digit
);

// states
localparam STATE_COUNT = 0;
localparam STATE_TENS = 1;
localparam STATE_UNITS = 2;

reg [1:0] state;
reg [6:0] edge_counter; // need to count up to 99
reg [BITS-1:0] clock_counter;


reg [BITS-1:0] update_period;



reg [3:0] ten_count;
reg [3:0] unit_count;
wire leading_edge_detect;

edge_detect edge_detect0(.clk(clk), .signal(signal), .leading_edge_detect(leading_edge_detect));

reg load_digit;
seven_segment seven_segment0(.clk(clk), .reset(reset), .load(load_digit), .ten_count(ten_count), .unit_count(unit_count), .segments(segments), .digit(digit));



always @(posedge clk) begin
    if (reset)
        update_period <= UPDATE_PERIOD;
    else if(period_load) 
        update_period <= period;
end



always @(posedge clk) begin
    if (reset) begin
        state <= STATE_COUNT;
        edge_counter <= 0;
        clock_counter <= 0;
        ten_count <= 0;
        unit_count <= 0;
        load_digit <= 0;
    end else begin
        case (state)
            STATE_COUNT: begin

                load_digit <= 1'b0;
                ten_count <= 0;
                unit_count <= 0;


                // count edges and clock cycles
                if (leading_edge_detect)
                    edge_counter <= edge_counter + 1'b1;
                clock_counter <= clock_counter + 1'b1;

                // if clock cycles >= UPDATE_PERIOD then go to next state
                if (clock_counter == update_period -1) begin
                    state <= STATE_TENS;
                end
            end

            STATE_TENS: begin
                // count number of tens by subtracting 10 while edge counter >= 10
                if (edge_counter >= 10) begin
                    edge_counter <= edge_counter - 7'd10;
                    ten_count <= ten_count + 1'b1;
                end else begin
                    state <= STATE_UNITS;
                end
            end

            STATE_UNITS: begin
                // what is left in edge counter is units
                unit_count <= edge_counter;
                edge_counter <= 0;  // Reset edge_counter for the next counting period
                clock_counter <= 0;
                // update the display
                load_digit <= 1;

                // go back to counting
                state <= STATE_COUNT;
            end

            default: state <= STATE_COUNT;
        endcase
    end
end

endmodule
