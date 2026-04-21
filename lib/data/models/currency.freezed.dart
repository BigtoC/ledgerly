// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'currency.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Currency {

/// PK. ISO 4217 for fiat, symbol for tokens.
 String get code;/// 2 for USD, 0 for JPY, 18 for ETH/ERC-20.
 int get decimals;/// Display symbol: `$`, `¥`, `NT$`, ...
 String? get symbol;/// Optional localized-name key (SQL column: `name_l10n_key`).
 String? get nameL10nKey;/// Phase 2 token flag. DB default `false`.
 bool get isToken;/// Order in pickers.
 int? get sortOrder;
/// Create a copy of Currency
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurrencyCopyWith<Currency> get copyWith => _$CurrencyCopyWithImpl<Currency>(this as Currency, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Currency&&(identical(other.code, code) || other.code == code)&&(identical(other.decimals, decimals) || other.decimals == decimals)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.nameL10nKey, nameL10nKey) || other.nameL10nKey == nameL10nKey)&&(identical(other.isToken, isToken) || other.isToken == isToken)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,code,decimals,symbol,nameL10nKey,isToken,sortOrder);

@override
String toString() {
  return 'Currency(code: $code, decimals: $decimals, symbol: $symbol, nameL10nKey: $nameL10nKey, isToken: $isToken, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $CurrencyCopyWith<$Res>  {
  factory $CurrencyCopyWith(Currency value, $Res Function(Currency) _then) = _$CurrencyCopyWithImpl;
@useResult
$Res call({
 String code, int decimals, String? symbol, String? nameL10nKey, bool isToken, int? sortOrder
});




}
/// @nodoc
class _$CurrencyCopyWithImpl<$Res>
    implements $CurrencyCopyWith<$Res> {
  _$CurrencyCopyWithImpl(this._self, this._then);

  final Currency _self;
  final $Res Function(Currency) _then;

/// Create a copy of Currency
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? decimals = null,Object? symbol = freezed,Object? nameL10nKey = freezed,Object? isToken = null,Object? sortOrder = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,decimals: null == decimals ? _self.decimals : decimals // ignore: cast_nullable_to_non_nullable
as int,symbol: freezed == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String?,nameL10nKey: freezed == nameL10nKey ? _self.nameL10nKey : nameL10nKey // ignore: cast_nullable_to_non_nullable
as String?,isToken: null == isToken ? _self.isToken : isToken // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Currency].
extension CurrencyPatterns on Currency {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Currency value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Currency() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Currency value)  $default,){
final _that = this;
switch (_that) {
case _Currency():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Currency value)?  $default,){
final _that = this;
switch (_that) {
case _Currency() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  int decimals,  String? symbol,  String? nameL10nKey,  bool isToken,  int? sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Currency() when $default != null:
return $default(_that.code,_that.decimals,_that.symbol,_that.nameL10nKey,_that.isToken,_that.sortOrder);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  int decimals,  String? symbol,  String? nameL10nKey,  bool isToken,  int? sortOrder)  $default,) {final _that = this;
switch (_that) {
case _Currency():
return $default(_that.code,_that.decimals,_that.symbol,_that.nameL10nKey,_that.isToken,_that.sortOrder);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  int decimals,  String? symbol,  String? nameL10nKey,  bool isToken,  int? sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _Currency() when $default != null:
return $default(_that.code,_that.decimals,_that.symbol,_that.nameL10nKey,_that.isToken,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc


class _Currency implements Currency {
  const _Currency({required this.code, required this.decimals, this.symbol, this.nameL10nKey, this.isToken = false, this.sortOrder});
  

/// PK. ISO 4217 for fiat, symbol for tokens.
@override final  String code;
/// 2 for USD, 0 for JPY, 18 for ETH/ERC-20.
@override final  int decimals;
/// Display symbol: `$`, `¥`, `NT$`, ...
@override final  String? symbol;
/// Optional localized-name key (SQL column: `name_l10n_key`).
@override final  String? nameL10nKey;
/// Phase 2 token flag. DB default `false`.
@override@JsonKey() final  bool isToken;
/// Order in pickers.
@override final  int? sortOrder;

/// Create a copy of Currency
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CurrencyCopyWith<_Currency> get copyWith => __$CurrencyCopyWithImpl<_Currency>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Currency&&(identical(other.code, code) || other.code == code)&&(identical(other.decimals, decimals) || other.decimals == decimals)&&(identical(other.symbol, symbol) || other.symbol == symbol)&&(identical(other.nameL10nKey, nameL10nKey) || other.nameL10nKey == nameL10nKey)&&(identical(other.isToken, isToken) || other.isToken == isToken)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,code,decimals,symbol,nameL10nKey,isToken,sortOrder);

@override
String toString() {
  return 'Currency(code: $code, decimals: $decimals, symbol: $symbol, nameL10nKey: $nameL10nKey, isToken: $isToken, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$CurrencyCopyWith<$Res> implements $CurrencyCopyWith<$Res> {
  factory _$CurrencyCopyWith(_Currency value, $Res Function(_Currency) _then) = __$CurrencyCopyWithImpl;
@override @useResult
$Res call({
 String code, int decimals, String? symbol, String? nameL10nKey, bool isToken, int? sortOrder
});




}
/// @nodoc
class __$CurrencyCopyWithImpl<$Res>
    implements _$CurrencyCopyWith<$Res> {
  __$CurrencyCopyWithImpl(this._self, this._then);

  final _Currency _self;
  final $Res Function(_Currency) _then;

/// Create a copy of Currency
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? decimals = null,Object? symbol = freezed,Object? nameL10nKey = freezed,Object? isToken = null,Object? sortOrder = freezed,}) {
  return _then(_Currency(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,decimals: null == decimals ? _self.decimals : decimals // ignore: cast_nullable_to_non_nullable
as int,symbol: freezed == symbol ? _self.symbol : symbol // ignore: cast_nullable_to_non_nullable
as String?,nameL10nKey: freezed == nameL10nKey ? _self.nameL10nKey : nameL10nKey // ignore: cast_nullable_to_non_nullable
as String?,isToken: null == isToken ? _self.isToken : isToken // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
