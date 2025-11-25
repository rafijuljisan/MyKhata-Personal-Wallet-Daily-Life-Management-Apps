// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bike_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BikeRepository)
const bikeRepositoryProvider = BikeRepositoryProvider._();

final class BikeRepositoryProvider
    extends $NotifierProvider<BikeRepository, void> {
  const BikeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bikeRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bikeRepositoryHash();

  @$internal
  @override
  BikeRepository create() => BikeRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$bikeRepositoryHash() => r'c19c9a7ade1aba6d5e189d53d9c9face68682d3c';

abstract class _$BikeRepository extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
