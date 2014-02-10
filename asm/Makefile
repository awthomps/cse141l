all:
	rm -f ${CURDIR}/bin/*.class
	cd ${CURDIR}/src/; javac -d ../bin/ vanillaAssembler.java
	cd ${CURDIR}/bin/; jar cfm ../../VAssembler.jar ../src/Manifest.txt *.class
	
