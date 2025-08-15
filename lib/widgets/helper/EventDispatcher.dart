// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

typedef Notifer1<A1> = void Function(A1 _);
typedef Notifer2<A1, A2> = void Function(A1 _, A2 _);
typedef Notifer3<A1, A2, A3> = void Function(A1 _, A2 _, A3 _);
typedef Notifer4<A1, A2, A3, A4> = void Function(A1 _, A2 _, A3 _, A4 _);
typedef Notifer5<A1, A2, A3, A4, A5> = void Function(A1 _, A2 _, A3 _, A4 _, A5 _);

typedef ChannelNotifer<T> = T Function(List<T> listeners);

abstract class Topic<T extends Function> implements Enum {
  ChannelNotifer<T> get notifier;
}

final class Channel<T extends Function> {
  Channel(Topic<T> topic):
    _notifier = topic.notifier([]),
    _topic = topic;

  T get notify => _notifier;

  set listeners(
    List<List<Function>> listeners
  ) =>_notifier = _topic.notifier(listeners[_topic.index].cast<T>());

  final Topic<T> _topic;
  T _notifier;
}

final class EventDispatcher {
  EventDispatcher(List<Topic> topics): _listeners = List.generate(
    topics.length, (_) => []
  );

  Channel<T> getChannel<T extends Function>(Topic<T> topic) {
    final channel = Channel(topic);
    attachChannel(channel);
    return channel;
  }

  void attachChannel(Channel channel) {
    channel.listeners =_listeners;
    _channels.add(channel);
  }

  void listen<T extends Function>(
    Topic<T> topic, T listener
  ) => _listeners[topic.index].add(listener);

  void syncChannels() {
    for(final channel in _channels) channel.listeners =_listeners;
  }

  final List<List<Function>> _listeners;
  final _channels = <Channel>[];
}

void Function() notifier0(
  List<void Function()> listeners
) => () {
  for(final listener in listeners) listener();
};

void Function(T1 _) notifier1<T1>(
  List<void Function(T1 _)> listeners
) => (a1) {
  for(final listener in listeners) listener(a1);
};

void Function(T1 _, T2 _) notifier2<T1, T2>(
  List<void Function(T1 _, T2 _)> listeners
) => (a1, a2) {
  for(final listener in listeners) listener(a1, a2);
};

void Function(T1 _, T2 _, T3 _) notifier3<T1, T2, T3>(
  List<void Function(T1 _, T2 _, T3 _)> listeners
) => (a1, a2, a3) {
  for(final listener in listeners) listener(a1, a2, a3);
};
