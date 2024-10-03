`timescale 1ms/1ms              //  timescale to be set, as we are using 50Hz clock frequency (20ms)
`include "traffic_light_controller.v"
//  including file containing design to te be tested


module tb_traffic_light_controller;
    
    reg clk, rst_bar, sensor;//  inputs are given reg datatype
    wire [2:0] highway_light, country_light;        //  outputs are given wire datatype

//  initialising the module
    traffic_light_controller DUT (
        .sensor(sensor),
        .clk(clk),
        .rst_bar(rst_bar),
        .highway_light(highway_light),
        .country_light(country_light)
    );

    localparam CLK_PERIOD = 20;         //  clock with timeperiod 20ms
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        $dumpfile("tb_traffic_light_controller.vcd");
        $dumpvars(0, tb_traffic_light_controller);
        $monitor($time, " sensor = %b, rst_bar = %b, highway_light = %b, country_light = %b", sensor, rst_bar, highway_light, country_light);
    end

    initial begin   //  initialising the reg type variables at t = 0
        rst_bar = 0;
        sensor = 0;
        clk = 0;
    end

    initial begin                               //  handles rst_bar for simulation
        #1e3;                                   //  t = 1  sec
        rst_bar = 1;                            
        #479e3;                                 //  t = 480 sec
        rst_bar = 0;
        #1e3;                                   //  t = 481 sec
        rst_bar = 1;
    end

    initial begin                               //  handles sensor for simulation
        #70e3;                                  //  t = 70  sec
        sensor = 1;
        #236e3;                                 //  t = 306 sec
        sensor = 0;
        #155e3;                                 //  t = 461 sec
        sensor = 1;
        #149e3;                                 //  t = 610 sec   (In this case the sensor value will be 1 from 298 to 300 sec when HGCR and therefore at 418 sec HGCR --> HYCR)
        sensor = 0;
    end

    initial begin
        #650e3;                         //  finish the simulation / exit
        $finish;                        //  finishes at t = 650 sec
    end
    
endmodule
