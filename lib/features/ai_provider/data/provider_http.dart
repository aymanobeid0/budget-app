import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/ai_provider.dart';
import 'sse.dart';

/// How long a provider gets to answer before it counts as unreachable.
const providerTimeout = Duration(seconds: 15);

/// Turns a provider's error status (and its `error` object, when the body
/// has one) into the outcome the user sees.
typedef ErrorClassifier = ConnectionOutcome Function(int statusCode, Map<String, dynamic>? error);

/// Waits for [response] to start, turning no connection or a timeout into
/// [ConnectionOutcome.unreachable].
Future<T> _reach<T>(Future<T> response) async {
  try {
    return await response.timeout(providerTimeout);
  } on TimeoutException {
    throw ProviderFailure(ConnectionOutcome.unreachable, 'No answer within ${providerTimeout.inSeconds} seconds.');
  } on SocketException catch (e) {
    throw ProviderFailure(ConnectionOutcome.unreachable, e.message);
  } on http.ClientException catch (e) {
    throw ProviderFailure(ConnectionOutcome.unreachable, e.message);
  }
}

/// Runs one request to a provider and returns the response when it succeeds.
/// Anything else is thrown as a [ProviderFailure]: no connection or a
/// timeout is [ConnectionOutcome.unreachable], an error status maps through
/// [classify] (by default [ConnectionOutcome.fromStatusCode]).
Future<http.Response> providerRequest(
  Future<http.Response> Function() send, {
  ErrorClassifier? classify,
}) async {
  final response = await _reach(send());
  if (response.statusCode >= 200 && response.statusCode < 300) return response;
  throw failureFor(response.statusCode, response.body, classify: classify);
}

/// Sends a streaming [request] and returns its SSE `data:` payloads. The
/// timeout covers waiting for the response to start, not the whole reply.
/// Failures are thrown as in [providerRequest]; the connection dropping
/// mid-reply is [ConnectionOutcome.unreachable] too.
Stream<String> providerStream(
  http.Client client,
  http.BaseRequest request, {
  ErrorClassifier? classify,
}) async* {
  final response = await _reach(client.send(request));
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw failureFor(response.statusCode, await response.stream.bytesToString(), classify: classify);
  }
  try {
    // Not yield*: it would pass a dropped connection on without catching it.
    await for (final data in sseData(response.stream)) {
      yield data;
    }
  } on SocketException catch (e) {
    throw ProviderFailure(ConnectionOutcome.unreachable, e.message);
  } on http.ClientException catch (e) {
    throw ProviderFailure(ConnectionOutcome.unreachable, e.message);
  }
}

/// One SSE event's JSON object. A payload that isn't one is
/// [ConnectionOutcome.providerError].
Map<String, dynamic> decodeEvent(String data) {
  try {
    final decoded = jsonDecode(data);
    if (decoded is Map<String, dynamic>) return decoded;
  } on FormatException {
    // Falls through to the failure below.
  }
  throw ProviderFailure(ConnectionOutcome.providerError, 'Unexpected reply: $data');
}

/// The failure for an error response. Providers wrap their message as
/// `{"error": {"message": ...}}`; any other body is shown as it is.
ProviderFailure failureFor(
  int statusCode,
  String body, {
  ErrorClassifier? classify,
}) {
  Map<String, dynamic>? error;
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic> && decoded['error'] is Map<String, dynamic>) {
      error = decoded['error'] as Map<String, dynamic>;
    }
  } on FormatException {
    // Not JSON: keep the raw body as the message.
  }
  final outcome = classify?.call(statusCode, error) ?? ConnectionOutcome.fromStatusCode(statusCode);
  return ProviderFailure(outcome, (error?['message'] as String?) ?? body.trim());
}
