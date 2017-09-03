//request response che utilizzo nel service AdminService.ol
interface AdminInterface {
  OneWay: 
  RequestResponse: 
  	ottieniOggetto(void)(int),

  	rimuoviOggetto(void)(void),

    inserisciOggetto(void)(void),
}