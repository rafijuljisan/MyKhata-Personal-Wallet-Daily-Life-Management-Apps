// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PartyRepository)
const partyRepositoryProvider = PartyRepositoryProvider._();

final class PartyRepositoryProvider
    extends $NotifierProvider<PartyRepository, void> {
  const PartyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'partyRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$partyRepositoryHash();

  @$internal
  @override
  PartyRepository create() => PartyRepository();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$partyRepositoryHash() => r'ccf9b38834cefad7e74d8dda2f19ae4beca79d07';

abstract class _$PartyRepository extends $Notifier<void> {
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
