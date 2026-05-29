module YUV422_to_444(
    // YUV 4:2:2 Input
    input  wire [15:0] iYCbCr,
    input  wire        i_valid,
    
    // YUV 4:4:4 Output
    output wire [7:0]  oY,
    output wire [7:0]  oCb,
    output wire [7:0]  oCr,
    
    // Control Signals
    input  wire [9:0]  iX,
    input  wire        iCLK,
    input  wire        iRST_N
);

    reg [7:0] mY;
    reg [7:0] mCb;
    reg [7:0] mCr;

    assign oY  = mY;
    assign oCb = mCb;
    assign oCr = mCr;

    always @(posedge iCLK or negedge iRST_N) begin
        if (!iRST_N) begin
            mY  <= 8'd0;
            mCb <= 8'd128; // 128 là giá trị trung tính (Không màu)
            mCr <= 8'd128; // Giúp màn hình không bị ám xanh khi chưa có camera
        end 
        else if (i_valid) begin // <--- Chỉ cập nhật dữ liệu khi luồng pipeline hợp lệ
            if (iX[0])
                {mCb, mY} <= iYCbCr; // Tự động chốt giữ mCr cũ
            else
                {mCr, mY} <= iYCbCr; // Tự động chốt giữ mCb cũ
        end
    end

endmodule