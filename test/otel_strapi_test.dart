// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_strapi/otel_strapi.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_strapi-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('find records populate_depth + content_type + draft', () async {
    await tracedStrapi<String>(
      operation: 'find',
      api: 'rest',
      invoke: () async => const StrapiCallResult(
        value: 'ok',
        result: StrapiResult(
          itemCount: 10,
          total: 200,
          page: 1,
          pageSize: 10,
          populateDepth: 3,
          contentType: 'api::article.article',
          locale: 'en',
          draftMode: true,
          deploymentTier: 'cloud',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('strapi find')!);
    expect(a['strapi.api'], 'rest');
    expect(a['strapi.populate_depth'], 3);
    expect(a['strapi.content_type'], 'api::article.article');
    expect(a['strapi.draft_mode'], true);
    expect(a['strapi.deployment.tier'], 'cloud');
  });

  test('suppression skips spans', () async {
    await runWithoutStrapiInstrumentationAsync(() async {
      await tracedStrapi<String>(
        operation: 'find',
        invoke: () async => const StrapiCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('strapi '), isEmpty);
  });
}
