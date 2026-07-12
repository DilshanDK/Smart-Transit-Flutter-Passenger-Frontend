class TicketState {
  final String? qrToken;
  final bool isLoading;
  final String? error;
  final int secondsRemaining;
  final Map<String, dynamic>? activeJourney;

  const TicketState({
    this.qrToken,
    this.isLoading = false,
    this.error,
    this.secondsRemaining = 30,
    this.activeJourney,
  });

  TicketState copyWith({
    String? qrToken,
    bool? isLoading,
    String? error,
    int? secondsRemaining,
    Map<String, dynamic>? activeJourney,
    bool clearQrToken = false,
    bool clearError = false,
    bool clearActiveJourney = false,
  }) {
    return TicketState(
      qrToken: clearQrToken ? null : (qrToken ?? this.qrToken),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      activeJourney: clearActiveJourney ? null : (activeJourney ?? this.activeJourney),
    );
  }
}
