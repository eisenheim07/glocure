/// Events for Home Banner Cubit
/// Events are actions that the UI can trigger
/// Think of events as "what the user wants to do"

/// Base class for all home banner events
abstract class HomeBannerEvent {}

/// Event to fetch home top banners
/// This event is triggered when we want to load banner data from the API
class FetchHomeBannersEvent extends HomeBannerEvent {
  FetchHomeBannersEvent();
}

/// Event to refresh home top banners
/// This event can be used to reload the banners
class RefreshHomeBannersEvent extends HomeBannerEvent {
  RefreshHomeBannersEvent();
}
