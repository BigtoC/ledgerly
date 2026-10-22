// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PendingTransaction {

 int get id; String get source; int get amountMinorUnits; Currency get currency; int? get categoryId; int get accountId; String? get memo; DateTime get date; DateTime get fetchedAt; int? get recurringRuleId;
/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingTransactionCopyWith<PendingTransaction> get copyWith => _$PendingTransactionCopyWithImpl<PendingTransaction>(this as PendingTransaction, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PendingTransaction;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingTransaction&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.source, _this.source) || other.source == _this.source)&&(identical(other.amountMinorUnits, _this.amountMinorUnits) || other.amountMinorUnits == _this.amountMinorUnits)&&(identical(other.currency, _this.currency) || other.currency == _this.currency)&&(identical(other.categoryId, _this.categoryId) || other.categoryId == _this.categoryId)&&(identical(other.accountId, _this.accountId) || other.accountId == _this.accountId)&&(identical(other.memo, _this.memo) || other.memo == _this.memo)&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.fetchedAt, _this.fetchedAt) || other.fetchedAt == _this.fetchedAt)&&(identical(other.recurringRuleId, _this.recurringRuleId) || other.recurringRuleId == _this.recurringRuleId));
}


@override
int get hashCode {
  final _this = this as PendingTransaction;
  return Object.hash(runtimeType,_this.id,_this.source,_this.amountMinorUnits,_this.currency,_this.categoryId,_this.accountId,_this.memo,_this.date,_this.fetchedAt,_this.recurringRuleId);
}

@override
String toString() {
  final _this = this as PendingTransaction;
  return 'PendingTransaction(id: ${_this.id}, source: ${_this.source}, amountMinorUnits: ${_this.amountMinorUnits}, currency: ${_this.currency}, categoryId: ${_this.categoryId}, accountId: ${_this.accountId}, memo: ${_this.memo}, date: ${_this.date}, fetchedAt: ${_this.fetchedAt}, recurringRuleId: ${_this.recurringRuleId})';
}


}

/// @nodoc
abstract mixin class $PendingTransactionCopyWith<$Res>  {
  factory $PendingTransactionCopyWith(PendingTransaction value, $Res Function(PendingTransaction) _then) = _$PendingTransactionCopyWithImpl;
@useResult
$Res call({
 int id, String source, int amountMinorUnits, Currency currency, int? categoryId, int accountId, String? memo, DateTime date, DateTime fetchedAt, int? recurringRuleId
});


$CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class _$PendingTransactionCopyWithImpl<$Res>
    implements $PendingTransactionCopyWith<$Res> {
  _$PendingTransactionCopyWithImpl(this._self, this._then);

  final PendingTransaction _self;
  final $Res Function(PendingTransaction) _then;

/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? source = null,Object? amountMinorUnits = null,Object? currency = null,Object? categoryId = freezed,Object? accountId = null,Object? memo = freezed,Object? date = null,Object? fetchedAt = null,Object? recurringRuleId = freezed,}) {
  return _then(PendingTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,recurringRuleId: freezed == recurringRuleId ? _self.recurringRuleId : recurringRuleId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res> get currency {
  
  return $CurrencyCopyWith<$Res>(_self.currency, (value) {
    return _then(_self.copyWith(currency: value));
  });
}
}


/// Adds pattern-matching-related methods to [PendingTransaction].
extension PendingTransactionPatterns on PendingTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingTransaction value)  $default,){
final _that = this;
switch (_that) {
case _PendingTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _PendingTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String source,  int amountMinorUnits,  Currency currency,  int? categoryId,  int accountId,  String? memo,  DateTime date,  DateTime fetchedAt,  int? recurringRuleId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingTransaction() when $default != null:
return $default(_that.id,_that.source,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.memo,_that.date,_that.fetchedAt,_that.recurringRuleId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String source,  int amountMinorUnits,  Currency currency,  int? categoryId,  int accountId,  String? memo,  DateTime date,  DateTime fetchedAt,  int? recurringRuleId)  $default,) {final _that = this;
switch (_that) {
case _PendingTransaction():
return $default(_that.id,_that.source,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.memo,_that.date,_that.fetchedAt,_that.recurringRuleId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String source,  int amountMinorUnits,  Currency currency,  int? categoryId,  int accountId,  String? memo,  DateTime date,  DateTime fetchedAt,  int? recurringRuleId)?  $default,) {final _that = this;
switch (_that) {
case _PendingTransaction() when $default != null:
return $default(_that.id,_that.source,_that.amountMinorUnits,_that.currency,_that.categoryId,_that.accountId,_that.memo,_that.date,_that.fetchedAt,_that.recurringRuleId);case _:
  return null;

}
}

}

/// @nodoc


class _PendingTransaction implements PendingTransaction {
  const _PendingTransaction({required this.id, required this.source, required this.amountMinorUnits, required this.currency, this.categoryId, required this.accountId, this.memo, required this.date, required this.fetchedAt, this.recurringRuleId});
  

@override final  int id;
@override final  String source;
@override final  int amountMinorUnits;
@override final  Currency currency;
@override final  int? categoryId;
@override final  int accountId;
@override final  String? memo;
@override final  DateTime date;
@override final  DateTime fetchedAt;
@override final  int? recurringRuleId;

/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingTransactionCopyWith<_PendingTransaction> get copyWith => __$PendingTransactionCopyWithImpl<_PendingTransaction>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.amountMinorUnits, amountMinorUnits) || other.amountMinorUnits == amountMinorUnits)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.date, date) || other.date == date)&&(identical(other.fetchedAt, fetchedAt) || other.fetchedAt == fetchedAt)&&(identical(other.recurringRuleId, recurringRuleId) || other.recurringRuleId == recurringRuleId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,source,amountMinorUnits,currency,categoryId,accountId,memo,date,fetchedAt,recurringRuleId);
}

@override
String toString() {
    return 'PendingTransaction(id: $id, source: $source, amountMinorUnits: $amountMinorUnits, currency: $currency, categoryId: $categoryId, accountId: $accountId, memo: $memo, date: $date, fetchedAt: $fetchedAt, recurringRuleId: $recurringRuleId)';
}


}

/// @nodoc
abstract mixin class _$PendingTransactionCopyWith<$Res> implements $PendingTransactionCopyWith<$Res> {
  factory _$PendingTransactionCopyWith(_PendingTransaction value, $Res Function(_PendingTransaction) _then) = __$PendingTransactionCopyWithImpl;
@override @useResult
$Res call({
 int id, String source, int amountMinorUnits, Currency currency, int? categoryId, int accountId, String? memo, DateTime date, DateTime fetchedAt, int? recurringRuleId
});


@override $CurrencyCopyWith<$Res> get currency;

}
/// @nodoc
class __$PendingTransactionCopyWithImpl<$Res>
    implements _$PendingTransactionCopyWith<$Res> {
  __$PendingTransactionCopyWithImpl(this._self, this._then);

  final _PendingTransaction _self;
  final $Res Function(_PendingTransaction) _then;

/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? source = null,Object? amountMinorUnits = null,Object? currency = null,Object? categoryId = freezed,Object? accountId = null,Object? memo = freezed,Object? date = null,Object? fetchedAt = null,Object? recurringRuleId = freezed,}) {
  return _then(_PendingTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,amountMinorUnits: null == amountMinorUnits ? _self.amountMinorUnits : amountMinorUnits // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as Currency,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,fetchedAt: null == fetchedAt ? _self.fetchedAt : fetchedAt // ignore: cast_nullable_to_non_nullable
as DateTime,recurringRuleId: freezed == recurringRuleId ? _self.recurringRuleId : recurringRuleId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of PendingTransaction
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res> get currency {
  
  return $CurrencyCopyWith<$Res>(_self.currency, (value) {
    return _then(_self.copyWith(currency: value));
  });
}
}

// dart format on
