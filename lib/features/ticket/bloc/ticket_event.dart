abstract class TicketEvent {
  const TicketEvent();
}

class StartTicketLoop extends TicketEvent {
  const StartTicketLoop();
}

class StopTicketLoop extends TicketEvent {
  const StopTicketLoop();
}

class TickTimer extends TicketEvent {
  const TickTimer();
}

class FetchTokenRequested extends TicketEvent {
  const FetchTokenRequested();
}

class CheckActiveJourneyRequested extends TicketEvent {
  const CheckActiveJourneyRequested();
}
