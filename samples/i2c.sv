module i2c_temp 
  #
  (
   parameter  INTERVAL     = 1000000000,
   parameter  CLK_PER      = 22
  )
  (
   input wire                      clk, 

   // Temperature Sensor Interface
   inout wire                      SCL,
   inout wire                      SDA
   );

  localparam TIME_1SEC   = int'(INTERVAL/CLK_PER); // Clock ticks in 1 sec
  localparam TIME_TFALL  = int'(100/CLK_PER);
  localparam TIME_TRISE  = int'(300/CLK_PER);
  localparam TIME_THDSTA = int'(600/CLK_PER);
  localparam TIME_TSUSTA = int'(600/CLK_PER);
  localparam TIME_THIGH  = int'(600/CLK_PER);
  localparam TIME_TLOW   = int'(1300/CLK_PER);
  localparam TIME_TSUDAT = int'(400/CLK_PER);
  //localparam TIME_THDDAT = int'(30/CLK_PER);
  localparam TIME_TSUSTO = int'(600/CLK_PER);
  
  localparam I2C_ADDR = 7'b1000000; // 0x40
  localparam I2CBITS  = 47; // Hold Master communication sequence without CRC

  logic               sda_en;
  logic               scl_en;
  logic               measure_done;
  logic [15:0]        i2c_data;
  logic               scl_release;
  logic               r_start;

  assign SCL = scl_en ? 'z : '0;
  assign SDA = sda_en ? 'z : '0;

  typedef enum bit [3:0]
               {
                IDLE,
                START,
                TLOW,
                TDATSU
                THIGH,
                TDATHD
                WAIT,
                RSTART,
                STOP
                } i2c_t;

  i2c_s I2C_State;


  always @(posedge clk) begin
    scl_en                     <= '1;
    if (counter_reset) counter <= '0;
    else counter  <= counter + 1'b1;
    counter_reset <= '0;
    measure_done  <= '0;
    scl_release   <= (SCL) ? '1 : '0;

    case (I2C_State)
      IDLE: begin
        sda_en    <= '1; // Force to 1 in the beginning.
        if (counter == TIME_1SEC) begin
          i2c_data      <= '0;
          I2C_State     <= START;
          counter_reset <= '1;
          sda_en        <= '0; // Drop the data
        end
      end
      START: begin
        sda_en <= '0; // Drop the data
        // Hold clock low for thd:sta
        if (counter == TIME_THDSTA) begin
          counter_reset   <= '1;
          scl_en          <= '0; // Drop the clock
          I2C_State       <= TLOW;
        end
      end
      TLOW: begin
        scl_en          <= '0; // Drop the clock
        if (counter == TIME_TFALL + TIME_TLOW - TIME_TSUDAT) begin
          bit_count     <= bit_count + 1'b1;
          counter_reset <= '1;
          I2C_State     <= TSUDATA;
        end
      end
      TSUDATA: begin
        scl_en          <= '0; // Drop the clock
        if (counter == TIME_TSUDAT) begin
          counter_reset <= '1;
          if (bit_count == 19) begin
            r_start     <= '1;
            I2C_State   <= THIGH;  
          end else if (bit_count == 30)
            I2C_State   <= WAIT;
          else if (bit_count == 48)
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
          if (r_start)
            I2C_State   <= START;
            r_start     <= '0;
            bit_count   <= bit_count + 1'b1;
        end
      end
      WAIT: begin
        I2C_State <= (scl_release) ? TLOW : WAIT 
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


endmodule
