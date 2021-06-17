extension MyIterable<T> on Iterable<T> {
  T? elementAtOrNull(final int? index) {
    if (index != null && index >= 0 && index < length) {
      return elementAt(index);
    }
    return null;
  }
}
