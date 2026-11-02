/// Whether Firebase started. It doesn't on platforms with no Firebase
/// configuration (iOS and desktop), where only local storage works.
bool firebaseReady = false;
