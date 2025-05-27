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
  localparam TIME_TFALL  = int'(300/CLK_PER);
  localparam TIME_TRISE  = int'(300/CLK_PER);
  localparam TIME_THDSTA = int'(600/CLK_PER);
  localparam TIME_TSUSTA = int'(600/CLK_PER);
  localparam TIME_THIGH  = int'(600/CLK_PER);
  localparam TIME_TLOW   = int'(1300/CLK_PER);
  localparam TIME_TSUDAT = int'(120/CLK_PER);
  localparam TIME_THDDAT = int'(30/CLK_PER);
  localparam TIME_TSUSTO = int'(600/CLK_PER);
  
  localparam I2C_ADDR = 7'b1000000; // 0x40
  localparam I2CBITS = 1 + // start
                       7 + // 7 bits for address
                       1 + // 1 bit for read
                       1 + // 1 bit for ack back
                       8 + // 8 bits upper data
                       1 + // 1 bit for ack
                       8 + // 8 bits lower data
                       1 + // 1 bit for ack
                       1;  // 1 bit for stop

  logic               sda_en;
  logic               scl_en;
  logic               convert;
  logic [15:0]        i2c_data;

  assign SCL = scl_en ? 'z : '0;
  assign SDA = sda_en ? 'z : '0;

  typedef enum bit [2:0]
               {
                IDLE,
                START,
                TLOW,
                TSU,
                THIGH,
                THD,
                TSTO
                } i2c_t;

  i2c_s I2C_State;


  always @(posedge clk) begin
    scl_en                     <= '1;
    if (counter_reset) counter <= '0;
    else counter <= counter + 1'b1;
    counter_reset <= '0;
    convert       <= '0;

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
          I2C_State     <= THIGH;
        end
      end
      THIGH: begin
        scl_en          <= '1; // Raise the clock
        if (counter == TIME_TRISE + TIME_THIGH) begin
          if (capture_en) i2c_data <= i2c_data << 1 | SDA;
          counter_reset <= '1;
          I2C_State     <= THD;
        end
      end
      THD: begin
        if (bit_count == I2CBITS-1) begin
          scl_en      <= '1; // Keep the clock high
        end else begin
          scl_en      <= '0; // Drop the clock
        end
        if (counter == TIME_THDDAT) begin
          counter_reset <= '1;
          I2C_State     <= (bit_count == I2CBITS-1) ? TSTO : TLOW;
        end
      end
      TSTO: begin
        if (counter == TIME_TSUSTO) begin
          convert       <= '1;
          counter_reset <= '1;
          I2C_State     <= IDLE;
        end
      end
    endcase
  end


endmodule
