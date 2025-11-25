// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cashInHand)
const cashInHandProvider = CashInHandProvider._();

final class CashInHandProvider
    extends $FunctionalProvider<AsyncValue<double>, double, Stream<double>>
    with $FutureModifier<double>, $StreamProvider<double> {
  const CashInHandProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cashInHandProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cashInHandHash();

  @$internal
  @override
  $StreamProviderElement<double> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double> create(Ref ref) {
    return cashInHand(ref);
  }
}

String _$cashInHandHash() => r'baed67cef8a4c3695f3680a25a523f022d0deac0';

@ProviderFor(totalReceivables)
const totalReceivablesProvider = TotalReceivablesProvider._();

final class TotalReceivablesProvider
    extends $FunctionalProvider<AsyncValue<double>, double, Stream<double>>
    with $FutureModifier<double>, $StreamProvider<double> {
  const TotalReceivablesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalReceivablesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalReceivablesHash();

  @$internal
  @override
  $StreamProviderElement<double> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double> create(Ref ref) {
    return totalReceivables(ref);
  }
}

String _$totalReceivablesHash() => r'a17c61bd20dfdb7337960cda89c47a307b85fb6b';

@ProviderFor(totalPayables)
const totalPayablesProvider = TotalPayablesProvider._();

final class TotalPayablesProvider
    extends $FunctionalProvider<AsyncValue<double>, double, Stream<double>>
    with $FutureModifier<double>, $StreamProvider<double> {
  const TotalPayablesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'totalPayablesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$totalPayablesHash();

  @$internal
  @override
  $StreamProviderElement<double> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<double> create(Ref ref) {
    return totalPayables(ref);
  }
}

String _$totalPayablesHash() => r'42b433d181e7e5e4aafc82b1ddc13ddf4aa4b8a9';
