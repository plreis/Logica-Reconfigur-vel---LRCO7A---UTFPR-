-- ============================================================================
-- spi_control.vhd
-- Interface SPI 3-wire para leitura do acelerômetro ADXL345 (G-Sensor)
-- Placa: Terasic DE10-Lite (MAX 10 FPGA)
--
-- Descrição:
--   Máquina de estados que inicializa o ADXL345 via SPI 3-wire e realiza
--   leitura contínua do eixo X (registros 0x32 e 0x33).
--   O clock SPI é derivado do clock de 50 MHz (~1 MHz).
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_control is
    port (
        clk         : in    std_logic;                      -- Clock de 50 MHz
        reset_n     : in    std_logic;                      -- Reset ativo baixo
        -- Interface física com o ADXL345
        spi_clk     : out   std_logic;                      -- GSENSOR_SCLK
        spi_sdi     : inout std_logic;                      -- GSENSOR_SDI (bidirecional, 3-wire)
        spi_cs_n    : out   std_logic;                      -- GSENSOR_CS_n
        spi_sdo     : out   std_logic;                      -- GSENSOR_SDO (endereço alternativo)
        -- Dados de saída
        data_x      : out   std_logic_vector(15 downto 0);  -- Valor do eixo X (complemento de 2)
        data_valid  : out   std_logic                       -- Pulso indicando dado válido
    );
end entity spi_control;

architecture rtl of spi_control is

    -- ========================================================================
    -- Constantes do protocolo SPI do ADXL345
    -- ========================================================================
    -- Formato do byte de comando: [R/W][MB][A5..A0]
    -- R/W = 1 para leitura, 0 para escrita
    -- MB  = 1 para multi-byte (leitura sequencial)
    constant SPI_WRITE      : std_logic := '0';
    constant SPI_READ       : std_logic := '1';
    constant SPI_MB         : std_logic := '1';  -- Multi-byte habilitado
    constant SPI_SB         : std_logic := '0';  -- Single-byte

    -- Endereços dos registros do ADXL345
    constant REG_DATA_FORMAT : std_logic_vector(5 downto 0) := "110001";  -- 0x31
    constant REG_POWER_CTL   : std_logic_vector(5 downto 0) := "101101";  -- 0x2D
    constant REG_DATAX0      : std_logic_vector(5 downto 0) := "110010";  -- 0x32

    -- Valores de configuração
    constant DATA_FORMAT_VAL : std_logic_vector(7 downto 0) := "01000000";  -- SPI 3-wire, ±2g
    constant POWER_CTL_VAL   : std_logic_vector(7 downto 0) := "00001000";  -- Modo medição

    -- ========================================================================
    -- Parâmetros de temporização
    -- ========================================================================
    -- Divisor de clock: 50 MHz / 50 = 1 MHz SPI clock
    constant CLK_DIV        : integer := 25;  -- Meio período do SPI clock (50/2)
    -- Atraso entre transações (~2 us)
    constant PAUSE_COUNT    : integer := 100;
    -- Intervalo entre leituras (~10 ms = 500000 ciclos a 50 MHz)
    constant READ_INTERVAL  : integer := 500000;

    -- ========================================================================
    -- Tipos e sinais da máquina de estados
    -- ========================================================================
    type state_t is (
        ST_IDLE,            -- Estado inicial, aguardando
        ST_INIT_FORMAT,     -- Escrevendo DATA_FORMAT (0x31)
        ST_INIT_POWER,      -- Escrevendo POWER_CTL (0x2D)
        ST_PAUSE,           -- Pausa entre comandos
        ST_READ_CMD,        -- Enviando comando de leitura do eixo X
        ST_READ_DATA,       -- Recebendo dados do eixo X (2 bytes)
        ST_DONE,            -- Leitura concluída, aguardando próximo ciclo
        ST_SPI_TX,          -- Sub-estado: transmitindo bits SPI
        ST_SPI_RX           -- Sub-estado: recebendo bits SPI
    );

    -- Estado principal e estado de retorno (para sub-estados)
    signal state            : state_t := ST_IDLE;
    signal next_state       : state_t;

    -- ========================================================================
    -- Sinais de controle SPI
    -- ========================================================================
    signal clk_counter      : integer range 0 to CLK_DIV := 0;
    signal spi_clk_en       : std_logic := '0';           -- Habilita geração do clock SPI
    signal spi_clk_reg      : std_logic := '1';           -- Registro do clock SPI (CPOL=1, CPHA=1)
    signal spi_clk_edge     : std_logic := '0';           -- Pulso na borda do SPI clock

    -- Buffer de transmissão e recepção
    signal tx_buffer        : std_logic_vector(15 downto 0) := (others => '0');
    signal rx_buffer        : std_logic_vector(15 downto 0) := (others => '0');
    signal bit_count        : integer range 0 to 31 := 0;
    signal total_bits       : integer range 0 to 31 := 0;
    signal sdi_out          : std_logic := '1';            -- Dado de saída para SDI
    signal sdi_oe           : std_logic := '1';            -- Output enable para SDI (1=saída, 0=entrada)

    -- Controle de chip select
    signal cs_n_reg         : std_logic := '1';

    -- Controle de pausa e intervalo
    signal pause_counter    : integer range 0 to READ_INTERVAL := 0;

    -- Dados do acelerômetro
    signal data_x_reg       : std_logic_vector(15 downto 0) := (others => '0');

    -- Fase da transação SPI (TX do comando, depois RX dos dados)
    signal spi_phase        : integer range 0 to 3 := 0;  -- 0=cmd TX, 1=data RX

begin

    -- ========================================================================
    -- Controle bidirecional do pino SDI (3-wire SPI)
    -- Quando sdi_oe = '1', o FPGA transmite; quando '0', o FPGA lê
    -- ========================================================================
    spi_sdi <= sdi_out when sdi_oe = '1' else 'Z';

    -- SDO fixo em alto para selecionar endereço I2C 0x1D (não usado em SPI, mas necessário)
    spi_sdo <= '1';

    -- Saídas
    spi_clk  <= spi_clk_reg;
    spi_cs_n <= cs_n_reg;
    data_x   <= data_x_reg;

    -- ========================================================================
    -- Gerador de clock SPI (~1 MHz a partir de 50 MHz)
    -- CPOL=1, CPHA=1: clock ocioso em alto, dados amostrados na borda de subida
    -- ========================================================================
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            clk_counter  <= 0;
            spi_clk_reg  <= '1';
            spi_clk_edge <= '0';
        elsif rising_edge(clk) then
            spi_clk_edge <= '0';
            if spi_clk_en = '1' then
                if clk_counter = CLK_DIV - 1 then
                    clk_counter  <= 0;
                    spi_clk_reg  <= not spi_clk_reg;
                    -- Pulso na borda de descida (quando clock vai de 1 para 0 = momento de mudar dado)
                    -- Pulso na borda de subida (quando clock vai de 0 para 1 = momento de amostrar)
                    if spi_clk_reg = '0' then
                        spi_clk_edge <= '1';  -- Borda de subida: amostrar dado recebido
                    end if;
                else
                    clk_counter <= clk_counter + 1;
                end if;
            else
                clk_counter <= 0;
                spi_clk_reg <= '1';  -- Clock ocioso em alto
            end if;
        end if;
    end process;

    -- ========================================================================
    -- Máquina de estados principal
    -- ========================================================================
    process(clk, reset_n)
        -- Variável para contar bordas SPI durante transmissão/recepção
        variable edge_action : std_logic;
    begin
        if reset_n = '0' then
            state         <= ST_IDLE;
            cs_n_reg      <= '1';
            spi_clk_en    <= '0';
            sdi_oe        <= '1';
            sdi_out       <= '1';
            tx_buffer     <= (others => '0');
            rx_buffer     <= (others => '0');
            bit_count     <= 0;
            total_bits    <= 0;
            spi_phase     <= 0;
            pause_counter <= 0;
            data_x_reg    <= (others => '0');
            data_valid    <= '0';

        elsif rising_edge(clk) then
            data_valid <= '0';  -- Pulso de um ciclo

            case state is

                -- ============================================================
                -- IDLE: Aguarda início (pequena pausa após reset)
                -- ============================================================
                when ST_IDLE =>
                    cs_n_reg   <= '1';
                    spi_clk_en <= '0';
                    sdi_oe     <= '1';
                    if pause_counter < PAUSE_COUNT then
                        pause_counter <= pause_counter + 1;
                    else
                        pause_counter <= 0;
                        state <= ST_INIT_FORMAT;
                    end if;

                -- ============================================================
                -- INIT_FORMAT: Escreve registro DATA_FORMAT (0x31) = 0x40
                -- Comando: [0][0][110001] = 0x31, Dado: 0x40
                -- ============================================================
                when ST_INIT_FORMAT =>
                    cs_n_reg   <= '0';          -- Ativa chip select
                    spi_clk_en <= '1';          -- Habilita clock SPI
                    sdi_oe     <= '1';          -- Modo transmissão
                    -- Monta buffer TX: byte de comando + byte de dado = 16 bits
                    tx_buffer  <= SPI_WRITE & SPI_SB & REG_DATA_FORMAT & DATA_FORMAT_VAL;
                    bit_count  <= 0;
                    total_bits <= 16;           -- 16 bits a transmitir
                    next_state <= ST_PAUSE;     -- Após TX, vai para pausa
                    spi_phase  <= 0;            -- Fase: após pausa, vai para INIT_POWER
                    state      <= ST_SPI_TX;

                -- ============================================================
                -- INIT_POWER: Escreve registro POWER_CTL (0x2D) = 0x08
                -- ============================================================
                when ST_INIT_POWER =>
                    cs_n_reg   <= '0';
                    spi_clk_en <= '1';
                    sdi_oe     <= '1';
                    tx_buffer  <= SPI_WRITE & SPI_SB & REG_POWER_CTL & POWER_CTL_VAL;
                    bit_count  <= 0;
                    total_bits <= 16;
                    next_state <= ST_PAUSE;
                    spi_phase  <= 1;            -- Fase: após pausa, vai para leitura
                    state      <= ST_SPI_TX;

                -- ============================================================
                -- PAUSE: Pausa entre comandos SPI (CS_n desativado)
                -- ============================================================
                when ST_PAUSE =>
                    cs_n_reg   <= '1';
                    spi_clk_en <= '0';
                    sdi_oe     <= '1';
                    if pause_counter < PAUSE_COUNT then
                        pause_counter <= pause_counter + 1;
                    else
                        pause_counter <= 0;
                        case spi_phase is
                            when 0 => state <= ST_INIT_POWER;   -- Próximo: escrever POWER_CTL
                            when 1 => state <= ST_READ_CMD;     -- Próximo: iniciar leitura
                            when others => state <= ST_READ_CMD;
                        end case;
                    end if;

                -- ============================================================
                -- READ_CMD: Envia comando de leitura multi-byte a partir de 0x32
                -- Comando: [1][1][110010] = 0xF2 (Read + MultiByte + 0x32)
                -- Após 8 bits de comando, recebe 16 bits de dados (DATAX0 + DATAX1)
                -- ============================================================
                when ST_READ_CMD =>
                    cs_n_reg   <= '0';
                    spi_clk_en <= '1';
                    sdi_oe     <= '1';
                    tx_buffer(15 downto 8) <= SPI_READ & SPI_MB & REG_DATAX0;
                    tx_buffer(7 downto 0)  <= (others => '0');  -- Don't care durante leitura
                    bit_count  <= 0;
                    total_bits <= 8;            -- Apenas 8 bits de comando
                    next_state <= ST_READ_DATA; -- Após TX comando, receber dados
                    state      <= ST_SPI_TX;

                -- ============================================================
                -- READ_DATA: Recebe 16 bits de dados do eixo X (LSB primeiro)
                -- ============================================================
                when ST_READ_DATA =>
                    sdi_oe     <= '0';          -- Modo recepção (SDI vira entrada)
                    bit_count  <= 0;
                    total_bits <= 16;           -- 16 bits a receber
                    rx_buffer  <= (others => '0');
                    state      <= ST_SPI_RX;

                -- ============================================================
                -- DONE: Leitura concluída, armazena resultado e aguarda intervalo
                -- ============================================================
                when ST_DONE =>
                    cs_n_reg   <= '1';
                    spi_clk_en <= '0';
                    sdi_oe     <= '1';
                    -- Os dados chegam LSB primeiro: rx_buffer(7:0) = DATAX0, rx_buffer(15:8) = DATAX1
                    data_x_reg <= rx_buffer;
                    data_valid <= '1';
                    -- Aguarda intervalo antes de nova leitura
                    if pause_counter < READ_INTERVAL then
                        pause_counter <= pause_counter + 1;
                    else
                        pause_counter <= 0;
                        state <= ST_READ_CMD;
                    end if;

                -- ============================================================
                -- SPI_TX: Sub-estado de transmissão de bits SPI
                -- Transmite MSB primeiro, muda dado na borda de descida
                -- ============================================================
                when ST_SPI_TX =>
                    if spi_clk_edge = '1' then
                        -- Na borda de subida: avança para o próximo bit
                        if bit_count < total_bits then
                            -- Coloca o próximo bit no SDI (MSB primeiro)
                            sdi_out   <= tx_buffer(total_bits - 1 - bit_count);
                            bit_count <= bit_count + 1;
                        else
                            -- Transmissão concluída
                            state <= next_state;
                        end if;
                    end if;
                    -- Coloca o bit atual no barramento entre as bordas
                    if bit_count = 0 and spi_clk_edge = '0' then
                        sdi_out <= tx_buffer(total_bits - 1);  -- Primeiro bit imediatamente
                    end if;

                -- ============================================================
                -- SPI_RX: Sub-estado de recepção de bits SPI
                -- Amostra SDI na borda de subida, armazena LSB primeiro
                -- ============================================================
                when ST_SPI_RX =>
                    if spi_clk_edge = '1' then
                        if bit_count < total_bits then
                            -- Amostra o bit recebido
                            rx_buffer(bit_count) <= spi_sdi;
                            bit_count <= bit_count + 1;
                        else
                            -- Recepção concluída
                            state <= ST_DONE;
                        end if;
                    end if;

            end case;
        end if;
    end process;

end architecture rtl;
