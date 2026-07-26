enum CrewProcess {
  /// Each task runs in order; later agents see earlier outputs.
  sequential,

  /// Manager agent runs first, then delegates remaining tasks in order.
  hierarchical,

  /// Sequential analysis, then agents debate and reach consensus.
  debate,
}
