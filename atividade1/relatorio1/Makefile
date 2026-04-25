ENTITY = atividade1
TB     = atividade1_tb
WAVE   = ondas.vcd

# Simula e abre o GTKWave com sinais e zoom pre-configurados
sim: $(WAVE)
	gtkwave $(WAVE) ondas.gtkw &

# Compila, elabora e roda a simulacao gerando o arquivo de ondas
$(WAVE): $(ENTITY).vhd $(TB).vhd
	ghdl -a $(ENTITY).vhd
	ghdl -a $(TB).vhd
	ghdl -e $(TB)
	ghdl -r $(TB) --vcd=$(WAVE)

# Exporta imagem PNG para relatorio (requer: sudo apt install imagemagick)
png: $(WAVE)
	@printf '%s\n' \
		'set signals [list a b z]' \
		'foreach sig $$signals { gtkwave::addSignalsFromList $$sig }' \
		'gtkwave::setZoomFactor -13' \
		'gtkwave::/File/Print_To_File' \
		'exit' > exporta.tcl
	gtkwave --dump=$(WAVE) --script=exporta.tcl
	@if [ -f "$(ENTITY).ps" ]; then convert $(ENTITY).ps ondas.png && echo "Imagem salva: ondas.png"; fi

# Gera diagrama RTL em PNG (requer: sudo apt install yosys graphviz)
rtl:
	yosys -p "read_verilog $(ENTITY)_rtl.v; prep -top $(ENTITY); show -format png -prefix rtl $(ENTITY)"
	@echo "Diagrama salvo em: rtl.png"

# Remove arquivos gerados
clean:
	rm -f *.o *.cf $(WAVE) $(TB) exporta.tcl ondas.ps ondas.png rtl.png rtl.dot

.PHONY: sim png rtl clean
