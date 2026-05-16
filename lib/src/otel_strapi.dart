// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_strapi_suppression.dart';

const _tracerName = 'dartastic_otel_libs_strapi';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class StrapiResult {
  const StrapiResult({
    this.itemCount,
    this.total,
    this.page,
    this.pageSize,
    this.populateDepth,
    this.contentType,
    this.locale,
    this.draftMode,
    this.deploymentTier,
    this.requestId,
    this.statusCode,
  });

  /// Number of rows returned in `data[]`.
  final int? itemCount;

  /// `meta.pagination.total`.
  final int? total;

  final int? page;
  final int? pageSize;

  /// `populate=*` depth or count of populated relations — bloat
  /// detector for Strapi N+1 patterns.
  final int? populateDepth;

  /// Strapi content-type UID, e.g. `api::article.article`.
  final String? contentType;

  final String? locale;

  /// Whether `publicationState=preview` (draft mode) was used.
  final bool? draftMode;

  /// `cloud` / `enterprise` / `community` — Strapi Cloud cost class
  /// when hosted by Strapi.
  final String? deploymentTier;

  /// `x-request-id` (when middleware emits it).
  final String? requestId;

  final int? statusCode;
}

class StrapiCallResult<T> {
  const StrapiCallResult({required this.value, this.result});
  final T value;
  final StrapiResult? result;
}

/// Wraps a Strapi REST/GraphQL call in a CLIENT span. [operation] is
/// one of `find`, `findOne`, `create`, `update`, `delete`, `publish`,
/// `unpublish`, `graphql`, `upload`, `i18n.locales.list`.
Future<T> tracedStrapi<T>({
  required String operation,
  required Future<StrapiCallResult<T>> Function() invoke,
  String? api,
  String? contentType,
}) async {
  if (strapiInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'strapi',
    'rpc.method': operation,
    'strapi.operation': operation,
  };
  if (api != null) m['strapi.api'] = api;
  if (contentType != null) m['strapi.content_type'] = contentType;

  final span = _tracer().startSpan(
    'strapi $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'strapi.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.total != null) {
        extras.add(OTel.attributeInt('strapi.total', r.result!.total!));
      }
      if (r.result!.page != null) {
        extras.add(OTel.attributeInt('strapi.page', r.result!.page!));
      }
      if (r.result!.pageSize != null) {
        extras.add(OTel.attributeInt(
          'strapi.page_size',
          r.result!.pageSize!,
        ));
      }
      if (r.result!.populateDepth != null) {
        extras.add(OTel.attributeInt(
          'strapi.populate_depth',
          r.result!.populateDepth!,
        ));
      }
      if (r.result!.contentType != null) {
        extras.add(OTel.attributeString(
          'strapi.content_type',
          r.result!.contentType!,
        ));
      }
      if (r.result!.locale != null) {
        extras.add(OTel.attributeString(
          'strapi.locale',
          r.result!.locale!,
        ));
      }
      if (r.result!.draftMode != null) {
        extras.add(OTel.attributeBool(
          'strapi.draft_mode',
          r.result!.draftMode!,
        ));
      }
      if (r.result!.deploymentTier != null) {
        extras.add(OTel.attributeString(
          'strapi.deployment.tier',
          r.result!.deploymentTier!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'strapi.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Strapi HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
