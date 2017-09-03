include "serverInterface.iol"
include "adminInterface.iol"

include "console.iol"
include "time.iol"

outputPort OutputServer {
	Location: "socket://localhost:8000"
	Protocol: sodep
	Interfaces: ServerInterface
}

inputPort InputAdmin {
	Location: "socket://localhost:8001"
	Protocol: sodep
	Interfaces: AdminInterface
}

//DEFINE generale per la stampa di un oggetto
define stampaObject
{
      println@Console( global.Object.name + "\nQuantita' disponibile: " + 
        global.Object.amount + "\nPrezzo: " + 
        global.Object.price + "\nId: " + 
        global.Object.index +  
        "\n------------------------------\n" )()
}

//DEFINE generale per l'inserimento di un oggetto
define inserisciObject
{
	registraOggetto@OutputServer(newObject)(global.Object);//invio l'oggetto al server per la registrazione
	println@Console( "\nNUOVO OGGETTO INSERITO!\n" )();
	stampaObject
}

define controllaOggetto {
	controllo = false;
	controllaMaxId@OutputServer()(indice);
	for (j = 0, j < indice, j++){
		stampaLista@OutputServer(j)(global.Object);
		if ( global.Object.index != -1 && global.Object.name == newObject.name) {
			controllo = true
			}
			
	}
}

define inserisciOggetto
{
	println@Console( "INSERIMENTO OGGETTO" )();
	sleep@Time(250)();
	//registerForInput@Console()();
	println@Console( "Nome oggetto: " )();
	in( newObject.name );
	println@Console( "Quantita': " )();
	in( amount );
	newObject.amount = int(amount);
	println@Console( "Prezzo: " )();
	in( price );
	newObject.price = double(price);
	controllaOggetto;
	if (controllo == true) {
		println@Console("ERRORE: Oggetto gia' presente!!!\n")()
	} else {
		inserisciObject
	};
	sleep@Time(500)()
}

define rimuoviOggetto
{
	println@Console( "RIMUOVI OGGETTO\n" )();
	sleep@Time(250)();
	controllaMaxId@OutputServer()(indice);
	for (j = 0, j < indice, j++){
		stampaLista@OutputServer(j)(global.Object);
		if ( global.Object.index != -1) {
			stampaObject;
			sleep@Time(500)()
		}
	};
	sleep@Time(250)();
	//registerForInput@Console()();
	print@Console( "Inserisci l'id dell'oggetto da rimuovere: " )();
	in(j);
	id = int(j);
	rimuoviOggetto@OutputServer(id)(res);
	if (res == true) {
		println@Console( "\nOggetto rimosso correttamente!!\n" )();
		sleep@Time(500)()
	} else {
		println@Console( "\nERRORE: Oggetto non presente!!\n" )();
		sleep@Time(500)()
	}
}

init {
	//println@Console( "OGGETTI IN VENDITA\n" )();
	//Creo la struttura degli oggetti principali
	//1° oggett
	newObject.name = "Iphone7";
	newObject.amount = int("5");
	newObject.price = double("800");
	newObject.index = int("0");
	registraOggetto@OutputServer(newObject)(global.Object);//invio l'oggetto al server per la registrazione
	//stampaObject;
	sleep@Time(150)();

	//2° oggetto
	newObject.name = "Asus X53sv";
	newObject.amount = int("3");
	newObject.price = double("300");
	newObject.index = int("0");
	registraOggetto@OutputServer(newObject)(global.Object);//invio l'oggetto al server per la registrazione
	//stampaObject;
	sleep@Time(150)();

	//3° oggetto
	newObject.name = "Tv Samsung";
	newObject.amount = int("10");
	newObject.price = double("1300");
	newObject.index = int("0");
	registraOggetto@OutputServer(newObject)(global.Object);//invio l'oggetto al server per la registrazione
	//stampaObject;
	sleep@Time(150)();

	//4° oggetto
	newObject.name = "Cassa BOSE";
	newObject.amount = int("7");
	newObject.price = double("98.99");
	newObject.index = int("0");
	registraOggetto@OutputServer(newObject)(global.Object);//invio l'oggetto al server per la registrazione
	//stampaObject;
	sleep@Time(150)();

	//5° oggetto
	newObject.name = "Rasoio Philips";
	newObject.amount = int("5");
	newObject.price = double("57.90");
	newObject.index = 0;
	registraOggetto@OutputServer(newObject)(global.Object);//invio l'oggetto al server per la registrazione
	//stampaObject;
	sleep@Time(150)()
}

main {
	println@Console( "BENVENUTO!!!\n\n" )();
	ferma = 0;
	registerForInput@Console()();
	while (ferma == 0) {
	  	print@Console( "OPERAZIONI DISPONIBILI:\n1)Inserisci oggetto\n2)Rimuovi oggetto\n(indicare la scelta con le opzioni 1 o 2) " )();
	  	operazione = 0;
	  	while (operazione != "1" && operazione != "2") {
		  	in( operazione );
		  	if (operazione == "1") {
				inserisciOggetto
		  	} else if (operazione == "2") {
		  		rimuoviOggetto
		  	} else {
		  		println@Console( "Scelta opzioni non corretta! Indicare la scelta con le opzioni 1 o 2!" )()
		  	}
		  }
	  }
}