// SPDX-License-Identifier: GPL-3.0-only
// This file is part of the Verticalysis project which is released under the
// GPLv3 license. Use of this file is governed by terms and conditions that
// can be found in the COPYRIGHT file.

typedef ChunkedStream<T> = Stream<List<T>>;
// TODO: pack more metadata about source into a chunk
typedef IntakeChunk<T extends Comparable> = (Iterable<(String, Iterable<T?>)>, int);
