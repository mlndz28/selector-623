tests = $(wildcard asm/tests/*.asm)
tests := $(subst asm/tests/,,$(tests:.asm=))
parts = init hw_init main config idle overview race keypad lcd isr utilities
AS12A = as12
AS12FLAGS =-L -s
BIN = asm/bin
SIM = java -jar /opt/hc12asm/simhc12.jar
MAIN = asm/roots.s19

default: render
pre:
	@mkdir -p $(BIN)
clean:
	@rm -rf asm/bin
	@rm -f asm/whole.asm
	@rm -f *.pdf
	@rm -f *.html
	@rm -f rendered.md
	@rm -f *.properties
	@rm -f *.zip

package: render cat
	@zip -r release.zip ./
	@mkdir -p release
	@cp report.pdf release/FABIANMELENDEZ_TF.pdf
	@cp asm/whole.asm release/FABIANMELENDEZ_TF.asm

render:
	@pandoc report.md report.yaml -s --filter pandoc-plantuml --pdf-engine=xelatex -o report.pdf -f markdown+implicit_figures --variable=fontsize:11pt
	@echo Document rendered: $(shell pwd)/report.pdf


list:
	@echo "Programs available:\n"
	@echo $(foreach f,$(tests),"\t$(f)\n")
	@echo $(foreach f,$(tests),"\t$(subst _test,,$(f))\n")
	@$(foreach f,$(assemble),"\t$(f)\n")

cat:
	@echo '' > asm/whole.asm
	@$(foreach f,$(parts),cat asm/$(f).asm >> asm/whole.asm;echo '\n' >> asm/whole.asm;)

main: pre cat
	@echo Assembling main program
	#@$(AS12A) asm/whole.asm -o$(BIN)/whole.s19 $(AS12FLAGS)
	@$(AS12A) $(foreach f,$(parts),asm/$(f).asm) -o$(BIN)/whole.s19 $(AS12FLAGS)
	@mv asm/$(word 1,$(parts)).lst $(BIN)/whole.lst
	@mv asm/$(word 1,$(parts)).sym $(BIN)/whole.sym
	@dbug12 load $(BIN)/whole.s19
	@dbug12 run 2000

$(foreach rule,$(tests),$(rule)_test): pre
	@echo Assembling test $(subst _test,,$@).asm and its parent src files
	@$(AS12A) asm/tests/$(subst _test,,$@).asm -o$(BIN)/$@.s19 $(AS12FLAGS)
	@mv asm/tests/$(subst _test,,$@).sym $(BIN)/$@.sym
	@mv asm/tests/$(subst _test,,$@).lst $(BIN)/$@.lst
	@sed -e '1,/;test/ s/.*//' -e 's/;//' asm/tests/$(subst _test,,$@).asm | python