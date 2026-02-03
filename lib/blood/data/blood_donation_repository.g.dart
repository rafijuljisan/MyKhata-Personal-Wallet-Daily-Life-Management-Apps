// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blood_donation_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BloodRepository)
const bloodRepositoryProvider = BloodRepositoryProvider._();

final class BloodRepositoryProvider
    extends $NotifierProvider<BloodRepository, void> {
  const BloodRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bloodRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bloodRepositoryHash();

  @$internal
  @override
  BloodRepository create() => BloodRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$bloodRepositoryHash() => r'b3075eb759ef99d881a948ce2356724c94384b81';

abstract class _$BloodRepository extends $Notifier<void> {
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
