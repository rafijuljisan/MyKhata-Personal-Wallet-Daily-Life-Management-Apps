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

String _$cashInHandHash() => r'6a5571ab8b0fafb0ed7ddaa8ff2cf00683f97e83';

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

String _$totalReceivablesHash() => r'b25f65251830423ef5db8382fe4c669e46e16c68';

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

String _$totalPayablesHash() => r'4c060ceb4ba27d3d707e4ae5fb62253c84a801f2';
