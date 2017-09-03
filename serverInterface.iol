//struttura oggetto
type Object: void {
	.name: string
	.amount: int
    .price: double
    .index: int
}

//struttura client
type Client: void {
		.name: string
        .index: int
}


//struttura carrello
type Cart: void {
	.name : string
	.objList[0, *] : Object
	.index : int
	.price : double
	.archiviato? : bool
}

//Request Response che uso nei server
interface ServerInterface {
    RequestResponse: 

    creaAccount(string)(Client), 

    registraOggetto(Object)(Object),
	rimuoviOggetto(int)(bool),
    aggiornaQuantitaOggetto(Object)(void),
    controllaMaxId(void)(int),
    stampaLista(int)(Object),
    ricercaOggetto(int)(Object),

    creaCarrello(string)(bool),
    cancellaCarrello(Cart)(bool),
    controllaMaxCart(void)(int),
    stampaListaCart(int)(string),
    ricercaCarrello(string)(Cart),
    aggiornaCarrello(Cart)(bool),
    acquistaCarrello(string)(bool),
    controllaCarrello(string)(bool),

    semaforoInizioLettura(string)(bool),
    semaforoFineLettura(string)(bool),
    semaforoInizioScrittura(string)(bool),
    semaforoFineScrittura(string)(bool)


}