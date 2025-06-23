`timescale 1ns / 10ps
//////////////////////////////////////////////////////////////////////////////////


module i2c_master 
  #
  (
   parameter  INTERVAL     = 1_000_000_000,
   parameter  CLK_PER      = 22
  )
  (
   input wire                      clk, 

   // I2C Interface
   inout wire                      SCL,
   inout wire                      SDA,
   output logic                    measure_done,
   output logic [15:0]             i2c_data
   );

  localparam TIME_1SEC   = int'(INTERVAL/CLK_PER); // Clock ticks in 1 sec
  localparam TIME_TFALL  = int'(100/CLK_PER);
  localparam TIME_TRISE  = int'(300/CLK_PER);
  localparam TIME_THDSTA = int'(600/CLK_PER);
//  localparam TIME_TSUSTA = int'(600/CLK_PER);
  localparam TIME_THIGH  = int'(600/CLK_PER);
  localparam TIME_TLOW   = int'(1300/CLK_PER);
  localparam TIME_TSUDAT = int'(400/CLK_PER);
//  localparam TIME_THDDAT = int'(30/CLK_PER);
  localparam TIME_TSUSTO = int'(600/CLK_PER);
  
  localparam I2C_ADDR = 7'b1000000; // 0x40
  localparam I2C_COMM_TEMP = 8'hE3;    // Temperature  
  localparam I2C_COMM_HUMI = 8'hE5;    // Humidity
  localparam I2CBITS  = 49; // Hold Master communication sequence without CRC

  logic               sda_en;
  logic               scl_en;
  logic               scl_release;
  logic               r_start;
  logic               temp_hum;
  logic [7:0]         reg_send;
  logic               send_en;
  logic               capture_en;
  logic [3:0]         bit_index;
  logic               counter_reset;
  logic [$clog2(TIME_1SEC)-1:0]  counter;
  logic [$clog2(I2CBITS)-1:0]    bit_count;
  //logic [$clog2(I2CBITS)-1:0]  bit_index;

  typedef enum bit [3:0]
               {
                IDLE,
                START,
                TLOW,
                TDATSU,
                THIGH,
                TWAIT,
                STOP
                } i2c_s;

  i2c_s I2C_State;

  initial begin
    measure_done = '0;
    r_start    = '0;
    bit_count  = '0;
    bit_index  = '0;
    send_en    = '0;
    capture_en = '0;
    sda_en     = '1;
    scl_en     = '1;
    temp_hum   = '0;
    I2C_State  = IDLE;
    counter    = '0;
    counter_reset = '0;
  end

  assign SCL = scl_en ? 'z : '0;
  assign SDA = sda_en ? 'z : '0;

  //assign bit_index = bit_count == I2CBITS ? '0 : I2CBITS - bit_count - 1;
  //assign capture_en = i2c_capt[bit_index];

  always @(posedge clk) begin
    scl_en                     <= '1;

    if (counter_reset) counter <= '0;
    else counter  <= counter + 1'b1;

    counter_reset <= '0;
    measure_done  <= '0;

    scl_release   <= (SCL) ? '1 : '0;

    case (I2C_State)
      IDLE: begin
        //sda_en    <= '1; // Force to 1 in the beginning.
        bit_count <= '0;
        //i2c_data  <= {1'b0, I2C_ADDR, 1'b1, 1'b0, 8'b00, 1'b0, 8'b00, 1'b1, 1'b0};
        //i2c_en    <= {1'b1, 7'h7F,    1'b1, 1'b0, 8'b00, 1'b1, 8'b00, 1'b1, 1'b1};
        //i2c_capt  <= {1'b0, 7'h00,    1'b0, 1'b0, 8'hFF, 1'b0, 8'hFF, 1'b0, 1'b0};

        if (counter == TIME_1SEC) begin
          temp_hum      <= ~temp_hum;
          i2c_data      <= '0;
          counter_reset <= '1;
          //sda_en        <= '0;    // Drop the data
          I2C_State     <= START;
        end
      end
      START:
        //sda_en <= '0; // Drop the data
        // Hold clock low for thd:sta
        if (counter == TIME_THDSTA) begin
          counter_reset   <= '1;
          scl_en          <= '0; // Drop the clock
          I2C_State       <= TLOW;
        end
      TLOW: begin
        scl_en          <= '0; // Drop the clock
        if (counter == TIME_TFALL + TIME_TLOW - TIME_TSUDAT) begin
          bit_count     <= bit_count + 1'b1;
          counter_reset <= '1;
          I2C_State     <= TDATSU;
          if (send_en | capture_en)  bit_index  <= bit_index + 1;
          if (bit_index == 8)        bit_index  <= '0;
        end
      end
      TDATSU: begin
        scl_en          <= '0;                          // Drop the clock
        if (bit_count == 29)   I2C_State   <= TWAIT;    // go to wait for measurement
        if (counter == TIME_TSUDAT) begin
          counter_reset <= '1;
          if (bit_count == 19) begin                    // start repeat
            r_start     <= '1;
            I2C_State   <= THIGH;   
          end else if (bit_count == 48)                 // stop
            I2C_State   <= STOP;
          else 
            I2C_State   <= THIGH;       
        end
      end
      THIGH: begin
        scl_en          <= '1; // Raise the clock
        if (counter == TIME_TRISE + TIME_THIGH) begin
          if (capture_en) i2c_data <= i2c_data << 1 | SDA;
          counter_reset <= '1;
          I2C_State     <= TLOW;
          if (r_start) begin
            I2C_State   <= START;
            r_start     <= '0;
          end     
        end
      end
      TWAIT: begin
        I2C_State <= (scl_release) ? TLOW : TWAIT; 
        counter_reset <= '1; 
      end             
      STOP: begin
        if (counter == TIME_TSUSTO) begin
          measure_done  <= '1;
          counter_reset <= '1;
          I2C_State     <= IDLE;
        end
      end
    endcase
  end

 
  always @(posedge clk) begin
    if (I2C_State == IDLE)
      sda_en  <= '1;
    else if (send_en &&  bit_index < 8)
      sda_en     <= reg_send[7-bit_index];
    else if (I2C_State == START)
      sda_en  <= '0;
    else if (bit_count == 1) begin                         // master send i2c address + write bit
      send_en    <= '1;
      reg_send   <= {I2C_ADDR, 1'b0};
    end else if (bit_count == 10) begin                    // master send i2c command
      send_en    <= '1;
      reg_send   <= temp_hum ? I2C_COMM_HUMI : I2C_COMM_TEMP;
    end else if (bit_count == 20) begin                    // master send i2c address + read bit
      send_en    <= '1;
      reg_send   <= {I2C_ADDR, 1'b1};
    end else if (bit_count == 30 || bit_count == 39) begin      // reacive data from slave
      capture_en <= '1;
      sda_en     <= '1;
    end else if (bit_count == 48 || bit_count == 38 || bit_count == 0)           // 38 master ACK, 0 after start before TDATSTU, and STOP
      sda_en     <= '0;
    else
      sda_en     <= '1;
      
    if (bit_index == 8) begin
      send_en    <= '0;
      capture_en <= '0;
    end     
  end

endmodule
