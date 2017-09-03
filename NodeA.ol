include "console.iol"
include "time.iol"
include "string_utils.iol"
include "math.iol"
include "semaphore_utils.iol"


include "Raft.iol"

/*
outputPort OutputRaft {
  Location: "socket://localhost:8002"
  Protocol: sodep
  Interfaces: RaftInterface
}
*/

inputPort InputNode {
  Location: "socket://localhost:8005"
  Protocol: sodep
  Interfaces: RaftInterface
}


inputPort NodeTimeout {
  Location: "local"
  Interfaces: RaftInterface
}


outputPort OutputNodeB {
  Location: "socket://localhost:8006"
  Protocol: sodep
  Interfaces: RaftInterface
}

outputPort OutputNodeC {
  Location: "socket://localhost:8007"
  Protocol: sodep
  Interfaces: RaftInterface
}


execution{ concurrent }


constants {
  FOLLOWER = "FOLLOWER",
  CANDIDATE = "CANDIDATE",
  LEADER = "LEADER",
  HEARTBEAT = 100
}


cset {
  location: HeartBeat.location
}


define updateTerm {
  //synchronized( state ) {
    if ( req.term > global.server.currentTerm ) {
      //log@DebugLogService(("updateTerm: req.term (" + req.term + ") > currentTerm (" + global.currentTerm + "), update term " ) { .server = NODE_LOCATION } );
      global.server.state = FOLLOWER;
      global.server.currentTerm = req.term;
      global.server.votedFor = "-1"
   }
  //}
}


define sendHeartBeats {

  global.appendEntriesReq.term = global.server.currentTerm;
  global.appendEntriesReq.leaderId = global.server.location;
  global.appendEntriesReq.prevLogIndex = global.server.lastLogIndex;
  global.appendEntriesReq.prevLogTerm = global.server.lastLogIndex;
  global.appendEntriesReq.leaderCommit = void;

  // log@DebugLogService("heartbeat: sending to server " + global.servers[i] { .server = NODE_LOCATION } );
  {  
    {
      acquire@SemaphoreUtils( semRequestVote)( res );//prendo il lock sulla richiesta di voto;
        
      if (global.server.state == LEADER) {
        {
          scope( scopeConnectionB )
          {
            install( IOException => println@Console(OutputNodeB.location + " ha rifiutato la connessione. Server offline.")() );
            appendEntries @ OutputNodeB (global.appendEntriesReq) (appendEntriesRespB);
            if ( appendEntriesRespB.success == false) {
              global.server.currentTerm = appendEntriesRespB.term;
              global.server.state = FOLLOWER;
              global.server.votedFor = -1;
              undef(global.server.nextIndices);
              undef(global.server.matchIndices);

              setNextTimeout@Time ( global.myNodeTimeout )
            }
          }
        }
      };
        release@SemaphoreUtils( semRequestVote)( res )//rilascio il lock sulla richiesta di voto
    }

    |

    {
      acquire@SemaphoreUtils( semRequestVote)( res );//prendo il lock sulla richiesta di voto;

      if (global.server.state == LEADER) {
        {
          scope( scopeConnectionC )
          {
            install( IOException => println@Console(OutputNodeC.location + " ha rifiutato la connessione. Server offline.")() );
            appendEntries @ OutputNodeC (global.appendEntriesReq) (appendEntriesRespC);
            if ( appendEntriesRespC.success == false) {
              global.server.currentTerm = appendEntriesRespC.term;
              global.server.state = FOLLOWER;
              global.server.votedFor = -1;
              undef(global.server.nextIndices);
              undef(global.server.matchIndices);

              setNextTimeout@Time ( global.myNodeTimeout )
            }
          }
        }
      };  
      release@SemaphoreUtils( semRequestVote)( res )//rilascio il lock sulla richiesta di voto
    }
  };

  if (global.server.state == LEADER) {
    global.heartbeat = 100;
    global.heartbeat.operation = "heartbeat";
    global.heartbeat.message.location = global.server.location;

    setNextTimeout@Time(global.heartbeat);

    println@Console("Io sono il LEADER")()
  }
}


init {

  semRequestVote.name = "Richiesta voto";
  semRequestVote.permits = 1;
  release@SemaphoreUtils( semRequestVote )( res );


  global.server.location = "socket://localhost:8005";
    
  global.server.state = FOLLOWER;

  global.server.currentTerm = 0;
  global.server.votedFor = "-1";

  global.server.log = 1;
  global.server.commitIndex = 0;
  global.server.lastApplied = 0;

  //csets.location = server.location;
  //registraServer@OutputRaft()(server);
  println@Console( "IO SONO " + global.server.state + " con indirizzo " + global.server.location)();
    
  //Si imposta un election timeout casuale per ogni server
  random@Math()(randomDouble);
  round@Math((10000 + randomDouble * 150 ) { .decimals = 0 } ) (timeout);
  global.myNodeTimeout = int (timeout);
  println@Console("Timeout value: " + global.myNodeTimeout)();

  global.myNodeTimeout.operation = "timeout";
  global.myNodeTimeout.message.location = global.server.location;
  setNextTimeout@Time ( global.myNodeTimeout)
}

main
{
  [heartbeat()]{
    sendHeartBeats
  }


  [timeout()] {
    if (global.server.state == LEADER) {
      println@Console( "timeout arrivato alla porta del LEADER" + global.server.location )()
    } 
    else
    {
      println@Console( "timeout arrivato alla porta " + global.server.location )();

      global.server.state = CANDIDATE;
      global.server.currentTerm = global.server.currentTerm + 1;
      global.server.votedFor = global.server.location;
      
      global.requestVoteReq.term = global.server.currentTerm;
      global.requestVoteReq.candidateId = global.server.location;
      global.requestVoteReq.lastLogIndex =  global.server.log;
      global.requestVoteReq.lastLogTerm =  global.server.log;
      
      voteCount = 1;
      serversCount=1;

      setNextTimeout@Time( global.myNodeTimeout);

      {
        {
          acquire@SemaphoreUtils( semRequestVote)( res );//prendo il lock sulla richiesta di voto;
          {
            scope( scopeConnectionB )
            {

              install( IOException => println@Console(OutputNodeB.location + " ha rifiutato la connessione. Server offline.")() );
              requestVote@OutputNodeB(global.requestVoteReq)(requestVoteResB);

              if ( requestVoteResB.voteGranted ) {
                voteCount++
                //log@DebugLogService(("Got vote from " + requestVoteReq.servers[i]) { .server = NODE_LOCATION } )
              };

              if (is_defined( requestVoteResB.term )) {
                serversCount++
              };
              println@Console(serversCount)()
            }
          };
          release@SemaphoreUtils( semRequestVote)( res )//rilascio il lock sulla richiesta di voto
        }

        |

        {
          acquire@SemaphoreUtils( semRequestVote)( res );//prendo il lock sulla richiesta di voto
          {
            scope( scopeConnectionB )
            {
              install( IOException => println@Console(OutputNodeC.location + " ha rifiutato la connessione. Server offline.")() );
              requestVote@OutputNodeC(global.requestVoteReq)(requestVoteResC);       
              
               if ( requestVoteResC.voteGranted ) {
                voteCount++
                //log@DebugLogService(("Got vote from " + requestVoteReq.servers[i]) { .server = NODE_LOCATION } )
              };

              if (is_defined( requestVoteResC.term )) {
                serversCount++
              };
              println@Console(serversCount)()
            }
          };
          release@SemaphoreUtils( semRequestVote)( res )//rilascio il lock sulla richiesta di voto
        }
      };

      if ( global.server.state == CANDIDATE ) {
        // se ha la maggioranza dei voti diventerà LEADER
        if ( voteCount > (serversCount/2) ) {
          //log@DebugLogService(("timeout: candidate won. Setting state LEADER and start sending heartbeats, term " + global.currentTerm ) { .server = NODE_LOCATION } );
          global.server.state = LEADER;
          global.server.nextIndices =  server.log + 1;
          global.server.matchIndices = 0;
          println@Console("Sono il nuovo LEADER muahahahahaha!!!")();
          sendHeartBeats
          
        }
        else { //non ha la maggioranza, ci sarà un altro leader o una nuova elezione
          //log@DebugLogService("timeout: candidate did not win. Setting state FOLLOWER and resetting timeout" { .server = NODE_LOCATION } );
          global.server.state = FOLLOWER;
          global.server.votedFor = "-1";
          setNextTimeout@Time(global.myNodeTimeout)
        }
      }
    }
  }


  //term, candicateId, lastLogIndex , lastLogTerm
  [ requestVote ( req ) ( resp ) {
    
    println@Console("sono quaaaaaaaa")();
    updateTerm;

    if ( global.server.state != LEADER ) {
      setNextTimeout@Time (global.myNodeTimeout)
    };

    if ( req.term == global.server.currentTerm && ( global.server.votedFor == "-1" || global.server.votedFor == req.candidateId ) ) {
      global.server.votedFor = req.candidateId;
      resp.voteGranted = true
      //log@DebugLogService(("RequestVote: voted yes to " + req.candidateId + " with term " + req.term ) { .server = NODE_LOCATION } )
    }
    else {
      //log@DebugLogService(("RequestVote: voted no to " + req.candidateId ) { .server = NODE_LOCATION } );
      resp.voteGranted = false
    };
    resp.term = global.server.currentTerm
  } ]


  [ appendEntries ( req ) ( resp ) {
    
    updateTerm; /* Notice: if req.term was larger than global.currentTerm, then they now would be 
                   equal now because of updateTerm */

    /* always give currentTerm to requester */
    resp.term = server.currentTerm;

    if (global.server.state == FOLLOWER ) {
      //reset timeout
      setNextTimeout@Time ( global.myNodeTimeout )
    };

    // Se il termine dell'Append è scaduto, viene rigettata la richiesta
    if ( req.term < global.server.currentTerm ) {
      resp.success = false
    };

    if ( req.term == global.server.currentTerm && global.server.state == CANDIDATE ) {
      global.server.state = FOLLOWER
    };
    
    if ( req.term == global.server.currentTerm && global.server.state == FOLLOWER ) {
      resp.success = true;
      println@Console("Io sono FOLLOWER")()
    }
/*
    if ( req.term == global.currentTerm && global.state == LEADER ) {
      log@DebugLogService(("DET SEJLER TOTALT! " + global.currentTerm ) { .server = NODE_LOCATION } );
      valueToPrettyString@StringUtils(debugreq) (debugstring1);
      log@DebugLogService(("1 -> " + debugstring1 ) { .server = NODE_LOCATION } );
      valueToPrettyString@StringUtils(global) (debugstring2);
      log@DebugLogService(("2 -> " + debugstring2 ) { .server = NODE_LOCATION } )
    }
  */
  }]
 
}