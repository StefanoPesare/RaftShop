include "serverInterface.iol"
include "adminInterface.iol"

include "console.iol"
include "time.iol"
include "semaphore_utils.iol"


inputPort InputServer {
	Location: "socket://localhost:8000"
	Protocol: sodep
	Interfaces: ServerInterface
}

outputPort OutputAdmin {
	Location: "socket://localhost:8001"
	Protocol: sodep
	Interfaces: AdminInterface
}

execution{ concurrent }

init {
	println@Console("SERVER\n\n")();

	semRegistraClient.name = "Registrazione Client";
  	semRegistraClient.permits = 1;
  	release@SemaphoreUtils( semRegistraClient )( res );

  	//semRegistraObject.name = "Registrazione Object";
  	//semRegistraObject.permits = 1;
  	//release@SemaphoreUtils( semRegistraObject )( res );

  	semRegistraCart.name = "Registrazione Cart";
  	semRegistraCart.permits = 1;
  	release@SemaphoreUtils( semRegistraCart )( res );

  	semScritturaObject.name = "Scrittura Object";
  	semScritturaObject.permits = 1;
  	release@SemaphoreUtils( semScritturaObject )( res );

  	global.oggetti = 0;
  	global.client = 0;
  	global.carrelli = 0;
  	global.semafori = 0

}

  
main {
	//REGISTRAZIONE OGGETTI
  	[registraOggetto(newObject)(registeredObject){

  		//acquire@SemaphoreUtils( semRegistraObject )( res );//prendo il lock sul registraObject

  		global.ObjectStructure.Item[global.oggetti].name  = newObject.name;
  		registeredObject.name = newObject.name;
		global.ObjectStructure.Item[global.oggetti].amount = newObject.amount;
		registeredObject.amount = newObject.amount;
		global.ObjectStructure.Item[global.oggetti].price = newObject.price;
		registeredObject.price = newObject.price;
		global.ObjectStructure.Item[global.oggetti].index = global.oggetti;
		registeredObject.index = global.oggetti;

		println@Console( registeredObject.name + " salvato nel Server con ID: " + registeredObject.index +
  
        "\n------------------------------\n" )();
        global.oggetti++

      	//release@SemaphoreUtils( semRegistraObject )( res )//rilascio il lock sul registraObject

  	}]


  	//CreaAccount assegna un account al Client e lo registra nel server 
  	[creaAccount( nomeClient )( Client ){

		acquire@SemaphoreUtils( semRegistraClient )( res );//prendo il lock sul registraClient

		for (i = 0, i < global.client, i++) {
			if (global.ClientStructure.Item[i].name == nomeClient) {
				esistente = true
			}
		};
		if (is_defined( esistente )) {
			Client.name = "";
			Client.index = -1;
			release@SemaphoreUtils( semRegistraClient )( res )//rilascio il lock sul registraClient
		} else {
			//NOME
		   	global.ClientStructure.Item[global.client].name = nomeClient;
		    Client.name = nomeClient;
		    //ID
		    global.ClientStructure.Item[global.client].index = global.client;
		    Client.index = global.client;
		    println@Console( nomeClient + " registrato nel Server" +
		    "\n------------------------------\n" )();
		    global.client++;

		    release@SemaphoreUtils( semRegistraClient )( res )//rilascio il lock sul registraClient

		}
  	}]	


  	//CREA CARRELLO NUOVO
  	[creaCarrello( nomeCart )( ris ){

		acquire@SemaphoreUtils( semRegistraCart )( res );	//prendo il lock sul registraCart

		for (i = 0, i < global.carrelli, i++) {
			if (global.CartStructure.Item[i].name == nomeCart) {
				ris = true
			}
		};
		if (is_defined( ris )) {

			release@SemaphoreUtils( semRegistraCart )( res )	//rilascio il lock sul registraCart

		} else {

			//DEFINISCO IL CARRELLO
		   	global.CartStructure.Item[global.carrelli].name = nomeCart;
		   	global.CartStructure.Item[global.carrelli].index = 0;
		   	global.CartStructure.Item[global.carrelli].objList[global.CartStructure.Item[global.carrelli].index].name = "";
		   	global.CartStructure.Item[global.carrelli].objList[global.CartStructure.Item[global.carrelli].index].amount = 0;
		   	global.CartStructure.Item[global.carrelli].objList[global.CartStructure.Item[global.carrelli].index].price = 0;
		   	global.CartStructure.Item[global.carrelli].objList[global.CartStructure.Item[global.carrelli].index].index = -1;
		   	global.CartStructure.Item[global.carrelli].price = 0.00;

		   	//DEFINISCO I SEMAFORI DEL CARRELLO

		   	global.semaforo[global.semafori].semMutexCarrello.name = nomeCart;
			global.semaforo[global.semafori].semMutexCarrello.permits = 1;
			release@SemaphoreUtils( global.semaforo[global.semafori].semMutexCarrello )( res );
			global.semaforo[global.semafori].numLettoriCarrello = 0;
			println@Console( "Semaforo lettura '" + global.semaforo[global.semafori].semMutexCarrello.name + "' registrato nel Server" +
		    "\n------------------------------\n" )();

		   	global.semaforo[global.semafori].semScritturaCarrello.name = nomeCart;
			global.semaforo[global.semafori].semScritturaCarrello.permits = 1;
			release@SemaphoreUtils( global.semaforo[global.semafori].semScritturaCarrello )( res );
			println@Console( "Semaforo scrittura '" + global.semaforo[global.semafori].semScritturaCarrello.name + "' registrato nel Server" +
		    "\n------------------------------\n" )();

		    ris = false;
		    println@Console( "Carrello '" + nomeCart + "' registrato nel Server" +
		    "\n------------------------------\n" )();
		    global.carrelli++;
		    global.semafori++;

		    release@SemaphoreUtils( semRegistraCart )( res )//rilascio il lock sul registraCart

		}
  	}]	


  	//CONTROLLA NUM ID OGGETTI
  	[controllaMaxId()(indice){
  		indice = global.oggetti
  	}]


  	//CONTROLLA NUM ID OGGETTI
  	[controllaMaxCart()(indice){
  		indice = global.carrelli
  	}]


  	//VISUALIZZA OGGETTO
  	[stampaLista(j)(visualizzaObject){
  		if (is_defined( global.ObjectStructure.Item[j].name )) {
  			visualizzaObject.name = global.ObjectStructure.Item[j].name;
  		  	visualizzaObject.amount = global.ObjectStructure.Item[j].amount;
  		  	visualizzaObject.price = global.ObjectStructure.Item[j].price;
  		  	visualizzaObject.index = global.ObjectStructure.Item[j].index
  		  } else {
  		  	visualizzaObject.name = "";
  		  	visualizzaObject.amount = 0;
  		  	visualizzaObject.price = 0.00;
  		  	visualizzaObject.index = -1
  		  }
  	}]


  	//RICERCA OGGETTO se è presente l'indice nel database
  	[ricercaOggetto(idOggetto)(oggettoTrovato){
  			if (is_defined(global.ObjectStructure.Item[idOggetto].name) && global.ObjectStructure.Item[idOggetto].amount > 0) {
  				trovato = true;
  				oggettoTrovato.name = global.ObjectStructure.Item[idOggetto].name;
  		  		oggettoTrovato.amount = global.ObjectStructure.Item[idOggetto].amount;
  		  		oggettoTrovato.price = global.ObjectStructure.Item[idOggetto].price;
  		  		oggettoTrovato.index = global.ObjectStructure.Item[idOggetto].index
  		};
  		if (trovato != true) {
  			oggettoTrovato.name = "";
  		  	oggettoTrovato.amount = 0;
  		  	oggettoTrovato.price = 0.00;
  		  	oggettoTrovato.index = -1
  		}

  	}]


  	//VISUALIZZA CARRELLO
  	[stampaListaCart(j)(name){
  		if (is_defined( global.CartStructure.Item[j].name ) && global.CartStructure.Item[j].archiviato =! true) {
  			name = global.CartStructure.Item[j].name
  		} else {
  			name = ""
  		}
  	}]


  	//RICERCA CARRELLO tramite il nome in input
	[ricercaCarrello(nomeCarrello)(carrelloTrovato){
	  		for(i = 0, i < global.carrelli, i++) {
	  			if (global.CartStructure.Item[i].name == nomeCarrello && global.CartStructure.Item[i].archiviato != true) {
	  				carrelloTrovato << global.CartStructure.Item[i];
	  		  		trovato = true
	  			}
	  		};
	  		if (trovato != true ) {
		  		carrelloTrovato.name = "";
			   	carrelloTrovato.index = 0;
			   	carrelloTrovato.objList[0].name = "";
			   	carrelloTrovato.objList[0].amount = 0;
			   	carrelloTrovato.objList[0].price = 0;
			   	carrelloTrovato.objList[0].index = -1;
			   	carrelloTrovato.price = 0
	  		}
	  	}]


	//AGGIORNAMENTO QUANTITà OGGETTO RICHIESTO
	[aggiornaQuantitaOggetto(objectModified)(){

		acquire@SemaphoreUtils( semScritturaObject )( res );//prendo il lock su scritturaObject

		if (global.ObjectStructure.Item[objectModified.index].amount > objectModified.amount) {
			aggiunto = true
		}
		else {
			aggiunto = false
		};

		global.ObjectStructure.Item[objectModified.index].amount = objectModified.amount;

		//global.ObjectStructure.Item[objectModified.index].amount = global.ObjectStructure.Item[objectModified.index].amount - qObject; 
		if (aggiunto) {
			println@Console( objectModified.name + " aggiunto al carrello!" +   
	        "\n------------------------------\n" )()
	    }
	    else {
	    	println@Console( objectModified.name + " rimosso dal carrello!" +   
	        "\n------------------------------\n" )()
	    };
        qAggiornata = true;
		

        release@SemaphoreUtils( semScritturaObject)(res) //rilascio il lock su scritturaObject

	}]


	 //AGGIUNTA DI UN OGGETTO AL CARRELLO
	 [aggiornaCarrello(cartInUse)(trovato){

	 	trovato = false;
	 	for(i = 0, i < global.carrelli, i++) {
	  			if (global.CartStructure.Item[i].name == cartInUse.name && global.CartStructure.Item[i].archiviato != true) {
	  				global.CartStructure.Item[i] << cartInUse;
	  		  		trovato = true;
	  		  		println@Console( "Prezzo carrello '" + global.CartStructure.Item[i].name + "': " + global.CartStructure.Item[i].price +  
       	 			"\n------------------------------\n" )()
	  			}
	  		}
	 }]


  	//RIMUOVI OGGETTO
  	[rimuoviOggetto(id)(res){

  		acquire@SemaphoreUtils( semScritturaObject )( res );//prendo il lock su scritturaObject

  		res = false;
  		for (j = 0, j < global.oggetti, j++) {
  			if (global.ObjectStructure.Item[j].index == id)
  				indice = j
  		};
  		if (is_defined(indice )) {
  			undef(global.ObjectStructure.Item[indice]);
  			res=true;
  			println@Console("L'oggetto " + id + " e' stato rimosso!" + 
  				"\n------------------------------\n")()
  		} else {
  			res = false;
  			println@Console("L'oggetto " + id + " non e' presente!" + 
  				"\n------------------------------\n")()
  		};

  		release@SemaphoreUtils( semScritturaObject)(res) //rilascio il lock su scritturaObject
  	}]


  	//CANCELLA CARRELLO tramite il nome in input
	[cancellaCarrello(cartInUse)(eliminato){

		for(i = 0, i < global.semafori, i++) {
	  			if (global.semaforo[i].semScritturaCarrello.name == cartInUse.name) {
	  				index = i;
	  		  		trovato = true
	  			}
	  		};

	  	if (trovato) {

	  		//acquire@SemaphoreUtils( global.semaforo[index].semScritturaCarrello )( res );	//prendo il lock sul cancellaCart
	  		println@Console("\nCancellazione) Prendo il lock del semaforo " + global.semaforo[index].semScritturaCarrello.name + res)();


			eliminato = false;
		  		for(i = 0, i < global.carrelli, i++) {
		  			if (global.CartStructure.Item[i].name == cartInUse.name && global.CartStructure.Item[i].archiviato != true) {
		  				indice = i;
		  		  		eliminato = true
		  			}
		  		};
		  		if (eliminato == true ) {

		  			for (i=0, i< cartInUse.index, i++) {
		  				for (j=0, j < global.oggetti, j++) {
		  					if (global.ObjectStructure.Item[j].name == cartInUse.objList[i].name) {
		  						presente = true;
		  						global.ObjectStructure.Item[j].amount = global.ObjectStructure.Item[j].amount + cartInUse.objList[i].amount
		  					}
		  				}
		  			};

			  		undef(global.CartStructure.Item[indice]);
			  		println@Console("Il carrello '" + nomeCarrello + "' e' stato cancellato!" + 
	  				"\n------------------------------\n")()
		  		} else {
		  			println@Console("Il carrello '" + nomeCarrello + "'' non e' presente!" + 
	  				"\n------------------------------\n")()
		  		};
		  		global.carrelli--;

		  	release@SemaphoreUtils( global.semaforo[index].semScritturaCarrello )( res );	//rilascio il lock sul cancellaCart
		  	println@Console("\nCancellazione) Rilascio il lock del semaforo " + global.semaforo[index].semScritturaCarrello.name + res)();

		  	undef(global.semaforo[index])
		  } else {
		  	eliminato = false
		  }
	  	}]


	//ACQUISTA CARRELLO tramite il nome in input
	[acquistaCarrello(nomeCarrello)(acquistato){

		for(i = 0, i < global.semafori, i++) {
	  			if (global.semaforo[i].semScritturaCarrello.name == nomeCarrello) {
	  				index = i;
	  		  		trovato = true
	  			}
	  		};

	  	if (trovato) {

			acquire@SemaphoreUtils( global.semaforo[index].semScritturaCarrello )( res );	//prendo il lock sull' acquistaCart

			acquistato = false;
			trovato = false;

		  		for(i = 0, i < global.carrelli, i++) {
		  			if (global.CartStructure.Item[i].name == nomeCarrello && global.CartStructure.Item[i].archiviato != true) {
		  				indice = i;
		  		  		trovato = true
		  			}
		  		};
		  		if (trovato == true ) {
		  			if (global.CartStructure.Item[indice].price > 0) {
				  		
				  		global.CartStructure.Item[indice].archiviato = true;

					   	acquistato = true;

				  		println@Console("Il carrello '" + nomeCarrello + "' e' stato acquistato!" + 
		  				"\n------------------------------\n")()
		  			} else {
		  				println@Console("Acquisto non valido!" + 
		  				"\n------------------------------\n")()
		  			}
		  		} else {
		  			println@Console("Il carrello '" + nomeCarrello + "'' non e' presente!" + 
	  				"\n------------------------------\n")()
		  		};

		  	release@SemaphoreUtils( global.semaforo[index].semScritturaCarrello )( res )	//rilascio il lock sull' acquistaCart

		  }
	  	}]


	 //CONTROLLA CARRELLO tramite il nome in input nel caso sia stato cancellato
	[controllaCarrello(nomeCarrello)(cancellato){
		cancellato = true;
	  		for(i = 0, i < global.carrelli, i++) {
	  			if (global.CartStructure.Item[i].name == nomeCarrello) {
	  		  		cancellato = false
	  			}
	  		}
	}]


	//SEMAFORO INIZIO LETTURA CARRELLO
 	[semaforoInizioLettura(nomeCarrello)(letto) {

	  	trovato = false;

	  	for(i = 0, i < global.carrelli, i++) {
				if (global.CartStructure.Item[i].name == nomeCarrello && global.CartStructure.Item[i].archiviato != true) {
			  		trovato = true
				}
			};
			println@Console("\n1)Sto gia' leggendo su questo carrello: " + nomeCarrello)();
		if (trovato){
			trovato = false;

			for(i = 0, i < global.semafori, i++) {
				println@Console("\nSemaforo: " + global.semaforo[i].semScritturaCarrello.name)();
	  			if (global.semaforo[i].semScritturaCarrello.name == nomeCarrello) {
	  				index = i;
	  		  		trovato = true
	  			}
	  		};

	  		println@Console("\n2)Sono entrato qui: " + nomeCarrello)();

	  		if (trovato) {
	  			letto = true;
				println@Console("\nSto lavorando su: " + nomeCarrello)();
			 	acquire@SemaphoreUtils( global.semaforo[index].semMutexCarrello )( res );
			 	println@Console("\nINIZIO A LEGGERE 1")();

			    global.semaforo[index].numLettoriCarrello++;
			    if(global.semaforo[index].numLettoriCarrello == 1){

			    	println@Console("\nCarrello " + global.semaforo[index].semScritturaCarrello.name + " Numero lettori: " + global.semaforo[index].numLettoriCarrello)();
			    	acquire@SemaphoreUtils( global.semaforo[index].semScritturaCarrello )( res );	//prendo i lock sugli scrittori del Carrello
			    	println@Console("\n1)Preso il lock del semaforo " + global.semaforo[index].semScritturaCarrello.name + res)();
			    	println@Console("\nINIZIO A SCRIVERE 0")()

			    };

			  	release@SemaphoreUtils( global.semaforo[index].semMutexCarrello )( res);
			  	println@Console("\nFINISCO DI LEGGERE 1")()
			  }
			  else {
			  	letto = false
			  }
			}
		else {
			letto = false
		}
	}]


	//SEMAFORO FINE LETTURA CARRELLO
	[semaforoFineLettura(nomeCarrello)(letto) {
	  	trovato = false;
	  	for(i = 0, i < global.carrelli, i++) {
			if (global.CartStructure.Item[i].name == nomeCarrello && global.CartStructure.Item[i].archiviato != true) {
				trovato = true
			}
		};
		if (trovato == true){
			trovato = false;

			for(i = 0, i < global.semafori, i++) {
	  			if (global.semaforo[i].semScritturaCarrello.name == nomeCarrello) {
	  			index = i;
	  		  		trovato = true
	  			}
	  		};

	  		if (trovato) {
	  			letto = true;
			  	acquire@SemaphoreUtils( global.semaforo[index].semMutexCarrello )( res);
			  	println@Console("\nINIZIO A LEGGERE 2")();

				global.semaforo[index].numLettoriCarrello--;
				if(global.semaforo[index].numLettoriCarrello == 0){

					release@SemaphoreUtils( global.semaforo[index].semScritturaCarrello )( res );	//rilascio il lock sugli scrittori del carrello
					println@Console("\n2)Rilascio il lock del semaforo " + global.semaforo[index].semScritturaCarrello.name + res)();
					println@Console("\nFINISCO DI SCRIVERE 0")()

				};

				release@SemaphoreUtils( global.semaforo[index].semMutexCarrello )( res );
				println@Console("\nFINISCO DI LEGGERE")()
			}
			else {
				letto = false
			}
		}
		else {
			letto = false
		}
	}]


	//SEMAFORO INIZIO SCRITTURA richiamato dal client
	[semaforoInizioScrittura(nomeCarrello)(scritto) {
		scritto = true;
		for(i = 0, i < global.semafori, i++) {
	  		if (global.semaforo[i].semScritturaCarrello.name == nomeCarrello) {
	  			index = i;
	  			trovato = true
	  		}
	  	};
	  	if (trovato) {		
	  		println@Console("\nCarrello " + global.semaforo[index].semMutexCarrello.name + " Numero lettori: " + global.semaforo[index].numLettoriCarrello)();

			acquire@SemaphoreUtils( global.semaforo[index].semScritturaCarrello )( res );	//prendo i lock sugli scrittori del Carrello
			println@Console("\n3)Preso il lock del semaforo " + global.semaforo[index].semScritturaCarrello.name + res)();
			println@Console("\nINIZIO A SCRIVERE 2")()

		}
		else {
			scritto = false
		}
	}]


	//SEMAFORO FINE SCRITTURA richiamato dal client
	[semaforoFineScrittura(nomeCarrello)(scritto) {
		scritto = true;

		for(i = 0, i < global.semafori, i++) {
	  		if (global.semaforo[i].semScritturaCarrello.name == nomeCarrello) {
	  			index = i;
	  			trovato = true
	  		}
	  	};

	  	if (trovato) {

			release@SemaphoreUtils( global.semaforo[index].semScritturaCarrello )( res );	//rilascio i lock sugli scrittori del Carrello
			println@Console("\n4)Rilascio il lock del semaforo " + global.semaforo[index].semScritturaCarrello.name + res)();
			println@Console("\nFINISCO DI SCRIVERE 2")()

		}
		else {
			scritto = false
		}
	}]
}