library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity jesd204b_tx_tb is
end;

architecture bench of jesd204b_tx_tb is


	signal gt0_txdata             : std_logic_vector(31 downto 0) := (others => '0');
	signal gt0_txcharisk          : std_logic_vector(3 downto 0) := (others => '0');
	signal gt1_txdata             : std_logic_vector(31 downto 0) := (others => '0');
	signal gt1_txcharisk          : std_logic_vector(3 downto 0) := (others => '0');
	signal gt2_txdata             : std_logic_vector(31 downto 0) := (others => '0');
	signal gt2_txcharisk          : std_logic_vector(3 downto 0) := (others => '0');
	signal gt3_txdata             : std_logic_vector(31 downto 0) := (others => '0');
	signal gt3_txcharisk          : std_logic_vector(3 downto 0) := (others => '0');
	signal gt4_txdata             : std_logic_vector(31 downto 0) := (others => '0');
	signal gt4_txcharisk          : std_logic_vector(3 downto 0) := (others => '0');
	signal gt5_txdata             : std_logic_vector(31 downto 0) := (others => '0');
	signal gt5_txcharisk          : std_logic_vector(3 downto 0) := (others => '0');
	signal gt6_txdata             : std_logic_vector(31 downto 0) := (others => '0');
	signal gt6_txcharisk          : std_logic_vector(3 downto 0) := (others => '0');
	signal gt7_txdata             : std_logic_vector(31 downto 0) := (others => '0');
	signal gt7_txcharisk          : std_logic_vector(3 downto 0) := (others => '0');
	signal tx_reset_done          : std_logic := '0';
	signal gt_prbssel_out         : std_logic_vector(2 downto 0) := (others => '0');
	signal tx_reset_gt            : std_logic := '0';
	signal tx_core_clk            : std_logic := '0';
	signal s_axi_aclk             : std_logic := '0';
	signal s_axi_aresetn          : std_logic := '0';
	signal s_axi_awaddr           : std_logic_vector(11 downto 0) := (others => '0');
	signal s_axi_awvalid          : std_logic := '0';
	signal s_axi_awready          : std_logic := '0';
	signal s_axi_wdata            : std_logic_vector(31 downto 0) := (others => '0');
	signal s_axi_wstrb            : std_logic_vector(3 downto 0) := (others => '0');
	signal s_axi_wvalid           : std_logic := '0';
	signal s_axi_wready           : std_logic := '0';
	signal s_axi_bresp            : std_logic_vector(1 downto 0) := (others => '0');
	signal s_axi_bvalid           : std_logic := '0';
	signal s_axi_bready           : std_logic := '1';
	signal s_axi_araddr           : std_logic_vector(11 downto 0) := (others => '0');
	signal s_axi_arvalid          : std_logic := '0';
	signal s_axi_arready          : std_logic := '0';
	signal s_axi_rdata            : std_logic_vector(31 downto 0) := (others => '0');
	signal s_axi_rresp            : std_logic_vector(1 downto 0) := (others => '0');
	signal s_axi_rvalid           : std_logic := '0';
	signal s_axi_rready           : std_logic := '0';
	signal tx_reset               : std_logic := '0';
	signal tx_sysref              : std_logic := '0';
	signal tx_start_of_frame      : std_logic_vector(3 downto 0) := (others => '0');
	signal tx_start_of_multiframe : std_logic_vector(3 downto 0) := (others => '0');
	signal tx_aresetn             : std_logic := '0';

	signal rx_start_of_frame      : std_logic_vector(3 downto 0) := (others => '0');
	signal rx_start_of_multiframe : std_logic_vector(3 downto 0) := (others => '0');
	signal rx_aresetn             : std_logic := '0';
	signal rx_tvalid              : std_logic := '0';

	signal tx_tdata_xilinx, tx_tdata_bbn, rx_tdata_xilinx : std_logic_vector(255 downto 0) := (others => '0');
	signal tx_tready_xilinx, tx_tready_bbn : std_logic := '0';
	signal tx_sync_xilinx, tx_sync_bbn, rx_sync_xilinx    : std_logic := '0';

	signal rst_bbn : std_logic := '1';

	signal gt_tdata, gt_tdata_scrambled : std_logic_vector(255 downto 0);
	type gt_tdata_array_t is array(7 downto 0) of std_logic_vector(31 downto 0);
	signal gt_tdata_array, gt_tdata_scrambled_array : gt_tdata_array_t;
	signal gt_charisk, gt_charisk_scrambled : std_logic_vector(31 downto 0);
	type gt_charisk_array_t is array(7 downto 0) of std_logic_vector(3 downto 0);
	signal gt_charisk_array, gt_charisk_scrambled_array : gt_charisk_array_t;

  constant axi_clock_period : time := 10 ns;
	constant core_clock_period : time := 5.5333 ns;
  signal stop_the_clocks : boolean;

	signal matches_xilinx, matches_xilinx_scrambled : boolean := false;

	type testbench_state_t is (RESETING, WRITE_AXI_CFG, TEST_UNSCRAMBLED, TEST_SCRAMBLED);
	signal testbench_state : testbench_state_t := RESETING;

	procedure push_test_data(signal tready : in std_logic; signal tdata : out std_logic_vector(255 downto 0)) is

	begin
		tdata <= (others => '0');
		wait until rising_edge(tx_core_clk) and tready = '1';
		for ct in 1 to 2055 loop
			wait until rising_edge(tx_core_clk);
		end loop;
		tdata <= x"abcdef01abcdef02abcdef03abcdef04abcdef05abcdef06abcdef07abcdef08";
		for ct in 1 to 2056 loop
			wait until rising_edge(tx_core_clk);
		end loop;
	end procedure push_test_data;

begin

uut_xilinx_tx : entity work.jesd204_xilinx_tx
	port map (
		gt0_txdata             => gt0_txdata,
		gt0_txcharisk          => gt0_txcharisk,
		gt1_txdata             => gt1_txdata,
		gt1_txcharisk          => gt1_txcharisk,
		gt2_txdata             => gt2_txdata,
		gt2_txcharisk          => gt2_txcharisk,
		gt3_txdata             => gt3_txdata,
		gt3_txcharisk          => gt3_txcharisk,
		gt4_txdata             => gt4_txdata,
		gt4_txcharisk          => gt4_txcharisk,
		gt5_txdata             => gt5_txdata,
		gt5_txcharisk          => gt5_txcharisk,
		gt6_txdata             => gt6_txdata,
		gt6_txcharisk          => gt6_txcharisk,
		gt7_txdata             => gt7_txdata,
		gt7_txcharisk          => gt7_txcharisk,
		tx_reset_done          => tx_reset_done,
		gt_prbssel_out         => gt_prbssel_out,
		tx_reset_gt            => tx_reset_gt,
		tx_core_clk            => tx_core_clk,
		s_axi_aclk             => s_axi_aclk,
		s_axi_aresetn          => s_axi_aresetn,
		s_axi_awaddr           => s_axi_awaddr,
		s_axi_awvalid          => s_axi_awvalid,
		s_axi_awready          => s_axi_awready,
		s_axi_wdata            => s_axi_wdata,
		s_axi_wstrb            => s_axi_wstrb,
		s_axi_wvalid           => s_axi_wvalid,
		s_axi_wready           => s_axi_wready,
		s_axi_bresp            => s_axi_bresp,
		s_axi_bvalid           => s_axi_bvalid,
		s_axi_bready           => s_axi_bready,
		s_axi_araddr           => s_axi_araddr,
		s_axi_arvalid          => s_axi_arvalid,
		s_axi_arready          => s_axi_arready,
		s_axi_rdata            => s_axi_rdata,
		s_axi_rresp            => s_axi_rresp,
		s_axi_rvalid           => s_axi_rvalid,
		s_axi_rready           => s_axi_rready,
		tx_reset               => tx_reset,
		tx_sysref              => tx_sysref,
		tx_start_of_frame      => tx_start_of_frame,
		tx_start_of_multiframe => tx_start_of_multiframe,
		tx_aresetn             => tx_aresetn,
		tx_tdata               => tx_tdata_xilinx,
		tx_tready              => tx_tready_xilinx,
		tx_sync                => tx_sync_xilinx
	);

uut_xilinx_rx : entity work.jesd204_xilinx_rx
port map (
	gt0_rxdata             => gt_tdata_scrambled_array(0),
	gt0_rxcharisk          => gt_charisk_scrambled_array(0),
	gt0_rxdisperr          => (others => '0'),
	gt0_rxnotintable       => (others => '0'),
	gt1_rxdata             => gt_tdata_scrambled_array(1),
	gt1_rxcharisk          => gt_charisk_scrambled_array(1),
	gt1_rxdisperr          => (others => '0'),
	gt1_rxnotintable       => (others => '0'),
	gt2_rxdata             => gt_tdata_scrambled_array(2),
	gt2_rxcharisk          => gt_charisk_scrambled_array(2),
	gt2_rxdisperr          => (others => '0'),
	gt2_rxnotintable       => (others => '0'),
	gt3_rxdata             => gt_tdata_scrambled_array(3),
	gt3_rxcharisk          => gt_charisk_scrambled_array(3),
	gt3_rxdisperr          => (others => '0'),
	gt3_rxnotintable       => (others => '0'),
	gt4_rxdata             => gt_tdata_scrambled_array(4),
	gt4_rxcharisk          => gt_charisk_scrambled_array(4),
	gt4_rxdisperr          => (others => '0'),
	gt4_rxnotintable       => (others => '0'),
	gt5_rxdata             => gt_tdata_scrambled_array(5),
	gt5_rxcharisk          => gt_charisk_scrambled_array(5),
	gt5_rxdisperr          => (others => '0'),
	gt5_rxnotintable       => (others => '0'),
	gt6_rxdata             => gt_tdata_scrambled_array(6),
	gt6_rxcharisk          => gt_charisk_scrambled_array(6),
	gt6_rxdisperr          => (others => '0'),
	gt6_rxnotintable       => (others => '0'),
	gt7_rxdata             => gt_tdata_scrambled_array(7),
	gt7_rxcharisk          => gt_charisk_scrambled_array(7),
	gt7_rxdisperr          => (others => '0'),
	gt7_rxnotintable       => (others => '0'),
	rx_reset_done          => tx_reset_done,
	rx_reset_gt            => open,
	rx_core_clk            => tx_core_clk,
	s_axi_aclk             => s_axi_aclk,
	s_axi_aresetn          => s_axi_aresetn,
	s_axi_aresetn          => open,
	s_axi_awaddr           => s_axi_awaddr,
	s_axi_awvalid          => s_axi_awvalid,
	s_axi_awready          => open,
	s_axi_wdata            => s_axi_wdata,
	s_axi_wstrb            => s_axi_wstrb,
	s_axi_wvalid           => s_axi_wvalid,
	s_axi_wready           => open,
	s_axi_bresp            => open,
	s_axi_bvalid           => open,
	s_axi_bready           => s_axi_bready,
	s_axi_araddr           => s_axi_araddr,
	s_axi_arvalid          => s_axi_arvalid,
	s_axi_arready          => open,
	s_axi_rdata            => open,
	s_axi_rresp            => open,
	s_axi_rvalid           => open,
	s_axi_rready           => s_axi_rready,
	rx_reset               => tx_reset,
	rx_sysref              => tx_sysref,
	rx_start_of_frame      => rx_start_of_frame,
	rx_start_of_multiframe => rx_start_of_multiframe,
	rx_aresetn             => rx_aresetn,
	rx_tdata               => rx_tdata_xilinx,
	rx_tvalid              => rx_tvalid,
	rx_sync                => rx_sync_xilinx
);


-- BBN module without scrambling
uut_bbn_without_scrambling : entity work.jesd204b_tx
	generic map (
		M => 4,
		L => 8,
		F => 1,
		K => 32,
		SCRAMBLING_ENABLED => false
	)
	port map (
		clk => tx_core_clk,
		rst => rst_bbn,

		syncn => tx_sync_bbn,
		sysref => tx_sysref,

		tx_tdata => tx_tdata_bbn,
		tx_tready => tx_tready_bbn,

		gt_tdata => gt_tdata,
		gt_charisk => gt_charisk
	);

-- BBN module with scrambling
uut_bbn_with_scrambling : entity work.jesd204b_tx
	generic map (
		M => 4,
		L => 8,
		F => 1,
		K => 32,
		SCRAMBLING_ENABLED => true
	)
	port map (
		clk => tx_core_clk,
		rst => rst_bbn,

		syncn => tx_sync_bbn,
		sysref => tx_sysref,

		tx_tdata => tx_tdata_bbn,
		tx_tready => tx_tready_bbn,

		gt_tdata => gt_tdata_scrambled,
		gt_charisk => gt_charisk_scrambled
	);

-- split out GT data per transceiver like Xilinx does
split_gt_data : for ct in 0 to 7 generate
	gt_tdata_array(ct) <= gt_tdata(32*(ct+1)-1 downto 32*ct);
	gt_charisk_array(ct) <= gt_charisk(4*(ct+1)-1 downto 4*ct);
	gt_tdata_scrambled_array(ct) <= gt_tdata_scrambled(32*(ct+1)-1 downto 32*ct);
	gt_charisk_scrambled_array(ct) <= gt_charisk_scrambled(4*(ct+1)-1 downto 4*ct);
end generate;

-- check whether we match the Xilinx core
matches_xilinx <=
	(gt_tdata_array(0) = gt0_txdata) and
	(gt_charisk_array(0) = gt0_txcharisk) and
	(gt_tdata_array(1) = gt1_txdata) and
	(gt_charisk_array(1) = gt1_txcharisk) and
	(gt_tdata_array(2) = gt2_txdata) and
	(gt_charisk_array(2) = gt2_txcharisk) and
	(gt_tdata_array(3) = gt3_txdata) and
	(gt_charisk_array(3) = gt3_txcharisk) and
	(gt_tdata_array(4) = gt4_txdata) and
	(gt_charisk_array(4) = gt4_txcharisk) and
	(gt_tdata_array(5) = gt5_txdata) and
	(gt_charisk_array(5) = gt5_txcharisk) and
	(gt_tdata_array(6) = gt6_txdata) and
	(gt_charisk_array(6) = gt6_txcharisk) and
	(gt_tdata_array(7) = gt7_txdata) and
	(gt_charisk_array(7) = gt7_txcharisk);

matches_xilinx_scrambled <=
(gt_tdata_scrambled_array(0) = gt0_txdata) and
(gt_charisk_scrambled_array(0) = gt0_txcharisk) and
(gt_tdata_scrambled_array(1) = gt1_txdata) and
(gt_charisk_scrambled_array(1) = gt1_txcharisk) and
(gt_tdata_scrambled_array(2) = gt2_txdata) and
(gt_charisk_scrambled_array(2) = gt2_txcharisk) and
(gt_tdata_scrambled_array(3) = gt3_txdata) and
(gt_charisk_scrambled_array(3) = gt3_txcharisk) and
(gt_tdata_scrambled_array(4) = gt4_txdata) and
(gt_charisk_scrambled_array(4) = gt4_txcharisk) and
(gt_tdata_scrambled_array(5) = gt5_txdata) and
(gt_charisk_scrambled_array(5) = gt5_txcharisk) and
(gt_tdata_scrambled_array(6) = gt6_txdata) and
(gt_charisk_scrambled_array(6) = gt6_txcharisk) and
(gt_tdata_scrambled_array(7) = gt7_txdata) and
(gt_charisk_scrambled_array(7) = gt7_txcharisk);

-- clocks
s_axi_aclk <= not s_axi_aclk after axi_clock_period / 2 when not stop_the_clocks;
tx_core_clk <= not tx_core_clk after core_clock_period /2 when not stop_the_clocks;
tx_sysref <= not tx_sysref after 2 * core_clock_period when not stop_the_clocks;

-- push test data into modules
drive_test_data_xilinx : process
begin
	push_test_data(tx_tready_xilinx, tx_tdata_xilinx);
end process;

drive_test_data_bbn : process
begin
	push_test_data(tx_tready_bbn, tx_tdata_bbn);
end process;


stimulus: process

-- helper procedure to write to Xilinx JESD AXI configuration register
procedure write_xilinx_cfg_reg(
	addr : std_logic_vector(11 downto 0);
	val : std_logic_vector(31 downto 0)) is
begin
	wait until rising_edge(s_axi_aclk);
	s_axi_awaddr <= addr;
	s_axi_awvalid <= '1';
	wait until rising_edge(s_axi_aclk) and s_axi_awready = '1';
	s_axi_awvalid <= '0';
	s_axi_wdata <= val;
	s_axi_wstrb <= b"1111";
	s_axi_wvalid <= '1';
	wait until rising_edge(s_axi_aclk) and s_axi_wready = '1';
	s_axi_wvalid <= '0';
	wait until rising_edge(s_axi_aclk) and s_axi_bvalid = '1';
end procedure write_xilinx_cfg_reg;

-- helper procedure to read a Xilinx JESD AXI configuration registers
procedure read_xilinx_cfg_reg(addr : std_logic_vector(11 downto 0)) is
	variable l : line;
begin
	wait until rising_edge(s_axi_aclk);
	s_axi_araddr <= addr;
	s_axi_arvalid <= '1';
	wait until rising_edge(s_axi_aclk) and s_axi_arready = '1';
	s_axi_arvalid <= '0';
	s_axi_rready <= '1';
	wait until rising_edge(s_axi_aclk) and s_axi_rvalid = '1';
	s_axi_rready <= '0';
	write(l, "Xilinx JESD cfg reg at addr " & to_hstring(addr) & " is " & to_hstring(s_axi_rdata) );
	writeline(output, l);
end procedure read_xilinx_cfg_reg;

begin

testbench_state <= RESETING;

tx_reset <= '1';
rst_bbn <= '1';
wait for 400 ns;

s_axi_aresetn <= '1';
wait for 100 ns;

testbench_state <= WRITE_AXI_CFG;

-- check Xilinx core version
read_xilinx_cfg_reg(x"000");
-- check subclass mode
read_xilinx_cfg_reg(x"02c");

-- write Xilinx core configuration registers
write_xilinx_cfg_reg(x"00C", x"0000_0000"); -- scrambling
write_xilinx_cfg_reg(x"020", x"0000_0000"); -- F-1
write_xilinx_cfg_reg(x"024", x"0000_001f"); -- K-1
write_xilinx_cfg_reg(x"02C", x"0000_0000"); --subclass 0

--ILA config data for each lane
for ct in 0 to 3 loop
	write_xilinx_cfg_reg(std_logic_vector(to_unsigned(16#80C# + ct*64, 12)), x"00000000"); -- BID - DID
	write_xilinx_cfg_reg(std_logic_vector(to_unsigned(16#810# + ct*64, 12)), x"000f0f03"); -- N' - N - M
	write_xilinx_cfg_reg(std_logic_vector(to_unsigned(16#814# + ct*64, 12)), x"00010000"); -- HD  S-1
end loop;

-- check subclass mode
read_xilinx_cfg_reg(x"02c");

testbench_state <= RESETING;

wait for 100 ns;
tx_reset <= '1';
tx_reset_done <='0';
wait for 400 ns;
tx_reset <= '0';
rst_bbn <= '0';
wait for 400 ns;
tx_reset_done <= '1';

wait until rising_edge(tx_core_clk) and  tx_aresetn = '1';
wait for 100ns;

-- write a AXI reset
write_xilinx_cfg_reg(x"004", x"0000_0001");
tx_reset_done <= '0';
wait for 400 ns;
tx_reset_done <= '1';

for ct in 0 to 2 loop
	read_xilinx_cfg_reg(x"004");
	wait for 100 ns;
end loop;

tx_sync_xilinx <= '1';
wait for 100 ns; -- Xilinx seems to take longer to respond to syncn
tx_sync_bbn <= '1';

testbench_state <= TEST_UNSCRAMBLED;

-- wait for some data to pass through
wait for 2 us;

testbench_state <= WRITE_AXI_CFG;

-- enable the scrambler on the Xilinx core
write_xilinx_cfg_reg(x"00C", x"0000_0001"); -- scrambling

testbench_state <= RESETING;

-- write a AXI reset
write_xilinx_cfg_reg(x"004", x"0000_0001");
tx_reset_done <= '0';
wait for 400 ns;
tx_sync_bbn <= '0';
tx_sync_xilinx <= '0';
tx_reset_done <= '1';

for ct in 0 to 2 loop
	read_xilinx_cfg_reg(x"004");
	wait for 100 ns;
end loop;

tx_sync_xilinx <= '1';
wait for 100 ns; -- Xilinx seems to take longer to respond to syncn
tx_sync_bbn <= '1';

testbench_state <= TEST_SCRAMBLED;

-- wait for some data to pass through
wait for 2 us;


-- stop_the_clocks <= true;
wait;
end process;


end;
