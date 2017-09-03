include "ServerInterface.iol"

include "console.iol"
include "time.iol"

outputPort OutputServer {
	Location: "socket://localhost:8000"
	Protocol: sodep
	Interfaces: ServerInterface
}

  
//DEFINE generale per la stampa di un oggetto
define stampaObject
{
      println@Console( "\n" + global.Object.name + "\nQuantita' disponibile: " + 
        global.Object.amount + "\nPrezzo: " + 
        global.Object.price + "\nId: " + 
        global.Object.index +  
        "\n------------------------------\n" )()
}


//DEFINE generale per la stampa di un carrello
define stampaCart
{
      println@Console( "\nNome carrello: " + name +  
        "\n------------------------------\n" )()
}


//DEFINE generale per la registrazione di un Client
define registraClient {
  registerForInput@Console()();
  print@Console( "Nome Client: " )();
  esistente = true;
  while (esistente == true) {
    in( name );
    //invio al server il nome del client per poi ricevere la conferma della registrazione 
    //ricevendo la struttura client che contiene il nome e l'id.
    creaAccount@OutputServer(name)(global.Client);
    if (global.Client.index == -1) {
      print@Console( "\nErrore: nome utente gia' esistente. Modificare nome Client: ")()
    } else {
      esistente = false
    }
  };
  print@Console(global.Client.name + " e' stato registrato!\n")();
  sleep@Time(300)()
}


//DEFINE generale per la visualizzazione della lista degli Oggetti
define visualizzaListaOggetti {
  controllaMaxId@OutputServer()(indice);
  if (indice == 0) {
    print@Console("\nNessun oggetto presente!\n")()
  } else {  
    for (j = 0, j < indice, j++){
      stampaLista@OutputServer(j)(global.Object);
      if ( global.Object.index != -1) {
        stampaObject;
        sleep@Time(500)()
      }
    }
  }
}


//DEFINE generale per la visualizzazione degli oggetti presenti in un carrello
define visualizzaOggettiCarrello {

  semaforoInizioLettura@OutputServer(cartInUse.name)(letto);

  if (letto) {
    controllaCarrello@OutputServer(cartInUse.name)(cancellato);
    if (cancellato == false) {
      if (cartInUse.index == 0) {
        println@Console("\nCarrello vuoto!!")()
      } else {
        for (j=0, j < cartInUse.index, j++) {
          println@Console( "\n" + cartInUse.objList[j].name + "\nQuantita': " + 
          cartInUse.objList[j].amount + "\nPrezzo: " + 
          (cartInUse.objList[j].price * cartInUse.objList[j].amount) + 
          "\n------------------------------\n" )();
          sleep@Time(500)()
        };
        println@Console("Totale carrello: " + cartInUse.price + 
          "\n------------------------------\n" )();
          sleep@Time(500)()
      }
    };

    semaforoFineLettura@OutputServer(cartInUse.name)(letto)

  } else {
    cancellato = true
  }
}


//DEFINE generale per la creazione di un carrello
define creaCarrello
{
  print@Console( "\nNome Carrello: " )();
  res = true;
  while (res == true) {
    in( name );
    //invio al server il nome del client per poi ricevere la conferma della registrazione 
    //ricevendo la struttura client che contiene il nome e l'id.
    creaCarrello@OutputServer(name)(res);
    if (res == true) {
      print@Console( "\nErrore: carrello gia' esistente. Modificare nome carrello: ")()
    } 
  };
  print@Console("Carrello '" + name + "' e' stato registrato!\n")();
  sleep@Time(300)()
}


//DEFINE generale per la visualizzazione della lista dei carrelli
define visualizzaListaCarrelli
{

  controllaMaxCart@OutputServer()(indice);
  if (indice == 0) {
    print@Console("\nNessun carrello presente!\n")()
  } else {
    for (j = 0, j < indice, j++){
      stampaListaCart@OutputServer(j)(name);
      if ( name != "") {
        stampaCart;
        sleep@Time(500)()
      }
    }
  }
}


//DEFINE generale per controllare se un oggetto è già presente nel carrello
define controllaOggettoCarrello
{
  trovatoNelCarrello = -1;
  for (j=0, j < cartInUse.index, j++) {
    if (cartInUse.objList[j].index == oggettoTrovato.index) {
      trovatoNelCarrello = j
    }
  }
}


//DEFINE generale per l'inserimento di un oggetto in un carrello
define inserisciOggetto
{ 

  semaforoInizioScrittura@OutputServer(cartInUse.name)(scritto);

  if (scritto) {  
    visualizzaListaOggetti;
    if (indice != 0) {
      trovato = false;
      print@Console( "\nInserisci l'Id dell'oggetto che vuoi aggiungere al carrello: ")();
      in(id);
      idOggetto = int (id);
          
      ricercaOggetto@OutputServer(idOggetto)(oggettoTrovato);
          
      if (oggettoTrovato.index == idOggetto) {
        quan = false;
        while (quan == false) {
          print@Console( "\nInserisci la quantita' da aggiungere al carrello: ")();
          in(q);
          qOggetto = int (q);

          controllaCarrello@OutputServer(cartInUse.name)(cancellato);

          if (cancellato == true) {
            quan = true
          } else if (oggettoTrovato.amount >= qOggetto && qOggetto > 0) {

            oggettoTrovato.amount = oggettoTrovato.amount - qOggetto;

            aggiornaQuantitaOggetto@OutputServer(oggettoTrovato)();

            
              oggettoTrovato.amount = qOggetto;

              controllaOggettoCarrello;

              if (trovatoNelCarrello > -1) {

                cartInUse.objList[trovatoNelCarrello].amount = cartInUse.objList[trovatoNelCarrello].amount + oggettoTrovato.amount

              } else {
                  cartInUse.objList[cartInUse.index] << oggettoTrovato;
                  cartInUse.index++
              };
              cartInUse.price = cartInUse.price + (oggettoTrovato.price * oggettoTrovato.amount);
                    
              aggiornaCarrello@OutputServer(cartInUse)(aggiornato);
              if (aggiornato) {
                println@Console("\n" + cartInUse.objList[cartInUse.index-1].name + " aggiunto al carrello con quantita' " + oggettoTrovato.amount + "!")();
                quan = true
              } else { 
                  println@Console("\nERRORE: errore nell'aggiornamento del carrello!")() 
                }
          } else {
            println@Console( "\nERRORE: quantita' errata o non disponibile!\n")()
          }
        }      
      } else {
        println@Console("\nERRORE: Id immesso inesistente o quantita' non disponibile!")()
      }
    };
    semaforoFineScrittura@OutputServer(cartInUse.name)(scritto)
  }
  else {
    cancellato = true
  }
}


define rimuoviOggetto {

    visualizzaOggettiCarrello;
    if (cartInUse.index > 0){

      semaforoInizioScrittura@OutputServer(cartInUse.name)(scritto);

      if (scritto) {
        trovato = false;
        print@Console( "\nInserisci il nome dell'oggetto che vuoi rimuovere dal carrello: ")();
        in(nomeOggetto);
        for (i=0, i < cartInUse.index, i++) {
          if (cartInUse.objList[i].name == nomeOggetto) {
            trovato = true;
            index = i
          }
        };

        if (trovato) {
          quan = false;
          while (quan == false) {

            if (cartInUse.objList[index].amount == 1) {
              qOggetto = 1;
              quan = true
            } else {
              print@Console( "\nInserisci la quantita' da rimuovere dal carrello: ")();
              in(q);
              qOggetto = int (q);

              if (qOggetto > 0 && qOggetto <= cartInUse.objList[index].amount) {
                quan = true
              } else {
                println@Console( "\nERRORE: quantita' errata o non disponibile!\n")()
              }
            }
          };
                
          cartInUse.objList[index].amount = cartInUse.objList[index].amount - qOggetto;

          cartInUse.price = cartInUse.price - (cartInUse.objList[index].price * qOggetto);

          aggiornaQuantitaOggetto@OutputServer(cartInUse.objList[index])();

          if (cartInUse.objList[index].amount == 0) {
            undef( cartInUse.objList[index] );
            cartInUse.index--
          };

          aggiornaCarrello@OutputServer(cartInUse)(aggiornato);

          if (aggiornato) {
            println@Console("\nRimosso dal carrello " + qOggetto + " " + nomeOggetto + "!")();
            quan = true
          } 
          else { 
            println@Console("\nERRORE: errore nell'aggiornamento del carrello!")() 
          }

        } else {
          println@Console("\nERRORE: Nome oggetto inesistente!")()
        };

        semaforoFineScrittura@OutputServer(cartInUse.name)(scritto)

      }      
      else {
        cancellato = true
      }
    }
}


//DEFINE generale per l'acquisto di un carrello
define acquistaCart
{
  nomeCarrello = cartInUse.name;
  acquistaCarrello@OutputServer(cartInUse.name)(acquistato);
  if (acquistato) {
    println@Console("\nIl carrello '" + nomeCarrello + "' e' stato acquistato correttamente!" + 
            "\n------------------------------\n")()
    } else {
      println@Console("\nERRORE: Acquisto non valido!" + 
          "\n------------------------------\n")()
    }
}


//DEFINE generale per la cancellazione di un carrello
define cancellaCart
{
  nomeCarrello = cartInUse.name;

  semaforoInizioScrittura@OutputServer(cartInUse.name)(scritto);

  if (scritto) {
    cancellaCarrello@OutputServer(cartInUse)(eliminato);
    if (eliminato) {
      println@Console("\nIl carrello '" + nomeCarrello + "' e' stato cancellato!" + 
              "\n------------------------------\n")()
      } else {
        println@Console("ERRORE: Il carrello '" + nomeCarrello + "'' non e' presente!" + 
            "\n------------------------------\n")()
      }
    } else {
      cancellato = true
    }
}


define aggiornaCart
{
  semaforoInizioLettura@OutputServer(cartInUse.name)(letto);

  if (letto) {
    ricercaCarrello@OutputServer(cartInUse.name)(cart);
    if (cart != "") {
      cartInUse << cart
    } else {
      cancellato = true
    };

    semaforoFineLettura@OutputServer(cartInUse.name)(letto)
    
  } else {
    cancellato = true
  }
}


main
{
  registraClient;
  println@Console( "\nBENVENUTO " + global.Client.name + "!!!\n" )();
  ferma = 0;
  while (ferma == 0) {
      print@Console( "\nCHE OPERAZIONE VUOI EFFETTUARE?:" + 
        "\n1)Visualizza lista oggetti\n2)Vai al carrello\n\n(indicare la scelta con le opzioni 1 o 2) " )();
      operazione = 0;
      while (operazione != "1" && operazione != "2") {
        in( operazione );
        if (operazione == "1") {
        visualizzaListaOggetti;
        sleep@Time(500)()
        } else if (operazione == "2") {
           print@Console( "\nCHE OPERAZIONE VUOI EFFETTUARE?" + 
            "\n1)Crea un nuovo carrello\n2)Vai ad un carrello esistente\n\n(indicare la scelta con le opzioni 1 o 2) " )();
            operazione2 = 0;
            while (operazione2 != "1" && operazione2 != "2") {
              in(operazione2);
              if (operazione2 == "1") {
                creaCarrello
              } else if (operazione2 == "2") {
                visualizzaListaCarrelli;
                sleep@Time(250)();
                if (indice != 0) {
                  scelta = false;
                  while (scelta == false) {
                    print@Console( "\nInserisci il nome del carrello scelto: " )();
                    in(carrello);
                    ricercaCarrello@OutputServer(carrello)(cart);
                    if (cart.name == "") {
                      println@Console( "\nNome carrello inesistente!" )()
                    } else {
                      scelta = true;
                      cartInUse << cart
                    }
                  };
                  cancellato = false;
                  print@Console( "\nCHE OPERAZIONE VUOI EFFETTUARE?" + 
                  "\n1)Visualizza oggetti nel carrello" + 
                  "\n2)Aggiungi oggetti al carrello" + 
                  "\n3)Rimuovi oggetti dal carrello" +
                  "\n4)Acquista carrello" + 
                  "\n5)Cancella carrello" +
                  "\n6)Torna al menu principale" + 
                  "\n\n(indicare la scelta con le opzioni 1, 2, 3, 4, 5 o 6) " )();
                  operazione3 = 0;
                  controllaCarrello@OutputServer(cartInUse.name)(cancellato);
                  while (operazione3 != "6" && operazione3!= "5" && operazione3 != "4" && cancellato == false) {
                    in(operazione3);
                    controllaCarrello@OutputServer(cartInUse.name)(cancellato);

                    if (operazione3 == "1" && cancellato == false) {
                      
                      aggiornaCart;

                      visualizzaOggettiCarrello;
                      if (cancellato == false) {
                        sleep@Time(500)();
                        println@Console("\nVUOI FARE ALTRO?" + 
                          "\n1)Visualizza oggetti nel carrello" + 
                          "\n2)Aggiungi oggetti al carrello" + 
                          "\n3)Rimuovi oggetti dal carrello" +
                          "\n4)Acquista carrello" + 
                          "\n5)Cancella carrello" +
                          "\n6)Torna al menu principale" + 
                          "\n\n(indicare la scelta con le opzioni 1, 2, 3, 4, 5 o 6)")()
                        }
                    } else if (operazione3 == "2" && cancellato == false) {
                      
                      aggiornaCart;

                      inserisciOggetto;
                      if (cancellato == false) {
                        sleep@Time(500)();
                        println@Console("\nVUOI FARE ALTRO?" + 
                          "\n1)Visualizza oggetti nel carrello" + 
                          "\n2)Aggiungi oggetti al carrello" + 
                          "\n3)Rimuovi oggetti dal carrello" +
                          "\n4)Acquista carrello" + 
                          "\n5)Cancella carrello" +
                          "\n6)Torna al menu principale" + 
                          "\n\n(indicare la scelta con le opzioni 1, 2, 3, 4, 5 o 6)")()
                        }
                    } else if (operazione3 == "3" && cancellato == false){

                      aggiornaCart;

                      rimuoviOggetto;
                      if (cancellato == false) {
                        sleep@Time(500)();
                        println@Console("\nVUOI FARE ALTRO?" + 
                          "\n1)Visualizza oggetti nel carrello" + 
                          "\n2)Aggiungi oggetti al carrello" + 
                          "\n3)Rimuovi oggetti dal carrello" +
                          "\n4)Acquista carrello" + 
                          "\n5)Cancella carrello" +
                          "\n6)Torna al menu principale" + 
                          "\n\n(indicare la scelta con le opzioni 1, 2, 3, 4, 5 o 6)")()
                        }
                    } else if (operazione3 == "4" && cancellato == false) {
                      aggiornaCart;
                      acquistaCart;
                      sleep@Time(500)()
                    } else if (operazione3 == "5" && cancellato == false) {
                      aggiornaCart;
                      cancellaCart;
                      sleep@Time(500)()
                    } else if (operazione3 == "6" && cancellato == false) {
                      println@Console("\nSei uscito dal carrello '" + cartInUse.name + "'!")()
                    } else if (cancellato == false ){
                      println@Console( "\n\nScelta opzioni non corretta! Indicare la scelta con le opzioni 1, 2, 3, 4, 5 o 6!" )()
                    }
                  };
                  if (cancellato == true) {
                      println@Console("\nERRORE: il carrello in uso e' stato cancellato!")();
                      sleep@Time(500)()
                    }
                } 
              } else {
                  println@Console( "Scelta opzioni non corretta! Indicare la scelta con le opzioni 1 o 2!" )()
              }
            }
        } else {
          println@Console( "Scelta opzioni non corretta! Indicare la scelta con le opzioni 1 o 2!" )()
        }
      }
    }
}