`timescale 1ms/1ms      //  unit of time and precision

module traffic_light_controller (sensor, clk, rst_bar, highway_light, country_light);

    input   sensor,     //  whether there is a car waiting at country road
            rst_bar,    //  an active low reset button
            clk;        //  clock of frequency 50KHz (20us)

    output reg [2:0]    highway_light,      //  represent highway traffic light
                        country_light;      //  represent country traffic light

    parameter   RED = 3'b100, YELLOW = 3'b010, GREEN = 3'b001;    //  parameters for traffic light

    parameter   HG_CR = 2'b00,  //  state when highway light is green, and country light is red
                HY_CR = 2'b01,  //  state when highway light is yellow, and country light is red
                HR_CG = 2'b10,  //  state when highway light is red, and country light is green
                HR_CY = 2'b11;  //  state when highway light is red, and country light is yellow

    reg [1:0]   PS, NS; //  depicts present state, and next state

    //  for a state in which one of the traffic light is yellow, we need to hold that for 5s
    //  when we are in HG_CR, we need that state for atleast 2 min, when we have reached that
    //  we can have HR_CG for atmost 30 sec

    reg [23:0]  num_y, num_hg, num_cg;      //  will count number of posedges of clock
    reg yellow, high_g, county_g,           //  initiate the following timer
        wait_5s, wait_120s, wait_30s;       //  tell when timer has reached its value

    //  when we get in HG_CR state, highest priority we need that state for atleast 2 min (120 sec)
    

    always @(posedge clk or negedge rst_bar) begin  //  we are using active low reset 
        
        if (!rst_bar) begin
            PS <= HG_CR;    //  default state, or state with most priority
            yellow  <= 1'b0;    high_g    <= 1'b0;  county_g <= 1'b0;
            wait_5s <= 1'b0;    wait_120s <= 1'b0;  wait_30s <= 1'b0;
            highway_light <= GREEN;   country_light <= RED;
        end
        else PS <= NS;
    end 

    always @(posedge clk) begin   
        
        case (PS)

            HG_CR:   begin
                highway_light = GREEN;  //  sets highway light to green
                country_light = RED;    //  sets country light to red
                high_g    = 1'b1;       //  highway light is green
                yellow    = 1'b0;       //  neither yellow light is onn
                wait_5s   = 1'b0;
                county_g  = 1'b0;       //  country light is not green
                wait_30s  = 1'b0;
                if (sensor && wait_120s) begin
                    NS = HY_CR;         //  if sensor signals there are cars at country road, moved to next state
                end
                else NS = HG_CR;        //  else remains at same state 
            end 

            HY_CR:  begin
                highway_light = YELLOW; //  sets highway light to yellow
                country_light = RED;    //  sets country light to red
                high_g    = 1'b0;       //  highway light is not green
                wait_120s = 1'b0;
                yellow    = 1'b1;       //  highway yellow light is onn
                county_g  = 1'b0;       //  country light is not green
                wait_30s  = 1'b0;
                if (wait_5s) begin
                    NS = HR_CG;         //  if 5 seconds has passed will move to next state
                end
                else NS = HY_CR;        //  else, stays there
            end

            HR_CG:   begin
                highway_light = RED;    //  sets highway light to red
                country_light = GREEN;  //  sets country light to green
                high_g    = 1'b0;       //  highway light is not green
                wait_120s = 1'b0;
                yellow    = 1'b0;
                wait_5s   = 1'b0;       //  nether yellow light is onn
                county_g  = 1'b1;       //  country light is green
                if (wait_30s || (~sensor)) begin
                    NS = HR_CY;         //  country light will be onn only for the time when cars need to pass
                end
                else NS = HR_CG;        //  if sensor signas no cars, will move to next state
            end 

            HR_CY:  begin
                highway_light = RED;    //  sets highway light to red
                country_light = YELLOW; //  sets country light to yellow
                high_g    = 1'b0;       //  highway light is not green
                wait_120s = 1'b0;
                yellow    = 1'b1;       //  country yellow light is onn
                county_g  = 1'b0;       //  country light is not green
                wait_30s  = 1'b0;
                if (wait_5s) begin
                    NS = HG_CR;         //  if 5 seconds has passed will move to next state
                end
                else NS = HR_CY;        //  else, stays there
            end

            default: NS = HG_CR;        //  most priority state 
        endcase
    end

    always @(posedge clk ) begin
        if (yellow) begin               //  if yellow light is onn
            num_y <= num_y + 1;         //  will begin to count num of posedges
        end
        else if (high_g) begin          //  if green light of highway is onn
            num_hg <= num_hg + 1;       //  will begin to count num of posedges
        end
        else if (county_g) begin        //  if green light of county_road is onn
            num_cg <= num_cg + 1;       //  will begin to count num of posedges
        end
        else begin
            num_y <= 0;                 //  if either of the yellow light or
            num_hg <= 0;                //  highway green light or
            num_cg <= 0;                //  county_road green light is off
            wait_5s <= 1'b0;            //  wait5s, wait_120s and wait_30s, and and num counters are set to zero
            wait_120s <= 1'b0;          //  they are required only when corresponding light is onn
            wait_30s <= 1'b0;           //  just to be used as a timer
        end
    end
    
    always @(posedge clk ) begin
        if (num_y >= 250) begin         //  when num of posedges = 5 x 50Hz, i.e. 5 seconds has passed
            num_y <= 0;                 //  num_y is set to 0
            wait_5s <= 1'b1;            //  and wait5s is set to 1, so that yellow light could be turned off
        end
        else if (num_hg >= 6e3) begin   //  when num of posedges = 120 x 50 Hz = 6e3, i.e. 120 seconds has passed
            num_hg <= 0;                //  num_hg is set to 0
            wait_120s = 1'b1;           //  and wait_120s is set to 1, so that highway green light could be turned off
        end
        else if (num_cg >= 15e2) begin  //  when num of posedges = 30 x 50 Hz = 15e2, i.e. 30 seconds has passed 
            num_cg <= 0;                //  num_cg is set to 0
            wait_30s = 1'b1;            //  and wait_30s is set to 1, so that county_road green light could be turned off
        end
    end

endmodule