// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_strapi/otel_strapi.dart';

/// Traces Strapi calls with OpenTelemetry.
///
/// `otel_strapi` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Strapi call in
/// [tracedStrapi]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'strapi-example');

  // Wraps a Strapi REST/GraphQL call in a CLIENT span.
  final strapiId = await tracedStrapi<String>(
    operation: 'create',
    api: 'example',
    contentType: 'standard',
    invoke: () async {
      // Make the Strapi call here, then report what it returned.
      const id = 'strapi_8f3a2c';
      return const StrapiCallResult(
          value: id,
          result: StrapiResult(
              itemCount: 3,
              total: 1,
              page: 1,
              pageSize: 512,
              populateDepth: 1,
              contentType: 'api::article.article',
              locale: 'en-US',
              draftMode: true,
              deploymentTier: 'cloud',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedStrapi create returned $strapiId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutStrapiInstrumentationAsync.
  await runWithoutStrapiInstrumentationAsync(
    () => tracedStrapi<String>(
      operation: 'create',
      api: 'example',
      contentType: 'standard',
      invoke: () async {
        const id = 'strapi_8f3a2c';
        return const StrapiCallResult(
            value: id,
            result: StrapiResult(
                itemCount: 3,
                total: 1,
                page: 1,
                pageSize: 512,
                populateDepth: 1,
                contentType: 'api::article.article',
                locale: 'en-US',
                draftMode: true,
                deploymentTier: 'cloud',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
