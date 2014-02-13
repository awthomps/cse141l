all:
	-rm -f *.class
	javac *.java
	jar cfm ../../core/VAssembler.jar Manifest.txt *.class
	-rm -f *.class

clean:
	-rm -f *.class

miner:
	-rm -f *.class
	javac *.java
	jar cfm VAssembler.jar Manifest.txt *.class
	-rm -f *.class
	java -jar VAssembler.jar ../../miner/miner.asm miner
	mv miner_i.hex ../../core/miner_i.hex
	mv miner_d.hex ../../core/miner_d.hex
	mv miner_r.hex ../../core/miner_r.hex
	mv miner_info.txt ../../core/miner_info.txt
	rm VAssembler.jar	
