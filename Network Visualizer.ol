include "console.iol"
include "time.iol"

include "Visualizer.iol"

execution { concurrent }


inputPort InputNetwork {
  Location: "socket://localhost:8010"
  Protocol: sodep
  Interfaces: VisualizerInterface
}


inputPort NodeTimeout {
  Location: "local"
  Interfaces: VisualizerInterface
}


outputPort OutputNode {
  Protocol: sodep
  Interfaces: VisualizerInterface
}


init {
	global.networkTimeout = 2000;
	global.networkTimeout.operation = "netTimeout";
	setNextTimeout@Time ( global.networkTimeout)
}

main {
	[netTimeout()] {
		println@Console("Visualizza!!")();
		leader = false;
		for (i = 0, i < 5, i++) {
			nodeLocation = "socket://localhost:800" + (5+i);
			OutputNode.location = nodeLocation;

			scope( scopeConnection )
			{
	            install( IOException => println@Console(OutputNode.location + " ha rifiutato la connessione. Server offline.")() );
				getStats@OutputNode(nodeLocation)(state);
				if (state != LEADER) {
					println@Console(nodeLocation + " e' " + state + "!")()
				} 
				else {
					leader = true;
					index = i
				}
			}
		};
		
		if (leader) {
			println@Console("socket://localhost:800" + index + "e' il LEADER!")()
			//getStatsCarts
		};
		setNextTimeout@Time(global.networkTimeout)
	}
}