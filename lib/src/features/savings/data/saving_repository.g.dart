// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saving_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SavingRepository)
const savingRepositoryProvider = SavingRepositoryProvider._();

final class SavingRepositoryProvider
    extends $NotifierProvider<SavingRepository, void> {
  const SavingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savingRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savingRepositoryHash();

  @$internal
  @override
  SavingRepository create() => SavingRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$savingRepositoryHash() => r'56c5e0b1da5100cf5e721a9d67f0e815aa80cb91';

abstract class _$SavingRepository extends $Notifier<void> {
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
